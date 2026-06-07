`timescale 1ns/1ps
module compression_engine_tb;

    reg        clk, rst_n, mode, in_valid, in_last;
    reg [31:0] in_data;
    wire       out_valid, out_last, busy;
    wire [31:0] out_data;

    compression_engine dut (
        .clk(clk), .rst_n(rst_n), .mode(mode),
        .in_valid(in_valid), .in_data(in_data), .in_last(in_last),
        .out_valid(out_valid), .out_data(out_data), .out_last(out_last), .busy(busy)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; mode = 1'b0;
        in_valid = 1'b0; in_data = 32'h0; in_last = 1'b0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        in_data  = 32'hDEADBEEF;
        in_last  = 1'b1;
        in_valid = 1'b1;
        @(posedge clk); #0; in_valid = 1'b0;

        if (!busy) begin
            $display("[FAIL] busy not asserted during transfer");
            fail = fail + 1;
        end

        @(posedge clk);
        if (!out_valid) begin
            $display("[FAIL] out_valid not asserted");
            fail = fail + 1;
        end
        if (out_data !== 32'hDEADBEEF) begin
            $display("[FAIL] out_data mismatch");
            fail = fail + 1;
        end
        if (!out_last) begin
            $display("[FAIL] out_last not asserted");
            fail = fail + 1;
        end

        @(posedge clk);
        if (busy) begin
            $display("[FAIL] busy still high after transfer");
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
