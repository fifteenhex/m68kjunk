# Buildroot
buildroot_040.configured.stamp:
	$(MAKE) -C buildroot -O buildroot_040 qemu_virt_mc68000_defconfig
	touch $@
