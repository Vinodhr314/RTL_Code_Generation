`timescale 1ns/1ps
module gp_dma_gen_1_tb;
    reg clk, rst_n, ch0_start, ch1_start;
    reg [31:0] ch0_src, ch0_dst, ch1_src, ch1_dst;
    reg [15:0] ch0_len, ch1_len;
    wire ch0_done, ch0_irq, ch1_done, ch1_irq;
    wire [31:0] mem_addr, mem_wdata;
    wire mem_wen, mem_ren;
    reg [31:0] mem_rdata;
    reg mem_ready;
    reg [31:0] mem [0:255];
    integer fail = 0, i;

    gp_dma_gen_1 dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;
    always @* if (mem_ren) mem_rdata = mem[mem_addr[9:2]]; else mem_rdata = 32'h0;
    always @(posedge clk) if (mem_wen) mem[mem_addr[9:2]] <= mem_wdata;

    initial begin
        rst_n = 0; ch0_start = 0; ch1_start = 0; mem_ready = 1;
        ch0_src = 32'h100; ch0_dst = 32'h200; ch0_len = 16'd4;
        mem[(32'h100>>2)] = 32'hDEAD_BEEF;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        ch0_start = 1; @(posedge clk); #0; ch0_start = 0;
        while (!ch0_done) @(posedge clk);
        if (!ch0_irq) begin $display("[FAIL] ch0_irq"); fail = fail + 1; end
        if (mem[(32'h200>>2)] !== 32'hDEAD_BEEF) begin
            $display("[FAIL] ch0 copy mismatch %08h", mem[(32'h200>>2)]); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
