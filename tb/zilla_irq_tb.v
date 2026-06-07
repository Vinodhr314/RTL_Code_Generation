`timescale 1ns/1ps
module zilla_irq_tb;
    reg clk, rst_n;
    reg [31:0] src;
    wire [7:0] vec;
    wire valid;
    integer fail = 0;
    zilla_irq dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; src = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        src = 32'h0000_0400;
        @(posedge clk); #1;
        if (!valid) begin $display("[FAIL] valid"); fail = fail + 1; end
        if (vec !== 8'd10) begin $display("[FAIL] vec=%0d", vec); fail = fail + 1; end
        src = 0;
        @(posedge clk); #1;
        if (valid) begin $display("[FAIL] valid clear"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
