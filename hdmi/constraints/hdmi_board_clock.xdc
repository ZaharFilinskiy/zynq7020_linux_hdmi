# Corrected working reference: fpga_10_vga_hdmi_test.
# 50 MHz oscillator on K17, active-low reset button on M20.
set_property PACKAGE_PIN K17 [get_ports hdmi_clk_50m]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_clk_50m]
# Clock Wizard creates the 20 ns input clock; do not duplicate it.
set_property PACKAGE_PIN M20 [get_ports hdmi_reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_reset_n]
set_false_path -from [get_ports hdmi_reset_n]
