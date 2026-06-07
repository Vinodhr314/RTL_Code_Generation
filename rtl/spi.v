// spi — SPI master stub (Verilog-2005)
module spi (
    input  wire       clk,
    input  wire       rst_n,
    output reg        sck,
    output reg        mosi,
    input  wire       miso,
    output reg  [3:0] cs_n,
    input  wire [7:0] tx,
    output reg  [7:0] rx,
    output reg        busy,
    output reg        done,
    output reg        irq
);
    reg [3:0] bit_cnt;
    reg [7:0] shreg;
    reg       active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck     <= 1'b0;
            mosi    <= 1'b0;
            cs_n    <= 4'hF;
            rx      <= 8'h0;
            busy    <= 1'b0;
            done    <= 1'b0;
            irq     <= 1'b0;
            bit_cnt <= 4'h0;
            shreg   <= 8'h0;
            active  <= 1'b0;
        end else begin
            done <= 1'b0;
            irq  <= 1'b0;
            if (!active && tx != 8'h00) begin
                active  <= 1'b1;
                busy    <= 1'b1;
                cs_n    <= 4'hE;
                shreg   <= tx;
                bit_cnt <= 4'h0;
                sck     <= 1'b0;
            end else if (active) begin
                sck <= ~sck;
                if (!sck) begin
                    mosi <= shreg[7];
                end else begin
                    shreg   <= {shreg[6:0], miso};
                    bit_cnt <= bit_cnt + 4'h1;
                    if (bit_cnt == 4'd7) begin
                        rx     <= {shreg[6:0], miso};
                        busy   <= 1'b0;
                        done   <= 1'b1;
                        irq    <= 1'b1;
                        cs_n   <= 4'hF;
                        active <= 1'b0;
                        sck    <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
