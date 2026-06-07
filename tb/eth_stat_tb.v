`timescale 1ns/1ps
module eth_stat_tb;

    reg        clk, rst_n, rx_frame, tx_frame, rx_err, tx_err, clear;
    wire [31:0] byte_cnt, frame_cnt, err_cnt;

    eth_stat dut (
        .clk(clk), .rst_n(rst_n),
        .rx_frame(rx_frame), .tx_frame(tx_frame),
        .rx_err(rx_err), .tx_err(tx_err),
        .byte_cnt(byte_cnt), .frame_cnt(frame_cnt), .err_cnt(err_cnt),
        .clear(clear)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    task pulse_rx;
        begin
            rx_frame = 1'b1;
            @(posedge clk);
            rx_frame = 1'b0;
        end
    endtask

    task pulse_tx;
        begin
            tx_frame = 1'b1;
            @(posedge clk);
            tx_frame = 1'b0;
        end
    endtask

    task pulse_err;
        begin
            rx_err = 1'b1;
            @(posedge clk);
            rx_err = 1'b0;
        end
    endtask

    initial begin
        rst_n = 1'b0; rx_frame = 1'b0; tx_frame = 1'b0;
        rx_err = 1'b0; tx_err = 1'b0; clear = 1'b0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        pulse_rx;
        @(posedge clk);
        pulse_tx;
        @(posedge clk);
        pulse_err;

        @(posedge clk);
        if (frame_cnt !== 32'd2) begin
            $display("[FAIL] frame_cnt expected 2 got %0d", frame_cnt);
            fail = fail + 1;
        end
        if (byte_cnt !== 32'd128) begin
            $display("[FAIL] byte_cnt expected 128 got %0d", byte_cnt);
            fail = fail + 1;
        end
        if (err_cnt !== 32'd1) begin
            $display("[FAIL] err_cnt expected 1 got %0d", err_cnt);
            fail = fail + 1;
        end

        clear = 1'b1;
        @(posedge clk); #0; clear = 1'b0;
        @(posedge clk);
        if (frame_cnt !== 32'd0 || byte_cnt !== 32'd0 || err_cnt !== 32'd0) begin
            $display("[FAIL] counters not cleared");
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
