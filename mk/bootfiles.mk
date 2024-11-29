# 1 - target
# 2 - vmlinux
# 3 - strip
define bootfiles_kernel
bootfiles/vmlinux.$1: build/linux.mc68ez328.build.stamp | bootfiles
	cp $2 $$@
	$3 $$@

bootfiles/vmlinux.$1.lz4: bootfiles/vmlinux.$1
	lz4 -f -9 $$<
endef
