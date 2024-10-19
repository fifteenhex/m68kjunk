u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl
	objcopy -O srec $< $@
