UBOOT_BUILDDIR_VIRT=build/uboot_virt
LINUX_BUILDDIR_VIRT=build/linux_virt

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

$(eval $(call create_uboot_target,$(UBOOT_BUILDDIR_VIRT),qemu_virt_m68k_mc68000_defconfig,virt,000))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_VIRT),virt_mc68000_defconfig,virt,000))
$(eval $(call create_qemu_target,virt,VIRT))

bootfiles/vmlinux.virt: bootfiles linux.virt.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux O=../$(LINUX_BUILDDIR_VIRT) ARCH=m68k CROSS_COMPILE=$(COMPILER) -j12
	cp $(LINUX_BUILDDIR_VIRT)/vmlinux $@
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(TCPREFIX)-strip $@

LINUX_VIRT=bootfiles/vmlinux.virt


u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf: u-boot.virt.build.stamp
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C u-boot O=$(UBOOT_BUILDDIR_VIRT) CROSS_COMPILE=$(COMPILER) -j12

.PHONY:u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged
u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged: u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf
	PATH=$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(TCPREFIX)-objcopy --change-start 0x400 $< $@

UBOOT_VIRT=u-boot/$(UBOOT_BUILDDIR_VIRT)/u-boot.elf.fudged