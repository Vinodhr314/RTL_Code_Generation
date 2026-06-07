// bch_encoder — BCH(15,5,3) systematic encoder (Verilog-2005)
// Generator: g(x) = x^10 + x^8 + x^5 + x^4 + x^2 + x + 1
// Uses data_in[4:0] as 5 message bits; outputs 15-bit codeword.
// Parity columns (x^(10+i) mod g(x)):
//   d[4] x^14: x^9+x^7+x^4+x^3+x+1       = 10'h29B
//   d[3] x^13: x^9+x^8+x^7+x^6+x^4+x^2+x = 10'h3D6
//   d[2] x^12: x^8+x^7+x^6+x^5+x^3+x+1   = 10'h1EB
//   d[1] x^11: x^9+x^6+x^5+x^3+x^2+x     = 10'h26E
//   d[0] x^10: x^8+x^5+x^4+x^2+x+1       = 10'h137
// done=1 one cycle after valid; codeword valid when done=1.
module bch_encoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        valid,
    output reg  [14:0] codeword,
    output reg         done
);
    wire [9:0] parity;
    assign parity = (data_in[4] ? 10'h29B : 10'h0)
                  ^ (data_in[3] ? 10'h3D6 : 10'h0)
                  ^ (data_in[2] ? 10'h1EB : 10'h0)
                  ^ (data_in[1] ? 10'h26E : 10'h0)
                  ^ (data_in[0] ? 10'h137 : 10'h0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            codeword <= 15'h0;
            done     <= 1'b0;
        end else begin
            done <= 1'b0;
            if (valid) begin
                codeword <= {data_in[4:0], parity};
                done     <= 1'b1;
            end
        end
    end
endmodule
