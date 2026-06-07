`timescale 1ns/1ps
module spi_tb;
    reg clk, rst_n;
    reg miso;
    reg [7:0] tx;
    wire sck, mosi, busy, done, irq;
    wire [3:0] cs_n;
    wire [7:0] rx;
    integer fail = 0;
    spi dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; tx = 8'h00; miso = 1'b0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        miso = 1'b1;
        tx = 8'hFF;
        while (!done) @(posedge clk);
        if (rx !== 8'hFF) begin $display("[FAIL] rx=%h", rx); fail = fail + 1; end
        if (!done) begin $display("[FAIL] done"); fail = fail + 1; end
        if (!irq) begin $display("[FAIL] irq"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
