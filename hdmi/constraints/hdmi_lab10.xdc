# Historical filename only: Lab10 pinout is NO LONGER used.
# fpga_10_vga_hdmi_test XDC and its implemented IO report are the reference.
set_property PACKAGE_PIN H16 [get_ports hdmi_tx_clk_p]
set_property PACKAGE_PIN H17 [get_ports hdmi_tx_clk_n]
set_property PACKAGE_PIN D19 [get_ports {hdmi_tx_data_p[0]}]
set_property PACKAGE_PIN D20 [get_ports {hdmi_tx_data_n[0]}]
set_property PACKAGE_PIN C20 [get_ports {hdmi_tx_data_p[1]}]
set_property PACKAGE_PIN B20 [get_ports {hdmi_tx_data_n[1]}]
set_property PACKAGE_PIN B19 [get_ports {hdmi_tx_data_p[2]}]
set_property PACKAGE_PIN A20 [get_ports {hdmi_tx_data_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_clk_p hdmi_tx_clk_n hdmi_tx_data_p[*] hdmi_tx_data_n[*]}]
# The reference drives the board HDMI output enable HIGH continuously.
set_property PACKAGE_PIN H18 [get_ports hdmi_out_en]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_out_en]
