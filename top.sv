`timescale 1ns/1ps
import nn_pkg::*;
module nn_block #(
 parameter int K_SIZE = nn_pkg::K_SIZE,
 parameter int PROD_W = nn_pkg::PROD_W,
 parameter int ACC_CONV_W = nn_pkg::ACC_CONV_W,
 parameter int RES_W = nn_pkg::RES_W,
 parameter int W_W = nn_pkg::W_W,
 parameter int ACC_FC_W = nn_pkg::ACC_FC_W,
 parameter int SHIFT_NORM = nn_pkg::SHIFT_NORM
)(
 input logic clk,
 input logic rst,
 input logic signed [8:0] windowImg [0:K_SIZE-1][0:K_SIZE-1],
 input logic signed [7:0] kernelCoeff [0:K_SIZE-1][0:K_SIZE-1],
 input logic signed [7:0] bias,
 input logic signed [7:0] scale,
 input logic signed [7:0] offset,
 input logic signed [W_W-1:0] weight [0:2],
 output logic signed [RES_W-1:0] conv_result,
 output logic signed [RES_W-1:0] norm_result,
 output logic signed [ACC_FC_W-1:0] acc0,
 output logic signed [ACC_FC_W-1:0] acc1,
 output logic signed [ACC_FC_W-1:0] acc2
);
 logic signed [RES_W-1:0] mid_conv;
 logic signed [RES_W-1:0] mid_norm;
 conv2d #(
 .K_SIZE (K_SIZE),
 .PROD_W (PROD_W),
 .ACC_W (ACC_CONV_W),
 .RES_W (RES_W)
 ) u_conv2d (
 .clk (clk),
 .rst (rst),
 .windowImg (windowImg),
 .kernelCoeff(kernelCoeff),
 .bias (bias),
 .result (mid_conv)
 );
 norm_relu #(
 .IN_W (RES_W),
 .SCALE_W (8),
 .OFFSET_W (8),
 .OUT_W (RES_W),
 .SHIFT (SHIFT_NORM)
 ) u_norm_relu (
 .clk (clk),
 .rst (rst),
 .conv_val (mid_conv),
 .scale (scale),
 .offset (offset),
 .norm_relu_val(mid_norm)
 );
 c_acc #(
 .IN_W (RES_W),
 .W_W (W_W),
 .ACC_W (ACC_FC_W)
 ) u_c_acc (
 .norm_val (mid_norm),
 .weight0 (weight[0]),
 .weight1 (weight[1]),
 .weight2 (weight[2]),
 .acc0 (acc0),
 .acc1 (acc1),
 .acc2 (acc2)
 );
 // Uscite “debug”
 assign conv_result = mid_conv;
 assign norm_result = mid_norm;
endmodule
