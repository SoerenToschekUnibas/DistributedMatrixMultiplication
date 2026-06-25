#include <stdlib.h>
#include <time.h>
#include <iostream>
#include <omp.h>

using namespace std;

int main(int argc, char** argv){
    if(argc < 3){
        cout << "Usage: " << argv[0] << endl;
        return 1;
    }
    
    //omp_set_num_threads(num_threads);
    const int num_threads = atoi(argv[1]);
    const int matrix_size = atoi(argv[2]);
    
    #define M matrix_size
    #define N matrix_size
    
    float* A = new float[N*N];
    float* B = new float[N*N];
    float* C = new float[N*N];

    

    omp_set_num_threads(num_threads);

    const float start = clock();

    int x = 12;
    //use static scheduling for matrix transposition.
    //for(int t_id = 0; t_id < num_threads; t_id++){


    
    
    //Each Thread should receive exactly one iteration of the outer loop.
    //float* B_part = new float[(N/num_threads)*N];
    #pragma omp parallel for schedule(static)
    for (int j = 0; j < M; j++) {
        for (int i = 0; i < N; i++) {
            B[i*N+j] = A[j*N+i];
        }
    }
    

    const float ending = clock();

    cout << matrix_size << "," << ending - start << endl; 
}