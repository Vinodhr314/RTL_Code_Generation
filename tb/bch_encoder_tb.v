`timescale 1ns/1ps
// BCH(15,5,3) encoder TB
// Parity columns (x^(10+i) mod g(x)):
//   d[4]=1: parity=10'h29B  -> codeword = {5'h10, 10'h29B} = 15'h429B
//   d[3]=1: parity=10'h3D6  -> codeword = {5'h08, 10'h3D6} = 15'h23D6 (but 5'b01000 = 8, so {8,0x3D6}=0x23D6? Let me recalculate)
//   Actually codeword = {data[4:0], parity[9:0]}
//   data=5'b00001 (d[0]=1): parity=0x137 -> codeword={5'h01, 10'h137}=0x0537
//   data=5'b00010 (d[1]=1): parity=0x26E -> codeword={5'h02, 10'h26E}=0x0A6E? 5'b00010<<10 = 0x0800, |0x26E = 0x0A6E
//   data=5'b00100 (d[2]=1): parity=0x1EB -> codeword={5'h04, 10'h1EB}=0x11EB (5'b00100<<10=0x1000, |0x1EB=0x11EB)
//   data=5'b01000 (d[3]=1): parity=0x3D6 -> codeword={5'h08, 10'h3D6}=0x23D6 (5'b01000<<10=0x2000, |0x3D6=0x23D6)
//   data=5'b10000 (d[4]=1): parity=0x29B -> codeword={5'h10, 10'h29B}=0x429B (5'b10000<<10=0x4000, |0x29B=0x429B)
//   data=5'b11111: parity = XOR of all 5 = 0x29B^0x3D6^0x1EB^0x26E^0x137 = ?
//     0x29B ^ 0x3D6 = 0x14D
//     0x14D ^ 0x1EB = 0x0A6
//     0x0A6 ^ 0x26E = 0x2C8
//     0x2C8 ^ 0x137 = 0x3FF
//   codeword={5'h1F, 10'h3FF}=0x7FFF
module bch_encoder_tb;

    reg        clk, rst_n;
    reg  [7:0] data_in;
    reg        valid;
    wire [14:0] codeword;
    wire        done;

    bch_encoder dut (
        .clk(clk), .rst_n(rst_n),
        .data_in(data_in), .valid(valid),
        .codeword(codeword), .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    task encode_check;
        input [7:0]  din;
        input [14:0] expected_cw;
        input [7:0]  tnum;
        begin
            // Set inputs before posedge
            data_in = din;
            valid   = 1'b1;
            @(posedge clk); // DUT latches at this edge
            #0; valid = 1'b0;
            // At next posedge: done=1, codeword=expected
            @(posedge clk);
            if (done !== 1'b1) begin
                $display("[FAIL] T%0d: done not asserted for data=%02h", tnum, din);
                fail = fail + 1;
            end
            if (codeword !== expected_cw) begin
                $display("[FAIL] T%0d: data=%02h codeword=%04h, expected=%04h",
                         tnum, din, codeword, expected_cw);
                fail = fail + 1;
            end
            // Allow done to deassert before next test
            @(posedge clk);
            if (done !== 1'b0) begin
                $display("[FAIL] T%0d: done still high after valid deasserted", tnum);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        rst_n   = 1'b0;
        valid   = 1'b0;
        data_in = 8'h00;

        // Sync reset: 2+ posedges
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // Test vectors (5-bit data, expected 15-bit systematic codeword)
        encode_check(8'h00, 15'h0000, 1); // data=0 -> codeword=0
        encode_check(8'h01, 15'h0537, 2); // d[0]=1 -> parity=0x137
        encode_check(8'h02, 15'h0A6E, 3); // d[1]=1 -> parity=0x26E
        encode_check(8'h04, 15'h11EB, 4); // d[2]=1 -> parity=0x1EB
        encode_check(8'h08, 15'h23D6, 5); // d[3]=1 -> parity=0x3D6
        encode_check(8'h10, 15'h429B, 6); // d[4]=1 -> parity=0x29B
        encode_check(8'h1F, 15'h7FFF, 7); // all 1s -> parity=0x3FF

        // Upper bits of data_in are ignored (only [4:0] used)
        encode_check(8'hE1, 15'h0537, 8); // data_in[7:5]=111, [4:0]=00001 -> same as test 2

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("[FAIL] %0d test(s) failed", fail);
        $finish;
    end

    initial begin
        #50000;
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
