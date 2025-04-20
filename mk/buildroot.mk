# Buildroot
BUILDROOT_PREFIX=build/buildroot
BUILDROOT_000_DIR=build/buildroot_000
BUILDROOT_000_DEFCONFIG=qemu_virt_mc68000_defconfig
BUILDROOT_030_DIR=build/buildroot_030
BUILDROOT_030_DEFCONFIG=mc68030_defconfig
BUILDROOT_040_DIR=build/buildroot_040
BUILDROOT_040_DEFCONFIG=mc68040_defconfig
BUILDROOT_060_DIR=build/buildroot_060
BUILDROOT_060_DEFCONFIG=mc68060_defconfig
BUILDROOT_ARGS=BR2_EXTERNAL=../br2m68k

$(eval $(call git_hash,$(BUILDROOT_PREFIX),buildroot))

# 1 - variant
define create_uboot_target
build/buildroot_$1.configured.stamp:
	@echo "CONFIGURE buildroot"
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR) $$(BUILDROOT_$1_DEFCONFIG)
	@touch $$@

build/buildroot_$1.build.stamp: build/buildroot_$1.configured.stamp $$(BUILDROOT_PREFIX).hash $$(BUILDROOT_$1_DIR)/.config
	@echo "BUILD buildroot"
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR)
	@touch $$@

# For CI
ifdef CI
build/buildroot_$1.toolchain.stamp: build/buildroot_$1.configured.stamp $$(BUILDROOT_PREFIX).hash $$(BUILDROOT_$1_DIR)/.config
	@echo "BUILD buildroot (toolchain)"
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR) toolchain
	@touch $$@

build/buildroot_$1_toolchain.tar.gz: build/buildroot_$1.toolchain.stamp
	@echo "TAR buildroot (toolchain)"
	tar -czf $$@ $$(BUILDROOT_$1_DIR) \
		build/buildroot_$1.configured.stamp \
		build/buildroot_$1.toolchain.stamp \
		$$(BUILDROOT_PREFIX).hash

build/buildroot_$1.tar.gz: build/buildroot_$1.build.stamp
	@echo "TAR buildroot"
	tar -cvzf $$@ $$(BUILDROOT_$1_DIR) \
		build/buildroot_$1.configured.stamp \
		build/buildroot_$1.build.stamp \
		$$(BUILDROOT_PREFIX).hash
endif
#

buildroot-$1-source: build/buildroot_$1.configured.stamp
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR) source

buildroot-$1-menuconfig:
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR) menuconfig

buildroot-$1-savedefconfig:
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR) savedefconfig

.PHONY: buildroot-$1-build
buildroot-$1-build: build/buildroot_$1.build.stamp

.PHONY: buildroot-$1-build-force
buildroot-$1-build-force:
	@echo "FORCEBUILD buildroot"
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR)

.PHONY: buildroot-$1-clean
buildroot-$1-clean:
	@echo "CLEAN buildroot"
	@- rm build/buildroot_$1.build.stamp
	$(MAKE) $(BUILDROOT_ARGS) -C buildroot O=../$$(BUILDROOT_$1_DIR) clean

buildroot-all:: buildroot-$1-build
endef

$(eval $(call create_uboot_target,000))
$(eval $(call create_uboot_target,030))
$(eval $(call create_uboot_target,040))
$(eval $(call create_uboot_target,060))

BUILDROOT_000_ROOTFS_SQUASHFS=build/buildroot_000/images/rootfs.squashfs
$(BUILDROOT_000_ROOTFS_SQUASHFS): build/buildroot_000.build.stamp
