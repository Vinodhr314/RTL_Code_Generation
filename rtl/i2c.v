// i2c — I2C master stub (Verilog-2005)
module i2c (
    input  wire       clk,
    input  wire       rst_n,
    inout  wire       scl,
    inout  wire       sda,
    input  wire [6:0] addr,
    input  wire [7:0] data,
    input  wire       rw,
    input  wire       start,
    output reg        done,
    output reg  [7:0] rdata,
    output reg        irq
);
    assign scl = 1'bz;
    assign sda = 1'bz;
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    reg state;
    reg [3:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; cnt <= 4'h0; done <= 1'b0; rdata <= 8'h0; irq <= 1'b0;
        end else begin
            irq <= 1'b0;
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin cnt <= 4'h0; state <= BUSY; end
                end
                BUSY: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'd7) begin
                        done <= 1'b1;
                        irq <= 1'b1;
                        rdata <= rw ? 8'hAB : 8'h0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
