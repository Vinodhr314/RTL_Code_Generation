`timescale 1ns/1ps
module coremark_benchmark_tb;

    reg        clk, rst_n, start, stop;
    wire [31:0] cycle_cnt, instret_cnt;

    coremark_benchmark dut (
        .clk(clk), .rst_n(rst_n), .start(start), .stop(stop),
        .cycle_cnt(cycle_cnt), .instret_cnt(instret_cnt)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;
    integer i;

    initial begin
        rst_n = 1'b0; start = 1'b0; stop = 1'b0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        start = 1'b1;
        @(posedge clk); #0; start = 1'b0;

        for (i = 0; i < 10; i = i + 1)
            @(posedge clk);

        stop = 1'b1;
        @(posedge clk); #0; stop = 1'b0;

        #1;
        if (cycle_cnt !== 32'd10) begin
            $display("[FAIL] cycle_cnt=%0d expected 10", cycle_cnt);
            fail = fail + 1;
        end
        if (instret_cnt !== 32'd10) begin
            $display("[FAIL] instret_cnt=%0d expected 10", instret_cnt);
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
