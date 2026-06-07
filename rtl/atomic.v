// RV32 A-extension atomic memory operation helper
// Supports LR/SC and AMO swap/add/and/or/xor
// Verilog-2005 synthesizable
module atomic (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  amo_op,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        valid,
    output reg  [31:0] rdata,
    output reg         success,
    output reg         done
);

    // AMO operation encoding
    localparam OP_LR     = 3'd0;
    localparam OP_SC     = 3'd1;
    localparam OP_SWAP   = 3'd2;
    localparam OP_ADD    = 3'd3;
    localparam OP_AND    = 3'd4;
    localparam OP_OR     = 3'd5;
    localparam OP_XOR    = 3'd6;

    // Internal reservation register (one-element "register file")
    reg [31:0] resv_data;
    reg [31:0] resv_addr;
    reg        resv_valid;

    reg [31:0] amo_result;

    always @(*) begin
        case (amo_op)
            OP_SWAP: amo_result = wdata;
            OP_ADD:  amo_result = resv_data + wdata;
            OP_AND:  amo_result = resv_data & wdata;
            OP_OR:   amo_result = resv_data | wdata;
            OP_XOR:  amo_result = resv_data ^ wdata;
            default: amo_result = resv_data;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resv_data  <= 32'h0;
            resv_addr  <= 32'h0;
            resv_valid <= 1'b0;
            rdata      <= 32'h0;
            success    <= 1'b0;
            done       <= 1'b0;
        end else begin
            done    <= 1'b0;
            success <= 1'b0;
            if (valid) begin
                case (amo_op)
                    OP_LR: begin
                        // Load reservation: return current resv_data for this addr
                        rdata      <= resv_data;
                        resv_addr  <= addr;
                        resv_valid <= 1'b1;
                        done       <= 1'b1;
                    end
                    OP_SC: begin
                        if (resv_valid && (resv_addr == addr)) begin
                            resv_data  <= wdata;
                            success    <= 1'b1;
                            rdata      <= 32'h0;
                        end else begin
                            success    <= 1'b0;
                            rdata      <= 32'h1;
                        end
                        resv_valid <= 1'b0;
                        done       <= 1'b1;
                    end
                    default: begin
                        // AMO: read-modify-write on reservation register
                        rdata      <= resv_data;
                        resv_data  <= amo_result;
                        resv_addr  <= addr;
                        resv_valid <= 1'b1;
                        done       <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
