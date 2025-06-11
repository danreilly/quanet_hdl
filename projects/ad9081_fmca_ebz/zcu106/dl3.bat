@echo.
@echo copying BOOT.BIN to zcu3
scp ad9081_fmca_ebz_zcu106.sdk/BOOT.BIN root@zcu3:/root/BOOT.BIN
rem   the h_vhdl_extract.h is automatically derived from vhdl,
rem   and contains register field definitions for C.
rem scp h_vhdl_extract.h root@zcu2:/home/analog/board_code/src/h_vhdl_extract.h
