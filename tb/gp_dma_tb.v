`timescale 1ns/1ps
module gp_dma_tb;

    reg        clk, rst_n, start;
    reg [31:0] src, dst;
    reg [15:0] len;
    wire       done, busy, irq;
    wire [31:0] mem_addr, mem_wdata;
    wire        mem_wen, mem_ren;
    reg [31:0]  mem_rdata;
    reg         mem_ready;

    reg [31:0] mem [0:255];

    gp_dma dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .src(src), .dst(dst), .len(len),
        .done(done), .busy(busy), .irq(irq),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_wen(mem_wen), .mem_ren(mem_ren),
        .mem_rdata(mem_rdata), .mem_ready(mem_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;
    integer i;

    always @* begin
        if (mem_ren)
            mem_rdata = mem[mem_addr[9:2]];
        else
            mem_rdata = 32'h0;
    end

    always @(posedge clk) begin
        if (mem_wen)
            mem[mem_addr[9:2]] <= mem_wdata;
    end

    initial begin
        rst_n = 1'b0; start = 1'b0;
        src = 32'h100; dst = 32'h200; len = 16'd8;
        mem_ready = 1'b1;

        for (i = 0; i < 4; i = i + 1)
            mem[(32'h100 >> 2) + i] = 32'hA000_0000 + i;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        start = 1'b1;
        @(posedge clk); #0; start = 1'b0;

        while (!done) @(posedge clk);

        if (!irq) begin
            $display("[FAIL] irq not asserted");
            fail = fail + 1;
        end
        if (busy) begin
            $display("[FAIL] busy still high");
            fail = fail + 1;
        end

        for (i = 0; i < 2; i = i + 1) begin
            if (mem[(32'h200 >> 2) + i] !== (32'hA000_0000 + i)) begin
                $display("[FAIL] dst[%0d] expected %08h got %08h",
                         i, 32'hA000_0000 + i, mem[(32'h200 >> 2) + i]);
                fail = fail + 1;
            end
        end

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);
        $finish;
    end

    initial begin #500000; $display("[FAIL] TIMEOUT"); $finish; end
endmodule
