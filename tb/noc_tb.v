`timescale 1ns/1ps
module noc_tb;
    reg clk, rst_n;
    reg [3:0] in_valid, out_ready;
    reg [255:0] in_data;
    wire [3:0] out_valid, in_ready;
    wire [255:0] out_data;
    integer fail = 0;
    noc dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; in_valid = 0; in_data = 0; out_ready = 4'hF;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        in_valid = 4'h1;
        in_data[63:0] = 64'hAABBCCDD11223344;
        @(posedge clk); #1;
        if (!out_valid[1]) begin $display("[FAIL] out_valid[1]"); fail = fail + 1; end
        if (out_data[127:64] !== 64'hAABBCCDD11223344) begin
            $display("[FAIL] routed data %016h", out_data[127:64]); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
