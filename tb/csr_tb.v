`timescale 1ns/1ps
module csr_tb;

    reg        clk;
    reg [11:0] csr_addr;
    reg [31:0] csr_wdata;
    reg [1:0]  csr_op;
    wire [31:0] csr_rdata;
    wire        illegal;

    csr dut (
        .clk(clk), .csr_addr(csr_addr), .csr_wdata(csr_wdata),
        .csr_op(csr_op), .csr_rdata(csr_rdata), .illegal(illegal)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        csr_addr = 12'h0; csr_wdata = 32'h0; csr_op = 2'b00;
        @(posedge clk);

        csr_addr = 12'h300; csr_op = 2'b00;
        @(posedge clk);
        if (csr_rdata !== 32'h00001800) begin
            $display("[FAIL] mstatus read=%h expected 1800", csr_rdata);
            fail = fail + 1;
        end

        csr_addr = 12'h304; csr_wdata = 32'h0000_0888; csr_op = 2'b01;
        @(posedge clk); #0; csr_op = 2'b00;
        @(posedge clk);
        if (csr_rdata !== 32'h00000888) begin
            $display("[FAIL] mie write/read mismatch got %h", csr_rdata);
            fail = fail + 1;
        end

        csr_addr = 12'h305; csr_wdata = 32'h8000_0000; csr_op = 2'b01;
        @(posedge clk); #0; csr_op = 2'b00;
        @(posedge clk);
        if (csr_rdata !== 32'h80000000) begin
            $display("[FAIL] mtvec write/read mismatch got %h", csr_rdata);
            fail = fail + 1;
        end

        csr_addr = 12'h999; csr_op = 2'b00;
        @(posedge clk);
        if (!illegal) begin
            $display("[FAIL] illegal not asserted for bad CSR");
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
