`timescale 1ns/1ps
module spu_tb;
    reg clk, rst_n, start;
    reg [3:0] op_sel;
    reg [31:0] a, b;
    wire [31:0] result;
    wire done, busy, irq;
    integer fail = 0;
    spu dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; start = 0; op_sel = 0; a = 32'd10; b = 32'd32;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        start = 1; @(posedge clk); #0; start = 0;
        while (!done) @(posedge clk);
        if (result !== 32'd42) begin $display("[FAIL] result=%0d", result); fail = fail + 1; end
        if (!irq) begin $display("[FAIL] irq"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
