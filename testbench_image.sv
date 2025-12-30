`timescale 1ns/1ps
module tb_nn_image_top;
 import nn_pkg::*;
 localparam int IMG_W = 8;
 localparam int IMG_H = 8;
 localparam int OUT_W = IMG_W - (K_SIZE-1); // 6
 localparam int OUT_H = IMG_H - (K_SIZE-1); // 6
 logic clk = 0;
 logic rst;
 always #5 clk = ~clk;
 // Stream input
 logic in_valid;
 logic signed [8:0] in_pixel;
 // Kernel scalare 3x3
 logic signed [7:0] k00,k01,k02;
 logic signed [7:0] k10,k11,k12;
 logic signed [7:0] k20,k21,k22;
 // Parametri
 logic signed [7:0] bias, scale, offset;
 // Pesi FC scalari
 logic signed [W_W-1:0] w0, w1, w2;
 // Outputs
 logic out_valid;
 logic signed [RES_W-1:0] conv_result, norm_result;
 logic signed [ACC_FC_W-1:0] acc0, acc1, acc2;
 logic [$clog2(IMG_W)-1:0] out_x;
 logic [$clog2(IMG_H)-1:0] out_y;
 // Immagine di test
 logic signed [8:0] img [0:IMG_H-1][0:IMG_W-1];
 // GOLDEN per 6x6
 integer signed exp_conv [0:OUT_H-1][0:OUT_W-1];
 integer signed exp_norm [0:OUT_H-1][0:OUT_W-1];
 integer signed exp_a0 [0:OUT_H-1][0:OUT_W-1];
 integer signed exp_a1 [0:OUT_H-1][0:OUT_W-1];
 integer signed exp_a2 [0:OUT_H-1][0:OUT_W-1];
 integer r, c;
 integer out_count;
 integer error_count;
 // DUT
 nn_image_top #(
 .IMG_W(IMG_W),
 .IMG_H(IMG_H)
 ) dut (
 .clk(clk),
 .rst(rst),
 .in_valid(in_valid),
 .in_pixel(in_pixel),
 .k00(k00), .k01(k01), .k02(k02),
 .k10(k10), .k11(k11), .k12(k12),
 .k20(k20), .k21(k21), .k22(k22),
 .bias(bias),
 .scale(scale),
 .offset(offset),
 .w0(w0),
 .w1(w1),
 .w2(w2),
 .out_valid(out_valid),
 .conv_result(conv_result),
 .norm_result(norm_result),
 .acc0(acc0),
 .acc1(acc1),
 .acc2(acc2),
 .out_x(out_x),
 .out_y(out_y)
 );
 // Task invio pixel
 task automatic push_pixel(input logic signed [8:0] p);
 begin
 in_valid = 1;
 in_pixel = p;
 @(posedge clk);
 end
 endtask
 // Calcolo golden per tutta la 6x6 (valid)
 task automatic build_golden;
 integer oy, ox;
 integer signed sum9;
 integer signed conv_i;
 integer signed prod;
 integer signed prod_shifted;
 integer signed sum_off;
 integer signed norm_i;
 begin
 for (oy = 0; oy < OUT_H; oy = oy + 1) begin
 for (ox = 0; ox < OUT_W; ox = ox + 1) begin
 sum9 =
 img[oy+0][ox+0]*k00 + img[oy+0][ox+1]*k01 + img[oy+0][ox+2]*k02 +
 img[oy+1][ox+0]*k10 + img[oy+1][ox+1]*k11 + img[oy+1][ox+2]*k12 +
 img[oy+2][ox+0]*k20 + img[oy+2][ox+1]*k21 + img[oy+2][ox+2]*k22;
 conv_i = (sum9 <<< 1) + $signed(bias);
 prod = conv_i * $signed(scale);
 if (SHIFT_NORM > 0) prod_shifted = prod >>> SHIFT_NORM;
 else if (SHIFT_NORM < 0) prod_shifted = prod <<< (-SHIFT_NORM);
 else prod_shifted = prod;
 sum_off = prod_shifted + $signed(offset);
 norm_i = (sum_off < 0) ? 0 : sum_off;
 exp_conv[oy][ox] = conv_i;
 exp_norm[oy][ox] = norm_i;
 exp_a0[oy][ox] = norm_i * $signed(w0);
 exp_a1[oy][ox] = norm_i * $signed(w1);
 exp_a2[oy][ox] = norm_i * $signed(w2);
 end
 end
 end
 endtask
 // Monitor + confronto
 always @(posedge clk) begin
 if (rst) begin
 out_count <= 0;
 error_count <= 0;
 end else if (out_valid) begin
 integer ox, oy;
 integer signed got_conv, got_norm, got0, got1, got2;
 integer signed e_conv, e_norm, e0, e1, e2;
 out_count <= out_count + 1;
 ox = out_x;
 oy = out_y;
 got_conv = $signed(conv_result);
 got_norm = $signed(norm_result);
 got0 = $signed(acc0);
 got1 = $signed(acc1);
 got2 = $signed(acc2);
 e_conv = exp_conv[oy][ox];
 e_norm = exp_norm[oy][ox];
 e0 = exp_a0[oy][ox];
 e1 = exp_a1[oy][ox];
 e2 = exp_a2[oy][ox];
 // stampa sempre (puoi togliere se vuoi)
 $display("OUT[%0d,%0d] conv=%0d norm=%0d acc0=%0d acc1=%0d acc2=%0d",
 ox, oy, got_conv, got_norm, got0, got1, got2);
end
 end
 initial begin
 integer v;
 // init
 in_valid = 0;
 in_pixel = 0;
 out_count = 0;
 error_count = 0;
 // immagine: 1..64
 v = 1;
 for (r = 0; r < IMG_H; r = r + 1) begin
 for (c = 0; c < IMG_W; c = c + 1) begin
 img[r][c] = v;
 v = v + 1;
 end
 end
 // kernel tutti 1
 k00=1; k01=1; k02=1;
 k10=1; k11=1; k12=1;
 k20=1; k21=1; k22=1;
 // parametri
 bias = 0;
 scale = 1;
 offset = 0;
 // pesi
 w0 = 1;
 w1 = 2;
 w2 = 3;
 // costruisci golden PRIMA di far girare lo stream
 build_golden();
 // reset
 rst = 1;
 repeat (2) @(posedge clk);
 rst = 0;
 // manda tutta l’immagine (raster scan)
 for (r = 0; r < IMG_H; r = r + 1) begin
 for (c = 0; c < IMG_W; c = c + 1) begin
 push_pixel(img[r][c]);
 end
 end
 // stop input
 in_valid = 0;
 in_pixel = 0;
 // aspetta che escano tutti gli output (36 + latenza + margine)
 repeat (100) @(posedge clk);
 $display("Totale output validi = %0d (atteso %0d)", out_count, OUT_W*OUT_H);
 if (out_count !== OUT_W*OUT_H)
 $display("ATTENZIONE: count output non coincide!");

 $finish;
 end
endmodule
