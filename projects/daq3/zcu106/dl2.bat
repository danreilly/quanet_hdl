@echo.
@echo copying BOOT.BIN to zcu106 board
scp daq3_zcu106.sdk/BOOT.BIN root@zcu2:/root/BOOT.BIN
rem   the h_vhdl_extract.h is automatically derived from vhdl,
rem   and contains register field definitions for C.
scp h_vhdl_extract.h root@zcu2:/home/analog/board_code/src/h_vhdl_extract.h
