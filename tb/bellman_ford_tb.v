`timescale 1ns/1ps
// bellman_ford testbench
// DUT: 4-node graph, Bellman-Ford from node 0.
// Expected result: 32'd3 (shortest distance from node 0 to node 1, via 0->2->1 with cost 2+1=3).
module bellman_ford_tb;

    reg        clk, rst_n;
    reg        start;
    reg [31:0] base_addr;
    reg [15:0] length;
    wire       done;
    wire       busy;
    wire [31:0] result;
    wire        irq;

    bellman_ford dut (
        .clk(clk), .rst_n(rst_n),
        .start(start), .base_addr(base_addr), .length(length),
        .done(done), .busy(busy), .result(result), .irq(irq)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    task run_accelerator;
        input [31:0] exp_result;
        input [7:0]  tnum;
        begin
            start = 1'b1;
            @(posedge clk); #0; start = 1'b0;

            @(posedge clk);
            if (!busy) begin
                $display("[FAIL] T%0d: busy did not assert after start", tnum);
                fail = fail + 1;
            end

            while (!done) @(posedge clk);

            if (result !== exp_result) begin
                $display("[FAIL] T%0d: result=%0d, expected=%0d", tnum, result, exp_result);
                fail = fail + 1;
            end
            if (!irq) begin
                $display("[FAIL] T%0d: irq not asserted with done", tnum);
                fail = fail + 1;
            end
            if (busy) begin
                $display("[FAIL] T%0d: busy still high when done", tnum);
                fail = fail + 1;
            end

            @(posedge clk);
            if (irq) begin
                $display("[FAIL] T%0d: irq did not pulse (still high)", tnum);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        rst_n     = 1'b0;
        start     = 1'b0;
        base_addr = 32'h0;
        length    = 16'h0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // Test 1: Shortest path from node 0 to node 1 = 3
        run_accelerator(32'd3, 1);

        @(posedge clk); @(posedge clk);

        // Test 2: Re-run gives same result
        run_accelerator(32'd3, 2);

        @(posedge clk); @(posedge clk);

        // Test 3: Third run
        run_accelerator(32'd3, 3);

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);
        $finish;
    end

    initial begin
        #500000;
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
