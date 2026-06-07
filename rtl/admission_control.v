// Token-bucket admission control — 16 traffic classes
module admission_control (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        pkt_valid,
  input  wire [3:0]  traffic_class,
  output wire        accept,
  output wire        drop,
  input  wire [15:0] tokens
);

  reg [15:0] bucket [0:15];
  integer i;

  wire [15:0] bucket_val = bucket[traffic_class];

  assign accept = pkt_valid && (bucket_val != 16'd0);
  assign drop   = pkt_valid && (bucket_val == 16'd0);

  always @(posedge clk) begin
    if (!rst_n) begin
      for (i = 0; i < 16; i = i + 1)
        bucket[i] <= tokens;
    end else if (pkt_valid && bucket[traffic_class] != 16'd0) begin
      bucket[traffic_class] <= bucket[traffic_class] - 16'd1;
    end
  end

endmodule
