`timescale 1ns/1ps
module fifo_tb;

    reg        clk, rst_n, wr_en, rd_en;
    reg [31:0] din;
    wire [31:0] dout;
    wire        full, empty;
    wire [3:0]  count;

    fifo #(.DEPTH(16), .ADDR_W(4)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout),
        .full(full), .empty(empty), .count(count)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;
    integer i;

    initial begin
        rst_n = 1'b0; wr_en = 1'b0; rd_en = 1'b0; din = 32'h0;
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        if (!empty) begin
            $display("[FAIL] FIFO should be empty after reset");
            fail = fail + 1;
        end

        for (i = 0; i < 4; i = i + 1) begin
            din = 32'h1000_0000 | i[31:0];
            wr_en = 1'b1;
            @(posedge clk); #0; wr_en = 1'b0;
        end

        @(posedge clk);
        if (count !== 4'd4) begin
            $display("[FAIL] count expected 4 got %0d", count);
            fail = fail + 1;
        end

        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk); #1;
            if (dout !== (32'h1000_0000 | i[31:0])) begin
                $display("[FAIL] read[%0d] mismatch got %08h", i, dout);
                fail = fail + 1;
            end
            rd_en = 1'b1;
            @(posedge clk); #0;
            rd_en = 1'b0;
        end

        @(posedge clk);
        if (!empty) begin
            $display("[FAIL] FIFO should be empty after drain");
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
