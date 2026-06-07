// ddr3_controller — AXI4 slave to DDR3 stub (Verilog-2005)
// 256-word memory; active only when init_done=1.
module ddr3_controller (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        awvalid,
    output reg         awready,
    input  wire [31:0] awaddr,
    input  wire [2:0]  awprot,
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
    input  wire [2:0]  arprot,
    output reg         rvalid,
    input  wire        rready,
    output reg  [31:0] rdata,
    output wire [1:0]  rresp,
    input  wire        init_done,
    output wire        ddr_ck,
    output wire        ddr_cke,
    output reg  [14:0] ddr_addr,
    output reg  [2:0]  ddr_ba,
    inout  wire [31:0] ddr_dq
);
    assign bresp = 2'b00;
    assign rresp = 2'b00;
    assign ddr_ck  = aclk;
    assign ddr_cke = init_done;

    reg [31:0] mem [0:255];
    reg [31:0] dq_out;
    reg        dq_oe;

    assign ddr_dq = dq_oe ? dq_out : 32'hzzzz_zzzz;

    localparam WR_IDLE = 2'd0;
    localparam WR_RESP = 2'd1;
    localparam RD_IDLE = 2'd0;
    localparam RD_DATA = 2'd1;

    reg [1:0] wr_state;
    reg [1:0] rd_state;
    reg [31:0] addr_latch;

    wire enabled = init_done;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wr_state <= WR_IDLE;
            rd_state <= RD_IDLE;
            awready  <= 1'b0;
            wready   <= 1'b0;
            bvalid   <= 1'b0;
            arready  <= 1'b0;
            rvalid   <= 1'b0;
            rdata    <= 32'h0;
            ddr_addr <= 15'h0;
            ddr_ba   <= 3'h0;
            dq_out   <= 32'h0;
            dq_oe    <= 1'b0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    bvalid  <= 1'b0;
                    awready <= enabled;
                    wready  <= enabled;
                    dq_oe   <= 1'b0;
                    if (enabled && awvalid && wvalid) begin
                        addr_latch <= awaddr;
                        if (awaddr[31:10] == 22'h0) begin
                            if (wstrb[0]) mem[awaddr[9:2]][7:0]   <= wdata[7:0];
                            if (wstrb[1]) mem[awaddr[9:2]][15:8]  <= wdata[15:8];
                            if (wstrb[2]) mem[awaddr[9:2]][23:16] <= wdata[23:16];
                            if (wstrb[3]) mem[awaddr[9:2]][31:24] <= wdata[31:24];
                        end
                        ddr_addr <= awaddr[16:2];
                        ddr_ba   <= awaddr[19:17];
                        dq_out   <= wdata;
                        dq_oe    <= 1'b1;
                        awready  <= 1'b0;
                        wready   <= 1'b0;
                        wr_state <= WR_RESP;
                    end
                end
                WR_RESP: begin
                    dq_oe  <= 1'b0;
                    bvalid <= 1'b1;
                    if (bready) begin
                        bvalid   <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase

            case (rd_state)
                RD_IDLE: begin
                    rvalid  <= 1'b0;
                    arready <= enabled;
                    if (enabled && arvalid) begin
                        addr_latch <= araddr;
                        ddr_addr   <= araddr[16:2];
                        ddr_ba     <= araddr[19:17];
                        arready    <= 1'b0;
                        rd_state   <= RD_DATA;
                    end
                end
                RD_DATA: begin
                    if (addr_latch[31:10] == 22'h0)
                        rdata <= mem[addr_latch[9:2]];
                    else
                        rdata <= 32'h0;
                    rvalid <= 1'b1;
                    if (rready) begin
                        rvalid   <= 1'b0;
                        rd_state <= RD_IDLE;
                    end
                end
                default: rd_state <= RD_IDLE;
            endcase
        end
    end
endmodule
