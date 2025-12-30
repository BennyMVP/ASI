`timescale 1ns/1ps
module window_gen_3x3_flat #(
 parameter int IMG_W = 8,
 parameter int IMG_H = 8
)(
 input logic clk,
 input logic rst,
 input logic in_valid,
 input logic signed [8:0] in_pixel,
 output logic win_valid,
 output logic [80:0] win_flat, // 9*9=81 bit, idx*9 +: 9
 output logic [$clog2(IMG_W)-1:0] out_x,
 output logic [$clog2(IMG_H)-1:0] out_y
);
 logic signed [8:0] line1 [0:IMG_W-1];
 logic signed [8:0] line2 [0:IMG_W-1];
 logic signed [8:0] s0[0:2], s1[0:2], s2[0:2];
 int unsigned x, y;
 integer k;
 // helper macro-like: scrive val nello slot idx
 task automatic put9(input int idx, input logic signed [8:0] val);
 begin
 win_flat[idx*9 +: 9] <= val;
 end
 endtask
 always_ff @(posedge clk) begin
 if (rst) begin
 x <= 0; y <= 0;
 win_valid <= 0;
 out_x <= '0; out_y <= '0;
 win_flat <= '0;
 for (k = 0; k < IMG_W; k = k + 1) begin
 line1[k] <= '0;
 line2[k] <= '0;
 end
 for (k = 0; k < 3; k = k + 1) begin
 s0[k] <= '0; s1[k] <= '0; s2[k] <= '0;
 end
 end else begin
 win_valid <= 0;
 if (in_valid) begin
 // shift colonne
 s0[0] <= s0[1]; s0[1] <= s0[2]; s0[2] <= line2[x];
 s1[0] <= s1[1]; s1[1] <= s1[2]; s1[2] <= line1[x];
 s2[0] <= s2[1]; s2[1] <= s2[2]; s2[2] <= in_pixel;
 // line buffers
 line2[x] <= line1[x];
 line1[x] <= in_pixel;
 // finestra valida
 if (y >= 2 && x >= 2) begin
 // idx = r*3 + c
 put9(0, s0[0]); put9(1, s0[1]); put9(2, s0[2]);
 put9(3, s1[0]); put9(4, s1[1]); put9(5, s1[2]);
 put9(6, s2[0]); put9(7, s2[1]); put9(8, s2[2]);
 win_valid <= 1;
 out_x <= x - 2;
 out_y <= y - 2;
 end
 // raster scan
 if (x == IMG_W-1) begin
 x <= 0;
 if (y != IMG_H-1) y <= y + 1;
 end else begin
 x <= x + 1;
 end
 end
 end
 end
endmodule
