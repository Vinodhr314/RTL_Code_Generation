// AXI4-Lite slave stub — 4 x 32-bit registers
// Verilog-2005 synthesizable
module axi (
    input  wire        aclk,
    input  wire        aresetn,
    // Write address channel
    input  wire        awvalid,
    output reg         awready,
    input  wire [31:0] awaddr,
    input  wire [2:0]  awprot,
    // Write data channel
    input  wire        wvalid,
    output reg         wready,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    // Write response channel
    output reg         bvalid,
    input  wire        bready,
    output wire [1:0]  bresp,
    // Read address channel
    input  wire        arvalid,
    output reg         arready,
    input  wire [31:0] araddr,
    input  wire [2:0]  arprot,
    // Read data channel
    output reg         rvalid,
    input  wire        rready,
    output reg  [31:0] rdata,
    output wire [1:0]  rresp
);

    assign bresp = 2'b00; // OKAY
    assign rresp = 2'b00; // OKAY

    // 4 x 32-bit register bank
    reg [31:0] regfile [0:3];

    // Write FSM
    localparam WR_IDLE   = 2'd0;
    localparam WR_DATA   = 2'd1;
    localparam WR_RESP   = 2'd2;

    reg [1:0]  wr_state;
    reg [31:0] aw_addr_latch;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wr_state     <= WR_IDLE;
            awready      <= 1'b0;
            wready       <= 1'b0;
            bvalid       <= 1'b0;
            aw_addr_latch<= 32'h0;
            regfile[0]   <= 32'h0;
            regfile[1]   <= 32'h0;
            regfile[2]   <= 32'h0;
            regfile[3]   <= 32'h0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    awready <= 1'b1;
                    wready  <= 1'b1;
                    bvalid  <= 1'b0;
                    if (awvalid && wvalid) begin
                        aw_addr_latch <= awaddr;
                        // Apply write with byte strobes
                        if (awaddr[3:2] < 4) begin
                            if (wstrb[0]) regfile[awaddr[3:2]][7:0]   <= wdata[7:0];
                            if (wstrb[1]) regfile[awaddr[3:2]][15:8]  <= wdata[15:8];
                            if (wstrb[2]) regfile[awaddr[3:2]][23:16] <= wdata[23:16];
                            if (wstrb[3]) regfile[awaddr[3:2]][31:24] <= wdata[31:24];
                        end
                        awready <= 1'b0;
                        wready  <= 1'b0;
                        wr_state <= WR_RESP;
                    end else if (awvalid) begin
                        aw_addr_latch <= awaddr;
                        awready <= 1'b0;
                        wr_state <= WR_DATA;
                    end
                end
                WR_DATA: begin
                    wready <= 1'b1;
                    if (wvalid) begin
                        if (aw_addr_latch[3:2] < 4) begin
                            if (wstrb[0]) regfile[aw_addr_latch[3:2]][7:0]   <= wdata[7:0];
                            if (wstrb[1]) regfile[aw_addr_latch[3:2]][15:8]  <= wdata[15:8];
                            if (wstrb[2]) regfile[aw_addr_latch[3:2]][23:16] <= wdata[23:16];
                            if (wstrb[3]) regfile[aw_addr_latch[3:2]][31:24] <= wdata[31:24];
                        end
                        wready   <= 1'b0;
                        wr_state <= WR_RESP;
                    end
                end
                WR_RESP: begin
                    bvalid <= 1'b1;
                    if (bready) begin
                        bvalid   <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // Read FSM
    localparam RD_IDLE = 1'b0;
    localparam RD_DATA = 1'b1;

    reg rd_state;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rd_state <= RD_IDLE;
            arready  <= 1'b0;
            rvalid   <= 1'b0;
            rdata    <= 32'h0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    arready <= 1'b1;
                    rvalid  <= 1'b0;
                    if (arvalid) begin
                        arready  <= 1'b0;
                        rdata    <= (araddr[3:2] < 4) ? regfile[araddr[3:2]] : 32'h0;
                        rvalid   <= 1'b1;
                        rd_state <= RD_DATA;
                    end
                end
                RD_DATA: begin
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
