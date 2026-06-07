// coremark_benchmark — Performance counter snapshot (Verilog-2005)
module coremark_benchmark (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        stop,
    output reg  [31:0] cycle_cnt,
    output reg  [31:0] instret_cnt
);
    reg running;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running     <= 1'b0;
            cycle_cnt   <= 32'h0;
            instret_cnt <= 32'h0;
        end else if (start && !running) begin
            running     <= 1'b1;
            cycle_cnt   <= 32'h0;
            instret_cnt <= 32'h0;
        end else if (running) begin
            if (stop) begin
                running <= 1'b0;
            end else begin
                cycle_cnt   <= cycle_cnt + 32'd1;
                instret_cnt <= instret_cnt + 32'd1;
            end
        end
    end
endmodule
