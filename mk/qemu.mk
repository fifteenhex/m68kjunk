QEMU_CMDLINE_COMMON=-nic user,tftp=bootfiles/
QEMU_BIN=qemu/build/qemu-system-m68k
QEMU_CPU ?= m68000

#qemu/build/qemu-system-m68k

qemu-deps:

qemu.stamp:
	mkdir -p qemu/build && cd qemu/build && ../configure --target-list=m68k-softmmu --enable-sdl --enable-slirp
	touch $@
	
PHONY:qemu/build/qemu-system-m68k
qemu/build/qemu-system-m68k: qemu.stamp
	cd qemu/build && make

# - 1 name
# - 2 name caps
define create_qemu_target
run-qemu-$1: qemu-deps
	$(QEMU_CMDLINE_$(2))

gdb-qemu-$1: qemu-deps
	gdb --args $(QEMU_CMDLINE_$(2))

run-qemu-$1-gdb: qemu-deps
	$(QEMU_CMDLINE_$(2)) -s

run-qemu-$1-gdb-wait: qemu-deps
	$(QEMU_CMDLINE_$(2)) -s -S

qemu-trace-$1: qemu-deps tcgmmu/build/libtcgmmu.so
	$(QEMU_CMDLINE_$(2)) -D ./log.txt \
	-plugin tcgmmu/build/libtcgmmu.so -s -S
endef
