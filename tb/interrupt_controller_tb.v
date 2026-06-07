`timescale 1ns/1ps
module interrupt_controller_tb;
    reg clk, rst_n, ack;
    reg [7:0] irq_in, irq_prio, mask;
    wire irq_out;
    wire [7:0] pending_w, claim_w;
    integer fail = 0;
    interrupt_controller dut (
        .clk(clk), .rst_n(rst_n), .irq_in(irq_in), .irq_out(irq_out),
        .irq_prio(irq_prio), .mask(mask), .pending(pending_w), .claim(claim_w), .ack(ack)
    );
    initial clk = 0; always #5 clk = ~clk;
    initial begin
        rst_n = 0; irq_in = 0; irq_prio = 8'h00; mask = 8'h00; ack = 0;
        @(posedge clk); @(posedge clk); rst_n = 1;
        irq_prio = 8'h10;
        irq_in = 8'h04;
        @(posedge clk); @(posedge clk); #1;
        if (!irq_out) begin $display("[FAIL] irq_out"); fail = fail + 1; end
        if (claim_w !== 8'd2) begin $display("[FAIL] claim=%0d", claim_w); fail = fail + 1; end
        ack = 1; @(posedge clk); #0; ack = 0;
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
