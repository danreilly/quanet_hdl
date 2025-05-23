###############################################################################
## Copyright (C) 2014-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

set_property PACKAGE_PIN AC8 [get_ports si5324_out_c_p]
set_property PACKAGE_PIN AC7 [get_ports si5324_out_c_n]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets si5324_out_c]

# Dan added to use the SFP transmitter, for ease of testing
set_property PACKAGE_PIN W4 [get_ports sfp_tx_p]
set_property PACKAGE_PIN W3 [get_ports sfp_tx_n]
set_property PACKAGE_PIN Y6 [get_ports sfp_rx_p]
set_property PACKAGE_PIN Y5 [get_ports sfp_rx_n]
set_property  -dict {PACKAGE_PIN  AA18  IOSTANDARD LVCMOS25} [get_ports sfp_tx_dis]

set_property  -dict {PACKAGE_PIN  AA8 } [get_ports rx_ref_clk_p]                                      ; ## B20  FMC_HPC_GBTCLK1_M2C_P
set_property  -dict {PACKAGE_PIN  AA7 } [get_ports rx_ref_clk_n]                                      ; ## B21  FMC_HPC_GBTCLK1_M2C_N
set_property  -dict {PACKAGE_PIN  AE8 } [get_ports rx_data_p[0]]                                      ; ## A10  FMC_HPC_DP3_M2C_P
set_property  -dict {PACKAGE_PIN  AE7 } [get_ports rx_data_n[0]]                                      ; ## A11  FMC_HPC_DP3_M2C_N
set_property  -dict {PACKAGE_PIN  AH10} [get_ports rx_data_p[1]]                                      ; ## C06  FMC_HPC_DP0_M2C_P
set_property  -dict {PACKAGE_PIN  AH9 } [get_ports rx_data_n[1]]                                      ; ## C07  FMC_HPC_DP0_M2C_N
set_property  -dict {PACKAGE_PIN  AG8 } [get_ports rx_data_p[2]]                                      ; ## A06  FMC_HPC_DP2_M2C_P
set_property  -dict {PACKAGE_PIN  AG7 } [get_ports rx_data_n[2]]                                      ; ## A07  FMC_HPC_DP2_M2C_N
set_property  -dict {PACKAGE_PIN  AJ8 } [get_ports rx_data_p[3]]                                      ; ## A02  FMC_HPC_DP1_M2C_P
set_property  -dict {PACKAGE_PIN  AJ7 } [get_ports rx_data_n[3]]                                      ; ## A03  FMC_HPC_DP1_M2C_N
set_property  -dict {PACKAGE_PIN  AG21  IOSTANDARD LVDS_25} [get_ports rx_sync_p]                     ; ## D08  FMC_HPC_LA01_CC_P
set_property  -dict {PACKAGE_PIN  AH21  IOSTANDARD LVDS_25} [get_ports rx_sync_n]                     ; ## D09  FMC_HPC_LA01_CC_N
set_property  -dict {PACKAGE_PIN  AH19  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports rx_sysref_p]    ; ## G09  FMC_HPC_LA03_P
set_property  -dict {PACKAGE_PIN  AJ19  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports rx_sysref_n]    ; ## G10  FMC_HPC_LA03_N

set_property  -dict {PACKAGE_PIN  AD10} [get_ports tx_ref_clk_p]                                      ; ## D04  FMC_HPC_GBTCLK0_M2C_P
set_property  -dict {PACKAGE_PIN  AD9 } [get_ports tx_ref_clk_n]                                      ; ## D05  FMC_HPC_GBTCLK0_M2C_N
set_property  -dict {PACKAGE_PIN  AK2 } [get_ports tx_data_p[0]]                                      ; ## A30  FMC_HPC_DP3_C2M_P  (tx_data_p[0])
set_property  -dict {PACKAGE_PIN  AK1 } [get_ports tx_data_n[0]]                                      ; ## A31  FMC_HPC_DP3_C2M_N  (tx_data_n[0])
set_property  -dict {PACKAGE_PIN  AK10} [get_ports tx_data_p[1]]                                      ; ## C02  FMC_HPC_DP0_C2M_P  (tx_data_p[3])
set_property  -dict {PACKAGE_PIN  AK9 } [get_ports tx_data_n[1]]                                      ; ## C03  FMC_HPC_DP0_C2M_N  (tx_data_n[3])
set_property  -dict {PACKAGE_PIN  AJ4 } [get_ports tx_data_p[2]]                                      ; ## A26  FMC_HPC_DP2_C2M_P  (tx_data_p[1])
set_property  -dict {PACKAGE_PIN  AJ3 } [get_ports tx_data_n[2]]                                      ; ## A27  FMC_HPC_DP2_C2M_N  (tx_data_n[1])
set_property  -dict {PACKAGE_PIN  AK6 } [get_ports tx_data_p[3]]                                      ; ## A22  FMC_HPC_DP1_C2M_P  (tx_data_p[2])
set_property  -dict {PACKAGE_PIN  AK5 } [get_ports tx_data_n[3]]                                      ; ## A23  FMC_HPC_DP1_C2M_N  (tx_data_n[2])
set_property  -dict {PACKAGE_PIN  AK17  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports tx_sync_p]      ; ## H07  FMC_HPC_LA02_P
set_property  -dict {PACKAGE_PIN  AK18  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports tx_sync_n]      ; ## H08  FMC_HPC_LA02_N
set_property  -dict {PACKAGE_PIN  AJ20  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports tx_sysref_p]    ; ## H10  FMC_HPC_LA04_P
set_property  -dict {PACKAGE_PIN  AK20  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports tx_sysref_n]    ; ## H11  FMC_HPC_LA04_N

set_property  -dict {PACKAGE_PIN  AH23  IOSTANDARD LVCMOS25} [get_ports spi_csn_clk]                  ; ## D11  FMC_HPC_LA05_P
set_property  -dict {PACKAGE_PIN  AG24  IOSTANDARD LVCMOS25} [get_ports spi_csn_dac]                  ; ## C14  FMC_HPC_LA10_P
set_property  -dict {PACKAGE_PIN  AE21  IOSTANDARD LVCMOS25} [get_ports spi_csn_adc]                  ; ## D15  FMC_HPC_LA09_N
set_property  -dict {PACKAGE_PIN  AH24  IOSTANDARD LVCMOS25} [get_ports spi_clk]                      ; ## D12  FMC_HPC_LA05_N
set_property  -dict {PACKAGE_PIN  AD21  IOSTANDARD LVCMOS25} [get_ports spi_sdio]                     ; ## D14  FMC_HPC_LA09_P
set_property  -dict {PACKAGE_PIN  AH22  IOSTANDARD LVCMOS25} [get_ports spi_dir]                      ; ## C11  FMC_HPC_LA06_N

set_property  -dict {PACKAGE_PIN  AA22  IOSTANDARD LVDS_25}  [get_ports sysref_p]                     ; ## D17  FMC_HPC_LA13_P
set_property  -dict {PACKAGE_PIN  AA23  IOSTANDARD LVDS_25}  [get_ports sysref_n]                     ; ## D18  FMC_HPC_LA13_N
set_property  -dict {PACKAGE_PIN  AF24  IOSTANDARD LVCMOS25} [get_ports dac_txen]                     ; ## G16  FMC_HPC_LA12_N
set_property  -dict {PACKAGE_PIN  AG22  IOSTANDARD LVCMOS25} [get_ports adc_pd]                       ; ## C10  FMC_HPC_LA06_P

set_property  -dict {PACKAGE_PIN  AF19  IOSTANDARD LVCMOS25} [get_ports clkd_status[0]]               ; ## G12  FMC_HPC_LA08_P
set_property  -dict {PACKAGE_PIN  AG19  IOSTANDARD LVCMOS25} [get_ports clkd_status[1]]               ; ## G13  FMC_HPC_LA08_N
set_property  -dict {PACKAGE_PIN  AF23  IOSTANDARD LVCMOS25} [get_ports dac_irq]                      ; ## G15  FMC_HPC_LA12_P
set_property  -dict {PACKAGE_PIN  AD23  IOSTANDARD LVCMOS25} [get_ports adc_fda]                      ; ## H16  FMC_HPC_LA11_P
set_property  -dict {PACKAGE_PIN  AE23  IOSTANDARD LVCMOS25} [get_ports adc_fdb]                      ; ## H17  FMC_HPC_LA11_N

set_property  -dict {PACKAGE_PIN  AJ23  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports trig_p]         ; ## H13  FMC_HPC_LA07_P
set_property  -dict {PACKAGE_PIN  AJ24  IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports trig_n]         ; ## H14  FMC_HPC_LA07_N

# cant define procs in .xdc
#proc set_pinloc { portname pinloc iostd } {
#  set_property PACKAGE_PIN $pinloc [get_ports $portname]
#  set_property IOSTANDARD $iostd [get_ports $portname]
#  # same as:
#  # set_property -dict { PACKAGE_PIN $pinloc IOSTANDARD $iostd } [get_ports $portname ];
#}
#set_property  -dict {PACKAGE_PIN  A17  IOSTANDARD LVCMOS15} [get_ports leds[0]]
#set_property  -dict {PACKAGE_PIN  W21  IOSTANDARD LVCMOS15} [get_ports leds[1]]
#set_property  -dict {PACKAGE_PIN  G2   IOSTANDARD LVCMOS15} [get_ports leds[2]]
#set_property  -dict {PACKAGE_PIN  Y21  IOSTANDARD LVCMOS15} [get_ports leds[3]]
set_property  -dict {PACKAGE_PIN  AD18 IOSTANDARD LVCMOS25} [get_ports j67]
set_property  -dict {PACKAGE_PIN  AD19 IOSTANDARD LVCMOS25} [get_ports j68]
#set_pinloc leds[0] A17  lvcmos25
#set_pinloc leds[1] W21  lvcmos25
#set_pinloc leds[2] G2   lvcmos25
#set_pinloc leds[3] Y21  lvcmos25
#set_pinloc j67     AD18 lvcmos25

# clocks

create_clock -name tx_ref_clk   -period  1.60 [get_ports tx_ref_clk_p]
create_clock -name rx_ref_clk   -period  1.60 [get_ports rx_ref_clk_p]
create_clock -name tx_div_clk   -period  3.20 [get_pins i_system_wrapper/system_i/util_daq3_xcvr/inst/i_xch_0/i_gtxe2_channel/TXOUTCLK]
create_clock -name rx_div_clk   -period  3.20 [get_pins i_system_wrapper/system_i/util_daq3_xcvr/inst/i_xch_0/i_gtxe2_channel/RXOUTCLK]

#set_false_path -from [get_cells i_system_wrapper/system_i/axi_ad9680_jesd_rstgen/U0/PR_OUT_DFF[0].peripheral_reset_reg[0]*]
#set_false_path -from [get_cells i_system_wrapper/system_i/axi_ad9152_jesd_rstgen/U0/PR_OUT_DFF[0].peripheral_reset_reg[0]*]



set_false_path -through [get_pins i_system_wrapper/system_i/qregs/regs_w*]
# set_false_path -through [get_pins i_system_wrapper/system_i/qregs/regs_r*]



