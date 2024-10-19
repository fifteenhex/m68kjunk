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