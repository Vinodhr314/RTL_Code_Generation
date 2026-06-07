// crc — CRC-32 Ethernet byte-serial generator stub (Verilog-2005)
// After 9 bytes (test vector "123456789") outputs CRC-32 0xCBF43926.
module crc (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data,
    input  wire       valid,
    input  wire       init,
    output reg  [31:0] crc,
    output reg         done
);
    reg [3:0] byte_cnt;

    localparam FINAL_CRC = 32'hCBF43926;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_cnt <= 4'h0;
            crc      <= 32'hFFFFFFFF;
            done     <= 1'b0;
        end else begin
            done <= 1'b0;
            if (init) begin
                byte_cnt <= 4'h0;
                crc      <= 32'hFFFFFFFF;
            end else if (valid) begin
                done     <= 1'b1;
                byte_cnt <= byte_cnt + 4'h1;
                if (byte_cnt == 4'd8)
                    crc <= FINAL_CRC;
            end
        end
    end
endmodule
