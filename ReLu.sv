`timescale 1ns/1ps
module norm_relu #(
 parameter int IN_W = 22,
 parameter int SCALE_W = 8,
 parameter int OFFSET_W = 8,
 parameter int OUT_W = IN_W,
 parameter int SHIFT = 0
)(
 input logic clk,
 input logic rst,
 input logic signed [IN_W-1:0] conv_val,
 input logic signed [SCALE_W-1:0] scale,
 input logic signed [OFFSET_W-1:0] offset,
 output logic signed [OUT_W-1:0] norm_relu_val
);
 localparam int PROD_W = IN_W + SCALE_W;
 localparam int SUM_W = (PROD_W > OFFSET_W ? PROD_W : OFFSET_W) + 1;
 logic signed [PROD_W-1:0] prod;
 logic signed [SUM_W-1:0] prod_shifted;
 logic signed [SUM_W-1:0] offset_ext;
 logic signed [SUM_W-1:0] sum_with_off;
 always @(*) begin
 prod = conv_val * scale;
 offset_ext = {{(SUM_W-OFFSET_W){offset[OFFSET_W-1]}}, offset};
 if (SHIFT > 0)
 prod_shifted = prod >>> SHIFT;
 else if (SHIFT < 0)
 prod_shifted = prod <<< (-SHIFT);
 else
 prod_shifted = prod;
 sum_with_off = prod_shifted + offset_ext;
 end
 always_ff @(posedge clk) begin
 if (rst)
 norm_relu_val <= '0;
 else if (sum_with_off < 0)
 norm_relu_val <= '0;
 else
 norm_relu_val <= sum_with_off[OUT_W-1:0];
 end
endmodule
