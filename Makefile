.PHONY: u-boot/u-boot.elf buildroot

TCPREFIX=m68k-buildroot-uclinux-uclibc
COMPILER=$(TCPREFIX)-

all: uboot

# Directory for the "boot files" to go into
bootfiles:
	mkdir $@

# Buildroot
buildroot.stamp:
	$(MAKE) -C buildroot qemu_virt_mc68000_defconfig
	touch $@

buildroot/output/images/rootfs.squashfs: buildroot.stamp
	$(MAKE) -C buildroot

# Linux
LINUX_BUILDDIR_VIRT=build_virt
LINUX_BUILDDIR_MC68EZ328=build_mc68ez328

linux.virt.stamp:
	$(MAKE) -C linux O=$(LINUX_BUILDDIR_VIRT) ARCH=m68k virt_mc68000_defconfig
	touch $@

linux.mc68ez328.stamp:
	$(MAKE) -C linux O=$(LINUX_BUILDDIR_MC68EZ328) ARCH=m68k mc68ez328_defconfig
	touch $@

linux-menuconfig:
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux ARCH=m68k CROSS_COMPILE=$(COMPILER) menuconfig

bootfiles/vmlinux.virt: bootfiles linux.virt.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux O=$(LINUX_BUILDDIR_VIRT) ARCH=m68k CROSS_COMPILE=$(COMPILER) -j12
	cp linux/$(LINUX_BUILDDIR_VIRT)/vmlinux $@
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(TCPREFIX)-strip $@

LINUX_VIRT=bootfiles/vmlinux.virt

.PHONY: bootfiles/vmlinux.mc68ez328
bootfiles/vmlinux.mc68ez328: bootfiles linux.mc68ez328.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) O=$(LINUX_BUILDDIR_MC68EZ328) -C linux ARCH=m68k CROSS_COMPILE=$(COMPILER) -j12
	cp linux/$(LINUX_BUILDDIR_MC68EZ328)/vmlinux $@
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(TCPREFIX)-strip $@

bootfiles/vmlinux.mc68ez328.lz4: bootfiles/vmlinux.mc68ez328
	lz4 -f -9 $<

# u-boot
UBOOT_BUILDDIR_VIRT=build_virt
UBOOT_BUILDDIR_MC68EZ328=build_mc68ez328

# virt
u-boot.virt.stamp:
	$(MAKE) -C u-boot O=$(UBOOT_BUILDDIR_VIRT) qemu_virt_m68k_mc68000_defconfig
	touch $@

u-boot.mc68ez328.stamp:
	$(MAKE) -C u-boot O=$(UBOOT_BUILDDIR_MC68EZ328) kanpapa_defconfig
	touch $@

u-boot-menuconfig:
	$(MAKE) -C u-boot menuconfig

u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf: u-boot.virt.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C u-boot O=$(UBOOT_BUILDDIR_VIRT) CROSS_COMPILE=$(COMPILER) -j12

.PHONY:u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged
u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged: u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(TCPREFIX)-objcopy --change-start 0x400 $< $@

UBOOT_VIRT=u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged

# mc68ez328
.PHONY: u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin
u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin: u-boot.mc68ez328.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C u-boot O=$(UBOOT_BUILDDIR_MC68EZ328) ARCH=m68k CROSS_COMPILE=$(COMPILER) -j12

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
	qemu-img create -f qcow2 $@ 1G
	sudo modprobe nbd max_part=8
	sudo qemu-nbd --connect=/dev/nbd0 disk.qcow2
	sudo sfdisk /dev/nbd0 < sfdisk.txt
	sudo mkfs.vfat /dev/nbd0p1
	sudo mount /dev/nbd0p1 /mnt
	sudo cp bootfiles/vmlinux.virt /mnt
	sudo cp bootfiles/vmlinux.mc68ez328* /mnt
	sudo umount /mnt
	sudo dd if=buildroot/output/images/rootfs.squashfs of=/dev/nbd0p2
	sudo qemu-nbd --disconnect /dev/nbd0

DISK=disk.qcow2

#-device loader,file=u-boot/u-boot.bin,addr=0x0,force-raw=on \
#-device loader,addr=0x100,cpu-num=0 \

.PHONY: tcgmmu/build/libtcgmmu.so

tcgmmu/build/libtcgmmu.so:
	cd tcgmmu/build/ && meson compile

QEMU_CPU ?= m68000

qemu-deps: qemu/build/qemu-system-m68k \
	$(UBOOT_VIRT) \
	$(DISK) \
	$(LINUX_VIRT) \
	buildroot/output/images/rootfs.squashfs

QEMU_CMDLINE=qemu/build/qemu-system-m68k \
	-cpu $(QEMU_CPU) \
	-m 128 \
	-M virt \
	-kernel $(UBOOT_VIRT) \
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

.PHONY:qemu/build/qemu-system-m68k
qemu/build/qemu-system-m68k: qemu.stamp
	cd qemu/build && make

# run targets

run-qemu-virt-68000: qemu-deps
	$(QEMU_CMDLINE)
#	-netdev user,id=net1 \
#	-device virtio-net-device,netdev=net1 \
#	-blockdev node-name=file0,driver=file,filename=$(DISK) \
#	-blockdev node-name=disk0,driver=qcow2,file=file0 \
#	-device	virtio-blk-device,drive=disk0 \

UBOOT_MC68EZ328=u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin
run-qemu-mc68ez328: qemu/build/qemu-system-m68k $(UBOOT_MC68EZ328) $(DISK)
	qemu/build/qemu-system-m68k \
	-cpu $(QEMU_CPU) \
	-m 8 \
	-M mc68ez328 \
	-bios $(UBOOT_MC68EZ328) \
	-nographic \
	-drive file=$(DISK),id=drive-sdcard,if=none \
	-device sd-card-spi,drive=drive-sdcard \
	-s
