// APB3 slave — four 32-bit memory-mapped registers
module apb (
  input  wire        pclk,
  input  wire        presetn,
  input  wire [11:0] paddr,
  input  wire        psel,
  input  wire        penable,
  input  wire        pwrite,
  input  wire [31:0] pwdata,
  output reg  [31:0] prdata,
  output reg         pready,
  output wire        pslverr
);

  reg [31:0] regs [0:3];
  reg [11:0] addr_latch;

  assign pslverr = 1'b0;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      regs[0]      <= 32'h0;
      regs[1]      <= 32'h0;
      regs[2]      <= 32'h0;
      regs[3]      <= 32'h0;
      prdata       <= 32'h0;
      pready       <= 1'b0;
      addr_latch   <= 12'h0;
    end else begin
      pready <= 1'b0;
      if (psel && !penable)
        addr_latch <= paddr;
      if (psel && penable) begin
        pready <= 1'b1;
        if (pwrite)
          regs[addr_latch[3:2]] <= pwdata;
        else
          prdata <= regs[addr_latch[3:2]];
      end
    end
  end

endmodule
