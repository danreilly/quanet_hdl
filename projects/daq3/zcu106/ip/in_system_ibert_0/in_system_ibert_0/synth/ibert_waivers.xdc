
############################################################


############################################################

create_waiver -internal -quiet -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1165975" -description "CDC-1 waiver for CPLL Calibration logic" \
                        -scope -from [get_ports {gt0_drpdo_i[*]}] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*GT*E*_CH[*].u_gt*e*_ch/i_regs/U_XSDB_SLAVE/G_1PIPE_IFACE.s_do_r_reg[*]}]]
