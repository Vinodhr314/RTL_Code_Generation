// APB bus arbiter: M masters to 1 slave, fixed-priority (M0 highest)
// Parameterized M masters; uses flattened port vectors
// Verilog-2005 synthesizable
module apb_arbiter #(
    parameter M = 2
) (
    input  wire          clk,
    input  wire          rst_n,
    input  wire [M-1:0]  m_req,
    output reg  [M-1:0]  m_grant,
    input  wire [M*12-1:0] m_paddr,   // flattened: m_paddr[(i+1)*12-1:i*12] for master i
    output reg  [11:0]   s_paddr,
    output reg           s_psel,
    output reg           s_penable,
    output reg           s_pwrite,
    output reg  [31:0]   s_pwdata,
    input  wire [31:0]   s_prdata,
    input  wire          s_pready
);

    // Master data signals (flattened pwdata bus: 32b per master)
    // Since design_description only lists m_paddr as a multi-master input,
    // we simplify: data lines are not listed in spec so we treat pwdata as 0
    // and pwrite as a write flag for simplicity in this skeleton.

    reg [$clog2(M)-1:0] active_master;
    reg                  busy;

    // APB state
    localparam APB_IDLE   = 2'd0;
    localparam APB_SETUP  = 2'd1;
    localparam APB_ACCESS = 2'd2;

    reg [1:0] apb_state;

    integer k;

    // Priority encode: find lowest-indexed requesting master
    reg [$clog2(M)-1:0] sel;
    always @(*) begin
        sel = {$clog2(M){1'b0}};
        for (k = M-1; k >= 0; k = k - 1) begin
            if (m_req[k]) sel = k[$clog2(M)-1:0];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_grant      <= {M{1'b0}};
            s_psel       <= 1'b0;
            s_penable    <= 1'b0;
            s_pwrite     <= 1'b0;
            s_paddr      <= 12'h0;
            s_pwdata     <= 32'h0;
            active_master<= {$clog2(M){1'b0}};
            busy         <= 1'b0;
            apb_state    <= APB_IDLE;
        end else begin
            case (apb_state)
                APB_IDLE: begin
                    s_psel    <= 1'b0;
                    s_penable <= 1'b0;
                    m_grant   <= {M{1'b0}};
                    if (|m_req) begin
                        active_master <= sel;
                        m_grant[sel]  <= 1'b1;
                        apb_state     <= APB_SETUP;
                    end
                end

                APB_SETUP: begin
                    // Latch address from winning master
                    s_paddr  <= m_paddr[(active_master * 12) +: 12];
                    s_pwrite <= 1'b0; // read-only skeleton (no pwdata in spec)
                    s_pwdata <= 32'h0;
                    s_psel   <= 1'b1;
                    s_penable<= 1'b0;
                    apb_state<= APB_ACCESS;
                end

                APB_ACCESS: begin
                    s_penable <= 1'b1;
                    if (s_pready) begin
                        s_psel    <= 1'b0;
                        s_penable <= 1'b0;
                        m_grant   <= {M{1'b0}};
                        apb_state <= APB_IDLE;
                    end
                end

                default: apb_state <= APB_IDLE;
            endcase
        end
    end

endmodule
