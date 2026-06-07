`timescale 1ns/1ps
module pp_tb;
    reg clk, rst_n, valid_in, ready_in;
    reg [31:0] data_in;
    wire ready_out, valid_out;
    wire [31:0] data_out;
    integer fail = 0;
    pp dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; valid_in = 0; ready_in = 1; data_in = 32'hDEAD_BEEF;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        valid_in = 1; @(posedge clk); #0; valid_in = 0;
        @(posedge clk);
        if (!valid_out || data_out !== 32'hDEAD_BEEF) begin
            $display("[FAIL] data_out=%08h", data_out); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
