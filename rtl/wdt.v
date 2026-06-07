// wdt — watchdog timer stub (Verilog-2005)
module wdt (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        kick,
    input  wire [31:0] timeout,
    output reg         wdt_rst,
    output reg         irq
);
    reg [31:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'h0;
            wdt_rst <= 1'b0;
            irq     <= 1'b0;
        end else begin
            if (kick) begin
                counter <= timeout;
                irq     <= 1'b0;
                wdt_rst <= 1'b0;
            end else if (counter != 32'h0) begin
                irq     <= (counter == 32'd3);
                wdt_rst <= (counter == 32'd1);
                counter <= counter - 32'd1;
            end else begin
                irq     <= 1'b0;
                wdt_rst <= 1'b0;
            end
        end
    end
endmodule
