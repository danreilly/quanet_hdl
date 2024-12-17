# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\reilly\proj\floodlight\hdl-main\projects\daq3\zcu106\daq3_zcu106.workspace\myplat\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\reilly\proj\floodlight\hdl-main\projects\daq3\zcu106\daq3_zcu106.workspace\myplat\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {myplat}\
-hw {C:\reilly\proj\floodlight\hdl-main\projects\daq3\zcu106\daq3_zcu106.sdk\system_top.xsa}\
-proc {psu_cortexa53} -os {linux} -arch {64-bit} -fsbl-target {psu_cortexa53_0} -out {C:/reilly/proj/floodlight/hdl-main/projects/daq3/zcu106/daq3_zcu106.workspace}

platform write
platform active {myplat}
