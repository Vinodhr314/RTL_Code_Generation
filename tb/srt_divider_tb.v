`timescale 1ns/1ps
module srt_divider_tb;
    reg clk, rst_n, valid;
    reg [31:0] dividend, divisor;
    wire [31:0] quotient, remainder;
    wire done, busy;
    integer fail = 0;
    srt_divider dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; valid = 0; dividend = 32'd100; divisor = 32'd7;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        valid = 1; @(posedge clk); #0; valid = 0;
        while (!done) @(posedge clk);
        if (quotient !== 32'd14) begin $display("[FAIL] quotient=%0d", quotient); fail = fail + 1; end
        if (remainder !== 32'd2) begin $display("[FAIL] remainder=%0d", remainder); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
