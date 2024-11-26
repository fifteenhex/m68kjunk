LINUX_BUILDDIR_MC68EZ328=build/linux_mc68ez328
UBOOT_MC68EZ328=u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin
run-qemu-mc68ez328: qemu/build/qemu-system-m68k $(UBOOT_MC68EZ328) $(DISK)
UBOOT_BUILDDIR_MC68EZ328=build_mc68ez328

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

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_MC68EZ328),kanpapa_defconfig,mc68ez328,000))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_MC68EZ328),mc68ez328_defconfig,mc68ez328,000))
$(eval $(call create_qemu_target,mc68ez328,MC68EZ328))

.PHONY: bootfiles/vmlinux.mc68ez328
bootfiles/vmlinux.mc68ez328: bootfiles linux.mc68ez328.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) O=../$(LINUX_BUILDDIR_MC68EZ328) -C linux ARCH=m68k CROSS_COMPILE=$(COMPILER) -j12
	cp $(LINUX_BUILDDIR_MC68EZ328)/vmlinux $@
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(TCPREFIX)-strip $@

bootfiles/vmlinux.mc68ez328.lz4: bootfiles/vmlinux.mc68ez328
	lz4 -f -9 $<