// srt_divider — integer divider stub (Verilog-2005)
module srt_divider (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid,
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output reg  [31:0] quotient,
    output reg  [31:0] remainder,
    output reg         done,
    output reg         busy
);
    reg [4:0] cnt;
    reg [31:0] la, lb;
    reg        run;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 32'h0; remainder <= 32'h0; done <= 1'b0; busy <= 1'b0;
            cnt <= 5'h0; run <= 1'b0;
        end else begin
            done <= 1'b0;
            if (valid && !run) begin
                la <= dividend; lb <= divisor; cnt <= 5'h0; busy <= 1'b1; run <= 1'b1;
            end else if (run) begin
                cnt <= cnt + 5'h1;
                if (cnt == 5'd31) begin
                    if (lb == 32'h0) begin
                        quotient  <= 32'hFFFFFFFF;
                        remainder <= la;
                    end else begin
                        quotient  <= la / lb;
                        remainder <= la % lb;
                    end
                    done <= 1'b1; busy <= 1'b0; run <= 1'b0;
                end
            end
        end
    end
endmodule
