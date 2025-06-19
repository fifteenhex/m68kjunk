LINUX_BUILDDIR_AMIGA=build/linux_amiga

$(eval $(call create_linux_target,$(LINUX_BUILDDIR_AMIGA),amiga_defconfig,amiga,040,m68k-buildroot-linux-musl-))
