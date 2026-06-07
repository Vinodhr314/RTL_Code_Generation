// pixel_decompanding — linear decompanding stub (Verilog-2005)
module pixel_decompanding (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] comp,
    input  wire        valid,
    output reg  [23:0] pixel,
    output reg         valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel     <= 24'h0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            if (valid) begin
                pixel     <= {comp[7:0], comp[15:8], comp[7:0]};
                valid_out <= 1'b1;
            end
        end
    end
endmodule
