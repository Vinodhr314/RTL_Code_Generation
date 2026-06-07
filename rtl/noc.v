// noc — 4-port router stub (Verilog-2005)
module noc (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [3:0]   in_valid,
    input  wire [255:0] in_data,
    output reg  [3:0]   out_valid,
    output reg  [255:0] out_data,
    output reg  [3:0]   in_ready,
    input  wire [3:0]   out_ready
);
    integer p;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 4'h0; out_data <= 256'h0; in_ready <= 4'hF;
        end else begin
            out_valid <= 4'h0;
            for (p = 0; p < 4; p = p + 1) begin
                if (in_valid[p] && out_ready[(p + 1) % 4]) begin
                    out_valid[(p + 1) % 4] <= 1'b1;
                    out_data[((p + 1) % 4) * 64 +: 64] <= in_data[p * 64 +: 64];
                end
            end
            in_ready <= out_ready;
        end
    end
endmodule
