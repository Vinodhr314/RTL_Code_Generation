`timescale 1ns/1ps
module multiplier_divider_tb;
    reg clk, rst_n;
    reg [2:0] op;
    reg [31:0] a, b;
    wire [31:0] result;
    wire done;
    integer fail = 0;
    multiplier_divider dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; op = 0; a = 32'd6; b = 32'd7;
        @(posedge clk); @(posedge clk); rst_n = 1;
        @(posedge clk);
        while (!done) @(posedge clk);
        if (result !== 32'd42) begin $display("[FAIL] mul=%0d", result); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
