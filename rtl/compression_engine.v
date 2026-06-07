// compression_engine — Streaming passthrough stub (Verilog-2005)
module compression_engine (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mode,
    input  wire        in_valid,
    input  wire [31:0] in_data,
    input  wire        in_last,
    output reg         out_valid,
    output reg  [31:0] out_data,
    output reg         out_last,
    output reg         busy
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= 32'h0;
            out_last  <= 1'b0;
            busy      <= 1'b0;
        end else begin
            out_valid <= 1'b0;
            if (in_valid) begin
                busy      <= 1'b1;
                out_valid <= 1'b1;
                out_data  <= in_data;
                out_last  <= in_last;
            end else begin
                busy <= 1'b0;
            end
        end
    end
endmodule
