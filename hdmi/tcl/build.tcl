# Rebuild and export the hardware to the SDK 2018.3 HDF format.
set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
if {[llength [get_bd_cells -quiet hdmi_source]] && [get_property CONFIG.TEST_PATTERN [get_bd_cells hdmi_source]] == 1} {
 error "Autonomous test is enabled. Use hdmi/tcl/build_test_pattern.tcl; old SDK exports must remain a separate set."
}
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
 error "Implementation did not complete: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
file mkdir [file join $root hdmi/export]
report_timing_summary -file [file join $root hdmi/export/timing.rpt]
# A bitstream file alone is not success: fail the script on timing errors.
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
if {[get_property SLACK $setup] < 0 || [get_property SLACK $hold] < 0} {
 error "Timing failed; do not deliver this bitstream (see hdmi/export/timing.rpt)"
}
report_drc -file [file join $root hdmi/export/drc.rpt]
report_utilization -file [file join $root hdmi/export/utilization.rpt]
write_hwdef -force -file [file join $root hdmi/export/design_1_wrapper.hwdef]
write_sysdef -force -hwdef [file join $root hdmi/export/design_1_wrapper.hwdef] \
 -bitfile [file join $root zynq_linux.runs/impl_1/design_1_wrapper.bit] \
 -file [file join $root hdmi/export/design_1_wrapper.hdf]
file copy -force [file join $root zynq_linux.runs/impl_1/design_1_wrapper.bit] [file join $root hdmi/export/design_1_wrapper.bit]
close_project
