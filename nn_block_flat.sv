`timescale 1ns/1ps
import nn_pkg::*;
module nn_block_flat #(
 parameter int SHIFT_NORM = nn_pkg::SHIFT_NORM
)(
 input logic clk,
 input logic rst,
 input logic [80:0] win_flat,
 input logic signed [7:0] k00, k01, k02,
 input logic signed [7:0] k10, k11, k12,
 input logic signed [7:0] k20, k21, k22,
 input logic signed [7:0] bias,
 input logic signed [7:0] scale,
 input logic signed [7:0] offset,
 input logic signed [W_W-1:0] w0,
 input logic signed [W_W-1:0] w1,
 input logic signed [W_W-1:0] w2,
 output logic signed [RES_W-1:0] conv_result,
 output logic signed [RES_W-1:0] norm_result,
 output logic signed [ACC_FC_W-1:0] acc0,
 output logic signed [ACC_FC_W-1:0] acc1,
 output logic signed [ACC_FC_W-1:0] acc2
);
 function automatic logic signed [8:0] pix(input int idx);
 begin
 pix = $signed(win_flat[idx*9 +: 9]);
 end
 endfunction
 // CONV (comb + reg)
 integer signed sum_temp;
 integer signed sum_next;
 always_comb begin
 sum_temp =
 pix(0)*k00 + pix(1)*k01 + pix(2)*k02 +
 pix(3)*k10 + pix(4)*k11 + pix(5)*k12 +
 pix(6)*k20 + pix(7)*k21 + pix(8)*k22;
 sum_next = (sum_temp <<< 1) + $signed(bias);
 end
 always_ff @(posedge clk) begin
 if (rst) conv_result <= '0;
 else conv_result <= sum_next[RES_W-1:0];
 end
 // NORM+ReLU (comb + reg)
 localparam int PROD_W = RES_W + 8;
 logic signed [PROD_W-1:0] prod;
 integer signed prod_shifted;
 integer signed sum_off;
 integer signed norm_next;
 always_comb begin
 prod = $signed(conv_result) * $signed(scale);
 if (SHIFT_NORM > 0) prod_shifted = $signed(prod) >>> SHIFT_NORM;
 else if (SHIFT_NORM < 0) prod_shifted = $signed(prod) <<< (-SHIFT_NORM);
 else prod_shifted = $signed(prod);
 sum_off = prod_shifted + $signed(offset);
 norm_next = (sum_off < 0) ? 0 : sum_off;
 end
 always_ff @(posedge clk) begin
 if (rst) norm_result <= '0;
 else norm_result <= norm_next[RES_W-1:0];
 end
 // FC combinatorio
 always_comb begin
 acc0 = $signed(norm_result) * $signed(w0);
 acc1 = $signed(norm_result) * $signed(w1);
 acc2 = $signed(norm_result) * $signed(w2);
 end
endmodule
