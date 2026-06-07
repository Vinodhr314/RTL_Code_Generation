`timescale 1ns/1ps
module wdt_tb;
    reg clk, rst_n, kick;
    reg [31:0] timeout;
    wire wdt_rst, irq;
    integer fail = 0;
    wdt dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; kick = 0; timeout = 32'd5;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        kick = 1; @(posedge clk); #0; kick = 0;
        repeat (4) @(posedge clk);
        if (!irq) begin $display("[FAIL] irq warning"); fail = fail + 1; end
        repeat (2) @(posedge clk);
        if (!wdt_rst) begin $display("[FAIL] wdt_rst"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
