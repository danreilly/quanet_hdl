# zcu106 constraints
# Note: spi constraints to the daq3 board are in proj/daq3/zc106/system_constr.xdc


# gpio (switches, leds and such)

# first I thought these should be 1.2 because user guide said so.
# but vadj_fmc is 1.8.
# all on bank64 must agree, this file with projects/daq3/zcu106/system_constr.xdc

# dip sw on bank67 is 1.8v
set_property  -dict {PACKAGE_PIN  A17  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[0]]           ; ## GPIO_DIP_SW0
set_property  -dict {PACKAGE_PIN  A16  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[1]]           ; ## GPIO_DIP_SW1
set_property  -dict {PACKAGE_PIN  B16  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[2]]           ; ## GPIO_DIP_SW2
set_property  -dict {PACKAGE_PIN  B15  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[3]]           ; ## GPIO_DIP_SW3
set_property  -dict {PACKAGE_PIN  A15  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[4]]           ; ## GPIO_DIP_SW4
set_property  -dict {PACKAGE_PIN  A14  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[5]]           ; ## GPIO_DIP_SW5
set_property  -dict {PACKAGE_PIN  B14  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[6]]           ; ## GPIO_DIP_SW6
set_property  -dict {PACKAGE_PIN  B13  IOSTANDARD LVCMOS18} [get_ports gpio_bd_i[7]]           ; ## GPIO_DIP_SW7

# bank66 also has ddr4 stuff, which uses SSTL12_DCI VCCO = 1.2.

# bank66
set_property  -dict {PACKAGE_PIN  AG13  IOSTANDARD LVCMOS12} [get_ports gpio_bd_i[8]]           ; ## GPIO_SW_N
set_property  -dict {PACKAGE_PIN  AC14  IOSTANDARD LVCMOS12} [get_ports gpio_bd_i[9]]           ; ## GPIO_SW_E
set_property  -dict {PACKAGE_PIN  AK12  IOSTANDARD LVCMOS12} [get_ports gpio_bd_i[10]]          ; ## GPIO_SW_W
set_property  -dict {PACKAGE_PIN  AP20  IOSTANDARD LVCMOS12} [get_ports gpio_bd_i[11]]          ; ## GPIO_SW_S
set_property  -dict {PACKAGE_PIN  AL10  IOSTANDARD LVCMOS12} [get_ports gpio_bd_i[12]]          ; ## GPIO_SW_C

# bank64
set_property  -dict {PACKAGE_PIN  AE15  IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[16]]           ; ## GPIO_LED_3
# NOTE: zcu106 ug page 88 is wrong about led3!!!

# bank66
set_property  -dict {PACKAGE_PIN  AL11  IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[13]]           ; ## GPIO_LED_0
set_property  -dict {PACKAGE_PIN  AL13  IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[14]]           ; ## GPIO_LED_1
set_property  -dict {PACKAGE_PIN  AK13  IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[15]]           ; ## GPIO_LED_2
set_property  -dict {PACKAGE_PIN  AM8   IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[17]]           ; ## GPIO_LED_4
set_property  -dict {PACKAGE_PIN  AM9   IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[18]]           ; ## GPIO_LED_5
set_property  -dict {PACKAGE_PIN  AM10  IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[19]]           ; ## GPIO_LED_6
set_property  -dict {PACKAGE_PIN  AM11  IOSTANDARD LVCMOS12} [get_ports gpio_bd_o[20]]           ; ## GPIO_LED_7


# rename SPI clocks
create_clock -name spi0_clk      -period 40   [get_pins -hier */EMIOSPI0SCLKO]
create_clock -name spi1_clk      -period 40   [get_pins -hier */EMIOSPI1SCLKO]

# Dont know why iface did not set loc constraints for these.  If I leave them out,
# i get critical warnings.
# 12/6/24 Now I get CRITICAL WARNING: [Netlist 29-69] Cannot set property 'PACKAGE_PIN', because the property does not exist for objects of type 'pin'. [C:/reilly/proj/floodlight/hdl-main/projects/common/zcu106/zcu106_system_constr.xdc:56]
# Yet these are the names of the top level ports!!!

# I think these are set!
#set_property  -dict {PACKAGE_PIN  AH18  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[0]];
#set_property  -dict {PACKAGE_PIN  AD15  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[1]];
#set_property  -dict {PACKAGE_PIN  AM16  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[2]];
#set_property  -dict {PACKAGE_PIN  AP18  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[3]];
#set_property  -dict {PACKAGE_PIN  AE18  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[4]];
#set_property  -dict {PACKAGE_PIN  AH22  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[5]];
#set_property  -dict {PACKAGE_PIN  AL20  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[6]];
#set_property  -dict {PACKAGE_PIN  AP19  IOSTANDARD POD12_DCI} [get_ports c0_ddr4_dm_n[7]];
