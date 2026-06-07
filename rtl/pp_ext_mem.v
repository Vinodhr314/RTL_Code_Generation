// pp_ext_mem — external memory interface stub (Verilog-2005)
module pp_ext_mem (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        wen,
    input  wire        ren,
    output reg  [31:0] rdata,
    output reg         ready
);
    reg        pending;
    reg [31:0] addr_latch;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata      <= 32'h0;
            ready      <= 1'b0;
            pending    <= 1'b0;
            addr_latch <= 32'h0;
        end else begin
            ready <= 1'b0;
            if (wen || ren) begin
                addr_latch <= addr;
                pending    <= 1'b1;
            end else if (pending) begin
                ready   <= 1'b1;
                rdata   <= addr_latch ^ 32'hA5A5_A5A5;
                pending <= 1'b0;
            end
        end
    end
endmodule
