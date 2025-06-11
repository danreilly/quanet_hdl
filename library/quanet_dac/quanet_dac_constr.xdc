###############################################################################
## Copyright (C) 2016-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

#set_property ASYNC_REG TRUE \
#  [get_cells -hierarchical -filter {name =~ *dac_xfer_out_*}]
  
#  [get_cells -hierarchical -filter {name =~ *dma_bypass*}] \
#  [get_cells -hierarchical -filter {name =~ *dac_bypass*}]
#  [get_cells -hierarchical -filter {name =~ *dac_xfer_req_m*}]
#  [get_cells -hierarchical -filter {name =~ *dac_lastaddr_m*}] \
# [get_cells -hierarchical -filter {name =~ *dac_waddr_m*}] \

#set_false_path -from [get_cells -hierarchical -filter {name =~ *dma_waddr_g* && IS_SEQUENTIAL}] \
#               -to [get_cells -hierarchical -filter {name =~ *dac_waddr_m1* && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hierarchical -filter {name =~ *dma_lastaddr_g* && IS_SEQUENTIAL}] \
#               -to [get_cells -hierarchical -filter {name =~ *dac_lastaddr_m1* && IS_SEQUENTIAL}]
#//set_false_path -from [get_cells -hierarchical -filter {name =~ *dma_xfer_out_fifo* && IS_SEQUENTIAL}] \
#//               -to [get_cells -hierarchical -filter {name =~ *dac_xfer_out_fifo_m1* && IS_SEQUENTIAL}]

#set_false_path -from [get_cells -hierarchical -filter {name =~ *dma_xfer_out_fifo* }] \
#               -to [get_cells -hierarchical -filter {name =~ *dac_rd_isdone* }]
#set_false_path -from [get_cells -hierarchical -filter {name =~ *dac_rd_isdone* }] \
#               -to [get_cells -hierarchical -filter {name =~ *dma_xfer_out_fifo* }]

# set_false_path -to [get_cells -hierarchical -filter {name =~ *dac_bypass_m1* && IS_SEQUENTIAL}]
# set_false_path -to [get_cells -hierarchical -filter {name =~ *dma_bypass_m1* && IS_SEQUENTIAL}]
# util_dacfifo_bypass CDC false-paths

# Dan: I think these are obsolete now:
#  I don't like AD's ad-hoc CDC approach
#set_property ASYNC_REG TRUE [get_cells -hierarchical -filter {name =~ *dac_mem_*_m*}] \
#  [get_cells -hierarchical -filter {name =~ *dma_mem_*_m*}] \
#  [get_cells -hierarchical -filter {name =~ *dma_rst_m1*}] \

# Dan: I think these are obsolete now:
#  I don't like AD's ad-hoc CDC approach
#set_false_path -from [get_cells  -hierarchical -filter {name =~ */dma_mem_waddr_g* && IS_SEQUENTIAL}] \
#               -to   [get_cells  -hierarchical -filter {name =~ */dac_mem_waddr_m1* && IS_SEQUENTIAL}]
#set_false_path -from [get_cells  -hierarchical -filter {name =~ */dac_mem_raddr_g* && IS_SEQUENTIAL}] \
#               -to   [get_cells  -hierarchical -filter {name =~ */dma_mem_raddr_m1* && IS_SEQUENTIAL}]
#set_false_path -to   [get_cells  -hierarchical -filter {name =~ */dma_rst_m1_reg && IS_SEQUENTIAL}]

# set_false_path -to   [get_cells  -hierarchical -filter {name =~ */dac_xfer_req_m1_reg && IS_SEQUENTIAL}]

#set_false_path -from [get_cells  -hierarchical -filter {name =~ */dma_xfer_req* && IS_SEQUENTIAL}] \
#               -to   [get_cells  -hierarchical -filter {name =~ */dac_mem_waddr_m1* && IS_SEQUENTIAL}]

