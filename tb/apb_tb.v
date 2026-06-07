`timescale 1ns/1ps

module apb_tb;

  reg        pclk;
  reg        presetn;
  reg [11:0] paddr;
  reg        psel;
  reg        penable;
  reg        pwrite;
  reg [31:0] pwdata;
  wire [31:0] prdata;
  wire       pready;
  wire       pslverr;

  apb uut (
    .pclk(pclk),
    .presetn(presetn),
    .paddr(paddr),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr)
  );

  integer errors;

  initial pclk = 0;
  always #5 pclk = ~pclk;

  task apb_write;
    input [11:0] addr;
    input [31:0] data;
    begin
      @(posedge pclk);
      psel    = 1;
      penable = 0;
      pwrite  = 1;
      paddr   = addr;
      pwdata  = data;
      @(posedge pclk);
      penable = 1;
      @(posedge pclk);
      psel    = 0;
      penable = 0;
    end
  endtask

  task apb_read;
    input  [11:0] addr;
    output [31:0] data;
    begin
      @(posedge pclk);
      psel    = 1;
      penable = 0;
      pwrite  = 0;
      paddr   = addr;
      @(posedge pclk);
      penable = 1;
      @(posedge pclk);
      data    = prdata;
      psel    = 0;
      penable = 0;
    end
  endtask

  reg [31:0] rd;

  initial begin
    errors  = 0;
    presetn = 0;
    psel    = 0;
    penable = 0;
    #20;
    presetn = 1;
    #10;

    apb_write(12'h0, 32'hDEADBEEF);
    apb_write(12'h4, 32'hCAFEBABE);
    apb_read(12'h0, rd);
    if (rd !== 32'hDEADBEEF) begin
      $display("[FAIL] reg0 expected DEADBEEF got %h", rd);
      errors = errors + 1;
    end
    apb_read(12'h4, rd);
    if (rd !== 32'hCAFEBABE) begin
      $display("[FAIL] reg1 expected CAFEBABE got %h", rd);
      errors = errors + 1;
    end
    if (pslverr !== 0) begin
      $display("[FAIL] unexpected pslverr");
      errors = errors + 1;
    end

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED: %0d test(s)", errors);
    $finish;
  end

endmodule
