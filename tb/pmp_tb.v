`timescale 1ns/1ps
module pmp_tb;
    reg clk;
    reg [31:0] addr, cfg;
    reg [1:0] access;
    reg mode;
    wire allow, fault;
    integer fail = 0;
    pmp dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        addr = 32'h0000_1000; access = 2'b01; mode = 0; cfg = 0;
        @(posedge clk); #1;
        if (!allow || fault) begin $display("[FAIL] allow region"); fail = fail + 1; end
        addr = 32'h8000_0000;
        @(posedge clk); #1;
        if (allow || !fault) begin $display("[FAIL] fault region"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
