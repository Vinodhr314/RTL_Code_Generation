`timescale 1ns/1ps

module adder_8bit_tb;

  reg  [7:0] a;
  reg  [7:0] b;
  wire [8:0] sum;

  adder_8bit uut (
    .a(a),
    .b(b),
    .sum(sum)
  );

  integer errors;
  integer i;

  task check;
    input [7:0] ta;
    input [7:0] tb;
    input [8:0] expected;
    begin
      a = ta;
      b = tb;
      #1;
      if (sum !== expected) begin
        $display("[FAIL] a=%h b=%h expected=%h got=%h", ta, tb, expected, sum);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    errors = 0;
    check(8'h00, 8'h00, 9'h000);
    check(8'h01, 8'h01, 9'h002);
    check(8'hFF, 8'h01, 9'h100);
    check(8'hFF, 8'hFF, 9'h1FE);
    for (i = 0; i < 16; i = i + 1)
      check(i[7:0], (8'd255 - i[7:0]), 9'd255);

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED: %0d test(s)", errors);
    $finish;
  end

endmodule
