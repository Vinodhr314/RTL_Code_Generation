`timescale 1ns/1ps
module axi_tb;

    reg        aclk, aresetn;
    reg        awvalid; wire awready;
    reg [31:0] awaddr;  reg [2:0] awprot;
    reg        wvalid;  wire wready;
    reg [31:0] wdata;   reg [3:0] wstrb;
    wire       bvalid;  reg bready;
    wire [1:0] bresp;
    reg        arvalid; wire arready;
    reg [31:0] araddr;  reg [2:0] arprot;
    wire       rvalid;  reg rready;
    wire [31:0] rdata;
    wire [1:0]  rresp;

    axi dut (
        .aclk(aclk), .aresetn(aresetn),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awprot(awprot),
        .wvalid(wvalid),   .wready(wready),   .wdata(wdata),   .wstrb(wstrb),
        .bvalid(bvalid),   .bready(bready),   .bresp(bresp),
        .arvalid(arvalid), .arready(arready), .araddr(araddr), .arprot(arprot),
        .rvalid(rvalid),   .rready(rready),   .rdata(rdata),   .rresp(rresp)
    );

    initial aclk = 0;
    always #5 aclk = ~aclk;

    integer fail = 0;

    // AXI write:
    //   1. Wait for DUT ready BEFORE driving valid (avoids stale-ready issue)
    //   2. Wait for bvalid BEFORE setting bready (avoids NBA suppression)
    task axi_write;
        input [31:0] a, d;
        input [3:0]  s;
        begin
            @(posedge aclk);
            while (!awready || !wready) @(posedge aclk);
            #1;
            awvalid = 1'b1; awaddr = a; awprot = 3'h0;
            wvalid  = 1'b1; wdata  = d; wstrb  = s;
            @(posedge aclk); #0;
            awvalid = 1'b0;
            wvalid  = 1'b0;
            // Wait for bvalid BEFORE asserting bready
            @(posedge aclk);
            while (!bvalid) @(posedge aclk);
            #0; bready = 1'b1;
            @(posedge aclk); #0;
            bready = 1'b0;
        end
    endtask

    // AXI read:
    //   Same approach: wait for DUT arready, then wait for rvalid before rready
    task axi_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge aclk);
            while (!arready) @(posedge aclk);
            #1;
            arvalid = 1'b1; araddr = a; arprot = 3'h0;
            @(posedge aclk); #0;
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
        awvalid = 1'b0; awaddr = 32'h0; awprot = 3'h0;
        wvalid  = 1'b0; wdata  = 32'h0; wstrb  = 4'hF;
        bready  = 1'b0;
        arvalid = 1'b0; araddr = 32'h0; arprot = 3'h0;
        rready  = 1'b0;

        @(posedge aclk); @(posedge aclk);
        aresetn = 1'b1;
        @(posedge aclk);

        // Test 1: Write reg 0
        axi_write(32'h00, 32'hDEAD_BEEF, 4'hF);

        // Test 2: Read back reg 0
        axi_read(32'h00, rd);
        if (rd !== 32'hDEAD_BEEF) begin
            $display("[FAIL] Test2: reg0 expected DEADBEEF got %08h", rd);
            fail = fail + 1;
        end

        // Test 3: Write and read reg 1
        axi_write(32'h04, 32'hCAFE_BABE, 4'hF);
        axi_read(32'h04, rd);
        if (rd !== 32'hCAFE_BABE) begin
            $display("[FAIL] Test3: reg1 expected CAFEBABE got %08h", rd);
            fail = fail + 1;
        end

        // Test 4: Write and read reg 2
        axi_write(32'h08, 32'h1234_5678, 4'hF);
        axi_read(32'h08, rd);
        if (rd !== 32'h1234_5678) begin
            $display("[FAIL] Test4: reg2 expected 12345678 got %08h", rd);
            fail = fail + 1;
        end

        // Test 5: Write and read reg 3
        axi_write(32'h0C, 32'hABCD_EF01, 4'hF);
        axi_read(32'h0C, rd);
        if (rd !== 32'hABCD_EF01) begin
            $display("[FAIL] Test5: reg3 expected ABCDEF01 got %08h", rd);
            fail = fail + 1;
        end

        // Test 6: reg 0 still holds value
        axi_read(32'h00, rd);
        if (rd !== 32'hDEAD_BEEF) begin
            $display("[FAIL] Test6: reg0 should still be DEADBEEF got %08h", rd);
            fail = fail + 1;
        end

        // Test 7: Byte-strobe write (lower byte only)
        axi_write(32'h00, 32'hXXXX_XX55, 4'h1);
        axi_read(32'h00, rd);
        if (rd[7:0] !== 8'h55) begin
            $display("[FAIL] Test7: reg0[7:0] expected 55 got %02h", rd[7:0]);
            fail = fail + 1;
        end
        if (rd[31:8] !== 24'hDEADBE) begin
            $display("[FAIL] Test7: reg0[31:8] should be unchanged, got %06h", rd[31:8]);
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
