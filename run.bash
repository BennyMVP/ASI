#!/bin/bash
set -e
echo "=== Compilazione con Icarus Verilog ==="
iverilog -Wall -g2012 \
 nn_pkg.sv \
 design.sv ReLu.sv fullyconnected.sv top.sv \
 nn_block_flat.sv window_gen_3x3_flat.sv nn_image_top.sv \
 testbench.sv \
 -o a.out
# Seed automatico basato sul tempo (nanosecondi). Se %N non è supportato, fallback ai secondi.
SEED=$(date +%s%N 2>/dev/null || date +%s)
vvp a.out +SEED=$SEED
echo "=== Fine ==="
