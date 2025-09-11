hsi open_hw_design system_top.xsa
set cpu_name [lindex [hsi get_cells -filter {IP_TYPE==PROCESSOR}] 0] 
platform create -name hw0 -hw system_top.xsa -os standalone -out tmp -proc $cpu_name
platform generate
