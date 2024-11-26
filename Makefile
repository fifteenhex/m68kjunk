.SUFFIXES:
.PHONY: u-boot/u-boot.elf buildroot

include mk/toolchain.mk

all: uboot

installpkgs:
	sudo apt install \
		meson \
		libglib2.0-dev \
		libsdl2-dev \
		bison \
		flex \
		bc \
		libssl-dev \
		lz4 \
		qemu-utils \
		libncurses-dev \
		gdb-multiarch

# Directory for the "boot files" to go into
bootfiles:
	mkdir $@

include mk/buildroot.mk
include mk/uboot.mk
include mk/linux.mk

u-boot.brec: uboot
	cat init.b > $@
	echo "\n\n*** uboot ***" >> $@
	python3 stob.py u-boot/u-boot.srec >> $@
	echo "\n\n*** go! ***" >> $@
	echo "0000100000" >> $@

# Disk image
disk.qcow2: bootfiles/vmlinux.virt \
	bootfiles/vmlinux.mc68ez328 \
	bootfiles/vmlinux.mc68ez328.lz4

	rm -f %@
	qemu-img create -f qcow2 $@ 1G
	sudo modprobe nbd max_part=8
	sudo qemu-nbd --connect=/dev/nbd0 disk.qcow2
	sleep 5
	sudo sfdisk /dev/nbd0 < sfdisk.txt
	sudo mkfs.vfat /dev/nbd0p1
	sudo mount /dev/nbd0p1 /mnt
	sudo cp bootfiles/vmlinux.virt /mnt
	sudo cp bootfiles/vmlinux.mc68ez328* /mnt
	sudo umount /mnt
	sudo dd if=buildroot/output/images/rootfs.squashfs of=/dev/nbd0p2
	sudo qemu-nbd --disconnect /dev/nbd0
	sleep 4

DISK=disk.qcow2

#-device loader,file=u-boot/u-boot.bin,addr=0x0,force-raw=on \
#-device loader,addr=0x100,cpu-num=0 \

.PHONY: tcgmmu/build/libtcgmmu.so

tcgmmu/build/libtcgmmu.so:
	cd tcgmmu/build/ && meson compile


include mk/qemu.mk
include mk/mvme147.mk
include mk/e17.mk
include mk/virt.mk
include mk/mc68ez328.mk

help:
	@echo "--- QEMU run targets"
	@echo "QEMU_CPU - CPU to use"

git-fetch-all:
	git submodule foreach 'git fetch --all'
