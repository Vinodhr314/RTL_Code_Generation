`timescale 1ns/1ps
module custom_circuits_tb;

    reg        clk, rst_n;
    wire [31:0] gpio;
    wire [31:0] status;

    custom_circuits dut (
        .clk(clk), .rst_n(rst_n), .gpio(gpio), .status(status)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0;
        force dut.gpio = 32'hA5A5_1234;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        if (status !== 32'hA5A5_1234) begin
            $display("[FAIL] status=%h expected A5A51234", status);
            fail = fail + 1;
        end

        release dut.gpio;

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);
        $finish;
    end

    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
