`timescale 1ns/1ps
module trace_unit_tb;
    reg clk, rst_n, valid;
    reg [31:0] pc, inst;
    wire [63:0] trace_data;
    wire trace_valid;
    integer fail = 0;
    trace_unit dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; valid = 0; pc = 32'h8000_0000; inst = 32'h0000_0013;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        valid = 1; @(posedge clk); #0; valid = 0;
        @(posedge clk);
        if (trace_data !== 64'h8000_0000_0000_0013) begin
            $display("[FAIL] trace_data=%016h", trace_data); fail = fail + 1;
        end
        if (!trace_valid) begin $display("[FAIL] trace_valid"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
