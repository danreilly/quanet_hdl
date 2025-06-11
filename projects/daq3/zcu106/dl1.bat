@echo.
@echo copying BOOT.BIN to zcu106 board
rem scp daq3_zcu106.sdk/BOOT.BIN analog@zcu:/home/analog/BOOT.BIN
scp daq3_zcu106.sdk/BOOT.BIN root@zcu1:/root/BOOT.BIN
rem   the h_vhdl_extract.h is automatically derived from vhdl,
rem   and contains register field definitions for C.
scp h_vhdl_extract.h root@zcu1:/home/analog/board_code/src/h_vhdl_extract.h
