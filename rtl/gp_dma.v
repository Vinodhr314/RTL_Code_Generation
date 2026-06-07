// gp_dma — General-purpose DMA stub (Verilog-2005)
module gp_dma (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] src,
    input  wire [31:0] dst,
    input  wire [15:0] len,
    output reg         done,
    output reg         busy,
    output reg         irq,
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_wdata,
    output reg         mem_wen,
    output reg         mem_ren,
    input  wire [31:0] mem_rdata,
    input  wire        mem_ready
);
    localparam IDLE     = 2'd0;
    localparam READ_ST  = 2'd1;
    localparam WRITE_ST = 2'd2;
    localparam DONE_ST  = 2'd3;

    reg [1:0]  state;
    reg [15:0] rem;
    reg [31:0] cur_src;
    reg [31:0] cur_dst;
    reg [31:0] latch;
    reg        read_done;
    reg        write_done;

    wire [15:0] beats = (len == 16'h0) ? 16'h0 : ((len + 16'd3) >> 2);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            done      <= 1'b0;
            busy      <= 1'b0;
            irq       <= 1'b0;
            mem_addr  <= 32'h0;
            mem_wdata <= 32'h0;
            mem_wen   <= 1'b0;
            mem_ren   <= 1'b0;
            rem       <= 16'h0;
            cur_src   <= 32'h0;
            cur_dst   <= 32'h0;
            latch     <= 32'h0;
            read_done  <= 1'b0;
            write_done <= 1'b0;
        end else begin
            irq      <= 1'b0;
            mem_wen  <= 1'b0;
            mem_ren  <= 1'b0;

            case (state)
                IDLE: begin
                    done <= 1'b0;
                    read_done  <= 1'b0;
                    write_done <= 1'b0;
                    if (start) begin
                        busy    <= 1'b1;
                        rem     <= beats;
                        cur_src <= src;
                        cur_dst <= dst;
                        if (beats == 16'h0)
                            state <= DONE_ST;
                        else
                            state <= READ_ST;
                    end
                end
                READ_ST: begin
                    mem_addr <= cur_src;
                    if (!read_done) begin
                        mem_ren <= 1'b1;
                        if (mem_ready)
                            read_done <= 1'b1;
                    end else begin
                        latch     <= mem_rdata;
                        read_done <= 1'b0;
                        state     <= WRITE_ST;
                    end
                end
                WRITE_ST: begin
                    mem_addr  <= cur_dst;
                    mem_wdata <= latch;
                    if (!write_done) begin
                        mem_wen <= 1'b1;
                        if (mem_ready)
                            write_done <= 1'b1;
                    end else begin
                        write_done <= 1'b0;
                        cur_src    <= cur_src + 32'd4;
                        cur_dst    <= cur_dst + 32'd4;
                        rem        <= rem - 16'd1;
                        if (rem == 16'd1)
                            state <= DONE_ST;
                        else
                            state <= READ_ST;
                    end
                end
                DONE_ST: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    irq  <= 1'b1;
                    if (start) begin
                        done  <= 1'b0;
                        busy  <= 1'b1;
                        rem   <= beats;
                        cur_src <= src;
                        cur_dst <= dst;
                        if (beats == 16'h0)
                            state <= DONE_ST;
                        else
                            state <= READ_ST;
                    end else begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
