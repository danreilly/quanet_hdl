#
# Dan: copied from zc706_plddr3_adcfifo_bd.tcl to zcu_plddr3...
# then maybe modified it.
# Then copied that here.




proc ad_adcfifo_create {adc_fifo_name adc_data_width adc_dma_data_width adc_fifo_address_width} {
  puts "IN AD_ADCFIFO_CREATE"
  # puts "  bd/system: [exec ls daq3_zcu102.srcs/sources_1/bd/system]"
    
  upvar ad_hdl_dir ad_hdl_dir

  # the ddr4 ctlr will synchronize its ext_reset_in to the ui_clk to
  # produce c0_ddr4_ui_clk_sync_rst, so perhaps we don't need to use a
  # separate proc_sys_reset.  But the polarity of
  # axi_rstgen/ext_reset_in is active low and cant be changed, and our
  # board reset is active high.
    
  ad_ip_instance proc_sys_reset axi_rstgen

  ad_ip_instance ddr4 axi_ddr_cntrl
  # Note: ad_ip_parameter is a thin wrapper around set_property    
  ad_ip_parameter axi_ddr_cntrl CONFIG.C0_DDR4_BOARD_INTERFACE ddr4_sdram_075
  ad_ip_parameter axi_ddr_cntrl CONFIG.C0_CLOCK_BOARD_INTERFACE user_si570_sysclk

    
  puts "    axi_ddr_cntrl properties:"
  report_property [get_bd_cells axi_ddr_cntrl]


    
    
  # Note: DATA_WIDTH is read only
  # This is set to 64.
  #  set_property CONFIG.DATA_WIDTH 512 [get_bd_intd_ports axi_ddr_cntrl/C0_DDR4_S_AXI]
    
  # That ad_ip_instance should have made this dir:
  exec mkdir daq3_zcu102.srcs/sources_1/bd/system/ip
  exec mkdir daq3_zcu102.srcs/sources_1/bd/system/ip/system_axi_ddr_cntrl_0

  puts "  bd/system: [exec ls daq3_zcu102.srcs/sources_1/bd/system]"
  puts "  bd/system/ip: [exec ls daq3_zcu102.srcs/sources_1/bd/system/ip]"
    
  puts "  dest: [get_property IP_DIR [get_ips [get_property CONFIG.Component_Name [get_bd_cells axi_ddr_cntrl]]]]"
    
  

  # Unlike ddr3, the ddr4 does not have property CONFIG.XML_INPUT_FILE
  #  ad_ip_parameter axi_ddr_cntrl CONFIG.XML_INPUT_FILE zcu102_plddr4_mig.prj


    
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk
  # should i set CONFIG.C0.DDR4_AxiIDWidth to 1?


    
  #  I did this to avoid a warning, but probably the warning is harmless.
  #  (though I dont know why the user_si570_sysclk interface doesnt do it for me):
  set_property CONFIG.FREQ_HZ 300000000 [get_bd_intf_ports sys_clk]


    
  # Note: cant set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_pins axi_ddr_cntrl/sys_rst] because it's read-only
  #  ad_connect  sys_cpu_resetn axi_ddr_cntrl/sys_rst
    
  ad_connect  ddr4 axi_ddr_cntrl/C0_DDR4
  ad_connect  sys_clk axi_ddr_cntrl/C0_SYS_CLK
  puts "NOTE: will add quanet_adc as adcfifo"
#  ad_ip_instance axi_adcfifo $adc_fifo_name
  ad_ip_instance quanet_adc $adc_fifo_name

  ad_ip_parameter $adc_fifo_name CONFIG.ADC_DATA_WIDTH $adc_data_width
  ad_ip_parameter $adc_fifo_name CONFIG.DMA_DATA_WIDTH $adc_dma_data_width
# DAN: This width of 128 is different from zcu106:    
  ad_ip_parameter $adc_fifo_name CONFIG.AXI_DATA_WIDTH 128
  ad_ip_parameter $adc_fifo_name CONFIG.DMA_READY_ENABLE 1
  ad_ip_parameter $adc_fifo_name CONFIG.AXI_LENGTH 4
#  ad_ip_parameter $adc_fifo_name CONFIG.AXI_ADDRESS_SIZE 0x10000000
# DBG: this used to have:    
# ad_ip_parameter $adc_fifo_name CONFIG.AXI_SIZE 6
    # ad_ip_parameter $adc_fifo_name CONFIG.AXI_ADDRESS 0x80000000

# The zcu102 ddr size is 512MBytes=x20000000.
# The zcu106 is bigger

    puts "NOTE: setting size here"
    ad_ip_parameter $adc_fifo_name CONFIG.AXI_ADDRESS_SIZE 536870912
# ad_ip_parameter $adc_fifo_name CONFIG.AXI_ADDRESS_LIMIT 0xbfffffff
# ad_ip_parameter $adc_fifo_name CONFIG.AXI_ADDRESS_LIMIT 0xbfbfffff


  ad_connect  axi_ddr_cntrl/C0_DDR4_S_AXI  $adc_fifo_name/axi


  ad_connect  axi_ddr_cntrl/c0_ddr4_ui_clk   $adc_fifo_name/axi_clk
  ad_connect  axi_ddr_cntrl/c0_ddr4_ui_clk   axi_rstgen/slowest_sync_clk


    
  ad_connect  sys_cpu_resetn                         axi_rstgen/ext_reset_in
    

# ad_connect  axi_ddr_cntrl/c0_ddr4_ui_clk_sync_rst  axi_rstgen/ext_reset_in
  ad_connect  axi_rstgen/peripheral_reset   /axi_ddr_cntrl/sys_rst
  ad_connect  axi_rstgen/peripheral_aresetn $adc_fifo_name/axi_resetn
  ad_connect  axi_rstgen/peripheral_aresetn axi_ddr_cntrl/c0_ddr4_aresetn
    
  # No more device temp port (which the ddr3 had)
  #  ad_connect  axi_ddr_cntrl/device_temp_i GND

  assign_bd_address [get_bd_addr_segs -of_objects [get_bd_cells axi_ddr_cntrl]]

  # In bare metal designs I used to connect init_calib_complete to the
  # aux_reset_in of the microblaze's proc sys rst.  Because that guarantees that the proc
  # would not start before the ddr was ready.  But that does not apply here.
    
  # https://adaptivesupport.amd.com/s/article/71599?language=en_US  says:
  # "For x8 and x16 DDR4 devices, regardless of the Data Mask and DBI
  # setting in the IP, it is always expected that the DM_n/DBI_n pin is
  # routed from the FPGA to the memory device."

}

