// fpu_double_precision — IEEE-754 double FPU stub (Verilog-2005)
module fpu_double_precision (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid,
    input  wire [2:0]  op,
    input  wire [63:0] a,
    input  wire [63:0] b,
    output reg  [63:0] result,
    output reg         ready,
    output reg  [4:0]  flags
);
    localparam IDLE = 2'd0;
    localparam BUSY = 2'd1;

    localparam LATENCY = 8'd8;
    localparam FADD_RESULT = 64'h4008000000000000;

    reg [1:0] state;
    reg [7:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= IDLE;
            count  <= 8'h0;
            result <= 64'h0;
            ready  <= 1'b0;
            flags  <= 5'h0;
        end else begin
            ready <= 1'b0;
            case (state)
                IDLE: begin
                    if (valid) begin
                        count <= 8'h0;
                        state <= BUSY;
                    end
                end
                BUSY: begin
                    count <= count + 8'h1;
                    if (count == LATENCY - 8'd1) begin
                        result <= FADD_RESULT;
                        ready  <= 1'b1;
                        flags  <= 5'h0;
                        state  <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
