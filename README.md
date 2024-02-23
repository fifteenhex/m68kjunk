# m68kjunk

This is all the bits you need to play with recent linux on mc68000

## Flashing the kanpapa mc68ez328 board

1. Press the bootloader button and then reset button
2. Open minicom, set your baud to 9600
3. Open the transfer methods configuration and update ascii to `ascii-xfr -dsv -l 1`.
   This adds a delay between lines for the mc68ez328 bootloader to catch up.
4. Open the file transfer menu and send the u-boot SPL `payload.b` via ascii
5. Send `0040000000` to jump to the SPL
6. Wait for the SPL to boot and start printing CCC..
7. Open the file transfer menu and send the u-boot binary `u-boot.img`
8. Wait for u-boot to boot. The SPL will complain the CRC is incorrect.
   This is due to some things being mapped over the memory in bootloader mode.
9. Send the command `mw.l 0x100000 0xffffffff 0x12000; loady 0x100000 57600` to clear
   the target memory and start loading over ymodem. Follow the u-boot prompt to change
   the baud rate.
10. Send `u-boot.bin` (Needs to be the .bin not .img as we need it without the header)
11. Erase the first part of the flash and write u-boot there with 
    `erase 0x10000000 +0x48000; cp.l 0x100000 0x10000000 0x12000`
12. You should now be able to reset and see u-boot load up from flash.

## Booting linux on the kanpapa mc68ez328 board

1. On an SD card you need:
   - 2 or more partitions.
   - The first should be FAT formatted.
   - The second shouldn't be formatted.
2. Put the kernel elf on the FAT partition
3. dd the squashfs rootfs to the second partition.


## Wiring for an SD card on the kanpapa mc68ez328

J4:
  - 13 (SCLK) -> SD clk
  - 15 (STXD) -> SD MOSI 
  - 16 (SRXD) -> SD MISO
  - 2  (PD0)  -> SD CS
  - 1  (PD1)  -> SD vcc on (Optional but might be needed to get some cards to init)
