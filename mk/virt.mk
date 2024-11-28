UBOOT_BUILDDIR_VIRT=build/uboot_virt
LINUX_BUILDDIR_VIRT=build/linux_virt
UBOOT_VIRT=$(UBOOT_BUILDDIR_VIRT)/u-boot.elf
LINUX_VIRT=bootfiles/vmlinux.virt

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_VIRT),qemu_virt_m68k_mc68000_defconfig,virt,000,m68k-buildroot-uclinux-uclibc-))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_VIRT),virt_mc68000_defconfig,virt,000,m68k-buildroot-uclinux-uclibc-))

bootfiles/vmlinux.virt: bootfiles build/linux.virt.build.stamp
	cp $(LINUX_BUILDDIR_VIRT)/vmlinux $@
	./build/buildroot_000/host/bin/m68k-buildroot-uclinux-uclibc-strip $@

QEMU_DEPS_VIRT=build/u-boot.virt.build.stamp \
		bootfiles/vmlinux.virt \
		$(BUILDROOT_000_ROOTFS_SQUASHFS)

QEMU_CMDLINE_VIRT=$(QEMU_BIN) \
	-cpu $(QEMU_CPU) \
	-m 128 \
	-M virt \
	-kernel $(UBOOT_VIRT) \
	-nographic \
	-drive file=fat:./bootfiles/,if=none,id=drive-dummy,readonly=on \
	-device virtio-blk-device,drive=drive-dummy \
	-drive format=raw,file=$(BUILDROOT_000_ROOTFS_SQUASHFS),if=none,id=drive-rootfs \
	-device virtio-blk-device,drive=drive-rootfs \
	-device virtio-serial-device

$(eval $(call create_qemu_target,virt,VIRT))

#u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf: u-boot.virt.build.stamp
#	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
#		$(MAKE) -C u-boot O=$(UBOOT_BUILDDIR_VIRT) CROSS_COMPILE=$(COMPILER) -j12

#.PHONY:u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged
#u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged: u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf
#	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
#		$(TCPREFIX)-objcopy --change-start 0x400 $< $@
