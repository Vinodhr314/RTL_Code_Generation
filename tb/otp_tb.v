`timescale 1ns/1ps
module otp_tb;
    reg clk, rst_n, read;
    reg [7:0] addr;
    wire [31:0] rdata;
    wire busy, error;
    integer fail = 0;
    otp dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; read = 0; addr = 8'h0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        read = 1; @(posedge clk); #0; read = 0;
        @(posedge clk); @(posedge clk); #1;
        if (rdata !== 32'hDEAD0001) begin $display("[FAIL] rdata=%08h", rdata); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
