# Buildroot
BUILDROOT_000_DIR=build/buildroot_000
BUILDROOT_000_DEFCONFIG=qemu_virt_mc68000_defconfig
BUILDROOT_030_DIR=build/buildroot_030
BUILDROOT_030_DEFCONFIG=mc68030_defconfig
BUILDROOT_040_DIR=build/buildroot_040
BUILDROOT_040_DEFCONFIG=mc68040_defconfig
BUILDROOT_060_DIR=build/buildroot_060
BUILDROOT_060_DEFCONFIG=mc68060_defconfig

# 1 - variant
define create_uboot_target
build/buildroot_$1.configured.stamp:
	$(MAKE) -C buildroot O=../$$(BUILDROOT_$1_DIR) $$(BUILDROOT_$1_DEFCONFIG)
	touch $$@

build/buildroot_$1.build.stamp: build/buildroot_$1.configured.stamp
	$(MAKE) -C buildroot O=../$$(BUILDROOT_$1_DIR)
	touch $$@

buildroot-$1-menuconfig:
	$(MAKE) -C buildroot O=../$$(BUILDROOT_$1_DIR) menuconfig

buildroot-$1-savedefconfig:
	$(MAKE) -C buildroot O=../$$(BUILDROOT_$1_DIR) savedefconfig

buildroot-all:: build/buildroot_$1.build.stamp
endef

$(eval $(call create_uboot_target,000))
$(eval $(call create_uboot_target,030))
$(eval $(call create_uboot_target,040))
$(eval $(call create_uboot_target,060))
