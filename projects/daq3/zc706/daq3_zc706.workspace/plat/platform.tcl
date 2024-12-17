# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\reilly\proj\floodlight\hdl-main\projects\daq3\zc706\daq3_zc706.workspace\plat\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\reilly\proj\floodlight\hdl-main\projects\daq3\zc706\daq3_zc706.workspace\plat\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {plat}\
-hw {C:\reilly\proj\floodlight\hdl-main\projects\daq3\zc706\daq3_zc706.sdk\system_top.xsa}\
-proc {ps7_cortexa9} -os {linux} -out {C:/reilly/proj/floodlight/hdl-main/projects/daq3/zc706/daq3_zc706.workspace}

platform write
platform active {plat}
domain active {zynq_fsbl}
bsp reload
bsp reload
domain active {linux_domain}
domain config -generate-bif
platform write
platform generate
platform active {plat}
platform active {plat}
