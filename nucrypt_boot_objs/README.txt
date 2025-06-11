nucrypt_boot_objs/README.txt



zcu106_BOOT_fwver###.BIN

  This is a BOOT.bin for a zcu106 with a DAQ3 board.  The
  projects/daq3/zcu106 makefile compiled it from the sources
  corrsponding to the specified firmware version, which is defined in
  quanet/global_pkg.vhd as the FWVER constant. The firmware version is
  revealed in a hardware register implemented by the HDL.  Board-level
  (or other-level) C code might require certain firmware versions, so
  this is a sanity check.

  The makefiles also produce h_vhdl_extract.h from the vhdl sources.
  Then the projects/daq3/zcu106/build_boot.bat script packed up the .BIN.

  Copy this to your SD card as /boot/BOOT.BIN
  or (what I often do) run the dl1.bat or dl2.bat,
  which copies not only the .BIN but the h_vhdl_extract.h also

  Also, every "released" firmware version should exist as a commit in
  the git repository with label daq3_fwver#

  TODO: automate a way to keep track of this.


zynqmp-zcu106-fmcdaq3.dtb
zynqmp-zcu106-fmcdaq3.dts

  This is the "compiled" (and src) device tree that goes with zcu106_BOOT_fwver###.BIN
  a copy of a file in Dan's forked "linux" repo at
  https://github.com/danreilly/linux.git
  Copy it to your SD card as /boot/system.dtb


Image

  This is the Kuiper linux image, compiled for a zcu106.
  From the Kuiper release: image_2024-11-08-ADI-Kuiper-full.img
  copy to your SD card as /boot/Image

zcu106_9988_BOOT_fwver#.BIN - for a zcu106 with a 9986 board.
                 Also, every "released" firmware version should exist
	         as a commit in the git repository with label
		 9988_fwver#




zc706_BOOT.BIN - This is the BOOT.BIN for the zc706 we used at happy camper.






zynqmp-zcu102-rev10-fmcdaq3  - This is a copy of the corresponding dir on the SD card.
    My scripts get u-boot.elf and bl31.elf from it, so as to avoid having to compile them.
zynq_zc706-fmcdaq3 - This is a copy of the corresponding dir on the SD card.
    My scripts get u-boot.elf and bl31.elf from it, so as to avoid having to compile them.




zynqmp-zcu106-ad9988.dtb - For the 9988 board.
			   This is a copy from Dan's forked "linux" repo
			   
