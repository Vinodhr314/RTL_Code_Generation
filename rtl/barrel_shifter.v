// barrel_shifter — 32-bit combinational barrel shifter (Verilog-2005)
// op=00 SLL, op=01 SRL, op=10 SRA, op=11 pass-through
module barrel_shifter (
    input  wire [31:0] a,
    input  wire [4:0]  shamt,
    input  wire [1:0]  op,
    output reg  [31:0] y
);
    localparam SLL = 2'b00;
    localparam SRL = 2'b01;
    localparam SRA = 2'b10;

    always @* begin
        case (op)
            SLL:     y = a << shamt;
            SRL:     y = a >> shamt;
            SRA:     y = $signed(a) >>> shamt;
            default: y = a;
        endcase
    end
endmodule
