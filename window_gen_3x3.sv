`timescale 1ns/1ps
module window_gen_3x3 #(
 parameter int IMG_W = 8,
 parameter int IMG_H = 8
)(
 input logic clk,
 input logic rst,
 input logic in_valid,
 input logic signed [8:0] in_pixel,
 output logic win_valid,
 output logic signed [8:0] windowImg [0:2][0:2],
 output logic [$clog2(IMG_W)-1:0] out_x,
 output logic [$clog2(IMG_H)-1:0] out_y
);
 // 2 line buffer per kernel 3x3
 logic signed [8:0] line1 [0:IMG_W-1];
 logic signed [8:0] line2 [0:IMG_W-1];
 // shift register per le 3 colonne
 logic signed [8:0] s0[0:2], s1[0:2], s2[0:2];
 // REGISTRO INTERNO della window (non pilotare direttamente l’output array)
 logic signed [8:0] win_reg [0:2][0:2];
 // assegnamenti continui elemento-per-elemento (Icarus-friendly)
 genvar gi, gj;
 generate
 for (gi = 0; gi < 3; gi = gi + 1) begin : G_ROW
 for (gj = 0; gj < 3; gj = gj + 1) begin : G_COL
 assign windowImg[gi][gj] = win_reg[gi][gj];
 end
 end
 endgenerate
 int unsigned x, y;
 integer k;
 always_ff @(posedge clk) begin
 if (rst) begin
 x <= 0;
 y <= 0;
 win_valid <= 0;
 out_x <= '0;
 out_y <= '0;
 // azzera line buffer
 for (k = 0; k < IMG_W; k = k + 1) begin
 line1[k] <= '0;
 line2[k] <= '0;
 end
 // azzera shift regs + win_reg
 for (k = 0; k < 3; k = k + 1) begin
 s0[k] <= '0;
 s1[k] <= '0;
 s2[k] <= '0;
 win_reg[0][k] <= '0;
 win_reg[1][k] <= '0;
 win_reg[2][k] <= '0;
 end
 end else begin
 win_valid <= 0;
 if (in_valid) begin
 // shift a sinistra delle 3 colonne
 s0[0] <= s0[1]; s0[1] <= s0[2]; s0[2] <= line2[x];
 s1[0] <= s1[1]; s1[1] <= s1[2]; s1[2] <= line1[x];
 s2[0] <= s2[1]; s2[1] <= s2[2]; s2[2] <= in_pixel;
 // aggiorna line buffer: line2 <= line1 <= current
 line2[x] <= line1[x];
 line1[x] <= in_pixel;
 // quando abbiamo almeno 3 righe e 3 colonne disponibili -> window valida
 if (y >= 2 && x >= 2) begin
 win_reg[0][0] <= s0[0]; win_reg[0][1] <= s0[1]; win_reg[0][2] <= s0[2];
 win_reg[1][0] <= s1[0]; win_reg[1][1] <= s1[1]; win_reg[1][2] <= s1[2];
 win_reg[2][0] <= s2[0]; win_reg[2][1] <= s2[1]; win_reg[2][2] <= s2[2];
 win_valid <= 1;
 out_x <= x - 2;
 out_y <= y - 2;
 end
 // aggiorna contatori (raster scan)
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
