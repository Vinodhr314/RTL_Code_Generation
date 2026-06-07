// fifo — Synchronous FIFO depth 16 (Verilog-2005)
module fifo #(
    parameter DEPTH  = 16,
    parameter ADDR_W = 4
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wr_en,
    input  wire        rd_en,
    input  wire [31:0] din,
    output wire [31:0] dout,
    output wire        full,
    output wire        empty,
    output wire [ADDR_W-1:0] count
);
    reg [31:0] mem [0:DEPTH-1];
    reg [ADDR_W:0] wptr;
    reg [ADDR_W:0] rptr;

    wire [ADDR_W:0] wptr_next = wptr + (wr_en && !full);
    wire [ADDR_W:0] rptr_next = rptr + (rd_en && !empty);

    assign full  = (wptr_next[ADDR_W] != rptr[ADDR_W]) &&
                   (wptr_next[ADDR_W-1:0] == rptr[ADDR_W-1:0]);
    assign empty = (wptr == rptr);
    assign count = wptr - rptr;
    assign dout  = mem[rptr[ADDR_W-1:0]];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= {(ADDR_W+1){1'b0}};
            rptr <= {(ADDR_W+1){1'b0}};
        end else begin
            if (wr_en && !full) begin
                mem[wptr[ADDR_W-1:0]] <= din;
                wptr <= wptr_next;
            end
            if (rd_en && !empty)
                rptr <= rptr_next;
        end
    end
endmodule
