`timescale 1ns/1ps
module i2c_tb;
    reg clk, rst_n, rw, start;
    reg [6:0] addr; reg [7:0] data;
    wire scl, sda, done, irq;
    wire [7:0] rdata;
    integer fail = 0;
    i2c dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; start = 0; rw = 1; addr = 7'h3C; data = 8'h55;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        start = 1; @(posedge clk); #0; start = 0;
        while (!done) @(posedge clk);
        if (rdata !== 8'hAB) begin $display("[FAIL] rdata=%h", rdata); fail = fail + 1; end
        if (!irq) begin $display("[FAIL] irq"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
