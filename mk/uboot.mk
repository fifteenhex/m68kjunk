# 1 - builddir
# 2 - defconfig
# 3 - stamp
# 4 - buildroot name

UBOOT_MAKE=$(MAKE) -C u-boot O=../$1 CROSS_COMPILE=`realpath build/buildroot_$4/host/bin/`/m68k-buildroot-uclinux-uclibc-
UBOOT_CONFIG=$1/.config
UBOOT_STAMP_CONFIGURED=build/u-boot.$3.configured.stamp
UBOOT_STAMP_BUILD=build/u-boot.$3.build.stamp

define create_uboot_target
$(UBOOT_STAMP_CONFIGURED): $(BUILDROOT_BUILT)
	$(UBOOT_MAKE) $2
	touch $$@

$(UBOOT_STAMP_BUILD): $(UBOOT_STAMP_CONFIGURED) $(UBOOT_CONFIG) $(BUILDROOT_BUILT)
	$(UBOOT_MAKE) -j12
	touch $$@

all-u-boot:: $(UBOOT_STAMP_BUILD)

.PHONY: u-boot-$3-menuconfig
u-boot-$3-menuconfig:
	$(UBOOT_MAKE) menuconfig

u-boot-$3-savedefconfig:
	$(UBOOT_MAKE) savedefconfig

endef