# Linux

# 1 - builddir
# 2 - defconfig
# 3 - stamp
# 4 - buildroot name
# 5 - toolchain prefix

LINUX_MAKE=$(MAKE) -C linux O=../$1 ARCH=m68k CROSS_COMPILE=../buildroot_$4/host/bin/$5
LINUX_PREFIX=build/linux
LINUX_STAMP_CONFIGURED=build/linux.$3.configured.stamp
LINUX_STAMP_BUILD=build/linux.$3.build.stamp
LINUX_TARBALL=build/linux.$3.tar.gz

$(eval $(call git_hash,$(LINUX_PREFIX),linux))

define create_linux_target
$(LINUX_STAMP_CONFIGURED):
	@echo "CONFIGURE linux"
	$(LINUX_MAKE) $2
	@touch $$@

$(LINUX_STAMP_BUILD): $(LINUX_STAMP_CONFIGURED) $(LINUX_PREFIX).hash
	@echo "BUILD linux ($3)"
	$(LINUX_MAKE) -j12
	@touch $$@

# For CI
ifdef CI
$(LINUX_TARBALL): $(LINUX_STAMP_BUILD)
	tar czf $$@ $1 \
		$(LINUX_STAMP_CONFIGURED) \
		$(LINUX_STAMP_BUILD) \
		$(LINUX_PREFIX).hash
endif
#

linux-all:: $(LINUX_STAMP_BUILD)

.PHONY: linux-$3-build
linux-$3-build: $(LINUX_STAMP_BUILD)

.PHONY: linux-$3-build-force
linux-$3-build-force:
	@echo "BUILD FORCE linux ($3)"
	$(LINUX_MAKE) -j12
	@touch $(LINUX_STAMP_BUILD)

linux-$3-menuconfig:
	$(LINUX_MAKE) menuconfig

linux-$3-savedefconfig:
	$(LINUX_MAKE) savedefconfig
	mv $1/defconfig linux/arch/m68k/configs/$2
endef
