`timescale 1ns/1ps

module aes_tb;

  reg         clk;
  reg         rst_n;
  reg         mode;
  reg [255:0] key;
  reg [127:0] block_in;
  wire [127:0] block_out;
  reg         valid;
  wire        done;

  aes uut (
    .clk(clk),
    .rst_n(rst_n),
    .mode(mode),
    .key(key),
    .block_in(block_in),
    .block_out(block_out),
    .valid(valid),
    .done(done)
  );

  integer errors;
  integer cycles;

  initial clk = 0;
  always #5 clk = ~clk;

  task aes_op;
    input         enc_mode;
    input [127:0] plain;
    input [127:0] exp_cipher;
    begin
      mode     = enc_mode;
      block_in = plain;
      valid    = 1'b1;
      @(posedge clk);
      @(negedge clk);
      if (!done) begin
        $display("[FAIL] AES done not asserted enc=%0d", enc_mode);
        errors = errors + 1;
      end else if (enc_mode == 0 && block_out !== exp_cipher) begin
        $display("[FAIL] encrypt expected %h got %h", exp_cipher, block_out);
        errors = errors + 1;
      end
      valid = 1'b0;
      @(posedge clk);
    end
  endtask

  initial begin
    errors = 0;
    rst_n  = 0;
    valid  = 0;
    mode   = 0;
    key    = 256'h0;
    #20;
    rst_n  = 1;
    #10;

    key = {128'h0, 128'h000102030405060708090a0b0c0d0e0f};
    aes_op(1'b0,
           128'h00112233445566778899aabbccddeeff,
           128'h69c4e0d86a7b0430d8cdb78070b4c55a);

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED: %0d test(s)", errors);
    $finish;
  end

endmodule
