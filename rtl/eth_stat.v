// eth_stat — Ethernet MAC statistics counters (Verilog-2005)
module eth_stat (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_frame,
    input  wire        tx_frame,
    input  wire        rx_err,
    input  wire        tx_err,
    output reg  [31:0] byte_cnt,
    output reg  [31:0] frame_cnt,
    output reg  [31:0] err_cnt,
    input  wire        clear
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_cnt  <= 32'h0;
            frame_cnt <= 32'h0;
            err_cnt   <= 32'h0;
        end else if (clear) begin
            byte_cnt  <= 32'h0;
            frame_cnt <= 32'h0;
            err_cnt   <= 32'h0;
        end else begin
            if (rx_frame) begin
                frame_cnt <= frame_cnt + 32'd1;
                byte_cnt  <= byte_cnt + 32'd64;
            end
            if (tx_frame) begin
                frame_cnt <= frame_cnt + 32'd1;
                byte_cnt  <= byte_cnt + 32'd64;
            end
            if (rx_err || tx_err)
                err_cnt <= err_cnt + 32'd1;
        end
    end
endmodule
