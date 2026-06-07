`timescale 1ns/1ps
module jtag_gen_1_tb;
    reg tck, tms, tdi;
    wire tdo;
    wire [63:0] ext_dr;
    integer fail = 0, i;
    jtag_gen_1 dut (.*);
    initial begin tck = 0; forever #10 tck = ~tck; end
    initial begin
        tms = 0; tdi = 0;
        tdi = 1'b1;
        @(posedge tck); #1;
        if (tdo !== 1'b1) begin $display("[FAIL] tdo=%b", tdo); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
