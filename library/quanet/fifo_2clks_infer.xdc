
# set_false_path -through [get_ports {din[*] wr_en}] -through [get_nets mem_o[*]]

# set_false_path -from [get_clocks -of [get_ports wclk]] -through [get_nets mem_o[*] ]

# This did not work
# set_false_path -through [get_ports wclk]  -through [get_nets mem_o[*] ]

set_false_path -from [get_pins mem_reg*/*/CLK] -through [get_nets mem_o[*] ]

# Note; -from [get_pins mem_reg*/WCLK] is not a valid startpoint.
# [get_clocks -of [get_ports wclk]] did not yeild any clocks!
# should I have said of_objects?
# tool adds -scoped_to_current_instance to get_ports

