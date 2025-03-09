QEMU_CMDLINE_COMMON=-nic user,tftp=bootfiles/
QEMU_CPU ?= m68000
QEMU_BUILDDIR=build/qemu
QEMU_PREFIX=build/qemu
QEMU_STAMP_CONFIGURE=build/qemu.configure.stamp
QEMU_STAMP_BUILD=build/qemu.build.stamp
QEMU_TARBALL=build/qemu.tar.gz
QEMU_BIN=$(QEMU_BUILDDIR)/qemu-system-m68k

$(QEMU_BUILDDIR): | build
	mkdir $@

$(QEMU_STAMP_CONFIGURE): | $(QEMU_BUILDDIR)
	cd $(QEMU_BUILDDIR) && ../../qemu/configure --target-list=m68k-softmmu --enable-sdl --enable-slirp
	touch $@

$(eval $(call git_hash,$(QEMU_PREFIX),qemu))

$(QEMU_STAMP_BUILD): $(QEMU_STAMP_CONFIGURE) $(QEMU_PREFIX).hash
	cd $(QEMU_BUILDDIR) && make
	touch $@

# For CI
ifdef CI
.PHONY: $(QEMU_TARBALL)
$(QEMU_TARBALL): $(QEMU_STAMP_BUILD)
	tar czf $@ $(QEMU_BUILDDIR) \
		$(QEMU_STAMP_BUILD) \
		$(QEMU_STAMP_CONFIGURE) \
		$(QEMU_PREFIX).hash
endif
#

# - 1 name
# - 2 name caps
define create_qemu_target
run-qemu-$1: $(QEMU_STAMP_BUILD) $(QEMU_DEPS_$(2))
	@echo QEMU $1
	@$(QEMU_CMDLINE_$(2))

gdb-qemu-$1: $(QEMU_STAMP_BUILD)
	gdb --args $(QEMU_CMDLINE_$(2))

run-qemu-$1-gdb: $(QEMU_STAMP_BUILD) $(QEMU_DEPS_$(2))
	@echo "QEMU (GDB)"
	@$(QEMU_CMDLINE_$(2)) -s

run-qemu-$1-gdb-wait: $(QEMU_STAMP_BUILD) $(QEMU_DEPS_$(2))
	echo $(QEMU_DEPS_$(2))
	@echo "QEMU (GDB,WAIT)"
	@$(QEMU_CMDLINE_$(2)) -s -S

qemu-trace-$1: $(QEMU_STAMP_BUILD) tcgmmu/build/libtcgmmu.so
	$(QEMU_CMDLINE_$(2)) -D ./log.txt \
	-plugin tcgmmu/build/libtcgmmu.so -s -S
endef
