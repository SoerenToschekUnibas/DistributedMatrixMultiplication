#!/bin/bash

#SBATCH --job-name=sparse-mmx
#SBATCH --time=02:00:00
#SBATCH --qos=30min
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1



ml CUDA/13.1.0
# need for NSight

ml intel
icpx matmul_dynamic.cpp -o dynamic.out -qopenmp
icpx matmul_guided.cpp -o guided.out -qopenmp
icpx matmul_static.cpp -o static.out -qopenmp

echo "----" >> dynamic.txt
echo "----" >> guided.txt
echo "----" >> static.txt


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


    # Run with NSight profiling
    #srun nsys profile \
    #    --trace=openmp,nvtx,osrt \
    #    --stats=true \
    #   --output=${PROFILE_DYNAMIC} \
    srun dynamic.out $num_threads $matrix_size  >> matmul_execution_time/dynamic_${num_threads}.txt
        
    #srun nsys profile \
    #    --trace=openmp,nvtx,osrt \
    #    --stats=true \
    #    --output=${PROFILE_GUIDED} \
    srun guided.out $num_threads $matrix_size  >> matmul_execution_time/guided_${num_threads}.txt
    
    #srun nsys profile \
    #    --trace=openmp,nvtx,osrt \
    #    --stats=true \
    #    --output=${PROFILE_STATIC} \
    srun static.out $num_threads $matrix_size  >> matmul_execution_time/static_${num_threads}.txt
    done
done
