// vpu — SIMD stub (Verilog-2005)
module vpu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid,
    input  wire [3:0]  op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output reg         done
);
    reg [1:0] cnt;
    reg [31:0] la, lb;
    reg        run;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'h0; done <= 1'b0; cnt <= 2'h0; run <= 1'b0;
        end else begin
            done <= 1'b0;
            if (valid && !run) begin
                la <= a; lb <= b; cnt <= 2'h0; run <= 1'b1;
            end else if (run) begin
                cnt <= cnt + 2'h1;
                if (cnt == 2'd1) begin
                    result <= {a[31:24] + b[31:24], a[23:16] + b[23:16],
                               a[15:8] + b[15:8], a[7:0] + b[7:0]};
                    done <= 1'b1; run <= 1'b0;
                end
            end
        end
    end
endmodule
