`timescale 1ns/1ps
// Check the real source+raster combination, without any PS/DMA activity.
module tb_hdmi_pattern;
    reg clk=0; always #5 clk=~clk;
    reg resetn=0;
    wire [31:0] data;
    wire valid,ready,userbit,lastbit,unused_ready;
    wire [23:0] rbg;
    wire de,hs,vs,err;
    axis_hdmi_source src(.pixel_clk(clk),.resetn(resetn),
        .s_axis_tdata(32'hxxxxxxxx),.s_axis_tvalid(1'bx),
        .s_axis_tready(unused_ready),.s_axis_tuser(1'bx),.s_axis_tlast(1'bx),
        .m_axis_tdata(data),.m_axis_tvalid(valid),.m_axis_tready(ready),
        .m_axis_tuser(userbit),.m_axis_tlast(lastbit));
    axis_hdmi_video video(.pixel_clk(clk),.resetn(resetn),
        .s_axis_tdata(data),.s_axis_tvalid(valid),.s_axis_tready(ready),
        .s_axis_tuser(userbit),.s_axis_tlast(lastbit),
        .video_rbg(rbg),.video_de(de),.video_hsync(hs),.video_vsync(vs),.stream_error(err));
    // The alternative mode is a transparent stream path with reset gating.
    wire [31:0] pass_data;
    wire pass_valid,pass_ready,pass_user,pass_last;
    axis_hdmi_source #(.TEST_PATTERN(0)) passthrough(.pixel_clk(clk),.resetn(resetn),
        .s_axis_tdata(data),.s_axis_tvalid(valid),.s_axis_tready(pass_ready),
        .s_axis_tuser(userbit),.s_axis_tlast(lastbit),.m_axis_tdata(pass_data),
        .m_axis_tvalid(pass_valid),.m_axis_tready(ready),.m_axis_tuser(pass_user),.m_axis_tlast(pass_last));
    integer x=0,y=0,frames=0,checked=0;
    reg held=0;
    reg [33:0] previous;
    reg [23:0] rgb,expected;
    always @(posedge clk) begin
        if (!resetn) begin x=0; y=0; frames=0; held=0; end
        else begin
            if (unused_ready !== 0) $fatal(1,"Test mode consumed PS stream");
            if (held && {userbit,lastbit,data} !== previous) $fatal(1,"AXI beat changed during stall");
            held=valid && !ready; previous={userbit,lastbit,data};
            if ({pass_data,pass_valid,pass_ready,pass_user,pass_last} !==
                {data,valid,ready,userbit,lastbit}) $fatal(1,"External stream mode mismatch");
            case (x/160)
                0:rgb=24'hffffff; 1:rgb=24'hffff00; 2:rgb=24'h00ffff; 3:rgb=24'h00ff00;
                4:rgb=24'hff00ff; 5:rgb=24'hff0000; 6:rgb=24'h0000ff; default:rgb=24'h000000;
            endcase
            if(y>=656) rgb=((x/32+y/32)%2) ? 24'hffffff : 24'h202020;
            if(x<2 || x>=1278 || y<2 || y>=718) rgb=24'hffffff;
            expected=(x<1280 && y<720) ? {rgb[23:16],rgb[7:0],rgb[15:8]} : 24'b0;
            #1;
            if (rbg !== expected) $fatal(1,"Pixel x=%0d y=%0d got=%h expected=%h",x,y,rbg,expected);
            if (de !== (x<1280 && y<720)) $fatal(1,"DE");
            if (hs !== (x>=1390 && x<1430)) $fatal(1,"HSYNC");
            if (vs !== (y>=725 && y<730)) $fatal(1,"VSYNC");
            if (err) $fatal(1,"Unexpected starvation/SOF/EOL error");
            checked=checked+1;
            if(x==1649) begin
                x=0;
                if(y==749) begin y=0; frames=frames+1; end else y=y+1;
            end else x=x+1;
        end
    end
    initial begin
        repeat(4) @(negedge clk); resetn=1;
        wait(frames==2);
        @(negedge clk); resetn=0;
        repeat(4) @(negedge clk);
        if(de || err || rbg || pass_valid || pass_ready) $fatal(1,"Reset outputs");
        resetn=1;
        wait(frames==2);
        $display("PASS: autonomous pattern, 4950000 pixel clocks, reset restart, backpressure and DMA bypass");
        $finish;
    end
    initial begin #60000000; $fatal(1,"Timeout"); end
endmodule
