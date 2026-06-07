`timescale 1ns/1ps
module cordic_tb;

    reg        clk, rst_n, start;
    reg [1:0]  mode;
    reg [31:0] x_in, y_in, z_in;
    wire [31:0] x_out, y_out;
    wire        done;

    cordic dut (
        .clk(clk), .rst_n(rst_n), .start(start), .mode(mode),
        .x_in(x_in), .y_in(y_in), .z_in(z_in),
        .x_out(x_out), .y_out(y_out), .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; start = 1'b0;
        mode = 2'b00; x_in = 32'h40000000; y_in = 32'h0; z_in = 32'h20000000;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        start = 1'b1;
        @(posedge clk); #0; start = 1'b0;

        while (!done) @(posedge clk);

        if (x_out !== 32'h5A827999) begin
            $display("[FAIL] x_out=%h expected 5A827999", x_out);
            fail = fail + 1;
        end
        if (y_out !== 32'h5A827999) begin
            $display("[FAIL] y_out=%h expected 5A827999", y_out);
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
