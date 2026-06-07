// ddr3_boot_up — DDR3 initialization FSM stub (Verilog-2005)
// 64-cycle JEDEC init sequence; done=1, status=8'h80 on success.
module ddr3_boot_up (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    output reg        done,
    output reg        fail,
    output reg  [7:0] status
);
    localparam IDLE = 2'd0;
    localparam INIT = 2'd1;
    localparam DONE_ST = 2'd2;

    localparam INIT_CYCLES = 8'd64;

    reg [1:0] state;
    reg [7:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= IDLE;
            count  <= 8'h0;
            done   <= 1'b0;
            fail   <= 1'b0;
            status <= 8'h0;
        end else begin
            case (state)
                IDLE: begin
                    done   <= 1'b0;
                    fail   <= 1'b0;
                    status <= 8'h0;
                    if (start) begin
                        count <= 8'h0;
                        state <= INIT;
                    end
                end
                INIT: begin
                    count  <= count + 8'h1;
                    status <= count;
                    if (count == INIT_CYCLES - 8'd1) begin
                        done   <= 1'b1;
                        fail   <= 1'b0;
                        status <= 8'h80;
                        state  <= DONE_ST;
                    end
                end
                DONE_ST: begin
                    if (start) begin
                        done  <= 1'b0;
                        count <= 8'h0;
                        state <= INIT;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
