`timescale 1ns/1ps
module barrel_shifter_tb;

    reg  [31:0] a;
    reg  [4:0]  shamt;
    reg  [1:0]  op;
    wire [31:0] y;

    barrel_shifter dut (
        .a(a), .shamt(shamt), .op(op), .y(y)
    );

    integer fail = 0;

    task check_result;
        input [31:0] expected;
        input [7:0]  tnum;
        begin
            #1;
            if (y !== expected) begin
                $display("[FAIL] T%0d: a=%h shamt=%0d op=%b => y=%h, exp=%h",
                         tnum, a, shamt, op, y, expected);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        // SLL (op=00)
        a = 32'h00000001; shamt = 5'd0;  op = 2'b00; check_result(32'h00000001, 1);
        a = 32'h00000001; shamt = 5'd1;  op = 2'b00; check_result(32'h00000002, 2);
        a = 32'h00000001; shamt = 5'd4;  op = 2'b00; check_result(32'h00000010, 3);
        a = 32'h00000001; shamt = 5'd31; op = 2'b00; check_result(32'h80000000, 4);
        a = 32'hFFFFFFFF; shamt = 5'd4;  op = 2'b00; check_result(32'hFFFFFFF0, 5);
        a = 32'h12345678; shamt = 5'd8;  op = 2'b00; check_result(32'h34567800, 6);

        // SRL (op=01)
        a = 32'h80000000; shamt = 5'd1;  op = 2'b01; check_result(32'h40000000, 7);
        a = 32'h80000000; shamt = 5'd31; op = 2'b01; check_result(32'h00000001, 8);
        a = 32'hFFFFFFFF; shamt = 5'd4;  op = 2'b01; check_result(32'h0FFFFFFF, 9);
        a = 32'h00000001; shamt = 5'd1;  op = 2'b01; check_result(32'h00000000, 10);
        a = 32'h12345678; shamt = 5'd8;  op = 2'b01; check_result(32'h00123456, 11);

        // SRA (op=10) — arithmetic right shift preserves sign
        a = 32'h80000000; shamt = 5'd1;  op = 2'b10; check_result(32'hC0000000, 12);
        a = 32'h80000000; shamt = 5'd31; op = 2'b10; check_result(32'hFFFFFFFF, 13);
        a = 32'hFFFFFFFF; shamt = 5'd4;  op = 2'b10; check_result(32'hFFFFFFFF, 14);
        a = 32'h40000000; shamt = 5'd2;  op = 2'b10; check_result(32'h10000000, 15);
        a = 32'h7FFFFFFF; shamt = 5'd1;  op = 2'b10; check_result(32'h3FFFFFFF, 16);

        // Pass-through (op=11)
        a = 32'hDEADBEEF; shamt = 5'd5;  op = 2'b11; check_result(32'hDEADBEEF, 17);
        a = 32'h00000000; shamt = 5'd0;  op = 2'b11; check_result(32'h00000000, 18);

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);
        $finish;
    end

    initial begin
        #10000;
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
