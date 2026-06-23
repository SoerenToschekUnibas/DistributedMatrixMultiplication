#include <stdlib.h>
#include <time.h>
#include <iostream>


#define M 2048
#define N 2048
#define K 2048

using namespace std;

int main(){

    float* A = (float*) malloc(M*N*sizeof(float));
    float* B = (float*) malloc(N*K*sizeof(float));
    float* C = (float*) malloc(M*K*sizeof(float));


    const float start = clock();
    
    for(int i = 0; i < M; i++){
        for(int k = 0; k < K; k++){
            for(int j = 0; j <M; j++){
                C[i*M+k] += A[i,j]*B[j*N+k];
            }
        }
        
    }


    const float stop = clock();


    cout << "duration: " << stop - start << endl;
    free(A);
    free(B);
    free(C);
    return 0;
}