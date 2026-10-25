set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
validate_bd_design
foreach c {hdmi_vdma hdmi_mem hdmi_clocks hdmi_pixel_reset hdmi_video hdmi_tx hdmi_stream_cdc hdmi_source hdmi_enable} {
 if {[llength [get_bd_cells -quiet $c]] != 1} {error "Missing block $c"}
}
if {[get_property CONFIG.TEST_PATTERN [get_bd_cells hdmi_source]] != 0} {error "Expected PS/VDMA stream mode TEST_PATTERN=0"}
set clknet [get_bd_nets -of_objects [get_bd_ports hdmi_clk_50m]]
if {$clknet ne [get_bd_nets -of_objects [get_bd_pins hdmi_clocks/clk_in1]]} {error "Video clock is not board oscillator"}
set rstnet [get_bd_nets -of_objects [get_bd_ports hdmi_reset_n]]
if {$rstnet ne [get_bd_nets -of_objects [get_bd_pins hdmi_pixel_reset/ext_reset_in]]} {error "Video reset is not independent of PS"}
if {[get_property CONFIG.H_ACTIVE [get_bd_cells hdmi_video]] != 1280} {error "Wrong active width"}
if {[get_property CONFIG.CONST_VAL [get_bd_cells hdmi_enable]] != 1} {error "HDMI output disabled"}
report_ip_status -file [file join $root hdmi/export/ip_status.rpt]
save_bd_design
close_project
puts "HDMI project relocation verified"

