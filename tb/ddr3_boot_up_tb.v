`timescale 1ns/1ps
module ddr3_boot_up_tb;

    reg       clk, rst_n, start;
    wire      done, fail;
    wire [7:0] status;

    ddr3_boot_up dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .done(done), .fail(fail), .status(status)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer f = 0;

    initial begin
        rst_n = 1'b0; start = 1'b0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        start = 1'b1;
        @(posedge clk); #0; start = 1'b0;

        while (!done) @(posedge clk);

        if (fail) begin
            $display("[FAIL] fail asserted on successful init");
            f = f + 1;
        end
        if (status !== 8'h80) begin
            $display("[FAIL] status=%h expected 80", status);
            f = f + 1;
        end

        if (f == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", f);
        $finish;
    end

    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
