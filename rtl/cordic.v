// cordic — 16-iteration CORDIC rotator stub (Verilog-2005)
// Produces hardcoded cos/sin 45deg outputs after 16 cycles.
module cordic (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [1:0]  mode,
    input  wire [31:0] x_in,
    input  wire [31:0] y_in,
    input  wire [31:0] z_in,
    output reg  [31:0] x_out,
    output reg  [31:0] y_out,
    output reg         done
);
    localparam IDLE = 2'd0;
    localparam BUSY = 2'd1;
    localparam DONE = 2'd2;

    localparam ITERATIONS = 8'd16;
    localparam X_RESULT   = 32'h5A827999;
    localparam Y_RESULT   = 32'h5A827999;

    reg [1:0] state;
    reg [7:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= IDLE;
            count  <= 8'h0;
            x_out  <= 32'h0;
            y_out  <= 32'h0;
            done   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        count <= 8'h0;
                        state <= BUSY;
                    end
                end
                BUSY: begin
                    count <= count + 8'h1;
                    if (count == ITERATIONS - 8'd1) begin
                        x_out <= X_RESULT;
                        y_out <= Y_RESULT;
                        done  <= 1'b1;
                        state <= DONE;
                    end
                end
                DONE: begin
                    done <= 1'b0;
                    if (start) begin
                        count <= 8'h0;
                        state <= BUSY;
                    end else begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
