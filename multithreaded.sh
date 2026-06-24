#!/bin/bash

#SBATCH --job-name=sparse-mmx
#SBATCH --time=00:05:00
#SBATCH --qos=30min
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --hint=nomultithread



ml intel/2024a
icpx matmul_dynamic.cpp -o dynamic.out -fopenmp
icpx matmul_guided.cpp -o guided.out -fopenmp
icpx matmul_static.cpp -o static.out -fopenmp

echo "----" >> dynamic.txt
echo "----" >> guided.txt
echo "----" >> static.txt

for num_threads in 2 4 8 16 
do
    for matrix_size in 32 64 128 256 512 1024 2048
    do
        ./dynamic.out $matrix_size $num_threads >> dynamic.txt
        ./guided.out $matrix_size $num_threads >> guided.txt
        ./static.out $matrix_size $num_threads >> static.txt
    done
done

