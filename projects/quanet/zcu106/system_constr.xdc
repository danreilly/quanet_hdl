###############################################################################
## Copyright (C) 2017-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

# FMC_HPC 0
# daq3

# set_property  -dict {PACKAGE_PIN  G14 IOSTANDARD LVDS} [get_ports rec_clock_p]
# set_property  -dict {PACKAGE_PIN  F13 IOSTANDARD LVDS} [get_ports rec_clock_n]
# 
# set_property PACKAGE_PIN W10 [get_ports si5328_out_c_p]
# set_property PACKAGE_PIN W9  [get_ports si5328_out_c_n]
# # Dan added to use the SFP transmitter, for ease of testing
# set_property PACKAGE_PIN Y4 [get_ports sfp0_tx_p]
# set_property PACKAGE_PIN Y3 [get_ports sfp0_tx_n]
# set_property PACKAGE_PIN AA2 [get_ports sfp0_rx_p]
# set_property PACKAGE_PIN AA1 [get_ports sfp0_rx_n]
# set_property  -dict {PACKAGE_PIN  AE22 IOSTANDARD LVCMOS12} [get_ports sfp0_tx_dis]

set_property  -dict {PACKAGE_PIN  H11   IOSTANDARD LVDS} [get_ports rec_clock_p]
set_property  -dict {PACKAGE_PIN  G11   IOSTANDARD LVDS} [get_ports rec_clock_n]


set_property  -dict {PACKAGE_PIN  H18   IOSTANDARD LVDS} [get_ports rx_sync_p]                                ; ## D08  FMC_HPC0_LA01_CC_P
set_property  -dict {PACKAGE_PIN  H17   IOSTANDARD LVDS} [get_ports rx_sync_n]                                ; ## D09  FMC_HPC0_LA01_CC_N

# lvds requires 1.8V
# Note: la03 is in bank67.
# diff term requires a voltage match.

set_property  -dict {PACKAGE_PIN  K19   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports rx_sysref_p]       ; ## G09  FMC_HPC0_LA03_P
set_property  -dict {PACKAGE_PIN  K18   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports rx_sysref_n]       ; ## G10  FMC_HPC0_LA03_N

set_property  -dict {PACKAGE_PIN  L20   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports tx_sync_p]         ; ## H07  FMC_HPC0_LA02_P
set_property  -dict {PACKAGE_PIN  K20   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports tx_sync_n]         ; ## H08  FMC_HPC0_LA02_N
set_property  -dict {PACKAGE_PIN  L17   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports tx_sysref_p]       ; ## H10  FMC_HPC0_LA04_P
set_property  -dict {PACKAGE_PIN  L16   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports tx_sysref_n]       ; ## H11  FMC_HPC0_LA04_N

set_property  -dict {PACKAGE_PIN  K17   IOSTANDARD LVCMOS18} [get_ports spi_csn_clk]                          ; ## D11  FMC_HPC0_LA05_P
set_property  -dict {PACKAGE_PIN  J17   IOSTANDARD LVCMOS18} [get_ports spi_clk]                              ; ## D12  FMC_HPC0_LA05_N
set_property  -dict {PACKAGE_PIN  L15   IOSTANDARD LVCMOS18} [get_ports spi_csn_dac]                          ; ## C14  FMC_HPC0_LA10_P
set_property  -dict {PACKAGE_PIN  G16   IOSTANDARD LVCMOS18} [get_ports spi_csn_adc]                          ; ## D15  FMC_HPC0_LA09_N
set_property  -dict {PACKAGE_PIN  H16   IOSTANDARD LVCMOS18} [get_ports spi_sdio]                             ; ## D14  FMC_HPC0_LA09_P
set_property  -dict {PACKAGE_PIN  G19   IOSTANDARD LVCMOS18} [get_ports spi_dir]                              ; ## C11  FMC_HPC0_LA06_N

# I got rid of this:
# set_property  -dict {PACKAGE_PIN  G15   IOSTANDARD LVDS}  [get_ports sysref_p]                                ; ## D17  FMC_HPC0_LA13_P
# set_property  -dict {PACKAGE_PIN  F15   IOSTANDARD LVDS}  [get_ports sysref_n]                                ; ## D18  FMC_HPC0_LA13_N

set_property  -dict {PACKAGE_PIN  F18   IOSTANDARD LVCMOS18} [get_ports dac_txen]                             ; ## G16  FMC_HPC0_LA12_N
set_property  -dict {PACKAGE_PIN  H19   IOSTANDARD LVCMOS18} [get_ports adc_pd]                               ; ## C10  FMC_HPC0_LA06_P

set_property  -dict {PACKAGE_PIN  E18   IOSTANDARD LVCMOS18} [get_ports clkd_status[0]]                       ; ## G12  FMC_HPC0_LA08_P
set_property  -dict {PACKAGE_PIN  E17   IOSTANDARD LVCMOS18} [get_ports clkd_status[1]]                       ; ## G13  FMC_HPC0_LA08_N
set_property  -dict {PACKAGE_PIN  G18   IOSTANDARD LVCMOS18} [get_ports dac_irq]                              ; ## G15  FMC_HPC0_LA12_P
set_property  -dict {PACKAGE_PIN  A13   IOSTANDARD LVCMOS18} [get_ports adc_fda]                              ; ## H16  FMC_HPC0_LA11_P
set_property  -dict {PACKAGE_PIN  A12   IOSTANDARD LVCMOS18} [get_ports adc_fdb]                              ; ## H17  FMC_HPC0_LA11_N

set_property  -dict {PACKAGE_PIN  J16   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports trig_p]            ; ## H13  FMC_HPC0_LA07_P
set_property  -dict {PACKAGE_PIN  J15   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports trig_n]            ; ## H14  FMC_HPC0_LA07_N

#set_property LOC GTHE5_COMMON_X1Y1 [get_cells -hierarchical -filter {NAME =~ *i_ibufds_rx_ref_clk}]
#set_property LOC GTHE4_COMMON_X1Y2 [get_cells -hierarchical -filter {NAME =~ *i_ibufds_tx_ref_clk}]

#set_property LOC GTHE4_CHANNEL_X1Y8  [get_cells -hierarchical -filter {NAME =~ *util_daq3_xcvr/inst/i_xch_0/i_gthe4_channel}]
#set_property LOC GTHE4_CHANNEL_X1Y10 [get_cells -hierarchical -filter {NAME =~ *util_daq3_xcvr/inst/i_xch_1/i_gthe4_channel}]
#set_property LOC GTHE4_CHANNEL_X1Y11 [get_cells -hierarchical -filter {NAME =~ *util_daq3_xcvr/inst/i_xch_2/i_gthe4_channel}]
#set_property LOC GTHE4_CHANNEL_X1Y9  [get_cells -hierarchical -filter {NAME =~ *util_daq3_xcvr/inst/i_xch_3/i_gthe4_channel}]

# clocks

create_clock -name tx_ref_clk   -period  1.60 [get_ports tx_ref_clk_p]
create_clock -name rx_ref_clk   -period  1.60 [get_ports rx_ref_clk_p]

# For transceiver output clocks use reference clock divided by two
# This will help autoderive the clocks correcly
set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/TXSYSCLKSEL[0]]
set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/TXSYSCLKSEL[1]]
set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/TXOUTCLKSEL[0]]
set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/TXOUTCLKSEL[1]]
set_case_analysis -quiet 1 [get_pins -quiet -hier *_channel/TXOUTCLKSEL[2]]

set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/RXSYSCLKSEL[0]]
set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/RXSYSCLKSEL[1]]
set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/RXOUTCLKSEL[0]]
set_case_analysis -quiet 0 [get_pins -quiet -hier *_channel/RXOUTCLKSEL[1]]
set_case_analysis -quiet 1 [get_pins -quiet -hier *_channel/RXOUTCLKSEL[2]]

# These pin paths dont "match" during synth, even though I think the pin path is correct.
# but they dont match for the zc706 target either, to no ill effect.
# Maybe these generated clock names are not even used, so maybe ok to elide.
create_generated_clock -name tx_div_clk   [get_pins i_system_wrapper/system_i/util_daq3_xcvr/inst/i_xch_0/i_gthe4_channel/TXOUTCLK]
create_generated_clock -name rx_div_clk   [get_pins i_system_wrapper/system_i/util_daq3_xcvr/inst/i_xch_0/i_gthe4_channel/RXOUTCLK]

# I did not write this comment, and not sure if its true:
# pin assignments below are for reference only and are ignored by the tool!

set_property  -dict {PACKAGE_PIN  T8  } [get_ports rx_ref_clk_p] ; ## B20  FMC_HPC0_GBTCLK1_M2C_C_P
set_property  -dict {PACKAGE_PIN  T7  } [get_ports rx_ref_clk_n] ; ## B21  FMC_HPC0_GBTCLK1_M2C_C_N
set_property  -dict {PACKAGE_PIN  V8  } [get_ports tx_ref_clk_p] ; ## D04  FMC_HPC0_GBTCLK0_M2C_C_P
set_property  -dict {PACKAGE_PIN  V7  } [get_ports tx_ref_clk_n] ; ## D05  FMC_HPC0_GBTCLK0_M2C_C_N

# bank 68
set_property  -dict {PACKAGE_PIN  K13 IOSTANDARD LVCMOS18} [get_ports j3_6]
set_property  -dict {PACKAGE_PIN  L14 IOSTANDARD LVCMOS18} [get_ports j3_8]
set_property  -dict {PACKAGE_PIN  J14 IOSTANDARD LVCMOS18} [get_ports j3_10]
set_property  -dict {PACKAGE_PIN  K14 IOSTANDARD LVCMOS18} [get_ports j3_12]
set_property  -dict {PACKAGE_PIN  J11 IOSTANDARD LVCMOS18} [get_ports j3_14]
set_property  -dict {PACKAGE_PIN  K12 IOSTANDARD LVCMOS18} [get_ports j3_16]
# set_property  -dict {PACKAGE_PIN  L11 IOSTANDARD LVCMOS18} [get_ports j3_18]
# set_property  -dict {PACKAGE_PIN  L12 IOSTANDARD LVCMOS18} [get_ports j3_20]
# set_property  -dict {PACKAGE_PIN  G24 IOSTANDARD LVCMOS18} [get_ports j3_24]
set_property  -dict {PACKAGE_PIN  G23 IOSTANDARD LVCMOS18} [get_ports j3_24]


# Note that data order is a bit scrambled
set_property  -dict {PACKAGE_PIN  V4  } [get_ports rx_data_p[0]]                                      ; ## A10  FMC_HPC0_DP3_M2C_P
set_property  -dict {PACKAGE_PIN  V3  } [get_ports rx_data_n[0]]                                      ; ## A11  FMC_HPC0_DP3_M2C_N
set_property  -dict {PACKAGE_PIN  R2  } [get_ports rx_data_p[1]]                                      ; ## C06  FMC_HPC0_DP0_M2C_P
set_property  -dict {PACKAGE_PIN  R1  } [get_ports rx_data_n[1]]                                      ; ## C07  FMC_HPC0_DP0_M2C_N
set_property  -dict {PACKAGE_PIN  P4  } [get_ports rx_data_p[2]]                                      ; ## A06  FMC_HPC0_DP2_M2C_P
set_property  -dict {PACKAGE_PIN  P3  } [get_ports rx_data_n[2]]                                      ; ## A07  FMC_HPC0_DP2_M2C_N
set_property  -dict {PACKAGE_PIN  U2  } [get_ports rx_data_p[3]]                                      ; ## A02  FMC_HPC0_DP1_M2C_P
set_property  -dict {PACKAGE_PIN  U1  } [get_ports rx_data_n[3]]                                      ; ## A03  FMC_HPC0_DP1_M2C_N

set_property  -dict {PACKAGE_PIN  U6  } [get_ports tx_data_p[0]]                                      ; ## A30  FMC_HPC0_DP3_C2M_P  (tx_data_p[0])
set_property  -dict {PACKAGE_PIN  U5  } [get_ports tx_data_n[0]]                                      ; ## A31  FMC_HPC0_DP3_C2M_N  (tx_data_n[0])
set_property  -dict {PACKAGE_PIN  R6  } [get_ports tx_data_p[1]]                                      ; ## C02  FMC_HPC0_DP0_C2M_P  (tx_data_p[3])
set_property  -dict {PACKAGE_PIN  R5  } [get_ports tx_data_n[1]]                                      ; ## C03  FMC_HPC0_DP0_C2M_N  (tx_data_n[3])
set_property  -dict {PACKAGE_PIN  N6  } [get_ports tx_data_p[2]]                                      ; ## A26  FMC_HPC0_DP2_C2M_P  (tx_data_p[1])
set_property  -dict {PACKAGE_PIN  N5  } [get_ports tx_data_n[2]]                                      ; ## A27  FMC_HPC0_DP2_C2M_N  (tx_data_n[1])
set_property  -dict {PACKAGE_PIN  T4  } [get_ports tx_data_p[3]]                                      ; ## A22  FMC_HPC0_DP1_C2M_P  (tx_data_p[2])
set_property  -dict {PACKAGE_PIN  T3  } [get_ports tx_data_n[3]]                                      ; ## A23  FMC_HPC0_DP1_C2M_N  (tx_data_n[2])


# set_false_path -through [get_pins i_system_wrapper/system_i/qregs/regs_w*]
# set_false_path -through [get_pins i_system_wrapper/system_i/qregs/regs_r*]
