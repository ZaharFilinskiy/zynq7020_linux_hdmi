# Run once on the existing HDMI project. Keep PS/DMA for later Linux work.
set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
add_files -norecurse [file join $root hdmi/rtl/axis_hdmi_source.v]
add_files -fileset constrs_1 -norecurse [file join $root hdmi/constraints/hdmi_board_clock.xdc]
update_compile_order -fileset sources_1
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
if {[llength [get_bd_cells -quiet hdmi_source]]} {error "Test source already exists"}
set src [create_bd_cell -type module -reference axis_hdmi_source hdmi_source]
set_property CONFIG.TEST_PATTERN 1 $src
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins hdmi_video/S_AXIS]]
connect_bd_intf_net [get_bd_intf_pins hdmi_stream_cdc/M_AXIS] [get_bd_intf_pins hdmi_source/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins hdmi_source/M_AXIS] [get_bd_intf_pins hdmi_video/S_AXIS]
connect_bd_net [get_bd_pins hdmi_clocks/clk_out1] [get_bd_pins hdmi_source/pixel_clk]
connect_bd_net [get_bd_pins hdmi_pixel_reset/peripheral_aresetn] [get_bd_pins hdmi_source/resetn]
# Autonomous clocks/resets: programming PL alone must start the image.
foreach pin {hdmi_clocks/clk_in1 hdmi_clocks/resetn hdmi_pixel_reset/ext_reset_in} {
 disconnect_bd_net [get_bd_nets -of_objects [get_bd_pins $pin]] [get_bd_pins $pin]
}
set c [create_bd_port -dir I -type clk hdmi_clk_50m]
set_property CONFIG.FREQ_HZ 50000000 $c
set r [create_bd_port -dir I -type rst hdmi_reset_n]
set_property CONFIG.POLARITY ACTIVE_LOW $r
connect_bd_net $c [get_bd_pins hdmi_clocks/clk_in1]
connect_bd_net $r [get_bd_pins hdmi_clocks/resetn] [get_bd_pins hdmi_pixel_reset/ext_reset_in]
set_property -dict [list CONFIG.PRIM_IN_FREQ {50.000} CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.200} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {126.000}] [get_bd_cells hdmi_clocks]
set_property CONFIG.C_EXT_RESET_HIGH 0 [get_bd_cells hdmi_pixel_reset]
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
make_wrapper -files [get_files design_1.bd] -top
update_compile_order -fileset sources_1
write_bd_tcl -force [file join $root hdmi/tcl/design_1_hdmi_generated.tcl]
close_project
