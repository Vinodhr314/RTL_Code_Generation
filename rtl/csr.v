// csr — RV32 privileged CSR file (Verilog-2005)
module csr (
    input  wire        clk,
    input  wire [11:0] csr_addr,
    input  wire [31:0] csr_wdata,
    input  wire [1:0]  csr_op,
    output reg  [31:0] csr_rdata,
    output reg         illegal
);
    localparam CSR_MSTATUS = 12'h300;
    localparam CSR_MIE     = 12'h304;
    localparam CSR_MTVEC   = 12'h305;

    localparam OP_READ  = 2'b00;
    localparam OP_WRITE = 2'b01;
    localparam OP_SET   = 2'b10;
    localparam OP_CLEAR = 2'b11;

    reg [31:0] mstatus;
    reg [31:0] mie;
    reg [31:0] mtvec;
    reg [1:0]  csr_op_r;
    reg [11:0] csr_addr_r;

    always @(posedge clk) begin
        csr_op_r   <= csr_op;
        csr_addr_r <= csr_addr;

        case (csr_addr)
            CSR_MSTATUS: begin
                case (csr_op)
                    OP_WRITE: mstatus <= csr_wdata;
                    OP_SET:   mstatus <= mstatus | csr_wdata;
                    OP_CLEAR: mstatus <= mstatus & ~csr_wdata;
                    default: ;
                endcase
            end
            CSR_MIE: begin
                case (csr_op)
                    OP_WRITE: mie <= csr_wdata;
                    OP_SET:   mie <= mie | csr_wdata;
                    OP_CLEAR: mie <= mie & ~csr_wdata;
                    default: ;
                endcase
            end
            CSR_MTVEC: begin
                case (csr_op)
                    OP_WRITE: mtvec <= csr_wdata;
                    OP_SET:   mtvec <= mtvec | csr_wdata;
                    OP_CLEAR: mtvec <= mtvec & ~csr_wdata;
                    default: ;
                endcase
            end
            default: ;
        endcase
    end

    always @* begin
        illegal   = 1'b0;
        csr_rdata = 32'h0;
        case (csr_addr)
            CSR_MSTATUS: csr_rdata = mstatus;
            CSR_MIE:     csr_rdata = mie;
            CSR_MTVEC:   csr_rdata = mtvec;
            default:     illegal   = 1'b1;
        endcase
    end

    initial begin
        mstatus = 32'h0000_1800;
        mie     = 32'h0;
        mtvec   = 32'h0;
    end
endmodule
