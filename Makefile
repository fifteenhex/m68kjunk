.PHONY: u-boot/u-boot.elf bootfiles/vmlinux buildroot

COMPILER=m68k-buildroot-uclinux-uclibc-

all: uboot

linux.stamp:
	$(MAKE) -C linux ARCH=m68k virt_mc68000_defconfig
	touch linux.stamp

linux-menuconfig:
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux ARCH=m68k CROSS_COMPILE=$(COMPILER) menuconfig

bootfiles:
	mkdir $@

bootfiles/vmlinux: bootfiles linux.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux ARCH=m68k CROSS_COMPILE=$(COMPILER) -j12
	cp linux/vmlinux $@
	$(COMPILER)-strip $@

buildroot.stamp:
	$(MAKE) -C buildroot qemu_virt_mc68000_defconfig
	touch $@

buildroot/output/images/rootfs.squashfs: buildroot.stamp
	$(MAKE) -C buildroot

u-boot.stamp:
	$(MAKE) -C u-boot qemu_virt_m68k_mc68000_defconfig
	touch $@

u-boot-menuconfig:
	$(MAKE) -C u-boot menuconfig

u-boot/u-boot.elf: u-boot.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C u-boot CROSS_COMPILE=$(COMPILER) -j12

u-boot/u-boot.elf.fudged: u-boot/u-boot.elf
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		m68k-buildroot-uclinux-uclibc-objcopy --change-start 0x400 $< $@

u-boot.brec: uboot
	cat init.b > $@
	echo "\n\n*** uboot ***" >> $@
	python3 stob.py u-boot/u-boot.srec >> $@
	echo "\n\n*** go! ***" >> $@
	echo "0000100000" >> $@

disk.qcow2:
	qemu-img create -f qcow2 $@ 1G

DISK=disk.qcow2

#-device loader,file=u-boot/u-boot.bin,addr=0x0,force-raw=on \
#-device loader,addr=0x100,cpu-num=0 \

.PHONY: tcgmmu/build/libtcgmmu.so

tcgmmu/build/libtcgmmu.so:
	cd tcgmmu/build/ && meson compile

QEMU_CPU ?= m68000

qemu-deps: qemu/build/qemu-system-m68k \
	u-boot/u-boot.elf.fudged \
	$(DISK) \
	bootfiles/vmlinux \
	buildroot/output/images/rootfs.squashfs

QEMU_CMDLINE=qemu/build/qemu-system-m68k \
	-cpu $(QEMU_CPU) \
	-m 128 \
	-M virt \
	-kernel u-boot/u-boot.elf.fudged \
	-nographic \
	-drive file=fat:./bootfiles/,if=none,id=drive-dummy,readonly=on \
	-device virtio-blk-device,drive=drive-dummy \
	-drive format=raw,file=buildroot/output/images/rootfs.squashfs,if=none,id=drive-rootfs \
	-device virtio-blk-device,drive=drive-rootfs \
	-device virtio-serial-device \
	-s

qemu-trace: qemu-deps tcgmmu/build/libtcgmmu.so
	$(QEMU_CMDLINE) \
	-D ./log.txt \
	-plugin tcgmmu/build/libtcgmmu.so -d plugin

qemu-wait-for-gdb: qemu-deps tcgmmu/build/libtcgmmu.so
	$(QEMU_CMDLINE) \
	-S

qemu.stamp:
	mkdir -p qemu/build && cd qemu/build && ../configure --target-list=m68k-softmmu
	touch $@

qemu/build/qemu-system-m68k: qemu.stamp
	cd qemu/build && make

run-qemu-virt-68000: qemu-deps
	$(QEMU_CMDLINE)
#	-netdev user,id=net1 \
#	-device virtio-net-device,netdev=net1 \
#	-blockdev node-name=file0,driver=file,filename=$(DISK) \
#	-blockdev node-name=disk0,driver=qcow2,file=file0 \
#	-device	virtio-blk-device,drive=disk0 \
