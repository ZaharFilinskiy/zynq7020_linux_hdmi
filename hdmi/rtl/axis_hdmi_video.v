`timescale 1ns / 1ps
// Parameterized scanout; default 1280x720, matching the corrected board example. The AXI stream carries one XRGB8888 pixel/beat:
// TDATA[23:16]=R, [15:8]=G, [7:0]=B; TUSER marks SOF, TLAST marks EOL.
// All logic runs on pixel_clk. An AXIS Clock Converter crosses from VDMA.
// This module is a Block Design module reference, so a camera/scaler can
// later replace the VDMA stream without changing the TMDS transmitter.
module axis_hdmi_video #(
    parameter H_ACTIVE=1280, H_FP=110, H_SYNC=40, H_BP=220,
    parameter V_ACTIVE=720, V_FP=5, V_SYNC=5, V_BP=20,
    parameter SYNC_POSITIVE=1
)(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pixel_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS, ASSOCIATED_RESET resetn" *)
    input wire pixel_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire resetn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input wire [31:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input wire s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output wire s_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TUSER" *)
    input wire s_axis_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)
    input wire s_axis_tlast,
    // Digilent rgb2dvi expects R,B,G byte order, not R,G,B.
    output reg [23:0] video_rbg,
    output reg video_de, video_hsync, video_vsync,
    output reg stream_error
);
    localparam H_TOTAL=H_ACTIVE+H_FP+H_SYNC+H_BP;
    localparam V_TOTAL=V_ACTIVE+V_FP+V_SYNC+V_BP;
    reg [11:0] x, y;
    reg in_frame;
    wire active = x < H_ACTIVE && y < V_ACTIVE;
    wire frame_start = x == 0 && y == 0;
    wire line_end = x == H_ACTIVE-1;
    // Hunt for SOF while dropping damaged/stale frame data. Hold the SOF
    // until the physical raster begins: never slide a frame after starvation.
    assign s_axis_tready = resetn && (in_frame ? active :
                           (s_axis_tuser ? frame_start : 1'b1));
    wire good_pixel = s_axis_tvalid && s_axis_tready && active &&
                      (s_axis_tlast == line_end) &&
                      (in_frame ? !s_axis_tuser : (frame_start && s_axis_tuser));
    always @(posedge pixel_clk) begin
        if (!resetn) begin
            x <= 0; y <= 0; in_frame <= 0;
            video_rbg <= 0; video_de <= 0;
            video_hsync <= !SYNC_POSITIVE; video_vsync <= !SYNC_POSITIVE; stream_error <= 0;
        end else begin
            if (x == H_TOTAL-1) begin
                x <= 0;
                if (y == V_TOTAL-1) y <= 0; else y <= y+1'b1;
            end else x <= x+1'b1;
            // 720p uses positive H/V sync; VGA can select negative polarity. Sync, DE and RGB have
            // exactly the same one-cycle latency through these registers.
            video_de <= active;
            video_hsync <= (x >= H_ACTIVE+H_FP && x < H_ACTIVE+H_FP+H_SYNC) ^ !SYNC_POSITIVE;
            video_vsync <= (y >= V_ACTIVE+V_FP && y < V_ACTIVE+V_FP+V_SYNC) ^ !SYNC_POSITIVE;
            video_rbg <= good_pixel ? {s_axis_tdata[23:16],
                                      s_axis_tdata[7:0],s_axis_tdata[15:8]} : 24'b0;
            if (good_pixel) begin
                in_frame <= !(line_end && y == V_ACTIVE-1);
            end else if (active && (in_frame || frame_start)) begin
                in_frame <= 0;
                // Sticky diagnostic for ILA; reset clears it. Missing data
                // produces black pixels, never malformed HDMI sync pulses.
                stream_error <= 1;
            end
        end
    end
endmodule
