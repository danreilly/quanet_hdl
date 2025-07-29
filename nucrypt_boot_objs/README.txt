nucrypt_boot_objs/README.txt

To build the .bit file:

  cd projects/<PROJNAME>/<BOARDNAME>
  make

Then run

  build_boot.bat
  
To pack the bitfile inside a BOOT.BIN file.
I used to keep copies of the latest BOOT.BINs here.
But now I keep them in their respective build directories in

    quanet_hdl/projects/<PROJNAME>/<BOARDNAME>/latest/BOOT.BIN

The register map (the h_vhdl_include.h file) change from
build to build.  They are kept next to the BOOT.BIN also in the
"latest" folder.   The project makefile produces h_vhdl_extract.h from the vhdl sources.
(see regextractor.opt, and global_pkg.vhd, quanet_dac.vhd, quanet_adc.vhd)

Per-IP resource utilization reports are also put into "latest"


The embedded code running on the PS (see my board_code repo) must be
compiled with the register map appropriate for the bitfile it talks
to.  Embedded code can read the FWVER register in the HDL, to see
if it matches the FWVER constant defined in h_vhdl_include.h,
as a sanity check.

There may be multiple day-to-day commits to my HDL repository.
This is work in progress.  When a milestone is reached,
I'll tag both commits in the hdl repo and the board_code repo.
Then I'll start using a new FWVER in both.


Copy this to your SD card as /boot/BOOT.BIN
or (what I often do) run the dl1.bat or dl2.bat,
which copies not only the .BIN but the h_vhdl_extract.h also.




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


zc706_BOOT.BIN - This is the BOOT.BIN for the zc706 we used at happy camper.


zynqmp-zcu102-rev10-fmcdaq3  - This is a copy of the corresponding dir on the SD card.
    My scripts get u-boot.elf and bl31.elf from it, so as to avoid having to compile them.
zynq_zc706-fmcdaq3 - This is a copy of the corresponding dir on the SD card.
    My scripts get u-boot.elf and bl31.elf from it, so as to avoid having to compile them.




zynqmp-zcu106-ad9988.dtb - For the 9988 board.
			   This is a copy from Dan's forked "linux" repo
			   
