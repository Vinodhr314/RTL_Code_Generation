`timescale 1ns/1ps
module ulss_tb;
    reg clk, rst_n, wfi;
    reg [3:0] wake;
    wire sleep, clk_gate;
    integer fail = 0;
    ulss dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; wfi = 0; wake = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        wfi = 1;
        @(posedge clk); #1;
        if (!sleep || clk_gate) begin $display("[FAIL] sleep mode"); fail = fail + 1; end
        wake = 4'b0001;
        @(posedge clk); #1;
        if (sleep || !clk_gate) begin $display("[FAIL] wake"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
