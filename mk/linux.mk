# Linux

# 1 - builddir
# 2 - defconfig
# 3 - stamp
# 4 - buildroot name
# 5 - toolchain prefix

LINUX_MAKE=$(MAKE) -C linux O=../$1 ARCH=m68k CROSS_COMPILE=../buildroot_$4/host/bin/$5

define create_linux_target
build/linux.$3.configured.stamp:
	$(LINUX_MAKE) $2
	touch $$@

build/linux.$3.build.stamp: build/linux.$3.configured.stamp
	$(LINUX_MAKE) -j12
	touch $$@

linux-$3-menuconfig:
	$(LINUX_MAKE) menuconfig

linux-$3-savedefconfig:
	$(LINUX_MAKE) savedefconfig
endef
