`timescale 1ns/1ps
module async_fifo_tb;

    reg        wclk, wrst_n, winc;
    reg [31:0] wdata;
    reg        rclk, rrst_n, rinc;
    wire [31:0] rdata;
    wire        wfull, rempty;

    async_fifo #(.DEPTH(16), .AWIDTH(4)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata),
        .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc),
        .rdata(rdata), .wfull(wfull), .rempty(rempty)
    );

    // Two clock domains
    initial wclk = 0;
    always #5  wclk = ~wclk;   // 100 MHz write clock

    initial rclk = 0;
    always #7  rclk = ~rclk;   //  ~71 MHz read clock

    integer fail = 0;
    integer i;
    reg [31:0] expected [0:15];

    // Write one word (keeps winc high for one wclk period)
    task write_word;
        input [31:0] d;
        begin
            @(posedge wclk); #1;
            wdata = d;
            winc  = 1'b1;
            @(posedge wclk); #1;
            winc  = 1'b0;
        end
    endtask

    // Read one word: rinc goes high for one rclk cycle.
    // rdata is async (mem[rptr_bin]) — capture BEFORE rinc increments rptr.
    task read_and_check;
        input [31:0] exp;
        input integer idx;
        reg [31:0] captured;
        begin
            // rdata shows mem[rptr_bin] right now (async).
            // Capture it, then assert rinc.
            @(posedge rclk); #1;
            captured = rdata;
            if (captured !== exp) begin
                $display("[FAIL] Read[%0d]: expected %08h got %08h", idx, exp, captured);
                fail = fail + 1;
            end
            rinc = 1'b1;
            @(posedge rclk); #1;
            rinc = 1'b0;
        end
    endtask

    initial begin
        wrst_n = 1'b0; rrst_n = 1'b0;
        winc   = 1'b0; rinc   = 1'b0;
        wdata  = 32'h0;

        // Sync reset: hold low for >= 2 clock edges on each domain
        @(posedge wclk); @(posedge wclk);
        @(posedge rclk); @(posedge rclk);
        wrst_n = 1'b1;
        rrst_n = 1'b1;

        // Allow sync stages to propagate
        repeat(6) @(posedge wclk);
        repeat(6) @(posedge rclk);

        // ------------------------------------------------
        // Test 1: FIFO should be empty after reset
        // ------------------------------------------------
        if (!rempty) begin
            $display("[FAIL] Test1: FIFO should be empty after reset, rempty=%b", rempty);
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 2: Write 8 words
        // ------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            expected[i] = 32'hA000_0000 | i[31:0];
            write_word(expected[i]);
        end

        // Allow write pointers to sync into read domain (2 rclk cycles + margin)
        repeat(10) @(posedge rclk);

        // FIFO should NOT be empty
        if (rempty) begin
            $display("[FAIL] Test2: FIFO should not be empty after 8 writes, rempty=%b", rempty);
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 3: Read back 8 words and verify
        // rdata is async: mem[rptr_bin]. After rinc posedge, rptr_bin advances.
        // ------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            read_and_check(expected[i], i);
        end

        // Allow read pointers to sync into write domain
        repeat(10) @(posedge rclk);
        repeat(6)  @(posedge wclk);

        // ------------------------------------------------
        // Test 4: FIFO should be empty again
        // ------------------------------------------------
        if (!rempty) begin
            $display("[FAIL] Test4: FIFO should be empty after draining, rempty=%b", rempty);
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 5: Write until full (16 entries total from empty state)
        // ------------------------------------------------
        for (i = 0; i < 16; i = i + 1) begin
            expected[i] = 32'hBEEF_0000 | i[31:0];
            if (!wfull)
                write_word(expected[i]);
        end

        // Allow wfull to register (1 wclk cycle)
        repeat(4) @(posedge wclk);

        if (!wfull) begin
            $display("[FAIL] Test5: FIFO should be full after 16 writes, wfull=%b", wfull);
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Result
        // ------------------------------------------------
        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);

        $finish;
    end

    // Timeout guard
    initial begin
        #200000;
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
