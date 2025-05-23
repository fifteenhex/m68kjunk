UBOOT_BUILDDIR_MC68EZ328=build/uboot_mc68ez328
LINUX_BUILDDIR_MC68EZ328=build/linux_mc68ez328
UBOOT_MC68EZ328=$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin
MC68EZ328_DISK=bootfiles/disk.mc68ez328.qcow2

# Disk image
$(MC68EZ328_DISK): bootfiles/vmlinux.mc68ez328 \
		   bootfiles/vmlinux.mc68ez328.lz4

	rm -f %@
	qemu-img create -f qcow2 $@ 1G
	sudo modprobe nbd max_part=8
	sudo qemu-nbd --connect=/dev/nbd0 $@
	sleep 5
	sudo sfdisk /dev/nbd0 < sfdisk.txt
	sudo mkfs.vfat /dev/nbd0p1
	sudo mount /dev/nbd0p1 /mnt
	sudo cp bootfiles/vmlinux.mc68ez328* /mnt
	sudo umount /mnt
	sudo dd if=$(BUILDROOT_000_ROOTFS_SQUASHFS) of=/dev/nbd0p2
	sudo qemu-nbd --disconnect /dev/nbd0
	sleep 4

QEMU_DEPS_MC68EZ328=build/u-boot.mc68ez328.build.stamp \
                bootfiles/vmlinux.mc68ez328.lz4 \
                $(BUILDROOT_000_ROOTFS_SQUASHFS) \
		$(MC68EZ328_DISK)

QEMU_CMDLINE_MC68EZ328= \
	$(QEMU_BIN) \
	-cpu $(QEMU_CPU) \
	-display sdl \
	-m 8 \
	-M mc68ez328 \
	-bios $(UBOOT_MC68EZ328) \
	-serial mon:stdio \
	-drive file=$(MC68EZ328_DISK),id=drive-sdcard,if=none \
	-device sd-card-spi,spec_version=1,drive=drive-sdcard

#	-trace "sd*"  -trace file=trace_output.log
#	-nographic


#	-icount shift=2
#	-device loader,addr=0x400000,cpu-num=0 \
#	-object filter-dump,id=user,netdev=lance,file=dump.dat
#	-netdev user,id=n1 \
#	-nic user

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_MC68EZ328),kanpapa_defconfig,mc68ez328,000,m68k-buildroot-uclinux-uclibc-))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_MC68EZ328),mc68ez328_defconfig,mc68ez328,000,m68k-buildroot-uclinux-uclibc-))
$(eval $(call bootfiles_kernel,mc68ez328,$(LINUX_BUILDDIR_MC68EZ328)/vmlinux,build/buildroot_000/host/bin/m68k-buildroot-uclinux-uclibc-strip))
$(eval $(call create_qemu_target,mc68ez328,MC68EZ328))
