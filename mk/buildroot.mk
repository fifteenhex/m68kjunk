# Buildroot

buildroot.stamp:
	$(MAKE) -C buildroot qemu_virt_mc68000_defconfig
	touch $@

BUILDROOT_BUILT=buildroot/output/images/rootfs.squashfs

buildroot/output/images/rootfs.squashfs: buildroot.stamp
	$(MAKE) -C buildroot

buildroot_040.configured.stamp:
	$(MAKE) -C buildroot -O buildroot_040 qemu_virt_mc68000_defconfig
	touch $@
