`timescale 1ns/1ps
module fpu_double_precision_tb;

    reg        clk, rst_n, valid;
    reg [2:0]  op;
    reg [63:0] a, b;
    wire [63:0] result;
    wire        ready;
    wire [4:0]  flags;

    fpu_double_precision dut (
        .clk(clk), .rst_n(rst_n), .valid(valid), .op(op),
        .a(a), .b(b), .result(result), .ready(ready), .flags(flags)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; valid = 1'b0; op = 3'h0;
        a = 64'h3FF0000000000000;
        b = 64'h4000000000000000;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        valid = 1'b1;
        @(posedge clk); #0; valid = 1'b0;

        while (!ready) @(posedge clk);

        if (result !== 64'h4008000000000000) begin
            $display("[FAIL] FADD expected 4008000000000000 got %016h", result);
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
