UBOOT_MC68EZ328=u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin
run-qemu-mc68ez328: qemu/build/qemu-system-m68k $(UBOOT_MC68EZ328) $(DISK)

QEMU_CMDLINE_MC68EZ328= \
	$(QEMU_BIN) \
	-cpu $(QEMU_CPU) \
	-m 8 \
	-M mc68ez328 \
	-bios $(UBOOT_MC68EZ328) \
	--display sdl \
	-serial mon:stdio \
	-drive file=$(DISK),id=drive-sdcard,if=none \
	-device sd-card-spi,drive=drive-sdcard

#	-icount shift=2

#	-device loader,addr=0x400000,cpu-num=0 \

#	-object filter-dump,id=user,netdev=lance,file=dump.dat
#	-netdev user,id=n1 \
#	-nic user

$(eval $(call create_qemu_target,mc68ez328,MC68EZ328))