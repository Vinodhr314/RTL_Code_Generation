`timescale 1ns/1ps
module pixel_decompanding_tb;
    reg clk, rst_n, valid;
    reg [15:0] comp;
    wire [23:0] pixel;
    wire valid_out;
    integer fail = 0;
    pixel_decompanding dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; valid = 0; comp = 16'h3412;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        valid = 1; @(posedge clk); #0; valid = 0;
        @(posedge clk);
        if (pixel !== 24'h123412) begin $display("[FAIL] pixel=%06h", pixel); fail = fail + 1; end
        if (!valid_out) begin $display("[FAIL] valid_out"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
