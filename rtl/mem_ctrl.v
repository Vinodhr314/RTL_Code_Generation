// mem_ctrl — memory controller stub (Verilog-2005)
module mem_ctrl (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_wen,
    input  wire        cpu_ren,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_ready,
    output reg  [31:0] ext_addr,
    output reg  [31:0] ext_wdata,
    output reg         ext_wen,
    output reg         ext_ren,
    input  wire [31:0] ext_rdata,
    input  wire        ext_ready
);
    reg [31:0] sram [0:255];
    wire internal = (cpu_addr[31:28] == 4'h0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_rdata <= 32'h0; cpu_ready <= 1'b0;
            ext_addr <= 32'h0; ext_wdata <= 32'h0;
            ext_wen <= 1'b0; ext_ren <= 1'b0;
        end else begin
            cpu_ready <= 1'b0;
            ext_wen <= 1'b0;
            ext_ren <= 1'b0;
            if (cpu_wen || cpu_ren) begin
                if (internal) begin
                    if (cpu_wen)
                        sram[cpu_addr[9:2]] <= cpu_wdata;
                    if (cpu_ren)
                        cpu_rdata <= sram[cpu_addr[9:2]];
                    cpu_ready <= 1'b1;
                end else begin
                    ext_addr <= cpu_addr;
                    ext_wdata <= cpu_wdata;
                    ext_wen <= cpu_wen;
                    ext_ren <= cpu_ren;
                    if (ext_ready) begin
                        cpu_rdata <= ext_rdata;
                        cpu_ready <= 1'b1;
                    end
                end
            end
        end
    end
endmodule
