`timescale 1ns/1ps
module power_of_two_check_tb;
    reg        clk, rst_n, start;
    reg [31:0] base_addr;
    reg [15:0] length;
    wire       done, busy, irq;
    wire [31:0] result;
    integer fail = 0;
    power_of_two_check dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .base_addr(base_addr), .length(length),
        .done(done), .busy(busy), .result(result), .irq(irq)
    );
    initial clk = 0; always #5 clk = ~clk;
    task run_accel; input [31:0] exp; input [7:0] tn;
        begin
            start = 1; @(posedge clk); #0; start = 0;
            @(posedge clk);
            if (!busy) begin $display("[FAIL] T%0d: busy", tn); fail = fail + 1; end
            while (!done) @(posedge clk);
            if (result !== exp) begin $display("[FAIL] T%0d: result=%0d exp=%0d", tn, result, exp); fail = fail + 1; end
            if (!irq) begin $display("[FAIL] T%0d: irq", tn); fail = fail + 1; end
            @(posedge clk);
            if (irq) begin $display("[FAIL] T%0d: irq pulse", tn); fail = fail + 1; end
        end
    endtask
    initial begin
        rst_n = 0; start = 0; base_addr = 0; length = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        run_accel(32'd1, 1);
        @(posedge clk); @(posedge clk);
        run_accel(32'd1, 2);
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
