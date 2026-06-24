#include <stdlib.h>
#include <time.h>
#include <iostream>




using namespace std;

int main(int argc, char** argv) {

    if(argc < 2){
        cout << "Usage: " << argv[0] << " <matrix_size>" << endl;
        return 1;
    }
    int matrix_size = atoi(argv[1]);
    #define M matrix_size
    #define N matrix_size
    #define K matrix_size

    float* A = (float*) malloc(M*N*sizeof(float));
    float* B = (float*) malloc(N*K*sizeof(float));
    float* C = (float*) malloc(M*K*sizeof(float));


    const float begin_compute = clock();
    
    //Simple O(N^3)

    
    for(int i = 0; i < M; i++){
        for(int k = 0; k < K; k++){
            for(int j = 0; j <M; j++){
                C[i*M+k] += A[i,j]*B[j*N+k];
            }
        }
        
    }


    const float end_compute = clock();


    cout << "compute: " << end_compute - begin_compute << endl;
    free(A);
    free(B);
    free(C);
    return 0;
}