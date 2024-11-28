# 1 - builddir
# 2 - defconfig
# 3 - stamp
# 4 - buildroot name
# 5 - toolchain prefix

UBOOT_MAKE=$(MAKE) -C u-boot O=../$1 CROSS_COMPILE=`realpath build/buildroot_$4/host/bin/`/$5
UBOOT_CONFIG=$1/.config
UBOOT_PREFIX=build/u-boot
UBOOT_STAMP_CONFIGURED=build/u-boot.$3.configured.stamp
UBOOT_STAMP_BUILD=build/u-boot.$3.build.stamp

$(eval $(call git_hash,$(UBOOT_PREFIX),u-boot))

define create_uboot_target
$(UBOOT_STAMP_CONFIGURED): $(BUILDROOT_BUILT)
	@echo "CONFIGURE u-boot"
	$(UBOOT_MAKE) $2
	@touch $$@

$(UBOOT_STAMP_BUILD): $(UBOOT_STAMP_CONFIGURED) $(UBOOT_PREFIX).hash $(UBOOT_CONFIG) $(BUILDROOT_BUILT)
	@echo "BUILD u-boot"
	$(UBOOT_MAKE) -j12
	@touch $$@

u-boot-all:: $(UBOOT_STAMP_BUILD)

.PHONY: u-boot-$3-menuconfig
u-boot-$3-menuconfig:
	$(UBOOT_MAKE) menuconfig

u-boot-$3-savedefconfig:
	$(UBOOT_MAKE) savedefconfig

endef
