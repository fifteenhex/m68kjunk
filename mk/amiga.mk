LINUX_BUILDDIR_AMIGA_040=build/linux_amiga_040
LINUX_BUILDDIR_AMIGA_060=build/linux_amiga_060

$(eval $(call create_linux_target,$(LINUX_BUILDDIR_AMIGA_040),amiga_defconfig,amiga-040,040,m68k-buildroot-linux-musl-))
$(eval $(call create_linux_target,$(LINUX_BUILDDIR_AMIGA_060),amiga_defconfig,amiga-060,040,m68k-buildroot-linux-musl-))
