`timescale 1ns/1ps
// bch_error_correction testbench
// DUT runs BCH(15,5,3) syndrome on internal hardcoded test vector.
// Expected result: 32'd1 (corrected data = 5'b00001, zero-extended).
module bch_error_correction_tb;

    reg        clk, rst_n;
    reg        start;
    reg [31:0] base_addr;
    reg [15:0] length;
    wire       done;
    wire       busy;
    wire [31:0] result;
    wire        irq;

    bch_error_correction dut (
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
            // Assert start for one cycle
            start = 1'b1;
            @(posedge clk); #0; start = 1'b0;

            // Wait for busy to assert
            @(posedge clk);
            if (!busy) begin
                $display("[FAIL] T%0d: busy did not assert after start", tnum);
                fail = fail + 1;
            end

            // Wait for done
            while (!done) @(posedge clk);

            // Check result at the cycle done asserts
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

            // irq should deassert next cycle
            @(posedge clk);
            if (irq) begin
                $display("[FAIL] T%0d: irq did not pulse (still high)", tnum);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        rst_n    = 1'b0;
        start    = 1'b0;
        base_addr = 32'h0;
        length    = 16'h0;

        // Sync reset: 2+ posedges
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // Test 1: Normal run
        run_accelerator(32'd1, 1);

        // Wait a few cycles
        @(posedge clk); @(posedge clk);

        // Test 2: Re-run (done clears, re-executes)
        run_accelerator(32'd1, 2);

        // Test 3: Start while in DONE state re-triggers computation
        @(posedge clk); @(posedge clk);
        run_accelerator(32'd1, 3);

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
