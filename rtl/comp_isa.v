// comp_isa — Custom ISA fused-add coprocessor (Verilog-2005)
// Opcode 7'h7B: rd = rs1 + rs2
module comp_isa (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] inst,
    input  wire        valid,
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,
    output reg  [31:0] rd,
    output reg         rd_valid
);
    localparam CUSTOM_OP = 7'h7B;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd       <= 32'h0;
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= 1'b0;
            if (valid && inst[6:0] == CUSTOM_OP) begin
                rd       <= rs1 + rs2;
                rd_valid <= 1'b1;
            end
        end
    end
endmodule
