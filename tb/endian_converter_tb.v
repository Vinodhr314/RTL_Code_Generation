`timescale 1ns/1ps
module endian_converter_tb;

    reg [31:0] din;
    reg [1:0]  mode;
    wire [31:0] dout;

    endian_converter dut (.din(din), .dout(dout), .mode(mode));

    integer fail = 0;

    initial begin
        din = 32'h12345678;

        mode = 2'b00;
        #1;
        if (dout !== 32'h78563412) begin
            $display("[FAIL] byte swap expected 78563412 got %08h", dout);
            fail = fail + 1;
        end

        mode = 2'b01;
        #1;
        if (dout !== 32'h56781234) begin
            $display("[FAIL] half swap expected 56781234 got %08h", dout);
            fail = fail + 1;
        end

        mode = 2'b10;
        #1;
        if (dout !== 32'h12345678) begin
            $display("[FAIL] pass-through expected 12345678 got %08h", dout);
            fail = fail + 1;
        end

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);
        $finish;
    end
endmodule
