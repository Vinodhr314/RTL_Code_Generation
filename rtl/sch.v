// sch — round-robin scheduler stub (Verilog-2005)
module sch (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] req,
    output reg  [3:0] grant,
    input  wire [7:0] irq_prio
);
    reg [1:0] rr_ptr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant  <= 4'h0;
            rr_ptr <= 2'h0;
        end else begin
            grant <= 4'h0;
            if (irq_prio[7]) begin
                if (req[3]) grant <= 4'b1000;
                else if (req[2]) grant <= 4'b0100;
                else if (req[1]) grant <= 4'b0010;
                else if (req[0]) grant <= 4'b0001;
            end else begin
                case (rr_ptr)
                    2'd0: begin
                        if (req[0]) begin grant <= 4'b0001; rr_ptr <= 2'd1; end
                        else if (req[1]) begin grant <= 4'b0010; rr_ptr <= 2'd2; end
                        else if (req[2]) begin grant <= 4'b0100; rr_ptr <= 2'd3; end
                        else if (req[3]) begin grant <= 4'b1000; rr_ptr <= 2'd0; end
                    end
                    2'd1: begin
                        if (req[1]) begin grant <= 4'b0010; rr_ptr <= 2'd2; end
                        else if (req[2]) begin grant <= 4'b0100; rr_ptr <= 2'd3; end
                        else if (req[3]) begin grant <= 4'b1000; rr_ptr <= 2'd0; end
                        else if (req[0]) begin grant <= 4'b0001; rr_ptr <= 2'd1; end
                    end
                    2'd2: begin
                        if (req[2]) begin grant <= 4'b0100; rr_ptr <= 2'd3; end
                        else if (req[3]) begin grant <= 4'b1000; rr_ptr <= 2'd0; end
                        else if (req[0]) begin grant <= 4'b0001; rr_ptr <= 2'd1; end
                        else if (req[1]) begin grant <= 4'b0010; rr_ptr <= 2'd2; end
                    end
                    default: begin
                        if (req[3]) begin grant <= 4'b1000; rr_ptr <= 2'd0; end
                        else if (req[0]) begin grant <= 4'b0001; rr_ptr <= 2'd1; end
                        else if (req[1]) begin grant <= 4'b0010; rr_ptr <= 2'd2; end
                        else if (req[2]) begin grant <= 4'b0100; rr_ptr <= 2'd3; end
                    end
                endcase
            end
        end
    end
endmodule
