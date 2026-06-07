// otp — OTP interface stub (Verilog-2005)
module otp (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] addr,
    input  wire       read,
    output reg  [31:0] rdata,
    output reg        busy,
    output reg        error
);
    reg pending;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 32'h0; busy <= 1'b0; error <= 1'b0; pending <= 1'b0;
        end else begin
            error <= 1'b0;
            if (read && !busy) begin
                busy <= 1'b1;
                pending <= 1'b1;
            end else if (pending) begin
                pending <= 1'b0;
                busy <= 1'b0;
                if (addr == 8'h0)
                    rdata <= 32'hDEAD0001;
                else if (addr > 8'h7F)
                    error <= 1'b1;
                else
                    rdata <= {24'h0, addr};
            end
        end
    end
endmodule
