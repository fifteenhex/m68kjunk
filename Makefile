.SUFFIXES:
.PHONY: u-boot/u-boot.elf buildroot

TCPREFIX=m68k-buildroot-uclinux-uclibc
COMPILER=$(TCPREFIX)-

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

# Linux
LINUX_BUILDDIR_VIRT=build_virt
LINUX_BUILDDIR_MC68EZ328=build_mc68ez328
LINUX_BUILDDIR_MVME147=build_mvme147

# 1 - builddir
# 2 - defconfig
# 3 - stamp
define create_linux_target
linux.$3.stamp:
	$(MAKE) -C linux O=$1 ARCH=m68k $2
	touch $$@

linux.$3.build.stamp:
	$(MAKE) -C linux O=$1 ARCH=m68k
	touch $$@

linux-$3-menuconfig:
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux O=$1 ARCH=m68k CROSS_COMPILE=$(COMPILER) menuconfig

linux-$3-savedefconfig:
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux O=$1 ARCH=m68k CROSS_COMPILE=$(COMPILER) savedefconfig
endef

$(eval $(call create_linux_target,$(LINUX_BUILDDIR_VIRT),virt_mc68000_defconfig,virt))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_MC68EZ328),mc68ez328_defconfig,mc68ez328))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_MVME147),mvme147_defconfig,mvme147))

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
UBOOT_BUILDDIR_MVME147=build_mvme147
UBOOT_BUILDDIR_E17=build_e17

include mk/uboot.mk

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_MVME147),mvme147_defconfig,mvme147))
$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_E17),mvme147_defconfig,e17))
$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_VIRT),qemu_virt_m68k_mc68000_defconfig,virt))
$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_MC68EZ328),kanpapa_defconfig,mc68ez328))

u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf: u-boot.virt.build.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C u-boot O=$(UBOOT_BUILDDIR_VIRT) CROSS_COMPILE=$(COMPILER) -j12

.PHONY:u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged
u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged: u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(TCPREFIX)-objcopy --change-start 0x400 $< $@

UBOOT_VIRT=u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged

# mc68ez328
.PHONY: u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin
u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin: u-boot.mc68ez328.build.stamp
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
