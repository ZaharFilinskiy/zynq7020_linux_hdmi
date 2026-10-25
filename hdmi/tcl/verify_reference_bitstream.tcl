set root [file normalize [file join [file dirname [info script]] ../..]]
set out [file join $root hdmi/export/vivado_test]
open_checkpoint [file join $root zynq_linux.runs/impl_1/design_1_wrapper_routed.dcp]
foreach {name pin} {hdmi_clk_50m K17 hdmi_reset_n M20 hdmi_out_en H18 hdmi_tx_clk_p H16 hdmi_tx_clk_n H17 hdmi_tx_data_p[0] D19 hdmi_tx_data_n[0] D20 hdmi_tx_data_p[1] C20 hdmi_tx_data_n[1] B20 hdmi_tx_data_p[2] B19 hdmi_tx_data_n[2] A20} {
 set actual [get_property PACKAGE_PIN [get_ports $name]]
 if {$actual ne $pin} {error "Wrong pin for $name: $actual instead of $pin"}
 puts "PIN VERIFIED: $name = $actual"
}
report_io -file $out/io.rpt
report_clocks -file $out/clocks.rpt
set mmcm [get_cells -hier -filter {REF_NAME == MMCME2_ADV}]
foreach {p expected} {DIVCLK_DIVIDE 1 CLKFBOUT_MULT_F 22.25 CLKOUT0_DIVIDE_F 15 CLKOUT1_DIVIDE 3} {
 if {[get_property $p $mmcm] != $expected} {error "Unexpected MMCM $p"}
}
puts "PASS: corrected reference pinout and MMCM parameters"
close_design
