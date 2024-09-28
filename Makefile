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
		libncurses-dev

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
	mkdir -p qemu/build && cd qemu/build && ../configure --target-list=m68k-softmmu	--enable-sdl
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
	--display sdl \
	-serial mon:stdio \
	-drive file=$(DISK),id=drive-sdcard,if=none \
	-device sd-card-spi,drive=drive-sdcard \
	-s

#	-icount shift=2

u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_MVME147)/spl/u-boot-spl
	objcopy -O srec $< $@

u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl.srec: u-boot/$(UBOOT_BUILDDIR_E17)/spl/u-boot-spl
	objcopy -O srec $< $@

QEMU_CMDLINE_MVME147=qemu/build/qemu-system-m68k \
	-cpu $(QEMU_CPU) \
	-M mvme147 \
	-kernel $(UBOOT_VIRT) \
	-nographic \
	-s

run-qemu-mvme147: qemu/build/qemu-system-m68k
	$(QEMU_CMDLINE_MVME147)

git-fetch-all:
	git submodule foreach 'git fetch --all'

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
