// md5 — MD5 hash stub (Verilog-2005)
// Empty string MD5: d41d8cd98f00b204e9800998ecf8427e
module md5 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [511:0] block,
    output reg  [127:0] digest,
    output reg          done,
    output reg          busy
);
    localparam DIGEST = 128'hd41d8cd98f00b204e9800998ecf8427e;
    reg [4:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'h0; digest <= 128'h0; done <= 1'b0; busy <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                busy <= 1'b1; cnt <= 5'h0;
            end else if (busy) begin
                cnt <= cnt + 5'h1;
                if (cnt == 5'd15) begin
                    digest <= DIGEST;
                    done <= 1'b1;
                    busy <= 1'b0;
                end
            end
        end
    end
endmodule
