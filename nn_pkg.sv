`timescale 1ns/1ps
package nn_pkg;
 localparam int K_SIZE = 3;
 localparam int PROD_W = 17;
 localparam int ACC_CONV_W = PROD_W + $clog2(K_SIZE*K_SIZE);
 localparam int RES_W = ACC_CONV_W + 1;
 localparam int W_W = 8;
 localparam int ACC_FC_W = 40;
 localparam int SHIFT_NORM = 6;
endpackage
