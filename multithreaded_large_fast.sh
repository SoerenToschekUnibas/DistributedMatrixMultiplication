#!/bin/bash

#SBATCH --job-name=matrix-multiplication-openmp
#SBATCH --time=0:30:00
#SBATCH --partition=scicore
#SBATCH --qos=30min
#SBATCH --hint=nomultithread
#SBATCH --exclude=sca43



ml CUDA/13.1.0


ml intel/2024a
ml impi/2021.13.0-intel-compilers-2024.2.0

mpiicx -O3 -qopenmp matmul_dynamic.cpp -o dynamic.out 
mpiicx -O3 -qopenmp matmul_guided.cpp -o guided.out 
mpiicx -O3 -qopenmp matmul_static.cpp -o static.out 

echo "----" >> dynamic.txt
echo "----" >> guided.txt
echo "----" >> static.txt


rm -f -r execution_time_tables
mkdir execution_time_tables

rm -f -r profiles
mkdir profiles

for num_threads in 8 16 32 64 128
do
    for matrix_size in 32 64 128 256 512 1024 2048
    do

    export PROFILE_DYNAMIC=profiles/nsys_dynamic_${num_threads}_${matrix_size}
    export PROFILE_GUIDED=profiles/nsys_guided_${num_threads}_${matrix_size}
    export PROFILE_STATIC=profiles/nsys_static_${num_threads}_${matrix_size}


    # Run with NSight profiling
    #srun nsys profile \
    #    --trace=openmp,nvtx,osrt \
    #    --stats=true \
    #   --output=${PROFILE_DYNAMIC} \
    srun dynamic.out $matrix_size $num_threads >> execution_time_tables/dynamic_${num_threads}.txt
        
    #srun nsys profile \
    #    --trace=openmp,nvtx,osrt \
    #    --stats=true \
    #    --output=${PROFILE_GUIDED} \
    srun guided.out $matrix_size $num_threads >> execution_time_tables/guided_${num_threads}.txt
    
    #srun nsys profile \
    #    --trace=openmp,nvtx,osrt \
    #    --stats=true \
    #    --output=${PROFILE_STATIC} \
    srun static.out $matrix_size $num_threads >> execution_time_tables/static_${num_threads}.txt
    done
done
