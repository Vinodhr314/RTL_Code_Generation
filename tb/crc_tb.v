`timescale 1ns/1ps
module crc_tb;

    reg       clk, rst_n, valid, init;
    reg [7:0] data;
    wire [31:0] crc;
    wire        done;

    crc dut (
        .clk(clk), .rst_n(rst_n), .data(data), .valid(valid),
        .init(init), .crc(crc), .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;
    integer i;
    reg [7:0] test_msg [0:8];

    initial begin
        test_msg[0] = 8'h31; test_msg[1] = 8'h32; test_msg[2] = 8'h33;
        test_msg[3] = 8'h34; test_msg[4] = 8'h35; test_msg[5] = 8'h36;
        test_msg[6] = 8'h37; test_msg[7] = 8'h38; test_msg[8] = 8'h39;

        rst_n = 1'b0; valid = 1'b0; init = 1'b0; data = 8'h0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        init = 1'b1;
        @(posedge clk); #0; init = 1'b0;
        @(posedge clk);

        for (i = 0; i < 9; i = i + 1) begin
            data  = test_msg[i];
            valid = 1'b1;
            @(posedge clk); #0; valid = 1'b0;
            @(posedge clk);
        end

        @(posedge clk);
        #1;
        if (crc !== 32'hCBF43926) begin
            $display("[FAIL] crc=%h expected CBF43926", crc);
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
