// AXI crossbar arbiter skeleton: 4 masters, 7 slaves
// Round-robin or priority arbitration; address-decode to slave regions
// Verilog-2005 synthesizable
module axi_axi_arbiter_4_7_config (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [31:0] cfg,
    // Master 0
    input  wire        m0_awvalid, output reg m0_awready,
    input  wire [31:0] m0_awaddr,
    input  wire        m0_wvalid,  output reg m0_wready,
    input  wire [31:0] m0_wdata,   input wire [3:0] m0_wstrb,
    output reg         m0_bvalid,  input wire m0_bready,
    output wire [1:0]  m0_bresp,
    input  wire        m0_arvalid, output reg m0_arready,
    input  wire [31:0] m0_araddr,
    output reg         m0_rvalid,  input wire m0_rready,
    output reg  [31:0] m0_rdata,   output wire [1:0] m0_rresp,
    // Master 1
    input  wire        m1_awvalid, output reg m1_awready,
    input  wire [31:0] m1_awaddr,
    input  wire        m1_wvalid,  output reg m1_wready,
    input  wire [31:0] m1_wdata,   input wire [3:0] m1_wstrb,
    output reg         m1_bvalid,  input wire m1_bready,
    output wire [1:0]  m1_bresp,
    input  wire        m1_arvalid, output reg m1_arready,
    input  wire [31:0] m1_araddr,
    output reg         m1_rvalid,  input wire m1_rready,
    output reg  [31:0] m1_rdata,   output wire [1:0] m1_rresp,
    // Master 2
    input  wire        m2_awvalid, output reg m2_awready,
    input  wire [31:0] m2_awaddr,
    input  wire        m2_wvalid,  output reg m2_wready,
    input  wire [31:0] m2_wdata,   input wire [3:0] m2_wstrb,
    output reg         m2_bvalid,  input wire m2_bready,
    output wire [1:0]  m2_bresp,
    input  wire        m2_arvalid, output reg m2_arready,
    input  wire [31:0] m2_araddr,
    output reg         m2_rvalid,  input wire m2_rready,
    output reg  [31:0] m2_rdata,   output wire [1:0] m2_rresp,
    // Master 3
    input  wire        m3_awvalid, output reg m3_awready,
    input  wire [31:0] m3_awaddr,
    input  wire        m3_wvalid,  output reg m3_wready,
    input  wire [31:0] m3_wdata,   input wire [3:0] m3_wstrb,
    output reg         m3_bvalid,  input wire m3_bready,
    output wire [1:0]  m3_bresp,
    input  wire        m3_arvalid, output reg m3_arready,
    input  wire [31:0] m3_araddr,
    output reg         m3_rvalid,  input wire m3_rready,
    output reg  [31:0] m3_rdata,   output wire [1:0] m3_rresp,
    // Arbitration output
    output reg  [2:0]  s_grant
);

    assign m0_bresp = 2'b00; assign m0_rresp = 2'b00;
    assign m1_bresp = 2'b00; assign m1_rresp = 2'b00;
    assign m2_bresp = 2'b00; assign m2_rresp = 2'b00;
    assign m3_bresp = 2'b00; assign m3_rresp = 2'b00;

    // Round-robin token
    reg [1:0] rr_ptr;

    // Request vector
    wire [3:0] req_aw = {m3_awvalid, m2_awvalid, m1_awvalid, m0_awvalid};
    wire [3:0] req_ar = {m3_arvalid, m2_arvalid, m1_arvalid, m0_arvalid};
    wire [3:0] any_req = req_aw | req_ar;

    // Address decode: map upper 3 bits of address to slave 0-6
    // Slave regions: 32-bit space divided into 8 regions, slave 7 unused (decode 0-6)
    function [2:0] decode_addr;
        input [31:0] a;
        reg [2:0] sl;
        begin
            case (a[31:29])
                3'd0: sl = 3'd0;
                3'd1: sl = 3'd1;
                3'd2: sl = 3'd2;
                3'd3: sl = 3'd3;
                3'd4: sl = 3'd4;
                3'd5: sl = 3'd5;
                3'd6: sl = 3'd6;
                default: sl = 3'd6;
            endcase
            decode_addr = sl;
        end
    endfunction

    // Grant logic: round-robin among requesting masters
    reg [1:0]  granted_master;
    reg        grant_valid;
    reg        grant_is_write;
    reg [31:0] grant_addr;
    reg [31:0] grant_wdata;

    // Simple internal slave response model (returns 0 for all reads)
    reg [2:0]  fsm;
    localparam FSM_IDLE  = 3'd0;
    localparam FSM_GRANT = 3'd1;
    localparam FSM_WDATA = 3'd2;
    localparam FSM_BRESP = 3'd3;
    localparam FSM_RRESP = 3'd4;

    integer i;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            fsm            <= FSM_IDLE;
            rr_ptr         <= 2'd0;
            s_grant        <= 3'd0;
            grant_valid    <= 1'b0;
            granted_master <= 2'd0;
            grant_is_write <= 1'b0;
            grant_addr     <= 32'h0;
            grant_wdata    <= 32'h0;
            m0_awready <= 1'b0; m0_wready <= 1'b0; m0_bvalid <= 1'b0;
            m0_arready <= 1'b0; m0_rvalid <= 1'b0; m0_rdata  <= 32'h0;
            m1_awready <= 1'b0; m1_wready <= 1'b0; m1_bvalid <= 1'b0;
            m1_arready <= 1'b0; m1_rvalid <= 1'b0; m1_rdata  <= 32'h0;
            m2_awready <= 1'b0; m2_wready <= 1'b0; m2_bvalid <= 1'b0;
            m2_arready <= 1'b0; m2_rvalid <= 1'b0; m2_rdata  <= 32'h0;
            m3_awready <= 1'b0; m3_wready <= 1'b0; m3_bvalid <= 1'b0;
            m3_arready <= 1'b0; m3_rvalid <= 1'b0; m3_rdata  <= 32'h0;
        end else begin
            // Default deasserts
            m0_awready <= 1'b0; m0_wready <= 1'b0;
            m1_awready <= 1'b0; m1_wready <= 1'b0;
            m2_awready <= 1'b0; m2_wready <= 1'b0;
            m3_awready <= 1'b0; m3_wready <= 1'b0;

            case (fsm)
                FSM_IDLE: begin
                    m0_bvalid <= 1'b0; m0_rvalid <= 1'b0;
                    m1_bvalid <= 1'b0; m1_rvalid <= 1'b0;
                    m2_bvalid <= 1'b0; m2_rvalid <= 1'b0;
                    m3_bvalid <= 1'b0; m3_rvalid <= 1'b0;
                    grant_valid <= 1'b0;
                    if (|any_req) begin
                        // Round-robin selection
                        if (cfg[0] == 1'b0) begin
                            // Round-robin
                            if      (any_req[rr_ptr])                     granted_master <= rr_ptr;
                            else if (any_req[(rr_ptr+2'd1) & 2'd3])       granted_master <= (rr_ptr + 2'd1) & 2'd3;
                            else if (any_req[(rr_ptr+2'd2) & 2'd3])       granted_master <= (rr_ptr + 2'd2) & 2'd3;
                            else                                           granted_master <= (rr_ptr + 2'd3) & 2'd3;
                        end else begin
                            // Priority: master 0 highest
                            if      (any_req[0]) granted_master <= 2'd0;
                            else if (any_req[1]) granted_master <= 2'd1;
                            else if (any_req[2]) granted_master <= 2'd2;
                            else                 granted_master <= 2'd3;
                        end
                        fsm <= FSM_GRANT;
                    end
                end

                FSM_GRANT: begin
                    grant_valid <= 1'b1;
                    case (granted_master)
                        2'd0: begin
                            if (m0_awvalid) begin
                                m0_awready     <= 1'b1;
                                grant_is_write <= 1'b1;
                                grant_addr     <= m0_awaddr;
                                s_grant        <= decode_addr(m0_awaddr);
                                fsm            <= FSM_WDATA;
                            end else begin
                                m0_arready     <= 1'b1;
                                grant_is_write <= 1'b0;
                                grant_addr     <= m0_araddr;
                                s_grant        <= decode_addr(m0_araddr);
                                m0_rdata       <= 32'hDEAD_0000 | {29'h0, decode_addr(m0_araddr)};
                                fsm            <= FSM_RRESP;
                            end
                        end
                        2'd1: begin
                            if (m1_awvalid) begin
                                m1_awready     <= 1'b1;
                                grant_is_write <= 1'b1;
                                grant_addr     <= m1_awaddr;
                                s_grant        <= decode_addr(m1_awaddr);
                                fsm            <= FSM_WDATA;
                            end else begin
                                m1_arready     <= 1'b1;
                                grant_is_write <= 1'b0;
                                grant_addr     <= m1_araddr;
                                s_grant        <= decode_addr(m1_araddr);
                                m1_rdata       <= 32'hDEAD_1000 | {29'h0, decode_addr(m1_araddr)};
                                fsm            <= FSM_RRESP;
                            end
                        end
                        2'd2: begin
                            if (m2_awvalid) begin
                                m2_awready     <= 1'b1;
                                grant_is_write <= 1'b1;
                                grant_addr     <= m2_awaddr;
                                s_grant        <= decode_addr(m2_awaddr);
                                fsm            <= FSM_WDATA;
                            end else begin
                                m2_arready     <= 1'b1;
                                grant_is_write <= 1'b0;
                                grant_addr     <= m2_araddr;
                                s_grant        <= decode_addr(m2_araddr);
                                m2_rdata       <= 32'hDEAD_2000 | {29'h0, decode_addr(m2_araddr)};
                                fsm            <= FSM_RRESP;
                            end
                        end
                        default: begin
                            if (m3_awvalid) begin
                                m3_awready     <= 1'b1;
                                grant_is_write <= 1'b1;
                                grant_addr     <= m3_awaddr;
                                s_grant        <= decode_addr(m3_awaddr);
                                fsm            <= FSM_WDATA;
                            end else begin
                                m3_arready     <= 1'b1;
                                grant_is_write <= 1'b0;
                                grant_addr     <= m3_araddr;
                                s_grant        <= decode_addr(m3_araddr);
                                m3_rdata       <= 32'hDEAD_3000 | {29'h0, decode_addr(m3_araddr)};
                                fsm            <= FSM_RRESP;
                            end
                        end
                    endcase
                end

                FSM_WDATA: begin
                    case (granted_master)
                        2'd0: begin m0_wready <= 1'b1; if (m0_wvalid) begin grant_wdata <= m0_wdata; fsm <= FSM_BRESP; end end
                        2'd1: begin m1_wready <= 1'b1; if (m1_wvalid) begin grant_wdata <= m1_wdata; fsm <= FSM_BRESP; end end
                        2'd2: begin m2_wready <= 1'b1; if (m2_wvalid) begin grant_wdata <= m2_wdata; fsm <= FSM_BRESP; end end
                        default: begin m3_wready <= 1'b1; if (m3_wvalid) begin grant_wdata <= m3_wdata; fsm <= FSM_BRESP; end end
                    endcase
                end

                FSM_BRESP: begin
                    case (granted_master)
                        2'd0: begin m0_bvalid <= 1'b1; if (m0_bready) begin m0_bvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                        2'd1: begin m1_bvalid <= 1'b1; if (m1_bready) begin m1_bvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                        2'd2: begin m2_bvalid <= 1'b1; if (m2_bready) begin m2_bvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                        default: begin m3_bvalid <= 1'b1; if (m3_bready) begin m3_bvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                    endcase
                end

                FSM_RRESP: begin
                    case (granted_master)
                        2'd0: begin m0_rvalid <= 1'b1; if (m0_rready) begin m0_rvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                        2'd1: begin m1_rvalid <= 1'b1; if (m1_rready) begin m1_rvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                        2'd2: begin m2_rvalid <= 1'b1; if (m2_rready) begin m2_rvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                        default: begin m3_rvalid <= 1'b1; if (m3_rready) begin m3_rvalid <= 1'b0; rr_ptr <= (rr_ptr + 2'd1) & 2'd3; fsm <= FSM_IDLE; end end
                    endcase
                end

                default: fsm <= FSM_IDLE;
            endcase
        end
    end

endmodule
