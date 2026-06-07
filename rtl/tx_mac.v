// tx_mac — Ethernet TX MAC stub (Verilog-2005)
module tx_mac (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    input  wire       tx_last,
    output reg        tx_ready,
    output reg  [7:0] gmii_txd,
    output reg        gmii_tx_en
);
    reg [2:0] state;
    reg [7:0] preamble_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_ready <= 1'b0; gmii_txd <= 8'h0; gmii_tx_en <= 1'b0;
            state <= 3'h0; preamble_cnt <= 8'h0;
        end else begin
            tx_ready <= 1'b0;
            case (state)
                3'h0: begin
                    if (tx_start) begin
                        state <= 3'h1; preamble_cnt <= 8'h0; gmii_tx_en <= 1'b1;
                    end
                end
                3'h1: begin
                    gmii_txd <= 8'h55;
                    preamble_cnt <= preamble_cnt + 8'h1;
                    if (preamble_cnt == 8'd6) state <= 3'h2;
                end
                3'h2: begin
                    gmii_txd <= 8'hD5;
                    state <= 3'h3;
                    tx_ready <= 1'b1;
                end
                3'h3: begin
                    if (tx_valid) begin
                        gmii_txd <= tx_data;
                        if (tx_last) begin
                            gmii_tx_en <= 1'b0;
                            state <= 3'h0;
                        end
                    end
                end
                default: state <= 3'h0;
            endcase
        end
    end
endmodule
