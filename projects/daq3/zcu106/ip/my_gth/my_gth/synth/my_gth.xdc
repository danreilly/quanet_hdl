#------------------------------------------------------------------------------
#  (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
#
#  This file contains confidential and proprietary information
#  of AMD, Inc. and is protected under U.S. and
#  international copyright and other intellectual property
#  laws.
#
#  DISCLAIMER
#  This disclaimer is not a license and does not grant any
#  rights to the materials distributed herewith. Except as
#  otherwise provided in a valid license issued to you by
#  AMD, and to the maximum extent permitted by applicable
#  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
#  WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
#  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
#  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
#  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
#  (2) AMD shall not be liable (whether in contract or tort,
#  including negligence, or under any other theory of
#  liability) for any loss or damage of any kind or nature
#  related to, arising under or in connection with these
#  materials, including for any direct, or any indirect,
#  special, incidental, or consequential loss or damage
#  (including loss of data, profits, goodwill, or any type of
#  loss or damage suffered as a result of any action brought
#  by a third party) even if such damage or loss was
#  reasonably foreseeable or AMD had been advised of the
#  possibility of the same.
#
#  CRITICAL APPLICATIONS
#  AMD products are not designed or intended to be fail-
#  safe, or for use in any application requiring fail-safe
#  performance, such as life-support or safety devices or
#  systems, Class III medical devices, nuclear facilities,
#  applications related to the deployment of airbags, or any
#  other applications that could lead to death, personal
#  injury, or severe property or environmental damage
#  (individually and collectively, "Critical
#  Applications"). Customer assumes the sole risk and
#  liability of any use of AMD products in Critical
#  Applications, subject only to applicable laws and
#  regulations governing limitations on product liability.
#
#  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
#  PART OF THIS FILE AT ALL TIMES.
#------------------------------------------------------------------------------


# UltraScale FPGAs Transceivers Wizard IP core-level XDC file
# ----------------------------------------------------------------------------------------------------------------------

# Commands for enabled transceiver GTHE4_CHANNEL_X0Y10
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE4_CHANNEL_X0Y10 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[2].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AA1 [get_ports gthrxn_in[0]]
#set_property package_pin AA2 [get_ports gthrxp_in[0]]
#set_property package_pin Y3 [get_ports gthtxn_out[0]]
#set_property package_pin Y4 [get_ports gthtxp_out[0]]
##set_false_path -through [get_pins -filter {REF_PIN_NAME=~*Q} -of_objects [get_cells -hierarchical -filter {NAME =~ *gen_pwrgood_delay_inst[0].delay_powergood_inst/gen_powergood_delay.pwr_on_fsm*}]] -quiet
set_case_analysis 1     [get_pins -filter {REF_PIN_NAME=~*Q} -of_objects [get_cells -hierarchical -filter {NAME =~ *gen_pwrgood_delay_inst[0].delay_powergood_inst/gen_powergood_delay.pwr_on_fsm*}]] -quiet


# False path constraints
# ----------------------------------------------------------------------------------------------------------------------

set_false_path -to [get_cells -hierarchical -filter {NAME =~ *bit_synchronizer*inst/i_in_meta_reg}] -quiet

##set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out*}]] -quiet



## NEW Waivers


create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/bit_synchronizer_plllock_rx_inst/i_in_meta_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/bit_synchronizer_plllock_tx_inst/i_in_meta_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/reset_synchronizer_txprogdivreset_inst/rst_in_meta_reg}]] 

create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.int_pwr_on_fsm_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME=~*gen_powergood_delay.intclk_rrst_n_r_reg*}]]
create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.int_pwr_on_fsm_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME=~*gen_powergood_delay.intclk_rrst_n_r_reg*}]]
create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.int_pwr_on_fsm_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME=~*gen_powergood_delay.wait_cnt_reg*}]]


create_waiver -internal -quiet -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.int_pwr_on_fsm_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME=~*gen_powergood_delay.wait_cnt_reg*}]]


create_waiver -internal -quiet -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/bit_synchronizer_plllock_rx_inst/i_in_meta_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/bit_synchronizer_plllock_tx_inst/i_in_meta_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/reset_synchronizer_txprogdivreset_inst/rst_in_meta_reg}]] 


create_waiver -internal -quiet -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_rx_i/gen_cal_rx_en.USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*bit_synchronizer_plllock_rx_inst/i_in_meta_reg}]] 




create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/bit_synchronizer_plllock_rx_inst/i_in_meta_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/bit_synchronizer_plllock_tx_inst/i_in_meta_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/reset_synchronizer_txprogdivreset_inst/rst_in_meta_reg}]] 

create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/pllreset_rx_out_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*rst_in_meta_reg}]] 

create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gtwiz_reset_inst/pllreset_tx_out_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*rst_in_meta_reg}]] 

create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.int_pwr_on_fsm_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.wait_cnt_reg*}]] 

create_waiver -internal -quiet -type CDC -id {CDC-1} -user gtwizard_ultrascale -tags "1165536" -description "CDC-1 waiver for CPLL Calibration logic" \
              -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.wait_cnt_reg*}]] \
			         -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.int_pwr_on_fsm_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-1} -user gtwizard_ultrascale -tags "1165536" -description "CDC-1 waiver for CPLL Calibration logic" \
              -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.int_pwr_on_fsm_reg}]] \
			         -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*gen_powergood_delay.pwr_on_fsm_reg}]] 


## QDMA

create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gtye4_cpll_cal_tx_i/U_TXOUTCLK_FREQ_COUNTER/state_reg*}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*reset_synchronizer_testclk_rst_inst/rst_in_meta_reg}]] 
create_waiver -internal -quiet -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 waiver for CPLL Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*gtye4_cpll_cal_tx_i/U_TXOUTCLK_FREQ_COUNTER/state_reg*}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*cpll_cal_tx_i/U_TXOUTCLK_FREQ_COUNTER/tstclk_*_dly1_reg}]]



## reset_synchronizer_testclk_rst_inst/rst_in_meta_reg/PRE
################################
create_waiver -internal -quiet -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1168849" -description "CDC-12 In exdes and vio path" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*gtwiz_buffbypass_rx_done_out_reg*}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*i_in_meta_reg}]]

create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1168849" -description "CDC-10 In exdes and vio path" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*prbs_match_out_reg_inv}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*rst_in_meta_reg}]]

create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1168849" -description "CDC-10 In exdes and vio path" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*gen_cal_rx_en.USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*rst_in_meta_reg}]]
create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1168849" -description "CDC-10 In exdes and vio path" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*gen_cal_rx_en.USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*rst_in_meta_reg}]]

create_waiver -internal -quiet -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1168849" -description "CDC-10 In exdes and vio path" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*gen_cal_rx_en.USER_CPLLLOCK_OUT_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*i_in_meta_reg}]]

create_waiver -internal -quiet -type CDC -id {CDC-1} -user gtwizard_ultrascale -tags "1168849" -description "CDC-1 In exdes and vio path" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*int_pwr_on_fsm_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME =~*intclk_rrst_n_r_reg*}]]

create_waiver -internal -quiet -type CDC -id {CDC-1} -user gtwizard_ultrascale -tags "1168849" -description "CDC-1 In exdes and vio path" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*int_pwr_on_fsm_reg}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME =~*wait_cnt_reg*}]]



