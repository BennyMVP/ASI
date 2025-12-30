`timescale 1ns/1ps
module tb_nn_block;
 import nn_pkg::*;
 // Seed: può arrivare grande da run.bash, lo riduciamo a 32 bit per $urandom(seed)
 longint unsigned seed64;
 int unsigned seed;
 logic clk = 0;
 logic rst;
 always #5 clk = ~clk;
 // Ingressi DUT
 logic signed [8:0] windowImg [0:K_SIZE-1][0:K_SIZE-1];
 logic signed [7:0] kernelCoeff [0:K_SIZE-1][0:K_SIZE-1];
 logic signed [7:0] bias;
 logic signed [7:0] scale;
 logic signed [7:0] offset;
 logic signed [W_W-1:0] weight [0:2];
 // Uscite DUT
 logic signed [RES_W-1:0] conv_result;
 logic signed [RES_W-1:0] norm_result;
 logic signed [ACC_FC_W-1:0] acc0, acc1, acc2;
 // Golden model (integer larghi)
 integer signed golden_conv_sum, golden_conv;
 integer signed golden_prod, golden_prod_shifted, golden_sum_off, golden_norm;
 integer signed golden_acc [0:2];
 integer i, j, c;
 integer error_count;
 // DUT
 nn_block dut (
 .clk (clk),
 .rst (rst),
 .windowImg (windowImg),
 .kernelCoeff(kernelCoeff),
 .bias (bias),
 .scale (scale),
 .offset (offset),
 .weight (weight),
 .conv_result(conv_result),
 .norm_result(norm_result),
 .acc0 (acc0),
 .acc1 (acc1),
 .acc2 (acc2)
 );
 // Helper: random signed in range [lo..hi] usando seed
 function automatic int signed rand_range(input int signed lo, input int signed hi);
 int unsigned r;
 int signed span;
 begin
 span = (hi - lo + 1);
 r = $urandom(seed);
 rand_range = lo + (r % span);
 end
 endfunction
 task automatic do_test(input int test_id);
 begin
 // GOLDEN conv2d
 golden_conv_sum = 0;
 for (i = 0; i < K_SIZE; i++)
 for (j = 0; j < K_SIZE; j++)
 golden_conv_sum += windowImg[i][j] * kernelCoeff[i][j];
 golden_conv = (golden_conv_sum <<< 1) + bias;
 // GOLDEN norm+ReLU
 golden_prod = golden_conv * scale;
 if (SHIFT_NORM > 0) golden_prod_shifted = golden_prod >>> SHIFT_NORM;
 else if (SHIFT_NORM < 0) golden_prod_shifted = golden_prod <<< (-SHIFT_NORM);
 else golden_prod_shifted = golden_prod;
 golden_sum_off = golden_prod_shifted + offset;
 golden_norm = (golden_sum_off < 0) ? 0 : golden_sum_off;
 // GOLDEN FC
 for (c = 0; c < 3; c++)
 golden_acc[c] = golden_norm * weight[c];
 // Latenza pipeline DUT: 2 cicli
 @(posedge clk);
 @(posedge clk);
 #1;
 $display("\n========================");
 $display(" Test %0d (seed=0x%08x)", test_id, seed);
 $display("========================");
 $display(" golden_conv = %0d, DUT conv_result = %0d", golden_conv,
$signed(conv_result));
 $display(" golden_norm = %0d, DUT norm_result = %0d", golden_norm,
$signed(norm_result));
 if ($signed(conv_result) !== golden_conv) begin
 $display(" --> MISMATCH conv2d");
 error_count++;
 end else $display(" conv2d OK");
 if ($signed(norm_result) !== golden_norm) begin
 $display(" --> MISMATCH norm_relu");
 error_count++;
 end else $display(" norm_relu OK");
 $display(" Classe0: golden=%0d acc0=%0d", golden_acc[0], $signed(acc0));
 $display(" Classe1: golden=%0d acc1=%0d", golden_acc[1], $signed(acc1));
 $display(" Classe2: golden=%0d acc2=%0d", golden_acc[2], $signed(acc2));
 if ($signed(acc0) !== golden_acc[0]) begin
 $display(" --> MISMATCH c_acc classe 0");
 error_count++;
 end
 if ($signed(acc1) !== golden_acc[1]) begin
 $display(" --> MISMATCH c_acc classe 1");
 error_count++;
 end
 if ($signed(acc2) !== golden_acc[2]) begin
 $display(" --> MISMATCH c_acc classe 2");
 error_count++;
 end
 end
 endtask
 initial begin
 error_count = 0;
 // Seed da run.bash (+SEED=...), fallback fisso
 if (!$value$plusargs("SEED=%d", seed64)) begin
 seed64 = 64'h00000000_C0FFEE01;
 $display("No +SEED provided, using default 0x%016x", seed64);
 end
 seed = int'(seed64 & 32'hFFFF_FFFF);
 // RESET + init ingressi
 rst = 1;
 bias = 0; scale = 0; offset = 0;
 for (i = 0; i < K_SIZE; i++)
 for (j = 0; j < K_SIZE; j++) begin
 windowImg[i][j] = '0;
 kernelCoeff[i][j] = '0;
 end
 for (c = 0; c < 3; c++) weight[c] = '0;
 @(posedge clk);
 rst = 0;
 // TEST 1
 windowImg[0][0]=1; windowImg[0][1]=2; windowImg[0][2]=3;
 windowImg[1][0]=4; windowImg[1][1]=5; windowImg[1][2]=6;
 windowImg[2][0]=7; windowImg[2][1]=8; windowImg[2][2]=9;
 for (i = 0; i < K_SIZE; i++)
 for (j = 0; j < K_SIZE; j++)
 kernelCoeff[i][j] = 1;
 bias = 0;
 scale = 2;
 offset = 4;
 weight[0] = 1; weight[1] = 2; weight[2] = 3;
 do_test(1);
 // TEST 2
 windowImg[0][0]=-1; windowImg[0][1]= 2; windowImg[0][2]=-3;
 windowImg[1][0]= 4; windowImg[1][1]=-5; windowImg[1][2]= 6;
 windowImg[2][0]=-7; windowImg[2][1]= 8; windowImg[2][2]=-9;
 kernelCoeff[0][0]= 1; kernelCoeff[0][1]= 0; kernelCoeff[0][2]=-1;
 kernelCoeff[1][0]= 2; kernelCoeff[1][1]= 0; kernelCoeff[1][2]=-2;
 kernelCoeff[2][0]= 1; kernelCoeff[2][1]= 0; kernelCoeff[2][2]=-1;
 bias = 10;
 scale = -1;
 offset = 3;
 weight[0] = 2; weight[1] = 4; weight[2] = 6;
 do_test(2);
 // TEST 3 (random, stabile e leggibile)
 for (i = 0; i < K_SIZE; i++)
 for (j = 0; j < K_SIZE; j++) begin
 windowImg[i][j] = rand_range(-10, 10);
 kernelCoeff[i][j] = rand_range(-4, 4);
 end
 bias = rand_range(-20, 20);
 scale = rand_range(-4, 4);
 offset = rand_range(-10, 10);
 for (c = 0; c < 3; c++)
 weight[c] = rand_range(-4, 4);
 do_test(3);
 // TEST 4 (ReLU a zero)
 windowImg[0][0]=1; windowImg[0][1]=2; windowImg[0][2]=3;
 windowImg[1][0]=4; windowImg[1][1]=5; windowImg[1][2]=6;
 windowImg[2][0]=7; windowImg[2][1]=8; windowImg[2][2]=9;
 for (i = 0; i < K_SIZE; i++)
 for (j = 0; j < K_SIZE; j++)
 kernelCoeff[i][j] = 1;
 bias = 0;
 scale = -1;
 offset = 0;
 weight[0] = 5; weight[1] = -3; weight[2] = 7;
 do_test(4);
 if (error_count == 0)
 $display("\n=== TUTTI I TEST PASSATI ===");
 else
 $display("\n=== %0d ERRORI RILEVATI ===", error_count);
 #20;
 $finish;
 end
endmodule
