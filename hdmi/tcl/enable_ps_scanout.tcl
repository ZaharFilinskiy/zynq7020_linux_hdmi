# Switch the proven board/pixel pipeline from PL bars to PS DDR scanout.
set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
set_property CONFIG.TEST_PATTERN 0 [get_bd_cells hdmi_source]
# Retain the known working K17 clock and 720p transmitter settings.
# VDMA/AXI/HP0 use PS FCLK0; only the AXIS clock converter crosses domains.
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
make_wrapper -files [get_files design_1.bd] -top
update_compile_order -fileset sources_1
write_bd_tcl -force [file join $root hdmi/tcl/design_1_hdmi_generated.tcl]
close_project
