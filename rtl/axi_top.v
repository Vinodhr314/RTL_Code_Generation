// axi_top — AXI4-Lite 1-master / 2-slave interconnect (Verilog-2005)
// Address bit [24] selects slave: 0 → s0, 1 → s1
// Write-select latched on AW handshake; read-select latched on AR handshake.
module axi_top (
    input  wire        aclk,
    input  wire        aresetn,

    // Master port (driven by CPU/DMA)
    input  wire        m_awvalid,
    output wire        m_awready,
    input  wire [31:0] m_awaddr,
    input  wire        m_wvalid,
    output wire        m_wready,
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,
    output wire        m_bvalid,
    input  wire        m_bready,
    output wire [1:0]  m_bresp,
    input  wire        m_arvalid,
    output wire        m_arready,
    input  wire [31:0] m_araddr,
    output wire        m_rvalid,
    input  wire        m_rready,
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,

    // Slave 0 port (addr[24]=0)
    output wire        s0_awvalid,
    input  wire        s0_awready,
    output wire [31:0] s0_awaddr,
    output wire        s0_wvalid,
    input  wire        s0_wready,
    output wire [31:0] s0_wdata,
    output wire [3:0]  s0_wstrb,
    input  wire        s0_bvalid,
    output wire        s0_bready,
    input  wire [1:0]  s0_bresp,
    output wire        s0_arvalid,
    input  wire        s0_arready,
    output wire [31:0] s0_araddr,
    input  wire        s0_rvalid,
    output wire        s0_rready,
    input  wire [31:0] s0_rdata,
    input  wire [1:0]  s0_rresp,

    // Slave 1 port (addr[24]=1)
    output wire        s1_awvalid,
    input  wire        s1_awready,
    output wire [31:0] s1_awaddr,
    output wire        s1_wvalid,
    input  wire        s1_wready,
    output wire [31:0] s1_wdata,
    output wire [3:0]  s1_wstrb,
    input  wire        s1_bvalid,
    output wire        s1_bready,
    input  wire [1:0]  s1_bresp,
    output wire        s1_arvalid,
    input  wire        s1_arready,
    output wire [31:0] s1_araddr,
    input  wire        s1_rvalid,
    output wire        s1_rready,
    input  wire [31:0] s1_rdata,
    input  wire [1:0]  s1_rresp
);

    // ----------------------------------------------------------------
    // Write-channel routing: latch slave select on AW handshake
    // ----------------------------------------------------------------
    reg  sel_wr;
    reg  wr_active;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            sel_wr    <= 1'b0;
            wr_active <= 1'b0;
        end else begin
            if (m_awvalid && m_awready) begin
                sel_wr    <= m_awaddr[24];
                wr_active <= 1'b1;
            end
            if (m_bvalid && m_bready)
                wr_active <= 1'b0;
        end
    end

    // AW channel: route using current awaddr (pre-handshake)
    assign s0_awvalid = m_awvalid && !m_awaddr[24];
    assign s1_awvalid = m_awvalid &&  m_awaddr[24];
    assign m_awready  = m_awaddr[24] ? s1_awready : s0_awready;
    assign s0_awaddr  = m_awaddr;
    assign s1_awaddr  = m_awaddr;

    // W and B channels: use latched sel_wr (valid after AW handshake)
    wire wr_sel = wr_active ? sel_wr : m_awaddr[24];

    assign s0_wvalid  = m_wvalid && !wr_sel;
    assign s1_wvalid  = m_wvalid &&  wr_sel;
    assign m_wready   = wr_sel ? s1_wready : s0_wready;
    assign s0_wdata   = m_wdata;
    assign s1_wdata   = m_wdata;
    assign s0_wstrb   = m_wstrb;
    assign s1_wstrb   = m_wstrb;

    assign m_bvalid   = wr_sel ? s1_bvalid  : s0_bvalid;
    assign s0_bready  = m_bready && !wr_sel;
    assign s1_bready  = m_bready &&  wr_sel;
    assign m_bresp    = wr_sel ? s1_bresp   : s0_bresp;

    // ----------------------------------------------------------------
    // Read-channel routing: latch slave select on AR handshake
    // ----------------------------------------------------------------
    reg  sel_rd;
    reg  rd_active;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            sel_rd    <= 1'b0;
            rd_active <= 1'b0;
        end else begin
            if (m_arvalid && m_arready) begin
                sel_rd    <= m_araddr[24];
                rd_active <= 1'b1;
            end
            if (m_rvalid && m_rready)
                rd_active <= 1'b0;
        end
    end

    wire rd_sel = rd_active ? sel_rd : m_araddr[24];

    assign s0_arvalid = m_arvalid && !m_araddr[24];
    assign s1_arvalid = m_arvalid &&  m_araddr[24];
    assign m_arready  = m_araddr[24] ? s1_arready : s0_arready;
    assign s0_araddr  = m_araddr;
    assign s1_araddr  = m_araddr;

    assign m_rvalid   = rd_sel ? s1_rvalid  : s0_rvalid;
    assign s0_rready  = m_rready && !rd_sel;
    assign s1_rready  = m_rready &&  rd_sel;
    assign m_rdata    = rd_sel ? s1_rdata   : s0_rdata;
    assign m_rresp    = rd_sel ? s1_rresp   : s0_rresp;

endmodule
