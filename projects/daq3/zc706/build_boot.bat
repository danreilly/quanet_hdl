@echo off
rem call C:\Xilinx\Vitis\2023.2\.settings64-Vitis.bat

set DIR=daq3_zc706.sdk

rem set S=daq3_zc706.sdk\create_fsbl_project.tcl
rem echo hsi open_hw_design system_top.xsa                                    > %S
rem echo set cpu_name [lindex [hsi get_cells -filter {IP_TYPE==PROCESSOR}] 0] >> %S%
rem echo platform create -name hw0 -hw system_top.xsa -os standalone -out tmp -proc $cpu_name >> rem rem %S%
rem echo platform generate >> $S%
rem echo wrote %S%

cd %DIR%
set ELF=tmp\hw0\export\hw0\sw\hw0\boot\fsbl.elf
if exist %ELF% (
  echo fsbl.elf exists
) else (
  call xsct ..\create_fsbl_project.tcl
)
copy %ELF% fsbl.elf

copy "G:\My Drive\proj\quanet\hdl_boot_zc706\bootgen_sysfiles\u-boot_zynq_zc706.elf" u-boot.elf
call bootgen -arch zynq -image ..\zynq.bif -o BOOT.BIN -w
echo made %DIR%\BOOT.BIN

cd ..




