`timescale 1ns/1ps
module fpu_tb;

    reg        clk, rst_n, valid;
    reg [2:0]  op;
    reg [31:0] a, b;
    wire [31:0] result;
    wire        ready;
    wire [4:0]  flags;

    fpu dut (
        .clk(clk), .rst_n(rst_n), .valid(valid), .op(op),
        .a(a), .b(b), .result(result), .ready(ready), .flags(flags)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; valid = 1'b0; op = 3'h0;
        a = 32'h3F800000; b = 32'h40000000;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        valid = 1'b1;
        @(posedge clk); #0; valid = 1'b0;

        while (!ready) @(posedge clk);

        if (result !== 32'h40400000) begin
            $display("[FAIL] FADD expected 40400000 got %08h", result);
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
