`timescale 1ns/1ps
module jtag_tb;
    reg tck, tms, tdi, trst_n;
    wire tdo, debug_req;
    integer fail = 0, i;
    jtag dut (.*);
    initial begin tck = 0; forever #10 tck = ~tck; end
    initial begin
        trst_n = 0; tms = 0; tdi = 0;
        #20; trst_n = 1;
        for (i = 0; i < 32; i = i + 1) begin
            tdi = 1'b1; @(posedge tck); #1;
        end
        if (tdo !== 1'b1) begin $display("[FAIL] tdo shift"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
