`timescale 1ns/1ps
module secured_hash_algorithm_tb;
    reg clk, rst_n, start;
    reg [511:0] block;
    wire [255:0] digest;
    wire done, busy;
    integer fail = 0;
    secured_hash_algorithm dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; start = 0; block = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        start = 1; @(posedge clk); #0; start = 0;
        while (!done) @(posedge clk);
        if (digest !== 256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855) begin
            $display("[FAIL] digest mismatch"); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
