#!/bin/bash

g++ matmul_dynamic.cpp -o dynamic.out -fopenmp
g++ matmul_guided.cpp -o guided.out -fopenmp
g++ matmul_static.cpp -o static.out -fopenmp

rm -f -r matmul_execution_time
mkdir matmul_execution_time

rm -f -r matmul_profiles
mkdir matmul_profiles



for num_threads in 2 4 8 16
do
    for matrix_size in 32 64 128 256 512 1024 2048
    do

        export PROFILE_DYNAMIC=matmul_profiles/nsys_dynamic_${num_threads}_${matrix_size}
        export PROFILE_GUIDED=matmul_profiles/nsys_guided_${num_threads}_${matrix_size}
        export PROFILE_STATIC=matmul_profiles/nsys_static_${num_threads}_${matrix_size}


        
        ./dynamic.out $num_threads $matrix_size  >> matmul_execution_time/dynamic_${num_threads}.txt
            
        
        ./guided.out $num_threads $matrix_size  >> matmul_execution_time/guided_${num_threads}.txt
        
        
        ./static.out $num_threads $matrix_size  >> matmul_execution_time/static_${num_threads}.txt
    done
done