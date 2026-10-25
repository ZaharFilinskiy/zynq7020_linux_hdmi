# Build a genuinely PL-only BD from the RTL, IP and constraints in the archived
# standalone test version. All video blocks remain visible in IP Integrator.
set root [file normalize [file join [file dirname [info script]] ../..]]
create_project -force zynq_linux $root -part xc7z020clg400-2
set_property target_language Verilog [current_project]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
add_files -norecurse [list [file join $root hdmi/rtl/axis_hdmi_source.v] [file join $root hdmi/rtl/axis_hdmi_video.v]]
foreach name {hdmi_board_clock.xdc hdmi_lab10.xdc} {
 add_files -fileset constrs_1 -norecurse [file join $root hdmi/constraints $name]
}
create_bd_design design_1
set clock [create_bd_port -dir I -type clk hdmi_clk_50m]
set_property CONFIG.FREQ_HZ 50000000 $clock
set reset [create_bd_port -dir I -type rst hdmi_reset_n]
set_property CONFIG.POLARITY ACTIVE_LOW $reset
set clk [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 hdmi_clocks]
set_property -dict [list CONFIG.PRIM_IN_FREQ 50.000 CONFIG.PRIM_SOURCE Single_ended_clock_capable_pin CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 74.2 CONFIG.CLKOUT2_USED true CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 371.25 CONFIG.RESET_TYPE ACTIVE_LOW] $clk
set rst [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 hdmi_pixel_reset]
set_property CONFIG.C_EXT_RESET_HIGH 0 $rst
set src [create_bd_cell -type module -reference axis_hdmi_source hdmi_source]
set_property -dict [list CONFIG.TEST_PATTERN 1 CONFIG.H_ACTIVE 1280 CONFIG.V_ACTIVE 720] $src
set video [create_bd_cell -type module -reference axis_hdmi_video hdmi_video]
set_property -dict [list CONFIG.H_ACTIVE 1280 CONFIG.H_FP 110 CONFIG.H_SYNC 40 CONFIG.H_BP 220 CONFIG.V_ACTIVE 720 CONFIG.V_FP 5 CONFIG.V_SYNC 5 CONFIG.V_BP 20 CONFIG.SYNC_POSITIVE 1] $video
set tx [create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 hdmi_tx]
set_property -dict [list CONFIG.kGenerateSerialClk false CONFIG.kRstActiveHigh false CONFIG.kClkRange 1] $tx
foreach {name width value} {hdmi_enable 1 1 hdmi_low 1 0 hdmi_zero_data 32 0} {
 set c [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 $name]
 set_property -dict [list CONFIG.CONST_WIDTH $width CONFIG.CONST_VAL $value] $c
}
connect_bd_net $clock [get_bd_pins hdmi_clocks/clk_in1]
connect_bd_net $reset [get_bd_pins hdmi_clocks/resetn] [get_bd_pins hdmi_pixel_reset/ext_reset_in]
connect_bd_net [get_bd_pins hdmi_clocks/clk_out1] [get_bd_pins hdmi_source/pixel_clk] [get_bd_pins hdmi_video/pixel_clk] [get_bd_pins hdmi_tx/PixelClk] [get_bd_pins hdmi_pixel_reset/slowest_sync_clk]
connect_bd_net [get_bd_pins hdmi_clocks/clk_out2] [get_bd_pins hdmi_tx/SerialClk]
connect_bd_net [get_bd_pins hdmi_clocks/locked] [get_bd_pins hdmi_pixel_reset/dcm_locked]
connect_bd_net [get_bd_pins hdmi_pixel_reset/peripheral_aresetn] [get_bd_pins hdmi_source/resetn] [get_bd_pins hdmi_video/resetn] [get_bd_pins hdmi_tx/aRst_n]
connect_bd_net [get_bd_pins hdmi_low/dout] [get_bd_pins hdmi_pixel_reset/aux_reset_in] [get_bd_pins hdmi_pixel_reset/mb_debug_sys_rst] [get_bd_pins hdmi_source/s_axis_tvalid] [get_bd_pins hdmi_source/s_axis_tuser] [get_bd_pins hdmi_source/s_axis_tlast]
connect_bd_net [get_bd_pins hdmi_zero_data/dout] [get_bd_pins hdmi_source/s_axis_tdata]
connect_bd_intf_net [get_bd_intf_pins hdmi_source/M_AXIS] [get_bd_intf_pins hdmi_video/S_AXIS]
foreach {vpin tpin} {video_rbg vid_pData video_de vid_pVDE video_hsync vid_pHSync video_vsync vid_pVSync} {
 connect_bd_net [get_bd_pins hdmi_video/$vpin] [get_bd_pins hdmi_tx/$tpin]
}
foreach {pin port width} {TMDS_Clk_p hdmi_tx_clk_p 1 TMDS_Clk_n hdmi_tx_clk_n 1 TMDS_Data_p hdmi_tx_data_p 3 TMDS_Data_n hdmi_tx_data_n 3} {
 if {$width==1} {create_bd_port -dir O $port} else {create_bd_port -dir O -from 2 -to 0 $port}
 connect_bd_net [get_bd_pins hdmi_tx/$pin] [get_bd_ports $port]
}
create_bd_port -dir O hdmi_out_en
connect_bd_net [get_bd_pins hdmi_enable/dout] [get_bd_ports hdmi_out_en]
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
set wrappers [make_wrapper -files [get_files design_1.bd] -top]
add_files -norecurse $wrappers
set_property top design_1_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
write_bd_tcl -force [file join $root hdmi/tcl/design_1_hdmi_generated.tcl]
close_project
