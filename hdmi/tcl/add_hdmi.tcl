# Vivado 2018.3. Run on a copy first; this script changes the existing BD.
# Paths are relative to this script so the resulting project is portable.
set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
add_files -norecurse [file join $root hdmi/rtl/axis_hdmi_video.v]
add_files -fileset constrs_1 -norecurse [file join $root hdmi/constraints/hdmi_lab10.xdc]
update_compile_order -fileset sources_1
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
if {[llength [get_bd_cells -quiet hdmi_vdma]]} {error "HDMI already exists; do not add twice"}
set ps [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64}] $ps
# Keep GPIO at GP0/M00, append the VDMA control registers at M01.
set_property CONFIG.NUM_MI 2 [get_bd_cells ps7_0_axi_periph]
set dma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 hdmi_vdma]
set_property -dict [list CONFIG.c_include_s2mm {0} CONFIG.c_include_sg {0} \
 CONFIG.c_num_fstores {1} CONFIG.c_m_axi_mm2s_data_width {64} \
 CONFIG.c_m_axis_mm2s_tdata_width {32} CONFIG.c_mm2s_linebuffer_depth {4096} \
 CONFIG.c_mm2s_max_burst_length {16} CONFIG.c_include_mm2s_dre {0} \
 CONFIG.c_mm2s_genlock_mode {0} CONFIG.c_include_internal_genlock {0} \
 CONFIG.c_use_fsync {0}] $dma
set hp [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 hdmi_mem]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $hp
set clk [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 hdmi_clocks]
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} CONFIG.PRIM_SOURCE {No_buffer} \
 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.200} CONFIG.CLKOUT2_USED {true} \
 CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {126.000} CONFIG.RESET_TYPE {ACTIVE_LOW}] $clk
set rst [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 hdmi_pixel_reset]
set video [create_bd_cell -type module -reference axis_hdmi_video hdmi_video]
# Keep every VDMA clock at 100 MHz. A dedicated AXIS FIFO handles CDC;
# this avoids cross-domain RAM-reset paths in VDMA 6.3's async line buffer.
set cdc [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 hdmi_stream_cdc]
set_property -dict [list CONFIG.TDATA_NUM_BYTES {4} CONFIG.TUSER_WIDTH {1} CONFIG.HAS_TLAST {1} CONFIG.IS_ACLK_ASYNC {1}] $cdc
set tx [create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 hdmi_tx]
set_property -dict [list CONFIG.kGenerateSerialClk {false} CONFIG.kRstActiveHigh {false}] $tx
proc net {pins} {
 set objs {}; foreach p $pins {lappend objs [get_bd_pins $p]}
 connect_bd_net {*}$objs
}
connect_bd_intf_net [get_bd_intf_pins ps7_0_axi_periph/M01_AXI] [get_bd_intf_pins hdmi_vdma/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins hdmi_vdma/M_AXI_MM2S] [get_bd_intf_pins hdmi_mem/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins hdmi_mem/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_intf_net [get_bd_intf_pins hdmi_vdma/M_AXIS_MM2S] [get_bd_intf_pins hdmi_stream_cdc/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins hdmi_stream_cdc/M_AXIS] [get_bd_intf_pins hdmi_video/S_AXIS]
net {processing_system7_0/FCLK_CLK0 hdmi_clocks/clk_in1 hdmi_vdma/s_axi_lite_aclk hdmi_vdma/m_axi_mm2s_aclk hdmi_vdma/m_axis_mm2s_aclk hdmi_stream_cdc/s_axis_aclk hdmi_mem/ACLK hdmi_mem/S00_ACLK hdmi_mem/M00_ACLK processing_system7_0/S_AXI_HP0_ACLK ps7_0_axi_periph/M01_ACLK}
net {proc_sys_reset_0/peripheral_aresetn hdmi_vdma/axi_resetn hdmi_stream_cdc/s_axis_aresetn hdmi_mem/ARESETN hdmi_mem/S00_ARESETN hdmi_mem/M00_ARESETN ps7_0_axi_periph/M01_ARESETN}
net {processing_system7_0/FCLK_RESET0_N hdmi_clocks/resetn hdmi_pixel_reset/ext_reset_in}
net {hdmi_clocks/clk_out1 hdmi_pixel_reset/slowest_sync_clk hdmi_stream_cdc/m_axis_aclk hdmi_video/pixel_clk hdmi_tx/PixelClk}
net {hdmi_clocks/clk_out2 hdmi_tx/SerialClk}
net {hdmi_clocks/locked hdmi_pixel_reset/dcm_locked}
net {hdmi_pixel_reset/peripheral_aresetn hdmi_stream_cdc/m_axis_aresetn hdmi_video/resetn hdmi_tx/aRst_n}
net {hdmi_video/video_rbg hdmi_tx/vid_pData}
net {hdmi_video/video_de hdmi_tx/vid_pVDE}
net {hdmi_video/video_hsync hdmi_tx/vid_pHSync}
net {hdmi_video/video_vsync hdmi_tx/vid_pVSync}
foreach {pin port width} {TMDS_Clk_p hdmi_tx_clk_p 1 TMDS_Clk_n hdmi_tx_clk_n 1 TMDS_Data_p hdmi_tx_data_p 3 TMDS_Data_n hdmi_tx_data_n 3} {
 if {$width == 1} {create_bd_port -dir O $port} else {create_bd_port -dir O -from 2 -to 0 $port}
 connect_bd_net [get_bd_pins hdmi_tx/$pin] [get_bd_ports $port]
}
assign_bd_address
set seg [get_bd_addr_segs processing_system7_0/Data/SEG_hdmi_vdma_Reg]
set_property offset 0x43000000 $seg
set_property range 64K $seg
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
make_wrapper -files [get_files design_1.bd] -top
update_compile_order -fileset sources_1
# Record exact generated settings; used to check requested clocks and addresses.
write_bd_tcl -force [file join $root hdmi/tcl/design_1_hdmi_generated.tcl]
close_project
