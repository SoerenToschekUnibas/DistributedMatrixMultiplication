#include <stdlib.h>
#include <time.h>
#include <iostream>


using namespace std;

int main(int argc, char** argv){
    if(argc < 3){
        cout << "Usage: " << argv[0] << endl;
        return 1;
    }
    const int num_threads = atoi(argv[2]);
    //omp_set_num_threads(num_threads);

    const int matrix_size = atoi(argv[1]);
    
    #define M matrix_size
    #define N matrix_size
    
    float* A = new float[N*N];
    float* B = new float[N*N];
    float* C = new float[N*N];


    //use static scheduling for matrix transposition.
    #pragma omp parallel for collapse(2)
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < M; j++) {
            B[j*N+i] = A[i*N+j];
        }
    }

}