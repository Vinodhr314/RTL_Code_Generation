`timescale 1ns/1ps
module comp_isa_tb;

    reg        clk, rst_n, valid;
    reg [31:0] inst, rs1, rs2;
    wire [31:0] rd;
    wire        rd_valid;

    comp_isa dut (
        .clk(clk), .rst_n(rst_n), .inst(inst), .valid(valid),
        .rs1(rs1), .rs2(rs2), .rd(rd), .rd_valid(rd_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; valid = 1'b0;
        inst = 32'h0; rs1 = 32'd10; rs2 = 32'd32;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        inst  = {25'h0, 7'h7B};
        valid = 1'b1;
        @(posedge clk); #0; valid = 1'b0;
        @(posedge clk);

        if (!rd_valid) begin
            $display("[FAIL] rd_valid not asserted");
            fail = fail + 1;
        end
        if (rd !== 32'd42) begin
            $display("[FAIL] rd=%0d expected 42", rd);
            fail = fail + 1;
        end

        inst  = 32'h0;
        valid = 1'b1;
        @(posedge clk); #0; valid = 1'b0;
        @(posedge clk);
        if (rd_valid) begin
            $display("[FAIL] rd_valid asserted for non-custom opcode");
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
