// gp_dma_gen_1 — dual-channel GP DMA stub (Verilog-2005)
module gp_dma_gen_1 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ch0_start,
    input  wire [31:0] ch0_src,
    input  wire [31:0] ch0_dst,
    input  wire [15:0] ch0_len,
    output reg         ch0_done,
    output reg         ch0_irq,
    input  wire        ch1_start,
    input  wire [31:0] ch1_src,
    input  wire [31:0] ch1_dst,
    input  wire [15:0] ch1_len,
    output reg         ch1_done,
    output reg         ch1_irq,
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_wdata,
    output reg         mem_wen,
    output reg         mem_ren,
    input  wire [31:0] mem_rdata,
    input  wire        mem_ready
);
    localparam IDLE = 2'd0;
    localparam READ_ST = 2'd1;
    localparam WRITE_ST = 2'd2;
    localparam DONE_ST = 2'd3;

    reg [1:0]  state;
    reg        ch_sel;
    reg [15:0] rem;
    reg [31:0] cur_src;
    reg [31:0] cur_dst;
    reg [31:0] latch;
    reg        read_done;
    reg        write_done;

    wire [15:0] ch0_beats = (ch0_len == 16'h0) ? 16'h0 : ((ch0_len + 16'd3) >> 2);
    wire [15:0] ch1_beats = (ch1_len == 16'h0) ? 16'h0 : ((ch1_len + 16'd3) >> 2);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ch_sel <= 1'b0;
            ch0_done <= 1'b0; ch0_irq <= 1'b0;
            ch1_done <= 1'b0; ch1_irq <= 1'b0;
            mem_addr <= 32'h0; mem_wdata <= 32'h0;
            mem_wen <= 1'b0; mem_ren <= 1'b0;
            rem <= 16'h0; cur_src <= 32'h0; cur_dst <= 32'h0;
            latch <= 32'h0; read_done <= 1'b0; write_done <= 1'b0;
        end else begin
            ch0_irq <= 1'b0;
            ch1_irq <= 1'b0;
            mem_wen <= 1'b0;
            mem_ren <= 1'b0;
            case (state)
                IDLE: begin
                    ch0_done <= 1'b0;
                    ch1_done <= 1'b0;
                    read_done <= 1'b0;
                    write_done <= 1'b0;
                    if (ch0_start) begin
                        ch_sel <= 1'b0;
                        rem <= ch0_beats;
                        cur_src <= ch0_src;
                        cur_dst <= ch0_dst;
                        state <= (ch0_beats == 16'h0) ? DONE_ST : READ_ST;
                    end else if (ch1_start) begin
                        ch_sel <= 1'b1;
                        rem <= ch1_beats;
                        cur_src <= ch1_src;
                        cur_dst <= ch1_dst;
                        state <= (ch1_beats == 16'h0) ? DONE_ST : READ_ST;
                    end
                end
                READ_ST: begin
                    mem_addr <= cur_src;
                    if (!read_done) begin
                        mem_ren <= 1'b1;
                        if (mem_ready) read_done <= 1'b1;
                    end else begin
                        latch <= mem_rdata;
                        read_done <= 1'b0;
                        state <= WRITE_ST;
                    end
                end
                WRITE_ST: begin
                    mem_addr <= cur_dst;
                    mem_wdata <= latch;
                    if (!write_done) begin
                        mem_wen <= 1'b1;
                        if (mem_ready) write_done <= 1'b1;
                    end else begin
                        write_done <= 1'b0;
                        cur_src <= cur_src + 32'd4;
                        cur_dst <= cur_dst + 32'd4;
                        rem <= rem - 16'd1;
                        if (rem == 16'd1)
                            state <= DONE_ST;
                        else
                            state <= READ_ST;
                    end
                end
                DONE_ST: begin
                    if (!ch_sel) begin
                        ch0_done <= 1'b1;
                        ch0_irq <= 1'b1;
                    end else begin
                        ch1_done <= 1'b1;
                        ch1_irq <= 1'b1;
                    end
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
