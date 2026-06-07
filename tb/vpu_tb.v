`timescale 1ns/1ps
module vpu_tb;
    reg clk, rst_n, valid;
    reg [3:0] op;
    reg [31:0] a, b;
    wire [31:0] result;
    wire done;
    integer fail = 0;
    vpu dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; valid = 0; op = 0;
        a = 32'h0101_0101; b = 32'h0202_0202;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        valid = 1; @(posedge clk); #0; valid = 0;
        while (!done) @(posedge clk);
        if (result !== 32'h0303_0303) begin $display("[FAIL] result=%08h", result); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
