// pmp — Physical Memory Protection stub (Verilog-2005)
module pmp (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [1:0]  access,
    input  wire        mode,
    output reg         allow,
    output reg         fault,
    input  wire [31:0] cfg
);
    always @(posedge clk) begin
        if (addr[31]) begin
            allow <= 1'b0;
            fault <= 1'b1;
        end else begin
            allow <= 1'b1;
            fault <= 1'b0;
        end
    end
endmodule
