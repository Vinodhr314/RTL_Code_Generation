`timescale 1ns/1ps
module uart_tb;
    reg clk, rst_n, tx, pwrite, psel, penable;
    reg [31:0] pwdata;
    reg [11:0] paddr;
    wire rx, pready, irq;
    wire [31:0] prdata;
    integer fail = 0;
    uart dut (.*);
    initial clk = 0; always #5 clk = ~clk;
    task apb_write; input [11:0] a; input [31:0] d;
        begin
            paddr = a; pwdata = d; psel = 1; pwrite = 1; penable = 0;
            @(posedge clk); penable = 1; @(posedge clk); #0;
            psel = 0; penable = 0; pwrite = 0;
        end
    endtask
    task apb_read; input [11:0] a; output [31:0] d;
        begin
            paddr = a; psel = 1; pwrite = 0; penable = 0;
            @(posedge clk); penable = 1; @(posedge clk); #1;
            d = prdata; psel = 0; penable = 0;
        end
    endtask
    reg [31:0] rd;
    initial begin
        rst_n = 0; tx = 1;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
        apb_write(12'h0, 32'hDEAD_BEEF);
        apb_read(12'h0, rd);
        if (rd !== 32'hDEAD_BEEF) begin $display("[FAIL] reg0 %08h", rd); fail = fail + 1; end
        apb_write(12'h0, 32'h0000_0001);
        @(posedge clk); #1;
        if (!irq) begin $display("[FAIL] irq"); fail = fail + 1; end
        if (fail == 0) $display("ALL TESTS PASSED"); else $display("[FAIL] %0d failed", fail);
        $finish;
    end
    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
