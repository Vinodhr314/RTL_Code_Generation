// zilla_irq — IRQ fan-in priority decoder (Verilog-2005)
module zilla_irq (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [31:0] src,
    output reg  [7:0] vec,
    output reg        valid
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vec   <= 8'h0;
            valid <= 1'b0;
        end else begin
            valid <= 1'b0;
            vec   <= 8'h0;
            if (src != 32'h0) begin
                valid <= 1'b1;
                for (i = 31; i >= 0; i = i - 1)
                    if (src[i]) begin vec <= i[7:0]; i = -1; end
            end
        end
    end
endmodule
