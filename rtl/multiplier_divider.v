// multiplier_divider — M-extension stub (Verilog-2005)
module multiplier_divider (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output reg         done
);
    localparam OP_MUL = 3'd0;
    localparam OP_DIV = 3'd2;

    localparam IDLE = 2'd0;
    localparam BUSY = 2'd1;
    localparam FIN  = 2'd2;

    reg [1:0] state;
    reg [2:0] cnt;
    reg [31:0] la, lb;
    reg [2:0]  lop;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= IDLE;
            cnt    <= 3'h0;
            result <= 32'h0;
            done   <= 1'b0;
            la     <= 32'h0;
            lb     <= 32'h0;
            lop    <= 3'h0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    la    <= a;
                    lb    <= b;
                    lop   <= op;
                    cnt   <= 3'h0;
                    state <= BUSY;
                end
                BUSY: begin
                    cnt <= cnt + 3'h1;
                    if (cnt == 3'd3) begin
                        case (lop)
                            OP_MUL: result <= la * lb;
                            OP_DIV: result <= (lb == 32'h0) ? 32'hFFFFFFFF : (la / lb);
                            default: result <= la * lb;
                        endcase
                        done  <= 1'b1;
                        state <= FIN;
                    end
                end
                FIN: begin
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
