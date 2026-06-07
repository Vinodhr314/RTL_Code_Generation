`timescale 1ns/1ps
module gpio_tb;
    reg clk, rst_n;
    reg [31:0] dir, out;
    wire [31:0] gpio, in, irq;
    integer fail = 0;
    gpio dut (.clk(clk), .rst_n(rst_n), .gpio(gpio), .dir(dir), .out(out), .in(in), .irq(irq));
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; dir = 32'h0; out = 32'h0;
        force dut.gpio = 32'h0000_0005;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        if (in !== 32'h0000_0005) begin $display("[FAIL] in=%h", in); fail = fail + 1; end
        release dut.gpio;
        dir = 32'h0000_00FF; out = 32'h0000_00AA;
        @(posedge clk); #1;
        if (gpio[7:0] !== 8'hAA) begin $display("[FAIL] gpio out"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
