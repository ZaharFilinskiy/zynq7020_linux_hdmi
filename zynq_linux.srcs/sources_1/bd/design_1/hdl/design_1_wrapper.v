//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Sun Oct 25 12:34:13 2026
//Host        : DESKTOP-22C40O7 running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (hdmi_clk_50m,
    hdmi_out_en,
    hdmi_reset_n,
    hdmi_tx_clk_n,
    hdmi_tx_clk_p,
    hdmi_tx_data_n,
    hdmi_tx_data_p);
  input hdmi_clk_50m;
  output [0:0]hdmi_out_en;
  input hdmi_reset_n;
  output hdmi_tx_clk_n;
  output hdmi_tx_clk_p;
  output [2:0]hdmi_tx_data_n;
  output [2:0]hdmi_tx_data_p;

  wire hdmi_clk_50m;
  wire [0:0]hdmi_out_en;
  wire hdmi_reset_n;
  wire hdmi_tx_clk_n;
  wire hdmi_tx_clk_p;
  wire [2:0]hdmi_tx_data_n;
  wire [2:0]hdmi_tx_data_p;

  design_1 design_1_i
       (.hdmi_clk_50m(hdmi_clk_50m),
        .hdmi_out_en(hdmi_out_en),
        .hdmi_reset_n(hdmi_reset_n),
        .hdmi_tx_clk_n(hdmi_tx_clk_n),
        .hdmi_tx_clk_p(hdmi_tx_clk_p),
        .hdmi_tx_data_n(hdmi_tx_data_n),
        .hdmi_tx_data_p(hdmi_tx_data_p));
endmodule
