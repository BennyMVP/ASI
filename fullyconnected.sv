`timescale 1ns/1ps
module c_acc #(
 parameter int IN_W = 22,
 parameter int W_W = 8,
 parameter int ACC_W = 40
)(
 input logic signed [IN_W-1:0] norm_val,
 input logic signed [W_W-1:0] weight0,
 input logic signed [W_W-1:0] weight1,
 input logic signed [W_W-1:0] weight2,
 output logic signed [ACC_W-1:0] acc0,
 output logic signed [ACC_W-1:0] acc1,
 output logic signed [ACC_W-1:0] acc2
);
 always_comb begin
 acc0 = norm_val * weight0;
 acc1 = norm_val * weight1;
 acc2 = norm_val * weight2;
 end
endmodule
