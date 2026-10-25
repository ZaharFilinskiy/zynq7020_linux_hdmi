set root [file normalize [file join [file dirname [info script]] ../..]]
create_project -force pattern_test [file join $root hdmi/tests/pattern_build] -part xc7z020clg400-2
add_files [list [file join $root hdmi/rtl/axis_hdmi_source.v] [file join $root hdmi/rtl/axis_hdmi_video.v]]
add_files -fileset sim_1 [file join $root hdmi/tests/tb_hdmi_pattern.sv]
set_property top tb_hdmi_pattern [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation
close_sim
set log [file join $root hdmi/tests/pattern_build/pattern_test.sim/sim_1/behav/xsim/simulate.log]
set f [open $log r]; set result [read $f]; close $f
if {[string first "PASS: autonomous pattern" $result]<0 || [string first "Fatal:" $result]>=0} {
 error "Pattern simulation failed: $log"
}
