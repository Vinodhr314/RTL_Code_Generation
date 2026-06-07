// Asynchronous FIFO with Gray-code pointer CDC
// Based on Cummings SNUG-2002 design; registered full/empty flags break
// the combinational loop that would exist with wire flags.
// Verilog-2005 synthesizable
module async_fifo #(
    parameter DEPTH  = 16,
    parameter AWIDTH = 4   // must equal log2(DEPTH)
) (
    input  wire        wclk,
    input  wire        wrst_n,
    input  wire        winc,
    input  wire [31:0] wdata,
    input  wire        rclk,
    input  wire        rrst_n,
    input  wire        rinc,
    output wire [31:0] rdata,
    output wire        wfull,
    output wire        rempty
);

    // Memory array
    reg [31:0] mem [0:DEPTH-1];

    // ----------------------------------------------------------------
    // Write domain
    // ----------------------------------------------------------------
    reg  [AWIDTH:0] wptr_bin;       // binary write pointer
    reg  [AWIDTH:0] wptr_gray;      // gray write pointer
    reg             wfull_r;        // registered full flag (breaks loop)

    // Combinational "next" values — no loop: uses registered wfull_r
    wire [AWIDTH:0] wptr_bin_next  = wptr_bin + (winc & ~wfull_r);
    wire [AWIDTH:0] wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;

    // Synchronize rptr_gray into write domain (2-FF)
    reg  [AWIDTH:0] rptr_gray_s1, rptr_gray_s2;

    // Full flag combinational: top 2 bits differ, lower bits equal
    wire wfull_next = (wptr_gray_next[AWIDTH]   != rptr_gray_s2[AWIDTH])   &&
                      (wptr_gray_next[AWIDTH-1] != rptr_gray_s2[AWIDTH-1]) &&
                      (wptr_gray_next[AWIDTH-2:0] == rptr_gray_s2[AWIDTH-2:0]);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin  <= {(AWIDTH+1){1'b0}};
            wptr_gray <= {(AWIDTH+1){1'b0}};
            wfull_r   <= 1'b0;
        end else begin
            wptr_bin  <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
            wfull_r   <= wfull_next;
        end
    end

    // Write port
    always @(posedge wclk) begin
        if (winc && !wfull_r)
            mem[wptr_bin[AWIDTH-1:0]] <= wdata;
    end

    // Synchronize rptr_gray into write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_s1 <= {(AWIDTH+1){1'b0}};
            rptr_gray_s2 <= {(AWIDTH+1){1'b0}};
        end else begin
            rptr_gray_s1 <= rptr_gray;
            rptr_gray_s2 <= rptr_gray_s1;
        end
    end

    assign wfull = wfull_r;

    // ----------------------------------------------------------------
    // Read domain
    // ----------------------------------------------------------------
    reg  [AWIDTH:0] rptr_bin;       // binary read pointer
    reg  [AWIDTH:0] rptr_gray;      // gray read pointer (exported for sync)
    reg             rempty_r;       // registered empty flag (breaks loop)

    // Combinational "next" values — uses registered rempty_r
    wire [AWIDTH:0] rptr_bin_next  = rptr_bin + (rinc & ~rempty_r);
    wire [AWIDTH:0] rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;

    // Synchronize wptr_gray into read domain (2-FF)
    reg  [AWIDTH:0] wptr_gray_s1, wptr_gray_s2;

    // Empty flag: next gray equals synchronized write gray
    wire rempty_next = (rptr_gray_next == wptr_gray_s2);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin  <= {(AWIDTH+1){1'b0}};
            rptr_gray <= {(AWIDTH+1){1'b0}};
            rempty_r  <= 1'b1;
        end else begin
            rptr_bin  <= rptr_bin_next;
            rptr_gray <= rptr_gray_next;
            rempty_r  <= rempty_next;
        end
    end

    // Synchronize wptr_gray into read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_s1 <= {(AWIDTH+1){1'b0}};
            wptr_gray_s2 <= {(AWIDTH+1){1'b0}};
        end else begin
            wptr_gray_s1 <= wptr_gray;
            wptr_gray_s2 <= wptr_gray_s1;
        end
    end

    assign rempty = rempty_r;

    // Read port (async read of current rptr_bin — shows NEXT entry to be read)
    assign rdata = mem[rptr_bin[AWIDTH-1:0]];

endmodule
