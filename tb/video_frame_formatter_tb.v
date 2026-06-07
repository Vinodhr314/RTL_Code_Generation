`timescale 1ns/1ps
module video_frame_formatter_tb;
    reg clk, rst_n, valid;
    reg [23:0] pixel;
    wire hsync, vsync, de;
    wire [11:0] line, frame;
    integer fail = 0;
    video_frame_formatter dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; valid = 0; pixel = 24'hFF0000;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        valid = 1;
        repeat (5) @(posedge clk);
        if (!de) begin $display("[FAIL] de"); fail = fail + 1; end
        valid = 0; @(posedge clk);
        if (de) begin $display("[FAIL] de off"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
