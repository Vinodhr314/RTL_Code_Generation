// trace_unit — ITM-style trace stub (Verilog-2005)
module trace_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pc,
    input  wire [31:0] inst,
    input  wire        valid,
    output reg  [63:0] trace_data,
    output reg         trace_valid
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trace_data  <= 64'h0;
            trace_valid <= 1'b0;
        end else begin
            trace_valid <= 1'b0;
            if (valid) begin
                trace_data  <= {pc, inst};
                trace_valid <= 1'b1;
            end
        end
    end
endmodule
