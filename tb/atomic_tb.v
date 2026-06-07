`timescale 1ns/1ps
module atomic_tb;

    reg        clk, rst_n;
    reg [2:0]  amo_op;
    reg [31:0] addr, wdata;
    reg        valid;
    wire [31:0] rdata;
    wire        success, done;

    atomic dut (
        .clk(clk), .rst_n(rst_n),
        .amo_op(amo_op), .addr(addr), .wdata(wdata), .valid(valid),
        .rdata(rdata), .success(success), .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    // Issue one AMO operation and wait for done
    task do_amo;
        input [2:0]  op;
        input [31:0] a, d;
        begin
            @(posedge clk); #1;
            amo_op = op;
            addr   = a;
            wdata  = d;
            valid  = 1'b1;
            @(posedge clk); #0;
            valid  = 1'b0;
            // Wait for done
            @(posedge clk);
            if (!done) @(posedge clk);
        end
    endtask

    initial begin
        // Reset
        rst_n  = 1'b0;
        amo_op = 3'd0;
        addr   = 32'h0;
        wdata  = 32'h0;
        valid  = 1'b0;

        // Hold reset for 2+ clock edges (sync reset lesson)
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // ------------------------------------------------
        // Test 1: LR — load reservation at addr 0x100
        // ------------------------------------------------
        do_amo(3'd0, 32'h100, 32'h0);  // LR
        // done should be 1 on cycle after valid
        if (!done) begin
            $display("[FAIL] Test1: LR done not asserted");
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 2: SC — store-conditional should succeed (addr matches)
        // ------------------------------------------------
        do_amo(3'd1, 32'h100, 32'hDEAD_BEEF);  // SC
        if (!done || !success) begin
            $display("[FAIL] Test2: SC should succeed, done=%b success=%b", done, success);
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 3: SC — should fail (reservation cleared)
        // ------------------------------------------------
        do_amo(3'd1, 32'h100, 32'hCAFE_BABE);  // SC again
        if (!done || success) begin
            $display("[FAIL] Test3: SC should fail after reservation cleared, done=%b success=%b", done, success);
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 4: AMOSWAP
        // ------------------------------------------------
        // First LR to set reservation value
        do_amo(3'd0, 32'h200, 32'h0);    // LR addr=0x200 (sets resv_addr)
        @(posedge clk); #1;
        // AMOSWAP: resv_data <- wdata=0x5555, rdata <- old resv_data
        do_amo(3'd2, 32'h200, 32'h5555_5555);  // AMOSWAP
        if (!done) begin
            $display("[FAIL] Test4: AMOSWAP done not asserted");
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 5: AMOADD
        // ------------------------------------------------
        // resv_data is now 0x5555_5555
        // LR first to verify
        do_amo(3'd3, 32'h200, 32'h0000_0001);  // AMOADD: resv+=1
        if (!done) begin
            $display("[FAIL] Test5: AMOADD done not asserted");
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 6: AMOOR
        // ------------------------------------------------
        do_amo(3'd5, 32'h200, 32'hF000_0000);  // AMOOR
        if (!done) begin
            $display("[FAIL] Test6: AMOOR done not asserted");
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 7: AMOXOR
        // ------------------------------------------------
        do_amo(3'd6, 32'h200, 32'hFFFF_FFFF);  // AMOXOR
        if (!done) begin
            $display("[FAIL] Test7: AMOXOR done not asserted");
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 8: AMOAND
        // ------------------------------------------------
        do_amo(3'd4, 32'h200, 32'h0F0F_0F0F);  // AMOAND
        if (!done) begin
            $display("[FAIL] Test8: AMOAND done not asserted");
            fail = fail + 1;
        end

        // ------------------------------------------------
        // Test 9: LR then SC with wrong address — should fail
        // ------------------------------------------------
        do_amo(3'd0, 32'hABC, 32'h0);   // LR at 0xABC
        do_amo(3'd1, 32'hDEF, 32'h999); // SC at different addr
        if (success) begin
            $display("[FAIL] Test9: SC should fail with wrong address, success=%b", success);
            fail = fail + 1;
        end

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);

        $finish;
    end

    initial begin
        #50000;
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
