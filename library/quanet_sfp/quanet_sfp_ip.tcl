# ip
puts "building quanet sfp"
source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

global VIVADO_IP_LIBRARY

adi_ip_create quanet_sfp
adi_ip_files quanet_sfp [list               \
  "$ad_hdl_dir/library/quanet/cdc_samp.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_samp.xdc" \
  "$ad_hdl_dir/library/quanet/lfsr_w.vhd"   \
  "axi_reg_array.vhd"                       \
  "my_gth_wrap.vhd"                         \
  "in_system_ibert_0/in_system_ibert_0.xci" \
  "my_gth/my_gth.xci"                       \
  "quanet_sfp.vhd" ]


# Should this be adi_ip_properties or adi_ip_properties_lite
adi_ip_properties quanet_sfp
set cc [ipx::current_core]

set_property scoped_to_ref cdc_samp [get_files cdc_samp.xdc]

ipx::infer_bus_interface { \
    s_axi_aclk    s_axi_aresetn  \
    s_axi_awaddr  s_axi_awvalid  s_axi_awready      \
    s_axi_wdata   s_axi_wvalid   s_axi_wstrb      s_axi_wready     s_axi_awprot  \
    s_axi_bresp   s_axi_bvalid   s_axi_bready \
    s_axi_araddr  s_axi_arprot   s_axi_arvalid    s_axi_arready \
    s_axi_rdata   s_axi_rresp    s_axi_rvalid    s_axi_rready } \
  xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]


set_property company_url {https://www.nucrypt.net} $cc

ipx::save_core $cc
