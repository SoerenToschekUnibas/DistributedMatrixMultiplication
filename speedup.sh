#!/bin/bash

#SBATCH --job-name=sparse-mmx
#SBATCH --time=00:05:00
#SBATCH --qos=30min
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1


ml CUDA/13.1.0
ml intel/2024a

icpx denseBaseline.cpp -o denseBaseline.out -O3
echo "Whatever node" >> denseBaseline.txt
echo "----" >> denseBaseline.txt
for matrix_size in 256 512 1024 2048 4096
do

    echo "Matrix size: $matrix_size" >> tableData.txt
    ./dense.out 32 $matrix_size >> tableData.txt
    ./denseBaseline.out $matrix_size >> tableData.txt
done