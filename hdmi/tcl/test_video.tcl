set root [file normalize [file join [file dirname [info script]] ../..]]
create_project -force video_test [file join $root hdmi/tests/build] -part xc7z020clg400-2
set_property target_simulator XSim [current_project]
add_files [file join $root hdmi/rtl/axis_hdmi_video.v]
add_files -fileset sim_1 [file join $root hdmi/tests/tb_axis_hdmi_video.sv]
set_property top tb_axis_hdmi_video [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation
close_sim
set log [file join $root hdmi/tests/build/video_test.sim/sim_1/behav/xsim/simulate.log]
set f [open $log r]; set result [read $f]; close $f
if {[string first "PASS: 3360000 pixels" $result] < 0 || [string first "Fatal:" $result] >= 0} {
 error "Video simulation did not pass; read $log"
}
