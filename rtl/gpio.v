// gpio — 32-bit GPIO bank stub (Verilog-2005)
module gpio (
    input  wire        clk,
    input  wire        rst_n,
    inout  wire [31:0] gpio,
    input  wire [31:0] dir,
    input  wire [31:0] out,
    output reg  [31:0] in,
    output reg  [31:0] irq
);
    wire [31:0] gpio_in;
    reg  [31:0] in_prev;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : pads
            assign gpio[i] = dir[i] ? out[i] : 1'bz;
        end
    endgenerate
    assign gpio_in = gpio;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in <= 32'h0; in_prev <= 32'h0; irq <= 32'h0;
        end else begin
            in <= gpio_in;
            irq <= (gpio_in & ~in_prev) & ~dir;
            in_prev <= gpio_in;
        end
    end
endmodule
