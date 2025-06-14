LINUX_BUILDDIR_MAC=build/linux_mac
MAC_ROM=machinefiles/mac/quadra.rom
MAC_PRAM=machinefiles/mac/pram.img
MAC_CD=bootfiles/maccd.iso

MAC_DISK=bootfiles/disk.mac.raw

# Disk image
$(MAC_DISK): sfdisk.mac.txt build/buildroot_040.build.stamp build/buildroot_040/images/rootfs.ext2
	rm -f %@
	qemu-img create -f raw $@ 160M
	/usr/sbin/sfdisk $@ < sfdisk.mac.txt
	dd if=build/buildroot_040/images/rootfs.ext2 of=$@ seek=1024 bs=1K conv=notrunc

machinefiles/mac:
	mkdir -p $@

$(MAC_ROM): machinefiles/mac
	wget "https://github.com/sentient06/MacROMan/raw/refs/heads/master/TestImages/1MB%20ROMs/1993-02%20-%20F1ACAD13%20-%20Quadra,%20Centris%20610,650,800.ROM" -O $@

$(MAC_PRAM): machinefiles/mac
	qemu-img create -f raw $@ 256

MAC_CD_CONF=bootfiles/emile_cd.conf

$(MAC_CD_CONF):	emile_cd.conf.in $(MAC_DISK)
	EMILE_PARTID=`/usr/sbin/blkid -o export $(MAC_DISK) | grep PTUUID | cut -d "=" -f 2` envsubst < $< > $@

MAC_CD_APPLEDRIVER ?= build/buildroot_040/target/boot/emile/appledriver
MAC_CD_KERNEL=build/linux_mac/vmlinux
MAC_CD_KERNELZ=build/linux_mac/vmlinux.gz
MAC_CD_RAMDISK=build/buildroot_040/images/rootfs.cpio.lz4
$(MAC_CD): $(MAC_CD_CONF) $(MAC_CD_APPLEDRIVER) $(MAC_CD_KERNEL) $(MAC_CD_RAMDISK) bootfiles
	build/buildroot_040/host/sbin/emile-mkisofs \
	-e $(MAC_CD_APPLEDRIVER) \
	-c emile_cd.conf \
	$@ $(MAC_CD_CONF) $(MAC_CD_KERNEL) $(MAC_CD_KERNELZ) $(MAC_CD_RAMDISK)

$(eval $(call create_linux_target,$(LINUX_BUILDDIR_MAC),lc475_defconfig,mac,040,m68k-buildroot-linux-musl-))

QEMU_DEPS_MAC=linux-mac-build \
	      $(MAC_ROM) \
	      $(MAC_PRAM) \
	      $(MAC_CD) \
	      $(MAC_DISK)

# Cribbed from https://wiki.qemu.org/Documentation/Platforms/m68k - Running Mac OS 7.1 up to 8.1
QEMU_CMDLINE_MAC=$(QEMU_BIN) \
        -cpu m68040 \
        -m 128 \
        -M q800 \
	-bios $(MAC_ROM) \
	-device scsi-hd,scsi-id=1,drive=hd1 \
	-drive file=$(MAC_DISK),format=raw,media=disk,if=none,id=hd1 \
	-drive file=$(MAC_PRAM),format=raw,if=mtd \
	-device scsi-cd,scsi-id=2,drive=cd0 \
	-drive file=$(MAC_CD),format=raw,media=cdrom,if=none,id=cd0 \
	-g 800x600x8 \
	-serial mon:stdio \
	-audio driver=none

$(eval $(call create_qemu_target,mac,MAC))
