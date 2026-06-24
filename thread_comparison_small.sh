g++ matmul_static.cpp -o static.out -fopenmp


mkdir local_comparison
for num_threads in 1 2 4 8 16
do 
    for matrix_size in 32 64 128 256 512 1024
    do
        ./static.out $matrix_size $num_threads >> local_comparison/static_${num_threads}.txt
    done 
done