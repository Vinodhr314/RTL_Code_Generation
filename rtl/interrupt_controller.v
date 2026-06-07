// interrupt_controller — 8-source PIC stub (Verilog-2005)
module interrupt_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] irq_in,
    output reg        irq_out,
    input  wire [7:0] irq_prio,
    input  wire [7:0] mask,
    output reg  [7:0] pending,
    output reg  [7:0] claim,
    input  wire       ack
);
    reg [7:0] active;
    wire [7:0] pending_next = (irq_in | active) & ~mask;
    wire [7:0] claim_next;

    assign claim_next =
        pending_next[7] ? 8'd7 :
        pending_next[6] ? 8'd6 :
        pending_next[5] ? 8'd5 :
        pending_next[4] ? 8'd4 :
        pending_next[3] ? 8'd3 :
        pending_next[2] ? 8'd2 :
        pending_next[1] ? 8'd1 :
        pending_next[0] ? 8'd0 : 8'h0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 8'h0;
            claim   <= 8'h0;
            irq_out <= 1'b0;
            active  <= 8'h0;
        end else begin
            pending <= pending_next;
            if (claim_next != 8'h0) begin
                claim   <= claim_next;
                irq_out <= 1'b1;
                active[claim_next[2:0]] <= 1'b1;
            end else begin
                claim   <= 8'h0;
                irq_out <= 1'b0;
            end
            if (ack && claim != 8'h0)
                active[claim[2:0]] <= 1'b0;
        end
    end
endmodule
