// pp — pipeline register with valid-ready (Verilog-2005)
module pp (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    output wire        ready_out,
    input  wire [31:0] data_in,
    output reg         valid_out,
    input  wire        ready_in,
    output reg  [31:0] data_out
);
    assign ready_out = !valid_out || ready_in;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out  <= 32'h0;
        end else if (ready_out) begin
            valid_out <= valid_in;
            if (valid_in)
                data_out <= data_in;
        end
    end
endmodule
