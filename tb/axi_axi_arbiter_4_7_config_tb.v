`timescale 1ns/1ps
module axi_axi_arbiter_4_7_config_tb;

    reg        aclk, aresetn;
    reg [31:0] cfg;

    reg        m0_awvalid; wire m0_awready;
    reg [31:0] m0_awaddr;
    reg        m0_wvalid;  wire m0_wready;
    reg [31:0] m0_wdata;   reg [3:0] m0_wstrb;
    wire       m0_bvalid;  reg m0_bready;
    wire [1:0] m0_bresp;
    reg        m0_arvalid; wire m0_arready;
    reg [31:0] m0_araddr;
    wire       m0_rvalid;  reg m0_rready;
    wire [31:0] m0_rdata;  wire [1:0] m0_rresp;

    reg        m1_awvalid; wire m1_awready;
    reg [31:0] m1_awaddr;
    reg        m1_wvalid;  wire m1_wready;
    reg [31:0] m1_wdata;   reg [3:0] m1_wstrb;
    wire       m1_bvalid;  reg m1_bready;
    wire [1:0] m1_bresp;
    reg        m1_arvalid; wire m1_arready;
    reg [31:0] m1_araddr;
    wire       m1_rvalid;  reg m1_rready;
    wire [31:0] m1_rdata;  wire [1:0] m1_rresp;

    reg        m2_awvalid; wire m2_awready;
    reg [31:0] m2_awaddr;
    reg        m2_wvalid;  wire m2_wready;
    reg [31:0] m2_wdata;   reg [3:0] m2_wstrb;
    wire       m2_bvalid;  reg m2_bready;
    wire [1:0] m2_bresp;
    reg        m2_arvalid; wire m2_arready;
    reg [31:0] m2_araddr;
    wire       m2_rvalid;  reg m2_rready;
    wire [31:0] m2_rdata;  wire [1:0] m2_rresp;

    reg        m3_awvalid; wire m3_awready;
    reg [31:0] m3_awaddr;
    reg        m3_wvalid;  wire m3_wready;
    reg [31:0] m3_wdata;   reg [3:0] m3_wstrb;
    wire       m3_bvalid;  reg m3_bready;
    wire [1:0] m3_bresp;
    reg        m3_arvalid; wire m3_arready;
    reg [31:0] m3_araddr;
    wire       m3_rvalid;  reg m3_rready;
    wire [31:0] m3_rdata;  wire [1:0] m3_rresp;

    wire [2:0] s_grant;

    axi_axi_arbiter_4_7_config dut (
        .aclk(aclk), .aresetn(aresetn), .cfg(cfg),
        .m0_awvalid(m0_awvalid), .m0_awready(m0_awready), .m0_awaddr(m0_awaddr),
        .m0_wvalid(m0_wvalid),   .m0_wready(m0_wready),   .m0_wdata(m0_wdata), .m0_wstrb(m0_wstrb),
        .m0_bvalid(m0_bvalid),   .m0_bready(m0_bready),   .m0_bresp(m0_bresp),
        .m0_arvalid(m0_arvalid), .m0_arready(m0_arready), .m0_araddr(m0_araddr),
        .m0_rvalid(m0_rvalid),   .m0_rready(m0_rready),   .m0_rdata(m0_rdata), .m0_rresp(m0_rresp),
        .m1_awvalid(m1_awvalid), .m1_awready(m1_awready), .m1_awaddr(m1_awaddr),
        .m1_wvalid(m1_wvalid),   .m1_wready(m1_wready),   .m1_wdata(m1_wdata), .m1_wstrb(m1_wstrb),
        .m1_bvalid(m1_bvalid),   .m1_bready(m1_bready),   .m1_bresp(m1_bresp),
        .m1_arvalid(m1_arvalid), .m1_arready(m1_arready), .m1_araddr(m1_araddr),
        .m1_rvalid(m1_rvalid),   .m1_rready(m1_rready),   .m1_rdata(m1_rdata), .m1_rresp(m1_rresp),
        .m2_awvalid(m2_awvalid), .m2_awready(m2_awready), .m2_awaddr(m2_awaddr),
        .m2_wvalid(m2_wvalid),   .m2_wready(m2_wready),   .m2_wdata(m2_wdata), .m2_wstrb(m2_wstrb),
        .m2_bvalid(m2_bvalid),   .m2_bready(m2_bready),   .m2_bresp(m2_bresp),
        .m2_arvalid(m2_arvalid), .m2_arready(m2_arready), .m2_araddr(m2_araddr),
        .m2_rvalid(m2_rvalid),   .m2_rready(m2_rready),   .m2_rdata(m2_rdata), .m2_rresp(m2_rresp),
        .m3_awvalid(m3_awvalid), .m3_awready(m3_awready), .m3_awaddr(m3_awaddr),
        .m3_wvalid(m3_wvalid),   .m3_wready(m3_wready),   .m3_wdata(m3_wdata), .m3_wstrb(m3_wstrb),
        .m3_bvalid(m3_bvalid),   .m3_bready(m3_bready),   .m3_bresp(m3_bresp),
        .m3_arvalid(m3_arvalid), .m3_arready(m3_arready), .m3_araddr(m3_araddr),
        .m3_rvalid(m3_rvalid),   .m3_rready(m3_rready),   .m3_rdata(m3_rdata), .m3_rresp(m3_rresp),
        .s_grant(s_grant)
    );

    initial aclk = 0;
    always #5 aclk = ~aclk;

    integer fail = 0;

    // Arbiter AXI write: assert valid, wait for awready (DUT asserts after grant),
    // then wait for wready (DUT asserts in FSM_WDATA), then wait for bvalid.
    // Keep valid asserted until the corresponding ready is seen (AXI spec).
    // Wait for bvalid BEFORE asserting bready (avoids NBA suppression).
    task m0_write;
        input [31:0] a, d;
        begin
            @(posedge aclk); #1;
            m0_awvalid = 1'b1; m0_awaddr = a;
            m0_wvalid  = 1'b1; m0_wdata  = d; m0_wstrb = 4'hF;
            @(posedge aclk);
            while (!m0_awready) @(posedge aclk);
            #0; m0_awvalid = 1'b0;
            @(posedge aclk);
            while (!m0_wready) @(posedge aclk);
            #0; m0_wvalid = 1'b0;
            @(posedge aclk);
            while (!m0_bvalid) @(posedge aclk);
            #0; m0_bready = 1'b1;
            @(posedge aclk); #0;
            m0_bready = 1'b0;
        end
    endtask

    task m1_write;
        input [31:0] a, d;
        begin
            @(posedge aclk); #1;
            m1_awvalid = 1'b1; m1_awaddr = a;
            m1_wvalid  = 1'b1; m1_wdata  = d; m1_wstrb = 4'hF;
            @(posedge aclk);
            while (!m1_awready) @(posedge aclk);
            #0; m1_awvalid = 1'b0;
            @(posedge aclk);
            while (!m1_wready) @(posedge aclk);
            #0; m1_wvalid = 1'b0;
            @(posedge aclk);
            while (!m1_bvalid) @(posedge aclk);
            #0; m1_bready = 1'b1;
            @(posedge aclk); #0;
            m1_bready = 1'b0;
        end
    endtask

    task m0_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge aclk); #1;
            m0_arvalid = 1'b1; m0_araddr = a;
            @(posedge aclk);
            while (!m0_arready) @(posedge aclk);
            #0; m0_arvalid = 1'b0;
            @(posedge aclk);
            while (!m0_rvalid) @(posedge aclk);
            d = m0_rdata;
            #0; m0_rready = 1'b1;
            @(posedge aclk); #0;
            m0_rready = 1'b0;
        end
    endtask

    task m2_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge aclk); #1;
            m2_arvalid = 1'b1; m2_araddr = a;
            @(posedge aclk);
            while (!m2_arready) @(posedge aclk);
            #0; m2_arvalid = 1'b0;
            @(posedge aclk);
            while (!m2_rvalid) @(posedge aclk);
            d = m2_rdata;
            #0; m2_rready = 1'b1;
            @(posedge aclk); #0;
            m2_rready = 1'b0;
        end
    endtask

    reg [31:0] rd;

    initial begin
        aresetn = 1'b0; cfg = 32'h0;
        m0_awvalid=0; m0_awaddr=0; m0_wvalid=0; m0_wdata=0; m0_wstrb=4'hF; m0_bready=0;
        m0_arvalid=0; m0_araddr=0; m0_rready=0;
        m1_awvalid=0; m1_awaddr=0; m1_wvalid=0; m1_wdata=0; m1_wstrb=4'hF; m1_bready=0;
        m1_arvalid=0; m1_araddr=0; m1_rready=0;
        m2_awvalid=0; m2_awaddr=0; m2_wvalid=0; m2_wdata=0; m2_wstrb=4'hF; m2_bready=0;
        m2_arvalid=0; m2_araddr=0; m2_rready=0;
        m3_awvalid=0; m3_awaddr=0; m3_wvalid=0; m3_wdata=0; m3_wstrb=4'hF; m3_bready=0;
        m3_arvalid=0; m3_araddr=0; m3_rready=0;

        @(posedge aclk); @(posedge aclk);
        aresetn = 1'b1;
        repeat(4) @(posedge aclk);

        // Test 1: M0 write to slave 0 region (addr[31:29]=000)
        m0_write(32'h0000_1000, 32'hABCD_0000);
        $display("Test1: M0 write slave-0 done, s_grant=%0d", s_grant);

        // Test 2: M0 read from slave 2 region (addr[31:29]=010 = 0x4000_0000)
        m0_read(32'h4000_0000, rd);
        if (rd[2:0] !== 3'd2) begin
            $display("[FAIL] Test2: expected slave-2 in rdata[2:0], got %0d", rd[2:0]);
            fail = fail + 1;
        end else
            $display("Test2: M0 read slave-2 ok, rdata=%08h", rd);

        // Test 3: M1 write to slave 3 region (addr[31:29]=011 = 0x6000_0000)
        m1_write(32'h6000_0000, 32'h1111_1111);
        $display("Test3: M1 write slave-3 done");

        // Test 4: M2 read from slave 5 region (addr[31:29]=101 = 0xA000_0000)
        m2_read(32'hA000_0000, rd);
        if (rd[2:0] !== 3'd5) begin
            $display("[FAIL] Test4: expected slave-5 in rdata[2:0], got %0d", rd[2:0]);
            fail = fail + 1;
        end else
            $display("Test4: M2 read slave-5 ok, rdata=%08h", rd);

        // Test 5: Priority mode (cfg[0]=1) M0 write
        cfg = 32'h1;
        m0_write(32'h0000_0000, 32'hFFFF_FFFF);
        $display("Test5: Priority mode M0 write done");

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);

        $finish;
    end

    initial begin
        #200000;
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
