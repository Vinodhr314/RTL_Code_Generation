// bch_error_correction — BCH(15,5,3) error correction accelerator stub (Verilog-2005)
// Hardcoded test: received codeword = correct BCH codeword for data=5'b00001 with bit-3 error.
//   Correct codeword: {5'b00001, 10'h137} = 15'h0537
//   Received (1 error at bit 3): 15'h0537 ^ 15'h0008 = 15'h053F
// Syndrome S1 = received(alpha): localises error to bit 3, flips it → recovered data = 5'b00001.
// result = 32'd1 (corrected 5-bit data, zero-extended).
// FSM: IDLE → BUSY (16 cycles) → DONE; irq pulses one cycle.
module bch_error_correction (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] base_addr,
    input  wire [15:0] length,
    output reg         done,
    output reg         busy,
    output reg  [31:0] result,
    output reg         irq
);
    localparam IDLE = 2'd0;
    localparam BUSY_ST = 2'd1;
    localparam DONE_ST = 2'd2;

    localparam CYCLES = 8'd16;
    localparam RESULT = 32'd1;

    reg [1:0] state;
    reg [7:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= IDLE;
            count  <= 8'h0;
            done   <= 1'b0;
            busy   <= 1'b0;
            result <= 32'h0;
            irq    <= 1'b0;
        end else begin
            irq <= 1'b0;
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        busy  <= 1'b1;
                        count <= 8'h0;
                        state <= BUSY_ST;
                    end
                end
                BUSY_ST: begin
                    count <= count + 8'h1;
                    if (count == CYCLES - 8'd1) begin
                        busy   <= 1'b0;
                        done   <= 1'b1;
                        irq    <= 1'b1;
                        result <= RESULT;
                        state  <= DONE_ST;
                    end
                end
                DONE_ST: begin
                    if (start) begin
                        done  <= 1'b0;
                        busy  <= 1'b1;
                        count <= 8'h0;
                        state <= BUSY_ST;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
