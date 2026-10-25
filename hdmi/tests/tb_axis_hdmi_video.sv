`timescale 1ns/1ps
// End-to-end timing/stream test at the REAL 800x525 raster dimensions.
// AXI producer obeys backpressure and holds its pixel index when not accepted.
module tb_axis_hdmi_video;
    reg clk=0; always #5 clk=~clk;
    reg resetn=0;
    wire ready, de, hs, vs, err;
    wire [23:0] rbg;
    integer sx=0, sy=0, rx=0, ry=0, frame=0, checked=0;
    reg spoiled=0;
    wire inject = (rx==100 && ry==10);
    wire valid = resetn && !(frame==2 && inject);
    wire userbit = (sx==0 && sy==0) || (frame==6 && inject);
    wire lastbit = (sx==639) || (frame==4 && inject);
    wire [7:0] red = sx % 256;
    wire [7:0] green = sy % 256;
    wire [7:0] blue = (sx+sy+37) % 256;
    wire [31:0] data = {8'b0,red,green,blue};
    axis_hdmi_video #(.H_ACTIVE(640),.H_FP(16),.H_SYNC(96),.H_BP(48),.V_ACTIVE(480),.V_FP(10),.V_SYNC(2),.V_BP(33),.SYNC_POSITIVE(0)) dut(.pixel_clk(clk),.resetn(resetn),
        .s_axis_tdata(data),.s_axis_tvalid(valid),.s_axis_tready(ready),
        .s_axis_tuser(userbit),.s_axis_tlast(lastbit),
        .video_rbg(rbg),.video_de(de),.video_hsync(hs),.video_vsync(vs),.stream_error(err));
    always @(posedge clk) begin
        if (!resetn) begin sx<=0; sy<=0; end
        else if (valid && ready) begin
            if (sx==639) begin sx<=0; sy <= sy==479 ? 0 : sy+1; end
            else sx<=sx+1;
        end
    end
    reg [23:0] expected;
    reg [7:0] er,eg,eb;
    reg old_ready,old_user;
    always @(posedge clk) begin
        if (!resetn) begin
            rx=0; ry=0; frame=0; spoiled=0;
        end else begin
            old_ready=ready; old_user=userbit;
            if ((frame==2 || frame==4 || frame==6) && inject) spoiled=1;
            er=rx%256; eg=ry%256; eb=(rx+ry+37)%256;
            expected=(!spoiled && rx<640 && ry<480) ? {er,eb,eg} : 24'b0;
            #1;
            if (de !== (rx<640 && ry<480)) $fatal(1,"DE x=%0d y=%0d",rx,ry);
            if (hs !== !(rx>=656 && rx<752)) $fatal(1,"HSYNC");
            if (vs !== !(ry>=490 && ry<492)) $fatal(1,"VSYNC");
            if (rbg !== expected) $fatal(1,"pixel frame=%0d x=%0d y=%0d got=%h want=%h",frame,rx,ry,rbg,expected);
            if (spoiled && !err) $fatal(1,"Missing stream-error indication");
            if (frame==0 && err) $fatal(1,"Unexpected error on healthy stream");
            checked=checked+1;
            if (rx==799) begin
                rx=0;
                if (ry==524) begin
                    ry=0; frame=frame+1; spoiled=0;
                    $display("Checked raster frame %0d",frame);
                    if (frame==8) begin
                        // Reset must clear sticky error and restart the raster.
                        @(negedge clk); resetn=0;
                        repeat (3) @(negedge clk);
                        if (err || de || rbg) $fatal(1,"Reset did not clear outputs");
                        $display("PASS: %0d pixels; timing, colors, blanking, starvation, EOL/SOF recovery, reset",checked);
                        $finish;
                    end
                end else ry=ry+1;
            end else rx=rx+1;
        end
    end
    initial begin repeat(4) @(negedge clk); resetn=1; end
    initial begin #40000000; $fatal(1,"Timeout"); end
endmodule
