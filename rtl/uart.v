// uart — APB UART stub (Verilog-2005)
module uart (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tx,
    output reg         rx,
    input  wire [31:0] pwdata,
    input  wire [11:0] paddr,
    input  wire        pwrite,
    input  wire        psel,
    input  wire        penable,
    output reg  [31:0] prdata,
    output reg         pready,
    output reg         irq
);
    reg [31:0] regs [0:3];
    reg [11:0] addr_latch;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regs[0] <= 32'h0; regs[1] <= 32'h0; regs[2] <= 32'h0; regs[3] <= 32'h0;
            prdata <= 32'h0; pready <= 1'b0; irq <= 1'b0; rx <= 1'b1;
            addr_latch <= 12'h0;
        end else begin
            pready <= 1'b0; irq <= 1'b0;
            if (psel && !penable)
                addr_latch <= paddr;
            if (psel && penable) begin
                pready <= 1'b1;
                if (pwrite)
                    regs[addr_latch[3:2]] <= pwdata;
                else
                    prdata <= regs[addr_latch[3:2]];
            end
            if (regs[0][0])
                irq <= 1'b1;
        end
    end
endmodule
