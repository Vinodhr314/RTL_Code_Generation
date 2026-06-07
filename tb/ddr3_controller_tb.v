`timescale 1ns/1ps
module ddr3_controller_tb;

    reg        aclk, aresetn, init_done;
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
    wire        ddr_ck, ddr_cke;
    wire [14:0] ddr_addr;
    wire [2:0]  ddr_ba;
    wire [31:0] ddr_dq;

    ddr3_controller dut (
        .aclk(aclk), .aresetn(aresetn), .init_done(init_done),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awprot(awprot),
        .wvalid(wvalid), .wready(wready), .wdata(wdata), .wstrb(wstrb),
        .bvalid(bvalid), .bready(bready), .bresp(bresp),
        .arvalid(arvalid), .arready(arready), .araddr(araddr), .arprot(arprot),
        .rvalid(rvalid), .rready(rready), .rdata(rdata), .rresp(rresp),
        .ddr_ck(ddr_ck), .ddr_cke(ddr_cke), .ddr_addr(ddr_addr), .ddr_ba(ddr_ba), .ddr_dq(ddr_dq)
    );

    initial aclk = 0;
    always #5 aclk = ~aclk;

    integer fail = 0;
    reg [31:0] rd;

    task axi_write;
        input [31:0] a, d;
        begin
            @(posedge aclk);
            while (!awready || !wready) @(posedge aclk);
            #1;
            awvalid = 1'b1; awaddr = a; awprot = 3'h0;
            wvalid  = 1'b1; wdata  = d; wstrb  = 4'hF;
            @(posedge aclk); #0;
            awvalid = 1'b0; wvalid = 1'b0;
            @(posedge aclk);
            while (!bvalid) @(posedge aclk);
            #0; bready = 1'b1;
            @(posedge aclk); #0; bready = 1'b0;
        end
    endtask

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
            @(posedge aclk); #0; rready = 1'b0;
        end
    endtask

    initial begin
        aresetn = 1'b0; init_done = 1'b0;
        awvalid = 1'b0; awaddr = 32'h0; awprot = 3'h0;
        wvalid  = 1'b0; wdata  = 32'h0; wstrb  = 4'hF;
        bready  = 1'b0;
        arvalid = 1'b0; araddr = 32'h0; arprot = 3'h0;
        rready  = 1'b0;

        @(posedge aclk); @(posedge aclk);
        aresetn = 1'b1; init_done = 1'b1;
        @(posedge aclk);

        axi_write(32'h100, 32'hCAFE_BABE);
        axi_read(32'h100, rd);
        if (rd !== 32'hCAFE_BABE) begin
            $display("[FAIL] readback expected CAFEBABE got %08h", rd);
            fail = fail + 1;
        end
        if (!ddr_cke) begin
            $display("[FAIL] ddr_cke should be high when init_done");
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
