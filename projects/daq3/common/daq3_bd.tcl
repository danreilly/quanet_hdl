#
# This instantiates IPs in the block design,
# sets parameters,
# and makes the interconnections (Dan)
# But the ps8 is configured in common/zcu106/zcu106_system_bd.tcl

#
# Parameter description:
#   [RX/TX]_JESD_M : Number of converters per link
#   [RX/TX]_JESD_L : Number of lanes per link
#   [RX/TX]_JESD_S : Number of samples per frame
#

puts "daq3_bd start"
# Note: [get_property BD_OUTPUT_DIR [get_bd_designs]]
#       is *.gen/sources_1/bd/system
# puts "   outdir [get_property BD_OUTPUT_DIR [get_bd_designs]]"
puts [exec ls $project_system_dir]
# still, only system.bd is there.
source $ad_hdl_dir/library/jesd204/scripts/jesd204.tcl

# TX parameters
set TX_NUM_OF_LANES $ad_project_params(TX_JESD_L)      ; # L
set TX_NUM_OF_CONVERTERS $ad_project_params(TX_JESD_M) ; # M
set TX_SAMPLES_PER_FRAME $ad_project_params(TX_JESD_S) ; # S
set TX_SAMPLE_WIDTH 16                                 ; # N/NP

set TX_SAMPLES_PER_CHANNEL [expr $TX_NUM_OF_LANES * 32 / \
                                ($TX_NUM_OF_CONVERTERS * $TX_SAMPLE_WIDTH)] ; # L * 32 / (M * N)

set dac_fifo_name axi_ad9152_fifo
set dac_data_width [expr $TX_SAMPLE_WIDTH * $TX_NUM_OF_CONVERTERS * $TX_SAMPLES_PER_CHANNEL]

# RX parameters
set RX_NUM_OF_LANES $ad_project_params(RX_JESD_L)      ; # L
set RX_NUM_OF_CONVERTERS $ad_project_params(RX_JESD_M) ; # M
set RX_SAMPLES_PER_FRAME $ad_project_params(RX_JESD_S) ; # S
set RX_SAMPLE_WIDTH 16                                 ; # N/NP

set RX_SAMPLES_PER_CHANNEL [expr $RX_NUM_OF_LANES * 32 / \
                                ($RX_NUM_OF_CONVERTERS * $RX_SAMPLE_WIDTH)] ; # L * 32 / (M * N)

set adc_fifo_name axi_ad9680_fifo
set adc_data_width [expr $RX_SAMPLE_WIDTH * $RX_NUM_OF_CONVERTERS * $RX_SAMPLES_PER_CHANNEL]

set MAX_TX_NUM_OF_LANES 4
set MAX_RX_NUM_OF_LANES 4

# dac peripherals

ad_ip_instance axi_adxcvr axi_ad9152_xcvr
puts "after first ad_up_instace"
puts [exec ls $project_system_dir]
# still, only system.bd is there.

ad_ip_parameter axi_ad9152_xcvr CONFIG.NUM_OF_LANES $TX_NUM_OF_LANES
ad_ip_parameter axi_ad9152_xcvr CONFIG.QPLL_ENABLE 1
ad_ip_parameter axi_ad9152_xcvr CONFIG.TX_OR_RX_N 1

adi_axi_jesd204_tx_create axi_ad9152_jesd $TX_NUM_OF_LANES

adi_tpl_jesd204_tx_create axi_ad9152_tpl_core $TX_NUM_OF_LANES \
                                               $TX_NUM_OF_CONVERTERS \
                                               $TX_SAMPLES_PER_FRAME \
                                               $TX_SAMPLE_WIDTH

ad_ip_instance util_upack2 axi_ad9152_upack [list \
  NUM_OF_CHANNELS $TX_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $TX_SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $TX_SAMPLE_WIDTH \
]

ad_ip_instance axi_dmac axi_ad9152_dma
ad_ip_parameter axi_ad9152_dma CONFIG.DMA_TYPE_SRC 0
ad_ip_parameter axi_ad9152_dma CONFIG.DMA_TYPE_DEST 1
ad_ip_parameter axi_ad9152_dma CONFIG.ID 1
ad_ip_parameter axi_ad9152_dma CONFIG.AXI_SLICE_SRC 1
ad_ip_parameter axi_ad9152_dma CONFIG.AXI_SLICE_DEST 1
ad_ip_parameter axi_ad9152_dma CONFIG.DMA_LENGTH_WIDTH 24
ad_ip_parameter axi_ad9152_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter axi_ad9152_dma CONFIG.CYCLIC 0
ad_ip_parameter axi_ad9152_dma CONFIG.DMA_DATA_WIDTH_SRC 128
ad_ip_parameter axi_ad9152_dma CONFIG.DMA_DATA_WIDTH_DEST $dac_data_width

# Quanet stuff: instead of util_dacfifo IP we use now our own quanet_dac.
#ad_dacfifo_create $dac_fifo_name $dac_data_width $dac_data_width $dac_fifo_address_width
  ad_ip_instance quanet_dac $dac_fifo_name
#  ad_ip_parameter $dac_fifo_name CONFIG.DATA_WIDTH $dac_data_width
#  ad_ip_parameter $dac_fifo_name CONFIG.ADDRESS_WIDTH $dac_fifo_address_width

# adc peripherals

ad_ip_instance axi_adxcvr axi_ad9680_xcvr
ad_ip_parameter axi_ad9680_xcvr CONFIG.NUM_OF_LANES $RX_NUM_OF_LANES
ad_ip_parameter axi_ad9680_xcvr CONFIG.QPLL_ENABLE 0
ad_ip_parameter axi_ad9680_xcvr CONFIG.TX_OR_RX_N 0

adi_axi_jesd204_rx_create axi_ad9680_jesd $RX_NUM_OF_LANES

adi_tpl_jesd204_rx_create axi_ad9680_tpl_core $RX_NUM_OF_LANES \
                                               $RX_NUM_OF_CONVERTERS \
                                               $RX_SAMPLES_PER_FRAME \
                                               $RX_SAMPLE_WIDTH
ad_ip_parameter axi_ad9680_tpl_core/adc_tpl_core CONFIG.CONVERTER_RESOLUTION 14
ad_ip_parameter axi_ad9680_tpl_core/adc_tpl_core CONFIG.TWOS_COMPLEMENT 0                                              

ad_ip_instance util_cpack2 axi_ad9680_cpack [list \
  NUM_OF_CHANNELS $RX_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $RX_SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $RX_SAMPLE_WIDTH \
  ]

ad_ip_instance axi_dmac axi_ad9680_dma
ad_ip_parameter axi_ad9680_dma CONFIG.DMA_TYPE_SRC 1
ad_ip_parameter axi_ad9680_dma CONFIG.DMA_TYPE_DEST 0
ad_ip_parameter axi_ad9680_dma CONFIG.ID 0
ad_ip_parameter axi_ad9680_dma CONFIG.AXI_SLICE_SRC 0
ad_ip_parameter axi_ad9680_dma CONFIG.AXI_SLICE_DEST 0
ad_ip_parameter axi_ad9680_dma CONFIG.SYNC_TRANSFER_START 0
ad_ip_parameter axi_ad9680_dma CONFIG.DMA_LENGTH_WIDTH 24
ad_ip_parameter axi_ad9680_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter axi_ad9680_dma CONFIG.CYCLIC 0
ad_ip_parameter axi_ad9680_dma CONFIG.DMA_DATA_WIDTH_SRC $adc_data_width
ad_ip_parameter axi_ad9680_dma CONFIG.DMA_DATA_WIDTH_DEST 64


# ad_ip_instance quanet_regs qregs
# Then later I will have to call ad_cpu_interconnect

if {0} {
    ad_ip_instance quanet_sfp qsfp
    create_bd_port -dir I rx_p
    create_bd_port -dir I rx_n
    create_bd_port -dir I gtrefclk
    create_bd_port -dir O tx_p
    create_bd_port -dir O tx_n
    create_bd_port -dir O txclk_out
    ad_connect qsfp/rx_p rx_p
    ad_connect qsfp/rx_n rx_n    
    ad_connect qsfp/tx_p tx_p
    ad_connect qsfp/tx_n tx_n
    ad_connect qsfp/gtrefclk gtrefclk
    ad_connect qsfp/txclk_out txclk_out
}

# Dan: originally this did not include sys_zynq 2. perhaps
# the mem iface is different in the ultrascale
# if {$sys_zynq == 0 || $sys_zynq == 1}
if {$sys_zynq == 0 || $sys_zynq == 1 || $sys_zynq == 2} {
  puts "DAN: will call: ad_adcfifo_create $adc_fifo_name $adc_data_width $adc_data_width $adc_fifo_address_width"
  puts [exec ls $project_system_dir]

  ad_adcfifo_create $adc_fifo_name $adc_data_width $adc_data_width $adc_fifo_address_width

  ad_cpu_interconnect 0x44ad0000 $adc_fifo_name

  # NuCrypt additions related to adcfifo:
  create_bd_port -dir O rxq_sw_ctl
  ad_connect  axi_ad9680_fifo/rxq_sw_ctl rxq_sw_ctl
  # dont have to do this beacause i set associated busif for this
  # ad_connect $sys_cpu_clk    axi_ad9680_fifo/s_axi_aclk
  # ad_connect $sys_cpu_resetn axi_ad9680_fifo/s_axi_aresetn
}

# shared transceiver core

ad_ip_instance util_adxcvr util_daq3_xcvr
ad_ip_parameter util_daq3_xcvr CONFIG.RX_NUM_OF_LANES $MAX_RX_NUM_OF_LANES
ad_ip_parameter util_daq3_xcvr CONFIG.TX_NUM_OF_LANES $MAX_TX_NUM_OF_LANES
ad_ip_parameter util_daq3_xcvr CONFIG.QPLL_REFCLK_DIV 1
ad_ip_parameter util_daq3_xcvr CONFIG.QPLL_FBDIV_RATIO 1
ad_ip_parameter util_daq3_xcvr CONFIG.QPLL_FBDIV 0x30; # 20
ad_ip_parameter util_daq3_xcvr CONFIG.RX_OUT_DIV 1
ad_ip_parameter util_daq3_xcvr CONFIG.TX_OUT_DIV 1
ad_ip_parameter util_daq3_xcvr CONFIG.RX_DFE_LPM_CFG 0x0904
ad_ip_parameter util_daq3_xcvr CONFIG.RX_CDR_CFG 0x0B000023FF10400020

ad_connect  $sys_cpu_resetn util_daq3_xcvr/up_rstn
ad_connect  $sys_cpu_clk util_daq3_xcvr/up_clk



# reference clocks & resets

create_bd_port -dir I tx_ref_clk_0
create_bd_port -dir I rx_ref_clk_0



ad_xcvrpll  tx_ref_clk_0 util_daq3_xcvr/qpll_ref_clk_*
ad_xcvrpll  rx_ref_clk_0 util_daq3_xcvr/cpll_ref_clk_*
ad_xcvrpll  axi_ad9152_xcvr/up_pll_rst util_daq3_xcvr/up_qpll_rst_*
ad_xcvrpll  axi_ad9680_xcvr/up_pll_rst util_daq3_xcvr/up_cpll_rst_*

# connections (dac)

ad_xcvrcon  util_daq3_xcvr axi_ad9152_xcvr axi_ad9152_jesd {0 2 3 1} {} {} $MAX_TX_NUM_OF_LANES
ad_connect  util_daq3_xcvr/tx_out_clk_0 axi_ad9152_tpl_core/link_clk
ad_connect  axi_ad9152_jesd/tx_data axi_ad9152_tpl_core/link
ad_connect  util_daq3_xcvr/tx_out_clk_0 axi_ad9152_upack/clk
ad_connect  axi_ad9152_jesd_rstgen/peripheral_reset axi_ad9152_upack/reset

ad_connect  axi_ad9152_tpl_core/dac_valid_0 axi_ad9152_upack/fifo_rd_en
for {set i 0} {$i < $TX_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  axi_ad9152_tpl_core/dac_enable_$i axi_ad9152_upack/enable_$i
  ad_connect  axi_ad9152_tpl_core/dac_data_$i axi_ad9152_upack/fifo_rd_data_$i
}

# dan added sys_zynq 2
if {$sys_zynq == 0 || $sys_zynq == 1 || $sys_zynq == 2 } { 
    ad_connect  $sys_dma_clk   axi_ad9152_fifo/dma_clk
    ad_connect  $sys_dma_reset axi_ad9152_fifo/dma_rst
    # ad_connect  axi_ad9152_fifo/bypass GND
    
    ad_connect  $sys_dma_clk    axi_ad9152_dma/m_axis_aclk
    ad_connect  $sys_dma_resetn axi_ad9152_dma/m_src_axi_aresetn
}
ad_connect  util_daq3_xcvr/tx_out_clk_0 axi_ad9152_fifo/dac_clk
ad_connect  axi_ad9152_jesd_rstgen/peripheral_reset axi_ad9152_fifo/dac_rst 

# TODO: Add streaming AXI interface for DAC FIFO
ad_connect  axi_ad9152_upack/s_axis_valid VCC
ad_connect  axi_ad9152_upack/s_axis_ready axi_ad9152_fifo/dac_valid
ad_connect  axi_ad9152_upack/s_axis_data axi_ad9152_fifo/dac_data

ad_connect  axi_ad9152_tpl_core/dac_dunf axi_ad9152_fifo/dac_dunf
ad_connect  axi_ad9152_fifo/dma_xfer_req axi_ad9152_dma/m_axis_xfer_req
ad_connect  axi_ad9152_fifo/dma_ready axi_ad9152_dma/m_axis_ready
ad_connect  axi_ad9152_fifo/dma_data axi_ad9152_dma/m_axis_data
ad_connect  axi_ad9152_fifo/dma_valid axi_ad9152_dma/m_axis_valid
ad_connect  axi_ad9152_fifo/dma_xfer_last axi_ad9152_dma/m_axis_last

# connections (adc)

ad_xcvrcon  util_daq3_xcvr axi_ad9680_xcvr axi_ad9680_jesd {} {} {} $MAX_RX_NUM_OF_LANES
ad_connect  util_daq3_xcvr/rx_out_clk_0 axi_ad9680_tpl_core/link_clk
ad_connect  axi_ad9680_jesd/rx_sof axi_ad9680_tpl_core/link_sof
ad_connect  axi_ad9680_jesd/rx_data_tdata axi_ad9680_tpl_core/link_data
ad_connect  axi_ad9680_jesd/rx_data_tvalid axi_ad9680_tpl_core/link_valid
ad_connect  axi_ad9680_tpl_core/adc_valid_0 axi_ad9680_cpack/fifo_wr_en

# dan added these for debug
#connect_bd_net -net [get_bd_nets -of [get_bd_pins axi_ad9680_jesd/rx_data_tvalid]] [get_bd_pins axi_ad9680_fifo/link_valid]
#ad_connect  axi_ad9680_jesd/rx_data_tvalid  axi_ad9680_fifo/link_valid
#connect_bd_net -net [get_bd_nets -of [get_bd_pins axi_ad9680_tpl_core/adc_valid_0]] [get_bd_pins axi_ad9680_fifo/core_valid]
#ad_connect axi_ad9680_jesd/dbg_core_rst axi_ad9680_fifo/dbg_core_rst
#ad_connect axi_ad9680_jesd/dbg_dev_rst  axi_ad9680_fifo/dbg_dev_rst
# ad_connect axi_ad9680_jesd/dbg_charisk  axi_ad9680_fifo/dbg_charisk


# dan added sys_zynq 2
if {$sys_zynq == 0 || $sys_zynq == 1 || $sys_zynq == 2 } {
    ad_connect  util_daq3_xcvr/rx_out_clk_0 axi_ad9680_fifo/adc_clk
    ad_connect  axi_ad9680_jesd_rstgen/peripheral_reset axi_ad9680_fifo/adc_rst
    ad_connect  axi_ad9680_cpack/packed_fifo_wr_en      axi_ad9680_fifo/adc_wr
    ad_connect  axi_ad9680_cpack/packed_fifo_wr_data    axi_ad9680_fifo/adc_wdata
    ad_connect  $sys_dma_clk axi_ad9680_fifo/dma_clk
    ad_connect  $sys_dma_clk axi_ad9680_dma/s_axis_aclk
    ad_connect  $sys_dma_resetn axi_ad9680_dma/m_dest_axi_aresetn
    ad_connect  axi_ad9680_fifo/dma_wr       axi_ad9680_dma/s_axis_valid
    ad_connect  axi_ad9680_fifo/dma_wdata    axi_ad9680_dma/s_axis_data
    ad_connect  axi_ad9680_fifo/dma_wready   axi_ad9680_dma/s_axis_ready
    ad_connect  axi_ad9680_fifo/dma_xfer_req axi_ad9680_dma/s_axis_xfer_req
    ad_connect  axi_ad9680_tpl_core/adc_dovf axi_ad9680_fifo/adc_wovf

}

puts "Quanet connections1"
# dac_xfer_out_port not used anymore
# create_bd_port -dir O dac_xfer_out_port
create_bd_port -dir O hdr_vld
#ad_connect  axi_ad9152_fifo/dac_xfer_out dac_xfer_out_port
ad_connect  util_daq3_xcvr/tx_out_clk_0 axi_ad9680_fifo/dac_clk
ad_connect  axi_ad9680_fifo/dac_tx axi_ad9152_fifo/dac_tx_in 
ad_connect  axi_ad9152_fifo/dac_tx_out axi_ad9680_fifo/dac_tx_in 
ad_connect  axi_ad9152_fifo/hdr_vld    hdr_vld

#ad_connect  util_dacfifo/regs_w                 axi_ad9152_fifo/regs_w
# ad_connect  axi_ad9152_fifo/regs_r       qregs/regs_r
# ad_connect  axi_ad9680_fifo/reg_samp     qregs/reg_samp
#ad_connect  axi_ad9680_fifo/reg_adc_stat qregs/reg_adc_stat

# This is a little kludgey for now
create_bd_port -from 3 -to 0 -dir I gth_status
create_bd_port -dir O gth_rst
ad_connect  gth_status  $dac_fifo_name/gth_status
ad_connect  gth_rst     $dac_fifo_name/gth_rst

# Note: you cant set time constrants (false paths) here.
# Do that in system_constr.xdc
# set_false_path -through [get_bd_pins axi_sysid_0/reg4_o*]"


# puts "type [ad_connect_int_class led0]"
# puts "tst [get_bd_ports led0]"
puts "dans connections"
ad_connect  util_daq3_xcvr/rx_out_clk_0 axi_ad9680_cpack/clk
ad_connect  axi_ad9680_jesd_rstgen/peripheral_reset axi_ad9680_cpack/reset

for {set i 0} {$i < $RX_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  axi_ad9680_tpl_core/adc_enable_$i axi_ad9680_cpack/enable_$i
  ad_connect  axi_ad9680_tpl_core/adc_data_$i axi_ad9680_cpack/fifo_wr_data_$i
}

# interconnect (cpu)

ad_cpu_interconnect 0x44A60000 axi_ad9152_xcvr
ad_cpu_interconnect 0x44A04000 axi_ad9152_tpl_core
ad_cpu_interconnect 0x44A90000 axi_ad9152_jesd
ad_cpu_interconnect 0x7c420000 axi_ad9152_dma

ad_cpu_interconnect 0x44A50000 axi_ad9680_xcvr
ad_cpu_interconnect 0x44A10000 axi_ad9680_tpl_core
ad_cpu_interconnect 0x44AA0000 axi_ad9680_jesd
ad_cpu_interconnect 0x7c400000 axi_ad9680_dma

# Dan added registers into this
ad_cpu_interconnect 0x44ab0000 $dac_fifo_name
# ad_cpu_interconnect 0x44ad0000 qsfp





# These add "high performance interconnects" to or from the PS
# dan added case 2 for zcu106
# hp0 is connected in <board>_system_bd.tcl for HDMI dma.
if {$sys_zynq == 0 || $sys_zynq == 1 || $sys_zynq==2 } {

    # from ADC dmac to PS
    ad_mem_hp1_interconnect $sys_dma_clk sys_ps7/S_AXI_HP1
    ad_mem_hp1_interconnect $sys_dma_clk axi_ad9152_dma/m_src_axi

    # from PS to ADC dmac
    ad_mem_hp2_interconnect $sys_dma_clk sys_ps7/S_AXI_HP2
    ad_mem_hp2_interconnect $sys_dma_clk axi_ad9680_dma/m_dest_axi

    # not sure yet what this is for.
    # seems to be something that DMAs either status or DMA addr delimiter fields
    # back to the processor.  But then I'm not sure why that wasn't implemented simply
    # as readable registers.
    ad_mem_hp3_interconnect $sys_cpu_clk sys_ps7/S_AXI_HP3
    ad_mem_hp3_interconnect $sys_cpu_clk axi_ad9680_xcvr/m_axi
}

# interrupts

ad_cpu_interrupt ps-10 mb-15 axi_ad9152_jesd/irq
ad_cpu_interrupt ps-11 mb-14 axi_ad9680_jesd/irq
ad_cpu_interrupt ps-12 mb-13 axi_ad9152_dma/irq
ad_cpu_interrupt ps-13 mb-12 axi_ad9680_dma/irq
