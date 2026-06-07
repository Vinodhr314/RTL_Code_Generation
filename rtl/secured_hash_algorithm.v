// secured_hash_algorithm — SHA-256 stub (Verilog-2005)
// Empty block digest: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
module secured_hash_algorithm (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [511:0] block,
    output reg  [255:0] digest,
    output reg          done,
    output reg          busy
);
    localparam DIGEST = 256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;
    reg [5:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 6'h0; digest <= 256'h0; done <= 1'b0; busy <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                busy <= 1'b1; cnt <= 6'h0;
            end else if (busy) begin
                cnt <= cnt + 6'h1;
                if (cnt == 6'd63) begin
                    digest <= DIGEST;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                end
            end
        end
    end
endmodule
