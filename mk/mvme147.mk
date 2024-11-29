UBOOT_BUILDDIR_MVME147=build/uboot_mvme147
LINUX_BUILDDIR_MVME147=build/linux_mvme147
UBOOT_SPL_MVME147=build/uboot_mvme147/spl/u-boot-spl.bin
ROOTFS_030=build/buildroot_030/images/rootfs.squashfs
QEMU_CMDLINE_MVME147=$(QEMU_BIN) \
	-M mvme147 \
	-bios mvme147-147bug.bin \
	-device loader,file=$(UBOOT_SPL_MVME147),addr=0x400000 \
	-nographic \
	-serial unix:/tmp/mvme147,server \
	$(QEMU_CMDLINE_COMMON)

#	-drive format=raw,file=$(ROOTFS_030),if=none,id=drive-rootfs \
##	-device scsi-hd,drive=drive-rootfs,bus=scsi.0,channel=0,scsi-id=1,lun=5 \
# 	-device loader,file=u-boot/build_mvme147/u-boot.img,addr=0x700000 \


u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl
	objcopy -O srec $< $@

mvme147-147bug.bin:
	wget -O $@ "http://www.bitsavers.org/pdf/motorola/VME/MVME147/firmware/147/147bug2.5-combined.bin"

QEMU_DEPS_MVME147=mvme147-147bug.bin \
		build/u-boot.mvme147.build.stamp \
		build/linux.mvme147.build.stamp

.PHONY:
mvme147_roms:
	./romwak/romwak /p u-boot/build_mvme147/spl/u-boot-spl.bin u-boot-spl.bin.padded 64 0xff
	cat u-boot-spl.bin.padded > u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	cat u-boot-spl.bin.padded >> u-boot-spl.padded.fill
	./romwak/romwak /b u-boot-spl.padded.fill u-boot-spl.even.bin u-boot-spl.odd.bin

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_MVME147),mvme147_defconfig,mvme147,030,m68k-buildroot-linux-gnu-))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_MVME147),mvme147_defconfig,mvme147,030,m68k-buildroot-linux-gnu-))
$(eval $(call create_qemu_target,mvme147,MVME147))
