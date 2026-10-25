# Autonomous bitstream for Vivado Hardware Manager; no SDK/FSBL required.
set root [file normalize [file join [file dirname [info script]] ../..]]
set out [file join $root hdmi/export/vivado_test]
file mkdir $out
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
if {[get_property CONFIG.TEST_PATTERN [get_bd_cells hdmi_source]] != 1} {
 error "This build requires hdmi_source.TEST_PATTERN=1"
}
validate_bd_design
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
 error "Implementation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
report_timing_summary -file $out/timing.rpt
report_drc -file $out/drc.rpt
report_utilization -file $out/utilization.rpt
report_methodology -file $out/methodology.rpt
report_cdc -file $out/cdc.rpt
foreach kind {max min} {
 if {[get_property SLACK [get_timing_paths -delay_type $kind -max_paths 1]] < 0} {
  error "Timing failed; see $out/timing.rpt"
 }
}
file copy -force [file join $root zynq_linux.runs/impl_1/design_1_wrapper.bit] $out/hdmi_test_pattern.bit
close_project
