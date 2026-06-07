// AXI4-Lite to APB bridge
// Translates AXI single-beat writes/reads to APB SETUP+ACCESS transactions
// Verilog-2005 synthesizable
module axi_apb_converter (
    input  wire        aclk,
    input  wire        aresetn,
    // AXI4-Lite slave — write address
    input  wire        awvalid,
    output reg         awready,
    input  wire [31:0] awaddr,
    // AXI4-Lite slave — write data
    input  wire        wvalid,
    output reg         wready,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    // AXI4-Lite slave — write response
    output reg         bvalid,
    input  wire        bready,
    output wire [1:0]  bresp,
    // AXI4-Lite slave — read address
    input  wire        arvalid,
    output reg         arready,
    input  wire [31:0] araddr,
    // AXI4-Lite slave — read data
    output reg         rvalid,
    input  wire        rready,
    output reg  [31:0] rdata,
    output wire [1:0]  rresp,
    // APB master
    output wire        pclk,
    output wire        presetn,
    output reg         psel,
    output reg         penable,
    output reg         pwrite,
    output reg  [31:0] paddr,
    output reg  [31:0] pwdata,
    input  wire [31:0] prdata,
    input  wire        pready
);

    assign bresp   = 2'b00;
    assign rresp   = 2'b00;
    assign pclk    = aclk;
    assign presetn = aresetn;

    // Bridge FSM
    localparam ST_IDLE    = 3'd0;
    localparam ST_AW_W    = 3'd1;  // waiting for AW+W
    localparam ST_APB_WR_SETUP  = 3'd2;
    localparam ST_APB_WR_ACCESS = 3'd3;
    localparam ST_AXI_WRESP     = 3'd4;
    localparam ST_APB_RD_SETUP  = 3'd5;
    localparam ST_APB_RD_ACCESS = 3'd6;
    localparam ST_AXI_RRESP     = 3'd7;

    reg [2:0]  state;
    reg [31:0] addr_latch;
    reg [31:0] data_latch;
    reg [3:0]  strb_latch;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state      <= ST_IDLE;
            awready    <= 1'b0;
            wready     <= 1'b0;
            bvalid     <= 1'b0;
            arready    <= 1'b0;
            rvalid     <= 1'b0;
            rdata      <= 32'h0;
            psel       <= 1'b0;
            penable    <= 1'b0;
            pwrite     <= 1'b0;
            paddr      <= 32'h0;
            pwdata     <= 32'h0;
            addr_latch <= 32'h0;
            data_latch <= 32'h0;
            strb_latch <= 4'h0;
        end else begin
            case (state)
                ST_IDLE: begin
                    bvalid  <= 1'b0;
                    rvalid  <= 1'b0;
                    psel    <= 1'b0;
                    penable <= 1'b0;
                    // Accept AXI write: AW and W simultaneously
                    if (awvalid && wvalid) begin
                        awready    <= 1'b1;
                        wready     <= 1'b1;
                        addr_latch <= awaddr;
                        data_latch <= wdata;
                        strb_latch <= wstrb;
                        state      <= ST_APB_WR_SETUP;
                    end else if (awvalid) begin
                        awready    <= 1'b1;
                        addr_latch <= awaddr;
                        state      <= ST_AW_W;
                    end else if (arvalid) begin
                        arready    <= 1'b1;
                        addr_latch <= araddr;
                        state      <= ST_APB_RD_SETUP;
                    end
                end

                ST_AW_W: begin
                    awready <= 1'b0;
                    if (wvalid) begin
                        wready     <= 1'b1;
                        data_latch <= wdata;
                        strb_latch <= wstrb;
                        state      <= ST_APB_WR_SETUP;
                    end
                end

                ST_APB_WR_SETUP: begin
                    awready <= 1'b0;
                    wready  <= 1'b0;
                    psel    <= 1'b1;
                    penable <= 1'b0;
                    pwrite  <= 1'b1;
                    paddr   <= addr_latch;
                    pwdata  <= data_latch;
                    state   <= ST_APB_WR_ACCESS;
                end

                ST_APB_WR_ACCESS: begin
                    penable <= 1'b1;
                    if (pready) begin
                        psel    <= 1'b0;
                        penable <= 1'b0;
                        state   <= ST_AXI_WRESP;
                    end
                end

                ST_AXI_WRESP: begin
                    bvalid <= 1'b1;
                    if (bready) begin
                        bvalid <= 1'b0;
                        state  <= ST_IDLE;
                    end
                end

                ST_APB_RD_SETUP: begin
                    arready <= 1'b0;
                    psel    <= 1'b1;
                    penable <= 1'b0;
                    pwrite  <= 1'b0;
                    paddr   <= addr_latch;
                    state   <= ST_APB_RD_ACCESS;
                end

                ST_APB_RD_ACCESS: begin
                    penable <= 1'b1;
                    if (pready) begin
                        psel    <= 1'b0;
                        penable <= 1'b0;
                        rdata   <= prdata;
                        state   <= ST_AXI_RRESP;
                    end
                end

                ST_AXI_RRESP: begin
                    rvalid <= 1'b1;
                    if (rready) begin
                        rvalid <= 1'b0;
                        state  <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
