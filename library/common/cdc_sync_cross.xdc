set_max_delay 3 -datapath_only      \
    -from [get_pins tog_r_i_reg/C]   \
    -to   [get_pins tog_r_p_reg/D]

set_max_delay 3 -datapath_only      \
    -from [get_pins tog_f_i_reg/C]   \
    -to   [get_pins tog_f_p_reg/D]

set_false_path -through [get_nets {tog_r_u tog_f_u clk_in_bad* rst2_u}]

#set_false_path -through [get_nets {d_in_0[*] d_in_1[*]}]
set_false_path -through [get_pins  {d_in_0_reg[*]/Q d_in_1_reg[*]/Q}]
