`timescale 1ns/1ps
module tx_mac_tb;
    reg clk, rst_n, tx_start, tx_valid, tx_last;
    reg [7:0] tx_data;
    wire tx_ready;
    wire [7:0] gmii_txd;
    wire gmii_tx_en;
    integer fail = 0;
    tx_mac dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; tx_start = 0; tx_valid = 0; tx_last = 0; tx_data = 8'hAB;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        tx_start = 1; @(posedge clk); #0; tx_start = 0;
        repeat (8) @(posedge clk);
        if (gmii_txd !== 8'hD5) begin $display("[FAIL] SFD got %02h", gmii_txd); fail = fail + 1; end
        if (!tx_ready) begin $display("[FAIL] tx_ready"); fail = fail + 1; end
        tx_valid = 1; tx_last = 1; @(posedge clk); #0; tx_valid = 0; tx_last = 0;
        @(posedge clk);
        if (gmii_txd !== 8'hAB) begin $display("[FAIL] payload %02h", gmii_txd); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
