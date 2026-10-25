set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
validate_bd_design
foreach name {processing_system7_0 hdmi_vdma hdmi_mem hdmi_stream_cdc axi_gpio_0 ps7_0_axi_periph proc_sys_reset_0} {
 if {[llength [get_bd_cells -quiet $name]]} {error "Unexpected PS/DMA block $name"}
}
foreach name {hdmi_source hdmi_video hdmi_clocks hdmi_pixel_reset hdmi_tx hdmi_enable} {
 if {[llength [get_bd_cells -quiet $name]] != 1} {error "Missing PL video block $name"}
}
if {[get_property CONFIG.TEST_PATTERN [get_bd_cells hdmi_source]] != 1} {error "Test image source is not selected"}
foreach name {DDR FIXED_IO gpio_rtl_0_tri_o} {
 if {[llength [get_bd_ports -quiet $name]] || [llength [get_bd_intf_ports -quiet $name]]} {error "Unexpected PS port $name"}
}
puts "PL-only cells: [get_bd_cells]"
puts "PASS: standalone PL HDMI, no PS, DDR, VDMA or CPU bus"
close_project
