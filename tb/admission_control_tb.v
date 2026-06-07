`timescale 1ns/1ps

module admission_control_tb;

  reg        clk;
  reg        rst_n;
  reg        pkt_valid;
  reg  [3:0] pkt_class;
  wire       accept;
  wire       drop;
  reg  [15:0] tokens;

  admission_control uut (
    .clk(clk),
    .rst_n(rst_n),
    .pkt_valid(pkt_valid),
    .traffic_class(pkt_class),
    .accept(accept),
    .drop(drop),
    .tokens(tokens)
  );

  integer errors;

  initial clk = 0;
  always #5 clk = ~clk;

  task send_pkt;
    input [3:0] cls;
    input exp_accept;
    begin
      pkt_class = cls;
      pkt_valid = 1'b1;
      #1;
      if (exp_accept && !accept) begin
        $display("[FAIL] class=%0d expected accept", cls);
        errors = errors + 1;
      end
      if (!exp_accept && !drop) begin
        $display("[FAIL] class=%0d expected drop", cls);
        errors = errors + 1;
      end
      @(posedge clk);
      #0;
      pkt_valid = 1'b0;
      @(posedge clk);
    end
  endtask

  initial begin
    errors     = 0;
    tokens     = 16'd3;
    pkt_valid  = 0;
    pkt_class  = 0;
    rst_n      = 0;
    @(posedge clk);
    @(posedge clk);
    rst_n      = 1;
    @(posedge clk);

    send_pkt(4'd0, 1);
    send_pkt(4'd0, 1);
    send_pkt(4'd0, 1);
    send_pkt(4'd0, 0);

    send_pkt(4'd5, 1);
    send_pkt(4'd5, 1);
    send_pkt(4'd5, 1);
    send_pkt(4'd5, 0);

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED: %0d test(s)", errors);
    $finish;
  end

endmodule
