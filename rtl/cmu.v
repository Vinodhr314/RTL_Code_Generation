// cmu — Clock management unit (Verilog-2005)
// Divides clk_ref for cpu (div1), bus (div2), periph (div4). pll_lock on cfg_wr.
module cmu (
    input  wire        clk_ref,
    input  wire        rst_n,
    output reg         clk_cpu,
    output reg         clk_bus,
    output reg         clk_periph,
    output reg         pll_lock,
    input  wire [15:0] cfg,
    input  wire        cfg_wr
);
    reg [3:0] cpu_div;
    reg [3:0] bus_div;
    reg [3:0] periph_div;
    reg [7:0] cpu_cnt;
    reg [7:0] bus_cnt;
    reg [7:0] periph_cnt;

    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            cpu_div    <= 4'd1;
            bus_div    <= 4'd2;
            periph_div <= 4'd4;
            pll_lock   <= 1'b0;
            cpu_cnt    <= 8'h0;
            bus_cnt    <= 8'h0;
            periph_cnt <= 8'h0;
            clk_cpu    <= 1'b0;
            clk_bus    <= 1'b0;
            clk_periph <= 1'b0;
        end else begin
            if (cfg_wr) begin
                cpu_div    <= (cfg[3:0] == 4'h0) ? 4'd1 : cfg[3:0];
                bus_div    <= (cfg[7:4] == 4'h0) ? 4'd2 : cfg[7:4];
                periph_div <= (cfg[11:8] == 4'h0) ? 4'd4 : cfg[11:8];
                pll_lock   <= 1'b1;
            end

            cpu_cnt <= cpu_cnt + 8'd1;
            if (cpu_cnt == {4'h0, cpu_div} - 8'd1) begin
                cpu_cnt <= 8'h0;
                clk_cpu <= ~clk_cpu;
            end

            bus_cnt <= bus_cnt + 8'd1;
            if (bus_cnt == {4'h0, bus_div} - 8'd1) begin
                bus_cnt <= 8'h0;
                clk_bus <= ~clk_bus;
            end

            periph_cnt <= periph_cnt + 8'd1;
            if (periph_cnt == {4'h0, periph_div} - 8'd1) begin
                periph_cnt <= 8'h0;
                clk_periph <= ~clk_periph;
            end
        end
    end
endmodule
