`timescale 1ns/1ps
module apb_arbiter_tb;

    parameter M = 2;

    reg          clk, rst_n;
    reg  [M-1:0] m_req;
    wire [M-1:0] m_grant;
    reg  [M*12-1:0] m_paddr;
    wire [11:0]  s_paddr;
    wire         s_psel, s_penable, s_pwrite;
    wire [31:0]  s_pwdata;
    reg  [31:0]  s_prdata;
    reg          s_pready;

    apb_arbiter #(.M(M)) dut (
        .clk(clk), .rst_n(rst_n),
        .m_req(m_req), .m_grant(m_grant),
        .m_paddr(m_paddr),
        .s_paddr(s_paddr), .s_psel(s_psel), .s_penable(s_penable),
        .s_pwrite(s_pwrite), .s_pwdata(s_pwdata),
        .s_prdata(s_prdata), .s_pready(s_pready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    // APB slave model: assert pready one cycle after ACCESS starts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s_pready <= 1'b0;
        else if (s_psel && s_penable)
            s_pready <= 1'b1;
        else
            s_pready <= 1'b0;
    end

    // Issue request from master idx and wait for full APB cycle
    task apb_request;
        input integer  master_idx;
        input [11:0]   addr;
        begin
            @(posedge clk); #1;
            m_req              = {M{1'b0}};
            m_req[master_idx]  = 1'b1;
            if (master_idx == 0)
                m_paddr[11:0]  = addr;
            else
                m_paddr[23:12] = addr;

            // Wait for grant
            @(posedge clk);
            while (!m_grant[master_idx]) @(posedge clk);

            // Wait for APB ACCESS + pready
            @(posedge clk); // SETUP cycle
            @(posedge clk); // ACCESS cycle (pready asserted after this)
            @(posedge clk); // pready becomes visible (registered)
            while (!s_pready) @(posedge clk);

            #0;
            m_req = {M{1'b0}};
            @(posedge clk);
        end
    endtask

    initial begin
        rst_n    = 1'b0;
        m_req    = {M{1'b0}};
        m_paddr  = {(M*12){1'b0}};
        s_prdata = 32'hDEAD_CAFE;
        s_pready = 1'b0;

        // Sync reset: 2+ clock edges
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // ------------------------------------------------
        // Test 1: Master 0 request
        // ------------------------------------------------
        apb_request(0, 12'hABC);
        $display("Test1: M0 granted, s_paddr=%03h", s_paddr);

        // ------------------------------------------------
        // Test 2: Master 1 request
        // ------------------------------------------------
        apb_request(1, 12'h123);
        $display("Test2: M1 granted, s_paddr=%03h", s_paddr);

        // ------------------------------------------------
        // Test 3: Both masters request simultaneously — M0 wins (fixed priority)
        // ------------------------------------------------
        @(posedge clk); #1;
        m_req         = 2'b11;
        m_paddr[11:0] = 12'hF00;
        m_paddr[23:12]= 12'hBA0;

        // Wait for grant
        @(posedge clk);
        while (!(|m_grant)) @(posedge clk);

        if (!m_grant[0]) begin
            $display("[FAIL] Test3: M0 should win priority contest, grant=%b", m_grant);
            fail = fail + 1;
        end
        // Wait for SETUP phase to latch address
        @(posedge clk);
        if (s_paddr !== 12'hF00) begin
            $display("[FAIL] Test3: s_paddr should be F00, got %03h", s_paddr);
            fail = fail + 1;
        end

        // Let transaction complete
        repeat(6) @(posedge clk);
        m_req = {M{1'b0}};
        repeat(2) @(posedge clk);

        // ------------------------------------------------
        // Test 4: Bus idle — s_psel should be deasserted
        // ------------------------------------------------
        @(posedge clk); #1;
        if (s_psel) begin
            $display("[FAIL] Test4: s_psel should be 0 when idle, got %b", s_psel);
            fail = fail + 1;
        end

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);

        $finish;
    end

    initial begin
        #100000;
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
