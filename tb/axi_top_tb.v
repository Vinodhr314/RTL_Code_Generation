`timescale 1ns/1ps
// axi_top testbench — 1M:2S interconnect
// Verifies write and read routing to both slave ports using inline AXI4-Lite slave models.

// Minimal AXI4-Lite slave: 4 x 32-bit registers
module axil_slave_model (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        awvalid,
    output reg         awready,
    input  wire [31:0] awaddr,
    input  wire        wvalid,
    output reg         wready,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output reg         bvalid,
    input  wire        bready,
    output wire [1:0]  bresp,
    input  wire        arvalid,
    output reg         arready,
    input  wire [31:0] araddr,
    output reg         rvalid,
    input  wire        rready,
    output reg  [31:0] rdata,
    output wire [1:0]  rresp
);
    assign bresp = 2'b00;
    assign rresp = 2'b00;

    reg [31:0] mem [0:3];
    reg [1:0]  wr_state;
    reg [1:0]  rd_state;
    reg [31:0] aw_latch;

    localparam WR_IDLE = 2'd0, WR_DATA = 2'd1, WR_RESP = 2'd2;
    localparam RD_IDLE = 1'd0, RD_DATA = 1'd1;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wr_state <= WR_IDLE; awready <= 0; wready <= 0; bvalid <= 0;
            aw_latch <= 0;
            mem[0] <= 0; mem[1] <= 0; mem[2] <= 0; mem[3] <= 0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    awready <= 1; wready <= 1; bvalid <= 0;
                    if (awvalid && wvalid) begin
                        aw_latch <= awaddr;
                        if (awaddr[3:2] < 4) begin
                            if (wstrb[0]) mem[awaddr[3:2]][7:0]   <= wdata[7:0];
                            if (wstrb[1]) mem[awaddr[3:2]][15:8]  <= wdata[15:8];
                            if (wstrb[2]) mem[awaddr[3:2]][23:16] <= wdata[23:16];
                            if (wstrb[3]) mem[awaddr[3:2]][31:24] <= wdata[31:24];
                        end
                        awready <= 0; wready <= 0; wr_state <= WR_RESP;
                    end else if (awvalid) begin
                        aw_latch <= awaddr; awready <= 0; wr_state <= WR_DATA;
                    end
                end
                WR_DATA: begin
                    wready <= 1;
                    if (wvalid) begin
                        if (aw_latch[3:2] < 4) begin
                            if (wstrb[0]) mem[aw_latch[3:2]][7:0]   <= wdata[7:0];
                            if (wstrb[1]) mem[aw_latch[3:2]][15:8]  <= wdata[15:8];
                            if (wstrb[2]) mem[aw_latch[3:2]][23:16] <= wdata[23:16];
                            if (wstrb[3]) mem[aw_latch[3:2]][31:24] <= wdata[31:24];
                        end
                        wready <= 0; wr_state <= WR_RESP;
                    end
                end
                WR_RESP: begin
                    bvalid <= 1;
                    if (bready) begin bvalid <= 0; wr_state <= WR_IDLE; end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rd_state <= RD_IDLE; arready <= 0; rvalid <= 0; rdata <= 0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    arready <= 1; rvalid <= 0;
                    if (arvalid) begin
                        arready <= 0;
                        rdata   <= (araddr[3:2] < 4) ? mem[araddr[3:2]] : 32'h0;
                        rvalid  <= 1; rd_state <= RD_DATA;
                    end
                end
                RD_DATA: begin
                    if (rready) begin rvalid <= 0; rd_state <= RD_IDLE; end
                end
                default: rd_state <= RD_IDLE;
            endcase
        end
    end
endmodule


module axi_top_tb;

    reg        aclk, aresetn;

    // Master port signals
    reg        m_awvalid; wire m_awready;
    reg [31:0] m_awaddr;
    reg        m_wvalid;  wire m_wready;
    reg [31:0] m_wdata;   reg [3:0] m_wstrb;
    wire       m_bvalid;  reg  m_bready;
    wire [1:0] m_bresp;
    reg        m_arvalid; wire m_arready;
    reg [31:0] m_araddr;
    wire       m_rvalid;  reg  m_rready;
    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;

    // Slave 0
    wire s0_awvalid; wire s0_awready;
    wire [31:0] s0_awaddr;
    wire s0_wvalid;  wire s0_wready;
    wire [31:0] s0_wdata; wire [3:0] s0_wstrb;
    wire s0_bvalid;  wire s0_bready; wire [1:0] s0_bresp;
    wire s0_arvalid; wire s0_arready;
    wire [31:0] s0_araddr;
    wire s0_rvalid;  wire s0_rready;
    wire [31:0] s0_rdata; wire [1:0] s0_rresp;

    // Slave 1
    wire s1_awvalid; wire s1_awready;
    wire [31:0] s1_awaddr;
    wire s1_wvalid;  wire s1_wready;
    wire [31:0] s1_wdata; wire [3:0] s1_wstrb;
    wire s1_bvalid;  wire s1_bready; wire [1:0] s1_bresp;
    wire s1_arvalid; wire s1_arready;
    wire [31:0] s1_araddr;
    wire s1_rvalid;  wire s1_rready;
    wire [31:0] s1_rdata; wire [1:0] s1_rresp;

    axi_top dut (
        .aclk(aclk), .aresetn(aresetn),
        .m_awvalid(m_awvalid), .m_awready(m_awready), .m_awaddr(m_awaddr),
        .m_wvalid(m_wvalid),   .m_wready(m_wready),   .m_wdata(m_wdata), .m_wstrb(m_wstrb),
        .m_bvalid(m_bvalid),   .m_bready(m_bready),   .m_bresp(m_bresp),
        .m_arvalid(m_arvalid), .m_arready(m_arready), .m_araddr(m_araddr),
        .m_rvalid(m_rvalid),   .m_rready(m_rready),   .m_rdata(m_rdata), .m_rresp(m_rresp),
        .s0_awvalid(s0_awvalid), .s0_awready(s0_awready), .s0_awaddr(s0_awaddr),
        .s0_wvalid(s0_wvalid),   .s0_wready(s0_wready),   .s0_wdata(s0_wdata), .s0_wstrb(s0_wstrb),
        .s0_bvalid(s0_bvalid),   .s0_bready(s0_bready),   .s0_bresp(s0_bresp),
        .s0_arvalid(s0_arvalid), .s0_arready(s0_arready), .s0_araddr(s0_araddr),
        .s0_rvalid(s0_rvalid),   .s0_rready(s0_rready),   .s0_rdata(s0_rdata), .s0_rresp(s0_rresp),
        .s1_awvalid(s1_awvalid), .s1_awready(s1_awready), .s1_awaddr(s1_awaddr),
        .s1_wvalid(s1_wvalid),   .s1_wready(s1_wready),   .s1_wdata(s1_wdata), .s1_wstrb(s1_wstrb),
        .s1_bvalid(s1_bvalid),   .s1_bready(s1_bready),   .s1_bresp(s1_bresp),
        .s1_arvalid(s1_arvalid), .s1_arready(s1_arready), .s1_araddr(s1_araddr),
        .s1_rvalid(s1_rvalid),   .s1_rready(s1_rready),   .s1_rdata(s1_rdata), .s1_rresp(s1_rresp)
    );

    axil_slave_model slave0 (
        .aclk(aclk), .aresetn(aresetn),
        .awvalid(s0_awvalid), .awready(s0_awready), .awaddr(s0_awaddr),
        .wvalid(s0_wvalid),   .wready(s0_wready),   .wdata(s0_wdata), .wstrb(s0_wstrb),
        .bvalid(s0_bvalid),   .bready(s0_bready),   .bresp(s0_bresp),
        .arvalid(s0_arvalid), .arready(s0_arready), .araddr(s0_araddr),
        .rvalid(s0_rvalid),   .rready(s0_rready),   .rdata(s0_rdata), .rresp(s0_rresp)
    );

    axil_slave_model slave1 (
        .aclk(aclk), .aresetn(aresetn),
        .awvalid(s1_awvalid), .awready(s1_awready), .awaddr(s1_awaddr),
        .wvalid(s1_wvalid),   .wready(s1_wready),   .wdata(s1_wdata), .wstrb(s1_wstrb),
        .bvalid(s1_bvalid),   .bready(s1_bready),   .bresp(s1_bresp),
        .arvalid(s1_arvalid), .arready(s1_arready), .araddr(s1_araddr),
        .rvalid(s1_rvalid),   .rready(s1_rready),   .rdata(s1_rdata), .rresp(s1_rresp)
    );

    initial aclk = 0;
    always #5 aclk = ~aclk;

    integer fail = 0;

    task axi_write;
        input [31:0] addr, data;
        input [3:0]  strb;
        begin
            @(posedge aclk);
            while (!m_awready || !m_wready) @(posedge aclk);
            #1;
            m_awvalid = 1; m_awaddr = addr;
            m_wvalid  = 1; m_wdata  = data; m_wstrb = strb;
            @(posedge aclk); #0;
            m_awvalid = 0; m_wvalid = 0;
            @(posedge aclk);
            while (!m_bvalid) @(posedge aclk);
            #0; m_bready = 1;
            @(posedge aclk); #0;
            m_bready = 0;
        end
    endtask

    task axi_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            @(posedge aclk);
            while (!m_arready) @(posedge aclk);
            #1;
            m_arvalid = 1; m_araddr = addr;
            @(posedge aclk); #0;
            m_arvalid = 0;
            @(posedge aclk);
            while (!m_rvalid) @(posedge aclk);
            data = m_rdata;
            #0; m_rready = 1;
            @(posedge aclk); #0;
            m_rready = 0;
        end
    endtask

    reg [31:0] rd;

    initial begin
        aresetn   = 0;
        m_awvalid = 0; m_awaddr = 0;
        m_wvalid  = 0; m_wdata  = 0; m_wstrb = 4'hF;
        m_bready  = 0;
        m_arvalid = 0; m_araddr = 0;
        m_rready  = 0;

        @(posedge aclk); @(posedge aclk);
        aresetn = 1;
        @(posedge aclk);

        // --- Slave 0 tests (addr[24]=0: base 32'h00000000) ---
        axi_write(32'h00000000, 32'hAAAA_1111, 4'hF);
        axi_read(32'h00000000, rd);
        if (rd !== 32'hAAAA_1111) begin
            $display("[FAIL] T1: s0 reg0 expected AAAA1111 got %08h", rd);
            fail = fail + 1;
        end

        axi_write(32'h00000004, 32'hBBBB_2222, 4'hF);
        axi_read(32'h00000004, rd);
        if (rd !== 32'hBBBB_2222) begin
            $display("[FAIL] T2: s0 reg1 expected BBBB2222 got %08h", rd);
            fail = fail + 1;
        end

        // --- Slave 1 tests (addr[24]=1: base 32'h01000000) ---
        axi_write(32'h01000000, 32'hCCCC_3333, 4'hF);
        axi_read(32'h01000000, rd);
        if (rd !== 32'hCCCC_3333) begin
            $display("[FAIL] T3: s1 reg0 expected CCCC3333 got %08h", rd);
            fail = fail + 1;
        end

        axi_write(32'h01000004, 32'hDDDD_4444, 4'hF);
        axi_read(32'h01000004, rd);
        if (rd !== 32'hDDDD_4444) begin
            $display("[FAIL] T4: s1 reg1 expected DDDD4444 got %08h", rd);
            fail = fail + 1;
        end

        // --- Cross-check: s0 unchanged after s1 write ---
        axi_read(32'h00000000, rd);
        if (rd !== 32'hAAAA_1111) begin
            $display("[FAIL] T5: s0 reg0 corrupted after s1 write, got %08h", rd);
            fail = fail + 1;
        end

        // --- Cross-check: s1 reg0 unchanged after s0 write to reg1 ---
        axi_read(32'h01000000, rd);
        if (rd !== 32'hCCCC_3333) begin
            $display("[FAIL] T6: s1 reg0 corrupted, got %08h", rd);
            fail = fail + 1;
        end

        // --- Byte-strobe write to s0 ---
        axi_write(32'h00000008, 32'hFF_EE_DD_CC, 4'hF); // write all bytes
        axi_write(32'h00000008, 32'h00_00_00_AA, 4'h1); // write only byte 0
        axi_read(32'h00000008, rd);
        if (rd[7:0] !== 8'hAA) begin
            $display("[FAIL] T7: s0 reg2[7:0] expected AA got %02h", rd[7:0]);
            fail = fail + 1;
        end
        if (rd[31:8] !== 24'hFF_EE_DD) begin
            $display("[FAIL] T7: s0 reg2[31:8] should be FFEEDD got %06h", rd[31:8]);
            fail = fail + 1;
        end

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
