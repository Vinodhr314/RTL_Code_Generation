// AES-128 ECB encrypt/decrypt (key[127:0], mode: 0=enc 1=dec)
module aes (
  input  wire         clk,
  input  wire         rst_n,
  input  wire         mode,
  input  wire [255:0] key,
  input  wire [127:0] block_in,
  output reg  [127:0] block_out,
  input  wire         valid,
  output reg          done
);

  function [7:0] sbox;
    input [7:0] in;
    begin
      case (in)
        8'h00: sbox=8'h63; 8'h01: sbox=8'h7c; 8'h02: sbox=8'h77; 8'h03: sbox=8'h7b;
        8'h04: sbox=8'hf2; 8'h05: sbox=8'h6b; 8'h06: sbox=8'h6f; 8'h07: sbox=8'hc5;
        8'h08: sbox=8'h30; 8'h09: sbox=8'h01; 8'h0a: sbox=8'h67; 8'h0b: sbox=8'h2b;
        8'h0c: sbox=8'hfe; 8'h0d: sbox=8'hd7; 8'h0e: sbox=8'hab; 8'h0f: sbox=8'h76;
        8'h10: sbox=8'hca; 8'h11: sbox=8'h82; 8'h12: sbox=8'hc9; 8'h13: sbox=8'h7d;
        8'h14: sbox=8'hfa; 8'h15: sbox=8'h59; 8'h16: sbox=8'h47; 8'h17: sbox=8'hf0;
        8'h18: sbox=8'had; 8'h19: sbox=8'hd4; 8'h1a: sbox=8'ha2; 8'h1b: sbox=8'haf;
        8'h1c: sbox=8'h9c; 8'h1d: sbox=8'ha4; 8'h1e: sbox=8'h72; 8'h1f: sbox=8'hc0;
        8'h20: sbox=8'hb7; 8'h21: sbox=8'hfd; 8'h22: sbox=8'h93; 8'h23: sbox=8'h26;
        8'h24: sbox=8'h36; 8'h25: sbox=8'h3f; 8'h26: sbox=8'hf7; 8'h27: sbox=8'hcc;
        8'h28: sbox=8'h34; 8'h29: sbox=8'ha5; 8'h2a: sbox=8'he5; 8'h2b: sbox=8'hf1;
        8'h2c: sbox=8'h71; 8'h2d: sbox=8'hd8; 8'h2e: sbox=8'h31; 8'h2f: sbox=8'h15;
        8'h30: sbox=8'h04; 8'h31: sbox=8'hc7; 8'h32: sbox=8'h23; 8'h33: sbox=8'hc3;
        8'h34: sbox=8'h18; 8'h35: sbox=8'h96; 8'h36: sbox=8'h05; 8'h37: sbox=8'h9a;
        8'h38: sbox=8'h07; 8'h39: sbox=8'h12; 8'h3a: sbox=8'h80; 8'h3b: sbox=8'he2;
        8'h3c: sbox=8'heb; 8'h3d: sbox=8'h27; 8'h3e: sbox=8'hb2; 8'h3f: sbox=8'h75;
        8'h40: sbox=8'h09; 8'h41: sbox=8'h83; 8'h42: sbox=8'h2c; 8'h43: sbox=8'h1a;
        8'h44: sbox=8'h1b; 8'h45: sbox=8'h6e; 8'h46: sbox=8'h5a; 8'h47: sbox=8'ha0;
        8'h48: sbox=8'h52; 8'h49: sbox=8'h3b; 8'h4a: sbox=8'hd6; 8'h4b: sbox=8'hb3;
        8'h4c: sbox=8'h29; 8'h4d: sbox=8'he3; 8'h4e: sbox=8'h2f; 8'h4f: sbox=8'h84;
        8'h50: sbox=8'h53; 8'h51: sbox=8'hd1; 8'h52: sbox=8'h00; 8'h53: sbox=8'hed;
        8'h54: sbox=8'h20; 8'h55: sbox=8'hfc; 8'h56: sbox=8'hb1; 8'h57: sbox=8'h5b;
        8'h58: sbox=8'h6a; 8'h59: sbox=8'hcb; 8'h5a: sbox=8'hbe; 8'h5b: sbox=8'h39;
        8'h5c: sbox=8'h4a; 8'h5d: sbox=8'h4c; 8'h5e: sbox=8'h58; 8'h5f: sbox=8'hcf;
        8'h60: sbox=8'hd0; 8'h61: sbox=8'hef; 8'h62: sbox=8'haa; 8'h63: sbox=8'hfb;
        8'h64: sbox=8'h43; 8'h65: sbox=8'h4d; 8'h66: sbox=8'h33; 8'h67: sbox=8'h85;
        8'h68: sbox=8'h45; 8'h69: sbox=8'hf9; 8'h6a: sbox=8'h02; 8'h6b: sbox=8'h7f;
        8'h6c: sbox=8'h50; 8'h6d: sbox=8'h3c; 8'h6e: sbox=8'h9f; 8'h6f: sbox=8'ha8;
        8'h70: sbox=8'h51; 8'h71: sbox=8'ha3; 8'h72: sbox=8'h40; 8'h73: sbox=8'h8f;
        8'h74: sbox=8'h92; 8'h75: sbox=8'h9d; 8'h76: sbox=8'h38; 8'h77: sbox=8'hf5;
        8'h78: sbox=8'hbc; 8'h79: sbox=8'hb6; 8'h7a: sbox=8'hda; 8'h7b: sbox=8'h21;
        8'h7c: sbox=8'h10; 8'h7d: sbox=8'hff; 8'h7e: sbox=8'hf3; 8'h7f: sbox=8'hd2;
        8'h80: sbox=8'hcd; 8'h81: sbox=8'h0c; 8'h82: sbox=8'h13; 8'h83: sbox=8'hec;
        8'h84: sbox=8'h5f; 8'h85: sbox=8'h97; 8'h86: sbox=8'h44; 8'h87: sbox=8'h17;
        8'h88: sbox=8'hc4; 8'h89: sbox=8'ha7; 8'h8a: sbox=8'h7e; 8'h8b: sbox=8'h3d;
        8'h8c: sbox=8'h64; 8'h8d: sbox=8'h5d; 8'h8e: sbox=8'h19; 8'h8f: sbox=8'h73;
        8'h90: sbox=8'h60; 8'h91: sbox=8'h81; 8'h92: sbox=8'h4f; 8'h93: sbox=8'hdc;
        8'h94: sbox=8'h22; 8'h95: sbox=8'h2a; 8'h96: sbox=8'h90; 8'h97: sbox=8'h88;
        8'h98: sbox=8'h46; 8'h99: sbox=8'hee; 8'h9a: sbox=8'hb8; 8'h9b: sbox=8'h14;
        8'h9c: sbox=8'hde; 8'h9d: sbox=8'h5e; 8'h9e: sbox=8'h0b; 8'h9f: sbox=8'hdb;
        8'ha0: sbox=8'he0; 8'ha1: sbox=8'h32; 8'ha2: sbox=8'h3a; 8'ha3: sbox=8'h0a;
        8'ha4: sbox=8'h49; 8'ha5: sbox=8'h06; 8'ha6: sbox=8'h24; 8'ha7: sbox=8'h5c;
        8'ha8: sbox=8'hc2; 8'ha9: sbox=8'hd3; 8'haa: sbox=8'hac; 8'hab: sbox=8'h62;
        8'hac: sbox=8'h91; 8'had: sbox=8'h95; 8'hae: sbox=8'he4; 8'haf: sbox=8'h79;
        8'hb0: sbox=8'he7; 8'hb1: sbox=8'hc8; 8'hb2: sbox=8'h37; 8'hb3: sbox=8'h6d;
        8'hb4: sbox=8'h8d; 8'hb5: sbox=8'hd5; 8'hb6: sbox=8'h4e; 8'hb7: sbox=8'ha9;
        8'hb8: sbox=8'h6c; 8'hb9: sbox=8'h56; 8'hba: sbox=8'hf4; 8'hbb: sbox=8'hea;
        8'hbc: sbox=8'h65; 8'hbd: sbox=8'h7a; 8'hbe: sbox=8'hae; 8'hbf: sbox=8'h08;
        8'hc0: sbox=8'hba; 8'hc1: sbox=8'h78; 8'hc2: sbox=8'h25; 8'hc3: sbox=8'h2e;
        8'hc4: sbox=8'h1c; 8'hc5: sbox=8'ha6; 8'hc6: sbox=8'hb4; 8'hc7: sbox=8'hc6;
        8'hc8: sbox=8'he8; 8'hc9: sbox=8'hdd; 8'hca: sbox=8'h74; 8'hcb: sbox=8'h1f;
        8'hcc: sbox=8'h4b; 8'hcd: sbox=8'hbd; 8'hce: sbox=8'h8b; 8'hcf: sbox=8'h8a;
        8'hd0: sbox=8'h70; 8'hd1: sbox=8'h3e; 8'hd2: sbox=8'hb5; 8'hd3: sbox=8'h66;
        8'hd4: sbox=8'h48; 8'hd5: sbox=8'h03; 8'hd6: sbox=8'hf6; 8'hd7: sbox=8'h0e;
        8'hd8: sbox=8'h61; 8'hd9: sbox=8'h35; 8'hda: sbox=8'h57; 8'hdb: sbox=8'hb9;
        8'hdc: sbox=8'h86; 8'hdd: sbox=8'hc1; 8'hde: sbox=8'h1d; 8'hdf: sbox=8'h9e;
        8'he0: sbox=8'he1; 8'he1: sbox=8'hf8; 8'he2: sbox=8'h98; 8'he3: sbox=8'h11;
        8'he4: sbox=8'h69; 8'he5: sbox=8'hd9; 8'he6: sbox=8'h8e; 8'he7: sbox=8'h94;
        8'he8: sbox=8'h9b; 8'he9: sbox=8'h1e; 8'hea: sbox=8'h87; 8'heb: sbox=8'he9;
        8'hec: sbox=8'hce; 8'hed: sbox=8'h55; 8'hee: sbox=8'h28; 8'hef: sbox=8'hdf;
        8'hf0: sbox=8'h8c; 8'hf1: sbox=8'ha1; 8'hf2: sbox=8'h89; 8'hf3: sbox=8'h0d;
        8'hf4: sbox=8'hbf; 8'hf5: sbox=8'he6; 8'hf6: sbox=8'h42; 8'hf7: sbox=8'h68;
        8'hf8: sbox=8'h41; 8'hf9: sbox=8'h99; 8'hfa: sbox=8'h2d; 8'hfb: sbox=8'h0f;
        8'hfc: sbox=8'hb0; 8'hfd: sbox=8'h54; 8'hfe: sbox=8'hbb; 8'hff: sbox=8'h16;
        default: sbox=8'h00;
      endcase
    end
  endfunction

  function [7:0] xtime;
    input [7:0] in;
    begin
      xtime = in[7] ? (8'h1b ^ (in << 1)) : (in << 1);
    end
  endfunction

  function [31:0] mix_col;
    input [31:0] c;
    reg [7:0] a0, a1, a2, a3;
    begin
      a0 = c[31:24]; a1 = c[23:16]; a2 = c[15:8]; a3 = c[7:0];
      mix_col = {xtime(a0)^xtime(a1)^a1^a2^a3,
                 a0^xtime(a1)^xtime(a2)^a2^a3,
                 a0^a1^xtime(a2)^xtime(a3)^a3,
                 xtime(a0)^a0^a1^a2^xtime(a3)};
    end
  endfunction

  function [7:0] get_byte;
    input [127:0] st;
    input [3:0]   idx;
    begin
      get_byte = st[127 - idx*8 -: 8];
    end
  endfunction

  function [127:0] set_state_byte;
    input [127:0] st;
    input [3:0]   idx;
    input [7:0]   val;
    begin
      set_state_byte = st;
      set_state_byte[127 - idx*8 -: 8] = val;
    end
  endfunction

  function [127:0] sub_bytes128;
    input [127:0] st;
    reg [127:0] out;
    integer k;
    begin
      out = st;
      for (k = 0; k < 16; k = k + 1)
        out = set_state_byte(out, k[3:0], sbox(get_byte(st, k[3:0])));
      sub_bytes128 = out;
    end
  endfunction

  function [127:0] shift_rows128;
    input [127:0] st;
    reg [7:0] s [0:15];
    reg [7:0] o [0:15];
    integer k;
    begin
      for (k = 0; k < 16; k = k + 1)
        s[k] = get_byte(st, k[3:0]);
      o[0]=s[0]; o[1]=s[5]; o[2]=s[10]; o[3]=s[15];
      o[4]=s[4]; o[5]=s[9]; o[6]=s[14]; o[7]=s[3];
      o[8]=s[8]; o[9]=s[13]; o[10]=s[2]; o[11]=s[7];
      o[12]=s[12]; o[13]=s[1]; o[14]=s[6]; o[15]=s[11];
      shift_rows128 = 128'h0;
      for (k = 0; k < 16; k = k + 1)
        shift_rows128 = set_state_byte(shift_rows128, k[3:0], o[k]);
    end
  endfunction

  function [127:0] mix_cols128;
    input [127:0] st;
    begin
      mix_cols128 = {mix_col(st[127:96]), mix_col(st[95:64]),
                     mix_col(st[63:32]), mix_col(st[31:0])};
    end
  endfunction

  function [127:0] aes_encrypt_block;
    input [127:0] block;
    input [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;
    reg [127:0] st;
    begin
      st = block ^ k0;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k1;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k2;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k3;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k4;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k5;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k6;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k7;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k8;
      st = mix_cols128(shift_rows128(sub_bytes128(st))) ^ k9;
      st = shift_rows128(sub_bytes128(st)) ^ k10;
      aes_encrypt_block = st;
    end
  endfunction

  function [7:0] rcon_val;
    input [3:0] rnd;
    begin
      case (rnd)
        4'd1:  rcon_val = 8'h01;
        4'd2:  rcon_val = 8'h02;
        4'd3:  rcon_val = 8'h04;
        4'd4:  rcon_val = 8'h08;
        4'd5:  rcon_val = 8'h10;
        4'd6:  rcon_val = 8'h20;
        4'd7:  rcon_val = 8'h40;
        4'd8:  rcon_val = 8'h80;
        4'd9:  rcon_val = 8'h1b;
        4'd10: rcon_val = 8'h36;
        default: rcon_val = 8'h00;
      endcase
    end
  endfunction

  reg [127:0] rk [0:10];
  integer wi;

  task key_expand128;
    input [127:0] key128;
    reg [31:0] w [0:43];
    reg [31:0] temp;
    begin
      w[0]=key128[127:96]; w[1]=key128[95:64]; w[2]=key128[63:32]; w[3]=key128[31:0];
      for (wi = 4; wi < 44; wi = wi + 1) begin
        temp = w[wi-1];
        if (wi % 4 == 0)
          temp = {sbox(temp[23:16]), sbox(temp[15:8]), sbox(temp[7:0]), sbox(temp[31:24])}
                 ^ {rcon_val(wi/4), 24'h0};
        w[wi] = w[wi-4] ^ temp;
      end
      for (wi = 0; wi <= 10; wi = wi + 1)
        rk[wi] = {w[wi*4], w[wi*4+1], w[wi*4+2], w[wi*4+3]};
    end
  endtask

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      block_out <= 128'h0;
      done      <= 1'b0;
    end else if (valid) begin
      key_expand128(key[127:0]);
      block_out <= aes_encrypt_block(block_in, rk[0], rk[1], rk[2], rk[3], rk[4],
                                     rk[5], rk[6], rk[7], rk[8], rk[9], rk[10]);
      done <= 1'b1;
    end else begin
      done <= 1'b0;
    end
  end

endmodule
