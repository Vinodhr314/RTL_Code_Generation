`timescale 1ns/1ps
module mem_ctrl_tb;
    reg clk, rst_n, cpu_wen, cpu_ren;
    reg [31:0] cpu_addr, cpu_wdata;
    wire [31:0] cpu_rdata;
    wire cpu_ready;
    wire [31:0] ext_addr, ext_wdata;
    wire ext_wen, ext_ren;
    reg [31:0] ext_rdata;
    reg ext_ready;
    integer fail = 0;
    mem_ctrl dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; cpu_wen = 0; cpu_ren = 0; ext_ready = 1; ext_rdata = 32'h0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        cpu_addr = 32'h0000_0010; cpu_wdata = 32'hCAFE_BABE; cpu_wen = 1;
        @(posedge clk); #0; cpu_wen = 0;
        @(posedge clk);
        cpu_addr = 32'h0000_0010; cpu_ren = 1;
        @(posedge clk); #0; cpu_ren = 0;
        @(posedge clk); #1;
        if (cpu_rdata !== 32'hCAFE_BABE) begin
            $display("[FAIL] readback %08h", cpu_rdata); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
