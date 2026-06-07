// jtag_gen_1 — extended JTAG stub (Verilog-2005)
module jtag_gen_1 (
    input  wire        tck,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,
    inout  wire [63:0] ext_dr
);
    reg [63:0] shift;

    assign ext_dr = 64'hzzzzzzzzzzzzzzzz;
    assign tdo    = shift[0];

    initial begin
        shift = 64'h0;
    end

    always @(posedge tck) begin
        if (!tms)
            shift <= {shift[63:1], tdi};
    end
endmodule
