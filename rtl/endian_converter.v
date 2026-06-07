// endian_converter — combinational byte/half-word swap (Verilog-2005)
module endian_converter (
    input  wire [31:0] din,
    output reg  [31:0] dout,
    input  wire [1:0]  mode
);
    always @* begin
        case (mode)
            2'b00: dout = {din[7:0], din[15:8], din[23:16], din[31:24]};
            2'b01: dout = {din[15:0], din[31:16]};
            default: dout = din;
        endcase
    end
endmodule
