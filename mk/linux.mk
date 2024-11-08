# Linux

# 1 - builddir
# 2 - defconfig
# 3 - stamp
define create_linux_target
build/linux.$3.configured.stamp:
	$(MAKE) -C linux O=../$1 ARCH=m68k $2
	touch $$@

build/linux.$3.build.stamp: build/linux.$3.configured.stamp
	$(MAKE) -C linux O=../$1 ARCH=m68k -j12
	touch $$@

linux-$3-menuconfig:
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux O=../$1 ARCH=m68k CROSS_COMPILE=$(COMPILER) menuconfig

linux-$3-savedefconfig:
	PATH=$$$$PATH:$(PWD)/buildroot/output/host/bin/ \
		$(MAKE) -C linux O=../$1 ARCH=m68k CROSS_COMPILE=$(COMPILER) savedefconfig
endef
