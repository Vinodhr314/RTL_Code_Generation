// frame_formatter — Ethernet frame formatter stub (Verilog-2005)
module frame_formatter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [31:0] in_data,
    input  wire        in_last,
    output reg         out_valid,
    output reg  [31:0] out_data,
    output reg         out_last,
    output reg  [15:0] frame_len
);
    reg        in_frame;
    reg        emit_header;
    reg        emit_payload;
    reg        payload_last;
    reg [31:0] payload_data;
    reg [15:0] word_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid     <= 1'b0;
            out_data      <= 32'h0;
            out_last      <= 1'b0;
            frame_len     <= 16'h0;
            in_frame      <= 1'b0;
            emit_header   <= 1'b0;
            emit_payload  <= 1'b0;
            payload_last  <= 1'b0;
            payload_data  <= 32'h0;
            word_cnt      <= 16'h0;
        end else begin
            out_valid    <= 1'b0;
            out_last     <= 1'b0;
            emit_header  <= 1'b0;
            emit_payload <= 1'b0;

            if (emit_header) begin
                out_valid <= 1'b1;
                out_data  <= 32'hAABBCCDD;
            end else if (emit_payload) begin
                out_valid <= 1'b1;
                out_data  <= payload_data;
                out_last  <= payload_last;
                if (payload_last) begin
                    frame_len <= 16'd8;
                    in_frame  <= 1'b0;
                    word_cnt  <= 16'h0;
                end
            end

            if (in_valid) begin
                if (!in_frame) begin
                    in_frame    <= 1'b1;
                    word_cnt    <= 16'd0;
                    emit_header <= 1'b1;
                end else begin
                    word_cnt       <= word_cnt + 16'd1;
                    payload_data   <= in_data;
                    payload_last   <= in_last;
                    emit_payload   <= 1'b1;
                end
            end
        end
    end
endmodule
