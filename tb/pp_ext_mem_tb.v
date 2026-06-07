`timescale 1ns/1ps
module pp_ext_mem_tb;
    reg clk, rst_n, wen, ren;
    reg [31:0] addr, wdata;
    wire [31:0] rdata;
    wire ready;
    integer fail = 0;
    pp_ext_mem dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; wen = 0; ren = 0; addr = 32'h1000_0000; wdata = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        ren = 1; @(posedge clk); #0; ren = 0;
        @(posedge clk); #1;
        if (!ready) begin $display("[FAIL] ready"); fail = fail + 1; end
        if (rdata !== (32'h1000_0000 ^ 32'hA5A5_A5A5)) begin
            $display("[FAIL] rdata=%08h", rdata); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
