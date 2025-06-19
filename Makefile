.SUFFIXES:
.PHONY: u-boot/u-boot.elf buildroot

include mk/toolchain.mk

all: uboot

installpkgs:
	sudo apt update
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
		gdb-multiarch \
		genisoimage

bootstrap:
	git submodule init
	git submodule update --init --recursive

build:
	mkdir $@

# Directory for the "boot files" to go into
bootfiles:
	mkdir $@

include mk/git.mk
include mk/buildroot.mk
include mk/uboot.mk
include mk/linux.mk
include mk/bootfiles.mk

u-boot.brec: uboot
	cat init.b > $@
	echo "\n\n*** uboot ***" >> $@
	python3 stob.py u-boot/u-boot.srec >> $@
	echo "\n\n*** go! ***" >> $@
	echo "0000100000" >> $@

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
include mk/mac.mk
include mk/amiga.mk

help:
	@echo "--- QEMU run targets"
	@echo "QEMU_CPU - CPU to use"

git-fetch-all:
	git submodule foreach 'git fetch --all'
