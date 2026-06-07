// packet_buffer — dual-port SRAM stub (Verilog-2005)
module packet_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wr_en,
    input  wire [11:0] wr_addr,
    input  wire [31:0] wr_data,
    input  wire        rd_en,
    input  wire [11:0] rd_addr,
    output reg  [31:0] rd_data,
    output reg         full,
    output reg         empty
);
    reg [31:0] mem [0:1023];
    reg [11:0] wr_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_cnt <= 12'h0; rd_data <= 32'h0; full <= 1'b0; empty <= 1'b1;
        end else begin
            if (wr_en) begin
                mem[wr_addr] <= wr_data;
                wr_cnt <= wr_cnt + 12'h1;
                empty <= 1'b0;
                if (wr_cnt == 12'd1023)
                    full <= 1'b1;
            end
            if (rd_en)
                rd_data <= mem[rd_addr];
        end
    end
endmodule
