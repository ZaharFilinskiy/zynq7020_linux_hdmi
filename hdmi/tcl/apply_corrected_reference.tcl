# Apply corrected board reference to the existing PS + HDMI Block Design.
set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
update_compile_order -fileset sources_1
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
update_module_reference [get_ips design_1_hdmi_source_0]
update_module_reference [get_ips design_1_hdmi_video_0]
set_property -dict [list CONFIG.TEST_PATTERN 1 CONFIG.H_ACTIVE 1280 CONFIG.V_ACTIVE 720] [get_bd_cells hdmi_source]
set_property -dict [list CONFIG.H_ACTIVE 1280 CONFIG.H_FP 110 CONFIG.H_SYNC 40 CONFIG.H_BP 220 CONFIG.V_ACTIVE 720 CONFIG.V_FP 5 CONFIG.V_SYNC 5 CONFIG.V_BP 20 CONFIG.SYNC_POSITIVE 1] [get_bd_cells hdmi_video]
# Same requested clock frequencies as the supplied working XCI.
# Actual MMCM frequencies are checked after implementation (ratio must be 5:1).
set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 74.2 CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 371.25] [get_bd_cells hdmi_clocks]
set_property CONFIG.kClkRange 1 [get_bd_cells hdmi_tx]
if {![llength [get_bd_cells -quiet hdmi_enable]]} {
 create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 hdmi_enable
 set_property -dict [list CONFIG.CONST_WIDTH 1 CONFIG.CONST_VAL 1] [get_bd_cells hdmi_enable]
 create_bd_port -dir O hdmi_out_en
 connect_bd_net [get_bd_pins hdmi_enable/dout] [get_bd_ports hdmi_out_en]
}
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
make_wrapper -files [get_files design_1.bd] -top
update_compile_order -fileset sources_1
write_bd_tcl -force [file join $root hdmi/tcl/design_1_hdmi_generated.tcl]
close_project

