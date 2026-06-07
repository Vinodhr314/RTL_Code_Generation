// debug_module — RISC-V Debug Module 0.13 stub (Verilog-2005)
module debug_module (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] dmi,
    output reg         halt_req,
    output reg         resume_req,
    input  wire        halted,
    inout  wire [31:0] abstract_data,
    output reg         error
);
    reg [31:0] gpr_val;
    reg        data_oe;

    assign abstract_data = data_oe ? gpr_val : 32'hzzzz_zzzz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halt_req   <= 1'b0;
            resume_req <= 1'b0;
            error      <= 1'b0;
            gpr_val    <= 32'h0;
            data_oe    <= 1'b0;
        end else begin
            halt_req   <= (dmi[1:0] == 2'b01);
            resume_req <= (dmi[1:0] == 2'b10);
            data_oe    <= (dmi[1:0] == 2'b11);
            error      <= 1'b0;
            if (dmi[1:0] == 2'b11)
                gpr_val <= 32'h0000_0042;
        end
    end
endmodule
