// jtag — TAP controller stub (Verilog-2005)
module jtag (
    input  wire tck,
    input  wire tms,
    input  wire tdi,
    output wire tdo,
    input  wire trst_n,
    output reg  debug_req
);
    reg [4:0] ir;
    reg [31:0] dr;

    assign tdo = dr[0];

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir        <= 5'h01;
            dr        <= 32'h0;
            debug_req <= 1'b0;
        end else begin
            if (!tms)
                dr <= {tdi, dr[31:1]};
            if (tms && tdi)
                ir <= {tdi, ir[4:1]};
            debug_req <= (ir == 5'h11);
        end
    end
endmodule
