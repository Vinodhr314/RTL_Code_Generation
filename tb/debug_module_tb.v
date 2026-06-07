`timescale 1ns/1ps
module debug_module_tb;

    reg        clk, rst_n;
    reg [31:0] dmi;
    wire       halt_req, resume_req, error;
    reg        halted;
    wire [31:0] abstract_data;

    debug_module dut (
        .clk(clk), .rst_n(rst_n), .dmi(dmi),
        .halt_req(halt_req), .resume_req(resume_req), .halted(halted),
        .abstract_data(abstract_data), .error(error)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    initial begin
        rst_n = 1'b0; dmi = 32'h0; halted = 1'b0;
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        dmi = 32'h0000_0001;
        @(posedge clk); #1;
        if (!halt_req) begin
            $display("[FAIL] halt_req not asserted");
            fail = fail + 1;
        end
        dmi = 32'h0000_0000;
        @(posedge clk); #1;
        if (halt_req) begin
            $display("[FAIL] halt_req should pulse one cycle");
            fail = fail + 1;
        end

        dmi = 32'h0000_0002;
        @(posedge clk); #1;
        if (!resume_req) begin
            $display("[FAIL] resume_req not asserted");
            fail = fail + 1;
        end
        dmi = 32'h0000_0000;
        @(posedge clk);

        dmi = 32'h0000_0003;
        @(posedge clk); #1;
        if (abstract_data !== 32'h0000_0042) begin
            $display("[FAIL] abstract_data expected 42 got %08h", abstract_data);
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
