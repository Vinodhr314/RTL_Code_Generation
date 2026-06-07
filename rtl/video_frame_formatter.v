// video_frame_formatter — display timing stub (Verilog-2005)
module video_frame_formatter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [23:0] pixel,
    input  wire        valid,
    output reg         hsync,
    output reg         vsync,
    output reg         de,
    output reg  [11:0] line,
    output reg  [11:0] frame
);
    reg [11:0] pix_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1'b0; vsync <= 1'b0; de <= 1'b0;
            line <= 12'h0; frame <= 12'h0; pix_cnt <= 12'h0;
        end else if (valid) begin
            de <= 1'b1;
            pix_cnt <= pix_cnt + 12'h1;
            if (pix_cnt == 12'd639) begin
                pix_cnt <= 12'h0;
                line    <= line + 12'h1;
                hsync   <= 1'b1;
                if (line == 12'd479) begin
                    line  <= 12'h0;
                    frame <= frame + 12'h1;
                    vsync <= 1'b1;
                end
            end else begin
                hsync <= 1'b0; vsync <= 1'b0;
            end
        end else begin
            de <= 1'b0;
        end
    end
endmodule
