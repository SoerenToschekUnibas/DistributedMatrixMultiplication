#include <stdio.h>
#include <vector>
#include <stdlib.h>
#include <iostream>
#include <omp.h>

#include <chrono>
#include <time.h>
using namespace std;


int main(int argc, char** argv) {

    //first argument is the matrix size.
    //2nd argument is the num threads.
    if(argc < 3){
        cout << "Usage: " << argv[0] << endl;
        return 1;
    }
    const int num_threads = atoi(argv[2]);
    //omp_set_num_threads(num_threads);

    const int matrix_size = atoi(argv[1]);
    #define N matrix_size
    float* A = new float[N*N];
    float* B = new float[N*N];
    float* C = new float[N*N];
    //Naive O(n^3) implementation, but with OpenMP.

    const float start_compute = clock();

    
    #pragma omp parallel for collapse(2) schedule(guided)
    for(int i = 0; i < N; i++){
        for(int j = 0; j < N; j++){
            // Matrix multiplication logic would go here
            for(int k = 0; k < N; k++){
                // Perform multiplication and accumulation
                C[i*N + j] += A[i*N + k] * B[k*N + j];
            }
        }
    }

    const float end_compute = clock();

    const float duration = (end_compute - start_compute) / CLOCKS_PER_SEC;
    cout << "size: " << matrix_size << ", Threads: " << num_threads << endl;
    cout << "Duration: " << duration << " seconds" << endl;
    
}