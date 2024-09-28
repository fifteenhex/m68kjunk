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

# Buildroot
buildroot.stamp:
	$(MAKE) -C buildroot qemu_virt_mc68000_defconfig
	touch $@

BUILDROOT_BUILT=buildroot/output/images/rootfs.squashfs

buildroot/output/images/rootfs.squashfs: buildroot.stamp
	$(MAKE) -C buildroot

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

# 1 - builddir
# 2 - defconfig
# 3 - stamp
define create_uboot_target
u-boot.$3.configured.stamp: $(BUILDROOT_BUILT)
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
		CROSS_COMPILE=$(COMPILER) \
		$(MAKE) -C u-boot O=$1 $2
	touch $$@

u-boot.$3.build.stamp: u-boot.$3.configured.stamp u-boot/$1/.config $(BUILDROOT_BUILT)
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
		CROSS_COMPILE=$(COMPILER) \
		$(MAKE) -C u-boot O=$1 -j12
	touch $$@

all-u-boot:: u-boot.$3.build.stamp

.PHONY: u-boot-$3-menuconfig
u-boot-$3-menuconfig:
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
	CROSS_COMPILE=$(COMPILER) \
		$(MAKE) -C u-boot O=$1 menuconfig

u-boot-$3-savedefconfig:
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
	CROSS_COMPILE=$(COMPILER) \
		$(MAKE) -C u-boot O=$1 savedefconfig

endef

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

u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl
	objcopy -O srec $< $@

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

QEMU_CPU ?= m68000

qemu-deps: qemu/build/qemu-system-m68k \
	$(UBOOT_VIRT) \
	$(DISK) \
	$(LINUX_VIRT) \
	buildroot/output/images/rootfs.squashfs

qemu.stamp:
	mkdir -p qemu/build && cd qemu/build && ../configure --target-list=m68k-softmmu	--enable-sdl --enable-slirp
	touch $@

.PHONY:qemu/build/qemu-system-m68k
qemu/build/qemu-system-m68k: qemu.stamp
	cd qemu/build && make

# run targets
QEMU_BIN=qemu/build/qemu-system-m68k

QEMU_CMDLINE_VIRT=$(QEMU_BIN) \
	-cpu $(QEMU_CPU) \
	-m 128 \
	-M virt \
	-kernel $(UBOOT_VIRT) \
	-nographic \
	-drive file=fat:./bootfiles/,if=none,id=drive-dummy,readonly=on \
	-device virtio-blk-device,drive=drive-dummy \
	-drive format=raw,file=buildroot/output/images/rootfs.squashfs,if=none,id=drive-rootfs \
	-device virtio-blk-device,drive=drive-rootfs \
	-device virtio-serial-device

UBOOT_MC68EZ328=u-boot/$(UBOOT_BUILDDIR_MC68EZ328)/u-boot.bin
run-qemu-mc68ez328: qemu/build/qemu-system-m68k $(UBOOT_MC68EZ328) $(DISK)

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

u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl
	objcopy -O srec $< $@

mvme147-147bug.bin:
	wget -O $@ "http://www.bitsavers.org/pdf/motorola/VME/MVME147/firmware/147/147bug2.5-combined.bin"

#	-device loader,addr=0x400000,cpu-num=0 \

#	-object filter-dump,id=user,netdev=lance,file=dump.dat
#	-netdev user,id=n1 \
#	-nic user

QEMU_CMDLINE_COMMON=-nic user,tftp=bootfiles/

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

# - 1 name
# - 2 name caps
define create_qemu_target
run-qemu-$1: qemu-deps
	$(QEMU_CMDLINE_$(2))

gdb-qemu-$1: qemu-deps
	gdb --args $(QEMU_CMDLINE_$(2))

run-qemu-$1-gdb: qemu-deps
	$(QEMU_CMDLINE_$(2)) -s

run-qemu-$1-gdb-wait: qemu-deps
	$(QEMU_CMDLINE_$(2)) -s -S

qemu-trace-$1: qemu-deps tcgmmu/build/libtcgmmu.so
	$(QEMU_CMDLINE_$(2)) -D ./log.txt \
	-plugin tcgmmu/build/libtcgmmu.so -s -S
endef

$(eval $(call create_qemu_target,mc68ez328,MC68EZ328))
$(eval $(call create_qemu_target,virt,VIRT))
$(eval $(call create_qemu_target,mvme147,MVME147))

help:
	@echo "--- QEMU run targets"
	@echo "QEMU_CPU - CPU to use"

git-fetch-all:
	git submodule foreach 'git fetch --all'
