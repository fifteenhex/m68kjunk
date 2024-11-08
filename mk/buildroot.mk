# Buildroot
BUILDROOT_BUILT=buildroot/output/images/rootfs.squashfs
BUILDROOT_000_DIR=build/buildroot_000
BUILDROOT_000_DEFCONFIG=qemu_virt_mc68000_defconfig
BUILDROOT_030_DIR=build/buildroot_030
BUILDROOT_030_DEFCONFIG=qemu_virt_mc68000_defconfig
BUILDROOT_040_DIR=build/buildroot_040
BUILDROOT_040_DEFCONFIG=qemu_virt_mc68000_defconfig

# 1 - variant
define create_uboot_target
build/buildroot_$1.configured.stamp:
	$(MAKE) -C buildroot O=../$$(BUILDROOT_$1_DIR) $$(BUILDROOT_$1_DEFCONFIG)
	touch $$@

build/buildroot_$1.build.stamp: build/buildroot_$1.configured.stamp
	$(MAKE) -C buildroot O=../$$(BUILDROOT_$1_DIR)
	touch $$@
	
buildroot-all:: build/buildroot_$1.build.stamp
endef

$(eval $(call create_uboot_target,000))
$(eval $(call create_uboot_target,030))
$(eval $(call create_uboot_target,040))
