`timescale 1ns/1ps
module packet_buffer_tb;
    reg clk, rst_n, wr_en, rd_en;
    reg [11:0] wr_addr, rd_addr;
    reg [31:0] wr_data;
    wire [31:0] rd_data;
    wire full, empty;
    integer fail = 0;
    packet_buffer dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; wr_en = 0; rd_en = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        if (!empty) begin $display("[FAIL] not empty after reset"); fail = fail + 1; end
        wr_addr = 12'h5; wr_data = 32'hBEEF_0005; wr_en = 1;
        @(posedge clk); #0; wr_en = 0;
        @(posedge clk);
        rd_addr = 12'h5; rd_en = 1;
        @(posedge clk); #1;
        if (rd_data !== 32'hBEEF_0005) begin
            $display("[FAIL] rd_data=%08h", rd_data); fail = fail + 1;
        end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
