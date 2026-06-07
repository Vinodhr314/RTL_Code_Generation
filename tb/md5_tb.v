`timescale 1ns/1ps
module md5_tb;
    reg clk, rst_n, start;
    reg [511:0] block;
    wire [127:0] digest;
    wire done, busy;
    integer fail = 0;
    md5 dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; start = 0; block = 512'h0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        start = 1; @(posedge clk); #0; start = 0;
        while (!done) @(posedge clk);
        if (digest !== 128'hd41d8cd98f00b204e9800998ecf8427e) begin
            $display("[FAIL] digest mismatch %032h", digest); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
