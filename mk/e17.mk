UBOOT_BUILDDIR_E17=build/uboot-e17

u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl
	objcopy -O srec $< $@

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_E17),eltec-e17_defconfig,e17,030,m68k-buildroot-linux-gnu-))
