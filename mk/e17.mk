u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl
	objcopy -O srec $< $@

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_E17),mvme147_defconfig,e17))