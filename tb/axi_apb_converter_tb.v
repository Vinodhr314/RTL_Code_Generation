`timescale 1ns/1ps
module axi_apb_converter_tb;

    reg        aclk, aresetn;
    reg        awvalid; wire awready;
    reg [31:0] awaddr;
    reg        wvalid;  wire wready;
    reg [31:0] wdata;   reg [3:0] wstrb;
    wire       bvalid;  reg bready;
    wire [1:0] bresp;
    reg        arvalid; wire arready;
    reg [31:0] araddr;
    wire       rvalid;  reg rready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        pclk, presetn;
    wire        psel, penable, pwrite;
    wire [31:0] paddr, pwdata;
    reg  [31:0] prdata;
    reg         pready;

    axi_apb_converter dut (
        .aclk(aclk), .aresetn(aresetn),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr),
        .wvalid(wvalid),   .wready(wready),   .wdata(wdata), .wstrb(wstrb),
        .bvalid(bvalid),   .bready(bready),   .bresp(bresp),
        .arvalid(arvalid), .arready(arready), .araddr(araddr),
        .rvalid(rvalid),   .rready(rready),   .rdata(rdata), .rresp(rresp),
        .pclk(pclk), .presetn(presetn),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready)
    );

    initial aclk = 0;
    always #5 aclk = ~aclk;

    integer fail = 0;

    // APB slave: respond with pready one cycle after ACCESS starts
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            pready <= 1'b0;
            prdata <= 32'h0;
        end else begin
            if (psel && penable) begin
                pready <= 1'b1;
                if (!pwrite)
                    prdata <= 32'hBEEF_0000 | paddr[7:0];
            end else begin
                pready <= 1'b0;
            end
        end
    end

    // AXI write:
    //   DUT only asserts awready/wready after seeing awvalid/wvalid.
    //   Drive valid first, then wait for ready (same pattern as arbiter).
    //   Wait for bvalid BEFORE setting bready (avoid NBA suppression).
    task axi_write;
        input [31:0] a, d;
        begin
            @(posedge aclk); #1;
            awvalid = 1'b1; awaddr = a;
            wvalid  = 1'b1; wdata  = d; wstrb = 4'hF;
            // DUT will assert awready and wready when it sees valid in ST_IDLE
            @(posedge aclk);
            while (!awready || !wready) @(posedge aclk);
            #0;
            awvalid = 1'b0;
            wvalid  = 1'b0;
            // Wait for write response — don't set bready until bvalid is seen
            @(posedge aclk);
            while (!bvalid) @(posedge aclk);
            #0; bready = 1'b1;
            @(posedge aclk); #0;
            bready = 1'b0;
        end
    endtask

    // AXI read: same pattern
    task axi_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge aclk); #1;
            arvalid = 1'b1; araddr = a;
            @(posedge aclk);
            while (!arready) @(posedge aclk);
            #0;
            arvalid = 1'b0;
            @(posedge aclk);
            while (!rvalid) @(posedge aclk);
            d = rdata;
            #0; rready = 1'b1;
            @(posedge aclk); #0;
            rready = 1'b0;
        end
    endtask

    reg [31:0] rd;

    initial begin
        aresetn = 1'b0;
        awvalid = 1'b0; awaddr = 32'h0;
        wvalid  = 1'b0; wdata  = 32'h0; wstrb = 4'hF;
        bready  = 1'b0;
        arvalid = 1'b0; araddr = 32'h0;
        rready  = 1'b0;

        @(posedge aclk); @(posedge aclk);
        aresetn = 1'b1;
        @(posedge aclk);

        // Test 1: AXI write -> APB write
        axi_write(32'h0000_0010, 32'hDEAD_BEEF);
        $display("Test1: write at 0x10 done");

        // Test 2: AXI read -> APB read returns BEEF_0010
        axi_read(32'h0000_0010, rd);
        if (rd !== (32'hBEEF_0000 | 32'h10)) begin
            $display("[FAIL] Test2: expected BEEF0010 got %08h", rd);
            fail = fail + 1;
        end

        // Test 3: write at 0x20, read returns BEEF_0020
        axi_write(32'h0000_0020, 32'h1234_5678);
        axi_read(32'h0000_0020, rd);
        if (rd !== (32'hBEEF_0000 | 32'h20)) begin
            $display("[FAIL] Test3: expected BEEF0020 got %08h", rd);
            fail = fail + 1;
        end

        // Test 4: sequential reads
        axi_read(32'h0000_0004, rd);
        if (rd !== (32'hBEEF_0000 | 32'h04)) begin
            $display("[FAIL] Test4: expected BEEF0004 got %08h", rd);
            fail = fail + 1;
        end

        // Test 5: read at addr 0
        axi_read(32'h0000_0000, rd);
        if (rd !== 32'hBEEF_0000) begin
            $display("[FAIL] Test5: expected BEEF0000 got %08h", rd);
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
