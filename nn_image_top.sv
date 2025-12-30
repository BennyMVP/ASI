`timescale 1ns/1ps
import nn_pkg::*;
module nn_image_top #(
 parameter int IMG_W = 8,
 parameter int IMG_H = 8
)(
 input logic clk,
 input logic rst,
 input logic in_valid,
 input logic signed [8:0] in_pixel,
 // Kernel 3x3 (scalari)
 input logic signed [7:0] k00, k01, k02,
 input logic signed [7:0] k10, k11, k12,
 input logic signed [7:0] k20, k21, k22,
 input logic signed [7:0] bias,
 input logic signed [7:0] scale,
 input logic signed [7:0] offset,
 // Pesi FC (scalari)
 input logic signed [W_W-1:0] w0,
 input logic signed [W_W-1:0] w1,
 input logic signed [W_W-1:0] w2,
 output logic out_valid,
 output logic signed [RES_W-1:0] conv_result,
 output logic signed [RES_W-1:0] norm_result,
 output logic signed [ACC_FC_W-1:0] acc0,
 output logic signed [ACC_FC_W-1:0] acc1,
 output logic signed [ACC_FC_W-1:0] acc2,
 output logic [$clog2(IMG_W)-1:0] out_x,
 output logic [$clog2(IMG_H)-1:0] out_y
);
 // ===== Window generator FLAT =====
 logic win_valid;
 logic [80:0] win_flat; // 9 pixel * 9 bit = 81
 logic [$clog2(IMG_W)-1:0] win_x;
 logic [$clog2(IMG_H)-1:0] win_y;
 window_gen_3x3_flat #(
 .IMG_W(IMG_W),
 .IMG_H(IMG_H)
 ) u_win (
 .clk (clk),
 .rst (rst),
 .in_valid (in_valid),
 .in_pixel (in_pixel),
 .win_valid(win_valid),
 .win_flat (win_flat),
 .out_x (win_x),
 .out_y (win_y)
 );
 // ===== Core FLAT (2 cicli: conv reg + norm reg) =====
 nn_block_flat #(
 .SHIFT_NORM(SHIFT_NORM)
 ) u_core (
 .clk (clk),
 .rst (rst),
 .win_flat (win_flat),
 .k00(k00), .k01(k01), .k02(k02),
 .k10(k10), .k11(k11), .k12(k12),
 .k20(k20), .k21(k21), .k22(k22),
 .bias (bias),
 .scale (scale),
 .offset (offset),
 .w0(w0),
 .w1(w1),
 .w2(w2),
 .conv_result(conv_result),
 .norm_result(norm_result),
 .acc0(acc0),
 .acc1(acc1),
 .acc2(acc2)
 );
 // ===== Pipeline valid + coordinate (2 cicli) =====
 logic [1:0] vpipe;
 logic [$clog2(IMG_W)-1:0] x_pipe0, x_pipe1;
 logic [$clog2(IMG_H)-1:0] y_pipe0, y_pipe1;
 always_ff @(posedge clk) begin
 if (rst) begin
 vpipe <= 2'b00;
 x_pipe0 <= '0; x_pipe1 <= '0;
 y_pipe0 <= '0; y_pipe1 <= '0;
 end else begin
 // valid delay 2 cicli
 vpipe <= {vpipe[0], win_valid};
 // campiona coordinate quando window valida
 if (win_valid) begin
 x_pipe0 <= win_x;
 y_pipe0 <= win_y;
 end
 // shift coordinate (2 cicli)
 x_pipe1 <= x_pipe0;
 y_pipe1 <= y_pipe0;
 end
 end
 assign out_valid = vpipe[1];
 assign out_x = x_pipe1;
 assign out_y = y_pipe1;
endmodule
