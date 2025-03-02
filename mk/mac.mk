MAC_ROM=machinefiles/mac/quadra.rom
MAC_PRAM=machinefiles/mac/pram.img
MAC_CD=bootfiles/maccd.iso

$(MAC_ROM):
	wget "https://github.com/sentient06/MacROMan/raw/refs/heads/master/TestImages/1MB%20ROMs/1993-02%20-%20F1ACAD13%20-%20Quadra,%20Centris%20610,650,800.ROM" -O $@

$(MAC_PRAM):
	qemu-img create -f raw $@ 256

MAC_CD_CONF=emile_cd.conf
#MAC_CD_APPLEDRIVER=/media/slimboy/coding/m68kjunk/EMILE/build-bbtoolchain/second/appledriver
MAC_CD_APPLEDRIVER=build/buildroot_040/target/boot/emile/appledriver
MAC_CD_KERNEL=tmpmacstuff/linux/vmlinux.gz
MAC_CD_RAMDISK=build/buildroot_040/images/rootfs.cpio.lz4
$(MAC_CD): $(MAC_CD_CONF) $(MAC_CD_APPLEDRIVER) $(MAC_CD_KERNEL) $(MAC_CD_RAMDISK)
	build/buildroot_040/build/emile-87adeb3aaed2e4241fc3530519fe0334ea091bd8/build/tools/emile-mkisofs-native \
	-e $(MAC_CD_APPLEDRIVER) \
	-c emile_cd.conf \
	$@ $(MAC_CD_CONF) $(MAC_CD_KERNEL) $(MAC_CD_RAMDISK)

QEMU_DEPS_MAC=$(MAC_ROM) \
	      $(MAC_PRAM) \
	      $(MAC_CD)



# Cribbed from https://wiki.qemu.org/Documentation/Platforms/m68k - Running Mac OS 7.1 up to 8.1
QEMU_CMDLINE_MAC=$(QEMU_BIN) \
        -cpu m68040 \
        -m 128 \
        -M q800 \
	-bios $(MAC_ROM) \
	-device scsi-hd,scsi-id=1,drive=hd1 \
	-drive file="/media/slimboy/coding/m68kjunk/build/buildroot_040/images/rootfs.ext2",format=raw,media=disk,if=none,id=hd1 \
	-drive file=$(MAC_PRAM),format=raw,if=mtd \
	-device scsi-cd,scsi-id=2,drive=cd0 \
	-drive file=$(MAC_CD),format=raw,media=cdrom,if=none,id=cd0 \
	-g 800x600x8 \
	-serial mon:stdio \
	-s
$(eval $(call create_qemu_target,mac,MAC))
