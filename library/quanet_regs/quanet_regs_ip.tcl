# ip
puts "building quanet regs"
source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

global VIVADO_IP_LIBRARY

adi_ip_create quanet_regs
adi_ip_files quanet_regs [list \
  "$ad_hdl_dir/library/common/up_axi.v" \
  "quanet_regs.v" ]

#  "$ad_hdl_dir/library/common/cdc_thru.vhd" \
#  "$ad_hdl_dir/library/common/cdc_thru.xdc" ]

# Should this be adi_ip_properties or adi_ip_properties_lite
adi_ip_properties quanet_regs
set cc [ipx::current_core]

ipx::infer_bus_interface clk xilinx.com:signal:clock_rtl:1.0 $cc

# set_property scoped_to_ref cdc_thru [get_files cdc_thru.xdc]

set_property company_url {https://wiki.analog.com/resources/fpga/docs/axi_sysid} $cc



ipx::save_core $cc
