UBOOT_BUILDDIR_MVME147=build/uboot_mvme147
LINUX_BUILDDIR_MVME147=build/linux_mvme147
QEMU_CMDLINE_MVME147=qemu/build/qemu-system-m68k \
	-M mvme147 \
	-bios mvme147-147bug.bin \
	-device loader,file=u-boot/build_mvme147/spl/u-boot-spl.bin,addr=0x400000 \
	-device loader,file=u-boot/build_mvme147/u-boot.img,addr=0x700000 \
	-nographic \
	-serial unix:/tmp/mvme147,server \
	-drive format=raw,file=buildroot/output/images/rootfs.squashfs,if=none,id=drive-rootfs \
	-device scsi-hd,drive=drive-rootfs,bus=scsi.0,channel=0,scsi-id=1,lun=5 \
	$(QEMU_CMDLINE_COMMON)

u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl
	objcopy -O srec $< $@

mvme147-147bug.bin:
	wget -o $@ "http://www.bitsavers.org/pdf/motorola/VME/MVME147/firmware/147/147bug2.5-combined.bin"

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
$(eval $(call create_qemu_target,mvme147,MVME147))
