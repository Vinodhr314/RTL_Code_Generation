`timescale 1ns/1ps
module cmu_tb;

    reg        clk_ref, rst_n, cfg_wr;
    reg [15:0] cfg;
    wire       clk_cpu, clk_bus, clk_periph, pll_lock;

    cmu dut (
        .clk_ref(clk_ref), .rst_n(rst_n),
        .clk_cpu(clk_cpu), .clk_bus(clk_bus), .clk_periph(clk_periph),
        .pll_lock(pll_lock), .cfg(cfg), .cfg_wr(cfg_wr)
    );

    initial clk_ref = 0;
    always #5 clk_ref = ~clk_ref;

    integer fail = 0;
    reg cpu_prev, bus_prev, periph_prev;

    initial begin
        rst_n  = 1'b0;
        cfg    = 16'h0;
        cfg_wr = 1'b0;

        @(posedge clk_ref); @(posedge clk_ref);
        rst_n = 1'b1;
        @(posedge clk_ref);

        cfg    = 16'h0421;
        cfg_wr = 1'b1;
        @(posedge clk_ref); #0; cfg_wr = 1'b0;

        if (!pll_lock) begin
            $display("[FAIL] pll_lock not asserted after cfg_wr");
            fail = fail + 1;
        end

        cpu_prev = clk_cpu; bus_prev = clk_bus; periph_prev = clk_periph;
        repeat (20) @(posedge clk_ref);
        if (clk_cpu === cpu_prev && clk_bus === bus_prev && clk_periph === periph_prev) begin
            $display("[FAIL] output clocks did not toggle");
            fail = fail + 1;
        end

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);
        $finish;
    end

    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
