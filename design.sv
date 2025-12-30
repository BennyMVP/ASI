`timescale 1ns/1ps
module conv2d #(
 parameter int K_SIZE = 3,
 parameter int PROD_W = 17,
 parameter int ACC_W = PROD_W + $clog2(K_SIZE*K_SIZE),
 parameter int RES_W = ACC_W + 1
)(
 input logic clk,
 input logic rst,
 input logic signed [8:0] windowImg [0:K_SIZE-1][0:K_SIZE-1],
 input logic signed [7:0] kernelCoeff [0:K_SIZE-1][0:K_SIZE-1],
 input logic signed [7:0] bias,
 output logic signed [RES_W-1:0] result
);
 logic signed [ACC_W-1:0] sum_temp;
 logic signed [RES_W-1:0] sum_shifted;
 integer i, j;
 always_comb begin
 sum_temp = '0;
 for (i = 0; i < K_SIZE; i++) begin
 for (j = 0; j < K_SIZE; j++) begin
 sum_temp = sum_temp + windowImg[i][j] * kernelCoeff[i][j];
 end
 end
 // equivalente a (sum_temp <<< 1) con ampiezza corretta
 sum_shifted = {sum_temp, 1'b0};
 end
 always_ff @(posedge clk) begin
 if (rst)
 result <= '0;
 else
 result <= sum_shifted + bias;
 end
endmodule
