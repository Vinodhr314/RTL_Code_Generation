// ethernet_classifier — ethertype classifier (Verilog-2005)
// Port traffic_class avoids Verilog keyword class.
module ethernet_classifier (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [31:0] in_data,
    output reg  [3:0]  traffic_class,
    output reg         class_valid
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            traffic_class <= 4'h0;
            class_valid   <= 1'b0;
        end else begin
            class_valid <= 1'b0;
            if (in_valid) begin
                class_valid <= 1'b1;
                case (in_data[15:0])
                    16'h0800: traffic_class <= 4'd1;
                    16'h0806: traffic_class <= 4'd2;
                    default:  traffic_class <= 4'd0;
                endcase
            end
        end
    end
endmodule
