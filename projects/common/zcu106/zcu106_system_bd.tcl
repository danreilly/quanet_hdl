#  There is a lot of board-specific stuff here
#  also see zcu106_system_constr.xdc for pin loc constraints
# Note that the other ddr4 is made in zcu106_plddr4_adcfifo_bd.tcl

# create board design
# default ports


# create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr
# DANs note: I don't think this instantiation belongs here.  Not all projects neeed an extra iic.
#    certainly daq3 does though, but this tcl script is for all zc706 projects.
# But I'm following the zc706 example.
#create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main
# create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 fixed_io


create_bd_port -dir O -from 2 -to 0 spi0_csn
create_bd_port -dir O spi0_sclk
create_bd_port -dir O spi0_mosi
create_bd_port -dir I spi0_miso

create_bd_port -dir O -from 2 -to 0 spi1_csn
create_bd_port -dir O spi1_sclk
create_bd_port -dir O spi1_mosi
create_bd_port -dir I spi1_miso

# I'd rather not spec a width for these here.
# why cant tool infer width from zynq ps8 configuration?
create_bd_port -dir I -from 38 -to 0 gpio_i
create_bd_port -dir O -from 38 -to 0 gpio_o
create_bd_port -dir O -from 38 -to 0 gpio_t

ad_ip_instance zynq_ultra_ps_e sys_ps8
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e \
  -config {apply_board_preset 1}  [get_bd_cells sys_ps8]

ad_ip_parameter sys_ps8 CONFIG.PSU__PSS_REF_CLK__FREQMHZ 33.333333333
ad_ip_parameter sys_ps8 CONFIG.PSU__USE__M_AXI_GP0 0
ad_ip_parameter sys_ps8 CONFIG.PSU__USE__M_AXI_GP1 0
ad_ip_parameter sys_ps8 CONFIG.PSU__USE__M_AXI_GP2 1
ad_ip_parameter sys_ps8 CONFIG.PSU__MAXIGP2__DATA_WIDTH 32
ad_ip_parameter sys_ps8 CONFIG.PSU__FPGA_PL0_ENABLE 1
ad_ip_parameter sys_ps8 CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL}
ad_ip_parameter sys_ps8 CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ 100
ad_ip_parameter sys_ps8 CONFIG.PSU__FPGA_PL1_ENABLE 1
ad_ip_parameter sys_ps8 CONFIG.PSU__FPGA_PL2_ENABLE 1
ad_ip_parameter sys_ps8 CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {IOPLL}
ad_ip_parameter sys_ps8 CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ 250
ad_ip_parameter sys_ps8 CONFIG.PSU__CRL_APB__PL2_REF_CTRL__SRCSEL {IOPLL}
ad_ip_parameter sys_ps8 CONFIG.PSU__CRL_APB__PL2_REF_CTRL__FREQMHZ 500
ad_ip_parameter sys_ps8 CONFIG.PSU__USE__IRQ0 1
ad_ip_parameter sys_ps8 CONFIG.PSU__USE__IRQ1 1
ad_ip_parameter sys_ps8 CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE 1
ad_ip_parameter sys_ps8 CONFIG.PSU__GPIO_EMIO_WIDTH 39


# PS iic0 is on mio 14,15 and goes to a bunch of board chips.
# PS iic1 is on mio 16,17 and goes to others inc fmc hpc0 iic sda/dcl.

#ad_ip_instance axi_iic axi_iic_main
#ad_ip_parameter axi_iic_main CONFIG.USE_BOARD_FLOW true
#ad_ip_parameter axi_iic_main CONFIG.IIC_BOARD_INTERFACE Custom
#ad_connect  iic_main axi_iic_main/iic


# The two spis are enabled too, but only one used, to ctl daq3 board.
# The zcu106 board has two qspis for flash I think

set_property -dict [list \
  CONFIG.PSU__SPI0__PERIPHERAL__ENABLE 1 \
  CONFIG.PSU__SPI0__PERIPHERAL__IO {EMIO} \
  CONFIG.PSU__SPI0__GRP_SS1__ENABLE 1 \
  CONFIG.PSU__SPI0__GRP_SS2__ENABLE 1 \
  CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__FREQMHZ 100 \
  CONFIG.PSU__SPI1__PERIPHERAL__ENABLE 1 \
  CONFIG.PSU__SPI1__PERIPHERAL__IO EMIO \
  CONFIG.PSU__SPI1__GRP_SS1__ENABLE 1 \
  CONFIG.PSU__SPI1__GRP_SS2__ENABLE 1 \
  CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__FREQMHZ 100 \
] [get_bd_cells sys_ps8]

# processor system reset instances for all the three system clocks

ad_ip_instance proc_sys_reset sys_rstgen
ad_ip_parameter sys_rstgen CONFIG.C_EXT_RST_WIDTH 1
ad_ip_instance proc_sys_reset sys_250m_rstgen
ad_ip_parameter sys_250m_rstgen CONFIG.C_EXT_RST_WIDTH 1
ad_ip_instance proc_sys_reset sys_500m_rstgen
ad_ip_parameter sys_500m_rstgen CONFIG.C_EXT_RST_WIDTH 1

# system reset/clock definitions

ad_connect  sys_cpu_clk  sys_ps8/pl_clk0
ad_connect  sys_250m_clk sys_ps8/pl_clk1
ad_connect  sys_500m_clk sys_ps8/pl_clk2

ad_connect  sys_ps8/pl_resetn0 sys_rstgen/ext_reset_in
ad_connect  sys_cpu_clk sys_rstgen/slowest_sync_clk
ad_connect  sys_ps8/pl_resetn0 sys_250m_rstgen/ext_reset_in
ad_connect  sys_250m_clk sys_250m_rstgen/slowest_sync_clk
ad_connect  sys_ps8/pl_resetn0 sys_500m_rstgen/ext_reset_in
ad_connect  sys_500m_clk sys_500m_rstgen/slowest_sync_clk

ad_connect  sys_cpu_reset sys_rstgen/peripheral_reset
ad_connect  sys_cpu_resetn sys_rstgen/peripheral_aresetn
ad_connect  sys_250m_reset sys_250m_rstgen/peripheral_reset
ad_connect  sys_250m_resetn sys_250m_rstgen/peripheral_aresetn
ad_connect  sys_500m_reset sys_500m_rstgen/peripheral_reset
ad_connect  sys_500m_resetn sys_500m_rstgen/peripheral_aresetn

# generic system clocks&resets pointers

set sys_cpu_clk            [get_bd_nets sys_cpu_clk]
set sys_dma_clk            [get_bd_nets sys_250m_clk]
set sys_iodelay_clk        [get_bd_nets sys_500m_clk]

set  sys_cpu_reset         [get_bd_nets sys_cpu_reset]
set  sys_cpu_resetn        [get_bd_nets sys_cpu_resetn]
set  sys_dma_reset         [get_bd_nets sys_250m_reset]
set  sys_dma_resetn        [get_bd_nets sys_250m_resetn]
set  sys_iodelay_reset     [get_bd_nets sys_500m_reset]
set  sys_iodelay_resetn    [get_bd_nets sys_500m_resetn]

# The PS DDR is already enabled, and when I did a report_property on the ps8,
# the ddr properties matched the ones from the xilinx example project for the zcu106.
report_property [get_bd_cells sys_ps8]

# current_bd_instance [get_bd_cells sys_ps8]
# create_bd_intf_pin -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr

# report_property [get_bd_cells sys_ps8]

# we dont need to instantiate a ddr controller because one is built in.
#ad_ip_instance ddr4 ps_ddr4_ctl
#ad_ip_parameter ps_ddr4_ctl CONFIG.C0_DDR4_BOARD_INTERFACE ddr4_sdram_062
#ad_ip_parameter ps_ddr4_ctl CONFIG.C0_CLOCK_BOARD_INTERFACE user_si570_sysclk
#ad_connect  ps_ddr4_ctl/C0_DDR4 ddr
# This is a copy of how we treated PL ddr
#ad_connect  sys_rst ps_ddr4_ctl/sys_rst

# I dont think we need to use all these automations.

# apply_bd_automation -rule xilinx.com:bd_rule:board -config { \
#	Board_Interface {ddr4_sdram_062 ( DDR4 SDRAM ) } Manual_Source {Auto}}  \
#                   [get_bd_intf_pins ps_ddr4_ctl/C0_DDR4]

# Typically the ddr4 ctlr's "ui clk" (ps_ddr4_ctl/c0_ddr4_ui_clk) feeds the axi connect and proc sys rst
# and 
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { \
# 	Clk_master {Auto} Clk_slave {/ps_ddr4_ctl/c0_ddr4_ui_clk (300 MHz)} \
# 	Clk_xbar {Auto} Master {/sys_ps8/M_AXI_HPM0_LPD} \
# 	Slave {/ps_ddr4_ctl/C0_DDR4_S_AXI} \
# 	ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}} \
#                   [get_bd_intf_pins ps_ddr4_ctl/C0_DDR4_S_AXI]

#apply_bd_automation -rule xilinx.com:bd_rule:board -config { \
#	Board_Interface {user_si570_sysclk ( User Programmable differential clock ) } Manual_Source {Auto}} \
#                   [get_bd_intf_pins ps_ddr4_ctl/C0_SYS_CLK]

#apply_bd_automation -rule xilinx.com:bd_rule:board -config { \
#        Board_Interface {Custom} Manual_Source {New External Port (ACTIVE_HIGH)}}
#                   [get_bd_pins ddr4_0/sys_rst]

ad_connect  gpio_i sys_ps8/emio_gpio_i
ad_connect  gpio_o sys_ps8/emio_gpio_o
ad_connect  gpio_t sys_ps8/emio_gpio_t

# spi

ad_ip_instance xlconcat spi0_csn_concat
ad_ip_parameter spi0_csn_concat CONFIG.NUM_PORTS 3
ad_connect  sys_ps8/emio_spi0_ss_o_n spi0_csn_concat/In0
ad_connect  sys_ps8/emio_spi0_ss1_o_n spi0_csn_concat/In1
ad_connect  sys_ps8/emio_spi0_ss2_o_n spi0_csn_concat/In2
ad_connect  spi0_csn_concat/dout spi0_csn
ad_connect  sys_ps8/emio_spi0_sclk_o spi0_sclk
ad_connect  sys_ps8/emio_spi0_m_o spi0_mosi
ad_connect  sys_ps8/emio_spi0_m_i spi0_miso
ad_connect  sys_ps8/emio_spi0_ss_i_n VCC
ad_connect  sys_ps8/emio_spi0_sclk_i GND
ad_connect  sys_ps8/emio_spi0_s_i GND

ad_ip_instance xlconcat spi1_csn_concat
ad_ip_parameter spi1_csn_concat CONFIG.NUM_PORTS 3
ad_connect  sys_ps8/emio_spi1_ss_o_n spi1_csn_concat/In0
ad_connect  sys_ps8/emio_spi1_ss1_o_n spi1_csn_concat/In1
ad_connect  sys_ps8/emio_spi1_ss2_o_n spi1_csn_concat/In2
ad_connect  spi1_csn_concat/dout spi1_csn
ad_connect  sys_ps8/emio_spi1_sclk_o spi1_sclk
ad_connect  sys_ps8/emio_spi1_m_o spi1_mosi
ad_connect  sys_ps8/emio_spi1_m_i spi1_miso
ad_connect  sys_ps8/emio_spi1_ss_i_n VCC
ad_connect  sys_ps8/emio_spi1_sclk_i GND
ad_connect  sys_ps8/emio_spi1_s_i GND

# system id

ad_ip_instance axi_sysid axi_sysid_0
ad_ip_instance sysid_rom rom_sys_0

ad_connect  axi_sysid_0/rom_addr   	rom_sys_0/rom_addr
ad_connect  axi_sysid_0/sys_rom_data   	rom_sys_0/rom_data
ad_connect  sys_cpu_clk                 rom_sys_0/clk








# interrupts	

ad_ip_instance xlconcat sys_concat_intc_0
ad_ip_parameter sys_concat_intc_0 CONFIG.NUM_PORTS 8
ad_ip_instance xlconcat sys_concat_intc_1
ad_ip_parameter sys_concat_intc_1 CONFIG.NUM_PORTS 8

# zc706 has only one intc.  zcu106 has two.
ad_connect  sys_concat_intc_0/dout sys_ps8/pl_ps_irq0
ad_connect  sys_concat_intc_1/dout sys_ps8/pl_ps_irq1

# on zc706 iic was on In14.  Here its different.
ad_connect  sys_concat_intc_1/In7 GND
ad_connect  sys_concat_intc_1/In6 GND
ad_connect  sys_concat_intc_1/In5 GND
ad_connect  sys_concat_intc_1/In4 GND
ad_connect  sys_concat_intc_1/In3 GND
ad_connect  sys_concat_intc_1/In2 GND
ad_connect  sys_concat_intc_1/In1 GND
ad_connect  sys_concat_intc_1/In0 GND
ad_connect  sys_concat_intc_0/In7 GND
ad_connect  sys_concat_intc_0/In6 GND
ad_connect  sys_concat_intc_0/In5 GND
ad_connect  sys_concat_intc_0/In4 GND
ad_connect  sys_concat_intc_0/In3 GND
ad_connect  sys_concat_intc_0/In2 GND
ad_connect  sys_concat_intc_0/In1 GND
ad_connect  sys_concat_intc_0/In0 GND


# ad_cpu_interconnect 0x41600000 axi_iic_main
ad_cpu_interconnect 0x45000000 axi_sysid_0
