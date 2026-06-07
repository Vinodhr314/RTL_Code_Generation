`timescale 1ns/1ps
module frame_formatter_tb;

    reg        clk, rst_n, in_valid, in_last;
    reg [31:0] in_data;
    wire       out_valid, out_last;
    wire [31:0] out_data;
    wire [15:0] frame_len;

    frame_formatter dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_data(in_data), .in_last(in_last),
        .out_valid(out_valid), .out_data(out_data),
        .out_last(out_last), .frame_len(frame_len)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; in_valid = 1'b0; in_data = 32'h0; in_last = 1'b0;
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        in_data = 32'h1111_1111;
        in_valid = 1'b1; in_last = 1'b0;
        @(posedge clk); #0; in_valid = 1'b0;
        @(posedge clk);
        if (!out_valid || out_data !== 32'hAABBCCDD) begin
            $display("[FAIL] header expected AABBCCDD got %08h", out_data);
            fail = fail + 1;
        end

        in_data = 32'h2222_2222;
        in_valid = 1'b1; in_last = 1'b1;
        @(posedge clk); #0; in_valid = 1'b0; in_last = 1'b0;
        @(posedge clk);
        if (!out_valid || out_data !== 32'h2222_2222) begin
            $display("[FAIL] payload mismatch");
            fail = fail + 1;
        end
        if (!out_last) begin
            $display("[FAIL] out_last not asserted");
            fail = fail + 1;
        end
        if (frame_len !== 16'd8) begin
            $display("[FAIL] frame_len expected 8 got %0d", frame_len);
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
