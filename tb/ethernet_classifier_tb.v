`timescale 1ns/1ps
module ethernet_classifier_tb;

    reg        clk, rst_n, in_valid;
    reg [31:0] in_data;
    wire [3:0] traffic_class;
    wire       class_valid;

    ethernet_classifier dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_data(in_data),
        .traffic_class(traffic_class), .class_valid(class_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; in_valid = 1'b0; in_data = 32'h0;
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        in_data = 32'h0000_0800;
        in_valid = 1'b1;
        @(posedge clk); #0; in_valid = 1'b0;
        if (!class_valid || traffic_class !== 4'd1) begin
            $display("[FAIL] IPv4 class expected 1 got %0d valid=%b", traffic_class, class_valid);
            fail = fail + 1;
        end

        @(posedge clk);
        in_data = 32'h0000_0806;
        in_valid = 1'b1;
        @(posedge clk); #0; in_valid = 1'b0;
        if (!class_valid || traffic_class !== 4'd2) begin
            $display("[FAIL] ARP class expected 2 got %0d", traffic_class);
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
