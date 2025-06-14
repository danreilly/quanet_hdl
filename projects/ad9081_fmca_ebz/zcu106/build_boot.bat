@echo off
rem call C:\Xilinx\Vitis\2023.2\.settings64-Vitis.bat

set DIR=ad9081_fmca_ebz_zcu106.sdk

rem set S=daq3_zc706.sdk\create_fsbl_project.tcl
rem echo hsi open_hw_design system_top.xsa                                    > %S
rem echo set cpu_name [lindex [hsi get_cells -filter {IP_TYPE==PROCESSOR}] 0] >> %S%
rem echo platform create -name hw0 -hw system_top.xsa -os standalone -out tmp -proc $cpu_name >> rem rem %S%
rem echo platform generate >> $S%
rem echo wrote %S%

cd %DIR%
set ELF=tmp\hw0\export\hw0\sw\hw0\boot\fsbl.elf
set PMUFW=tmp\hw0\export\hw0\sw\hw0\boot\pmufw.elf
if exist %ELF% (
  echo fsbl.elf already exists
) else (
  call xsct ..\create_fsbl_project.tcl
)
call :cp %ELF% fsbl.elf
call :cp %PMUFW% pmufw.elf



	

rem if u-boot has different name, you're supposed to rename it to u-boot.elf.
rem copy "G:\My Drive\proj\quanet\hdl_boot_zcu106\u-boot_xilinx_zynq_zcu102_revA.elf" u-boot.elf
rem copy "G:\My Drive\proj\quanet\hdl_boot_zcu106\from_new_SD_image\bootgen_sysfiles\u-boot.elf .
rem copy "G:\My Drive\proj\quanet\hdl_boot_zcu106\from_new_SD_image\bootgen_sysfiles\bl31.elf .
call :cp "..\..\..\..\nucrypt_boot_objs\zynqmp-zcu102-rev10-fmcdaq3\u-boot_xilinx_zynqmp_zcu102_revA.elf" u-boot.elf
call :cp "..\..\..\..\nucrypt_boot_objs\zynqmp-zcu102-rev10-fmcdaq3\bl31.elf" .

call bootgen -arch zynqmp -image ..\zynq.bif -o BOOT.BIN -w
echo made %DIR%\BOOT.BIN
call :cp BOOT.BIN ..\..\..\..\nucrypt_boot_objs\zcu106_9988_BOOT.BIN
git rev-parse HEAD > gitrev.txt
set /p GITREV=<gitrev.txt
call :cp BOOT.BIN ..\..\..\..\nucrypt_boot_objs\zcu106_9988_BOOT.BIN
call :cp BOOT.BIN ..\..\..\..\nucrypt_boot_objs\zcu106_9988_BOOT_%GITREV%.BIN
cd ..

goto :eof




:cp
  echo :cp %1 %2
  if not exist %1 (
    echo ERR: copy from %1 does not exist!
    pause
    exit /b 99
  )
  echo F|xcopy /Y %1 %2
