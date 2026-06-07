`timescale 1ns/1ps
module sch_tb;
    reg clk, rst_n;
    reg [3:0] req;
    reg [7:0] irq_prio;
    wire [3:0] grant;
    integer fail = 0;
    sch dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; req = 0; irq_prio = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        req = 4'b0100;
        @(posedge clk); #1;
        if (grant !== 4'b0100) begin $display("[FAIL] grant=%b", grant); fail = fail + 1; end
        req = 4'b0010;
        @(posedge clk); #1;
        if (grant !== 4'b0010) begin $display("[FAIL] rr grant=%b", grant); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
