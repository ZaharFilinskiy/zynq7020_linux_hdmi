`timescale 1ns/1ps
// Autonomous PL test picture, or transparent AXI4-Stream input for later DMA.
// TEST_PATTERN is a build-time BD parameter: 1 = no ARM/DDR/software needed.
// Clock and reset must come from the board oscillator, NOT from PS FCLK.
module axis_hdmi_source #(parameter TEST_PATTERN = 1, parameter H_ACTIVE = 1280, parameter V_ACTIVE = 720)(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pixel_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET resetn" *)
    input wire pixel_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire resetn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *) input wire [31:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *) input wire s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *) output wire s_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TUSER" *) input wire s_axis_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *) input wire s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *) output wire [31:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *) output wire m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *) input wire m_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TUSER" *) output wire m_axis_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *) output wire m_axis_tlast
);
    generate if (TEST_PATTERN) begin : test_picture
        reg [11:0] x;
        reg [11:0] y;
        reg [23:0] rgb;
        // Eight bars show channel order; 32x32 squares show pixel geometry.
        // A 2-pixel white border makes overscan/cropping visible on monitors.
        always @* begin
            if      (x < H_ACTIVE/8)  rgb = 24'hffffff;
            else if (x < H_ACTIVE*2/8) rgb = 24'hffff00;
            else if (x < H_ACTIVE*3/8) rgb = 24'h00ffff;
            else if (x < H_ACTIVE*4/8) rgb = 24'h00ff00;
            else if (x < H_ACTIVE*5/8) rgb = 24'hff00ff;
            else if (x < H_ACTIVE*6/8) rgb = 24'hff0000;
            else if (x < H_ACTIVE*7/8) rgb = 24'h0000ff;
            else             rgb = 24'h000000;
            if (y >= V_ACTIVE-64) rgb = (x[5] ^ y[5]) ? 24'hffffff : 24'h202020;
            if (x < 2 || x >= H_ACTIVE-2 || y < 2 || y >= V_ACTIVE-2) rgb = 24'hffffff;
        end
        // State advances ONLY on transfer. The entire AXI beat stays stable
        // while the downstream raster backpressures during video blanking.
        always @(posedge pixel_clk) begin
            if (!resetn) begin x <= 0; y <= 0; end
            else if (m_axis_tready) begin
                if (x == H_ACTIVE-1) begin
                    x <= 0;
                    if (y == V_ACTIVE-1) y <= 0; else y <= y + 1'b1;
                end else x <= x + 1'b1;
            end
        end
        assign m_axis_tdata = {8'b0,rgb};
        assign m_axis_tvalid = resetn;
        assign m_axis_tuser = (x == 0 && y == 0);
        assign m_axis_tlast = (x == H_ACTIVE-1);
        // No data from DDR is consumed in autonomous test mode.
        assign s_axis_tready = 1'b0;
    end else begin : external_stream
        assign m_axis_tdata = s_axis_tdata;
        assign m_axis_tvalid = s_axis_tvalid && resetn;
        assign m_axis_tuser = s_axis_tuser;
        assign m_axis_tlast = s_axis_tlast;
        assign s_axis_tready = m_axis_tready && resetn;
    end endgenerate
endmodule
