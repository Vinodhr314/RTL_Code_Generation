// spu — DSP MAC stub (Verilog-2005)
module spu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [3:0]  op_sel,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output reg         done,
    output reg         busy,
    output reg         irq
);
    reg [2:0] cnt;
    reg [31:0] la, lb;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'h0; done <= 1'b0; busy <= 1'b0; irq <= 1'b0; cnt <= 3'h0;
        end else begin
            done <= 1'b0; irq <= 1'b0;
            if (start && !busy) begin
                busy <= 1'b1; cnt <= 3'h0; la <= a; lb <= b;
            end else if (busy) begin
                cnt <= cnt + 3'h1;
                if (cnt == 3'd3) begin
                    result <= la + lb;
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    irq    <= 1'b1;
                end
            end
        end
    end
endmodule
