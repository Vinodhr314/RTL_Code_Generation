// ulss — sleep supervisor stub (Verilog-2005)
module ulss (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       wfi,
    input  wire [3:0] wake,
    output reg        sleep,
    output reg        clk_gate
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep    <= 1'b0;
            clk_gate <= 1'b1;
        end else begin
            if (wfi && (wake == 4'h0)) begin
                sleep    <= 1'b1;
                clk_gate <= 1'b0;
            end else begin
                sleep    <= 1'b0;
                clk_gate <= 1'b1;
            end
        end
    end
endmodule
