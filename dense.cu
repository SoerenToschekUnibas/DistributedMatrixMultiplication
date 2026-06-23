#include <cuda_runtime.h>
#include <iostream>
#include <vector>
#include <cassert>
#include <time.h>



#define NUM_GPUS 1
#define COL_DIVISIONS 1
#define M 4096
#define K 4096
#define N 4096

using namespace std;

/*
Wrapper for CUDA calls.
*/
#define CHECK_CUDA(call)                                         \
do {                                                             \
    cudaError_t err = call;                                      \
    if (err != cudaSuccess) {                                    \
        std::cerr << "CUDA Error: "                              \
                  << cudaGetErrorString(err)                     \
                  << " at line " << __LINE__ << std::endl;       \
        exit(EXIT_FAILURE);                                      \
    }                                                            \
} while(0)




/*
Kernel for the product A*B=C;
assuming that B has already been transposed.
Furthermore its adding its results back on to C; so can be applied for matrix patches. (FMA)
*/
__global__
void matmul_kernel_transposed(
    const float* A,
    const float* B_transposed,
    float* C,
    int rowsA)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < rowsA && col < N)
    {
        float res = 0.0f;

        for (int k = 0; k < K; k++){
            res += A[row * K + k] * B_transposed[col * N + k];
        }
        C[row * N + col] = res;
    }
}



///////////////////////////////////////////////////////////////////////////////
// Multi-GPU GEMM
///////////////////////////////////////////////////////////////////////////////
void multi_gpu_gemm(
    const float* h_A,
    const float* h_B_transposed,
    float* h_C)
{
    int device_count = 0;
    CHECK_CUDA(cudaGetDeviceCount(&device_count));

    if (false && device_count < NUM_GPUS)
    {
        std::cerr << "Need at least "
                  << NUM_GPUS
                  << " GPUs." << std::endl;
        exit(EXIT_FAILURE);
    }

    int rows_per_gpu = M / NUM_GPUS;

    vector<float*> d_A(NUM_GPUS);
    vector<float*> d_B_t(NUM_GPUS);
    vector<float*> d_C(NUM_GPUS);

    vector<cudaStream_t> streams(NUM_GPUS);


    #define B_T_ROWS_PER_GPU (K/ NUM_GPUS)//We also split up B_transposed into different blocks.
    //The blocks are then rotated from GPU to GPU, following a synchronization step.

    //Initiate the CUDA streams on the different GPUs, and allocate the necessary memory on each GPU.
    for (int gpu = 0; gpu < NUM_GPUS; ++gpu)
    {
        CHECK_CUDA(cudaSetDevice(0));
        CHECK_CUDA(cudaStreamCreate(&streams[gpu]));
        CHECK_CUDA(cudaStreamCreate(&streams[gpu]));

        const int row_start = gpu * rows_per_gpu;

        const int local_rows =
            (gpu == NUM_GPUS - 1)
            ? (M - row_start)
            : rows_per_gpu;
        //Although this can work with arbitrary shaped matrices, we will stick to dimensions that are a power of 2.


        //The matrix A is split along its rows.
        size_t bytesA = local_rows * K * sizeof(float);


        

        //The matrix B is split along its columns.
        size_t bytesB = B_T_ROWS_PER_GPU * N * sizeof(float);
        size_t bytesC = local_rows * N * sizeof(float);

        CHECK_CUDA(cudaMalloc(&d_A[gpu], bytesA));
        CHECK_CUDA(cudaMalloc(&d_B_t[gpu], bytesB));
        CHECK_CUDA(cudaMalloc(&d_C[gpu], bytesC));


        //Copy the content of the corresponding patch of A, and patch of B; to the relevant 
        CHECK_CUDA(cudaMemcpyAsync(
            d_A[gpu],
            h_A + row_start * K,
            bytesA,
            cudaMemcpyHostToDevice,
            streams[gpu]));
        //Right now, we only split up the matrix A.

        CHECK_CUDA(cudaMemcpyAsync(
            d_B_t[gpu],
            h_B_transposed+gpu*B_T_ROWS_PER_GPU,
            bytesB,
            cudaMemcpyHostToDevice,
            streams[gpu]));

    }
    for(int timestep=0; timestep<4; timestep++){

        //Allocate Work on the different GPUs (spatially.)
        for (int gpu = 0; gpu < NUM_GPUS; ++gpu)
        {
            CHECK_CUDA(cudaSetDevice(0));

            

            const int row_start = gpu * rows_per_gpu;

            const int local_rows =
                (gpu == NUM_GPUS - 1)
                ? (M - row_start)
                : rows_per_gpu;
            //Although this can work with arbitrary shaped matrices, we will stick to dimensions that are a power of 2.



            

            
            dim3 block(16,16);

            dim3 grid(
                (N + block.x - 1) / block.x,
                (local_rows + block.y - 1) / block.y);

            matmul_kernel_transposed<<<grid, block, 0, streams[gpu]>>>(
                d_A[gpu],
                d_B_t[gpu],
                d_C[gpu],
                local_rows);
        }
        //After each timestep, where each GPU has the exact same number of FLOPs, (but may have time differences, due to memory operations, WARP scheduling, ....)
        


        for (int gpu = 0; gpu < NUM_GPUS; gpu++){
            cudaSetDevice(0);
            cudaDeviceSynchronize();//Basically a Barrier.
        }
        //Now swap content of matrix B between GPUs.
        for (int gpu = 0; gpu < NUM_GPUS-1; gpu++){
            size_t bytesB = K/NUM_GPUS * N * sizeof(float);
            const int next_gpu = (gpu+1)%4;
            cudaMemcpyPeerAsync(d_B_t[next_gpu],next_gpu,d_B_t[gpu],gpu,bytesB);
        }

        cudaSetDevice(0);
        cudaMemcpy(
            d_B_t[0],
            d_B_t[((-1 + timestep)%4)*B_T_ROWS_PER_GPU],
            B_T_ROWS_PER_GPU,
            cudaMemcpyHostToDevice
        );
        cudaDeviceSynchronize();//Basically a Barrier.
    }

    //Copy the data back to the host.

    for (int gpu = 0; gpu < NUM_GPUS; ++gpu)
    {   

        const int row_start = gpu * rows_per_gpu;
        const int local_rows =
            (gpu == NUM_GPUS - 1)
            ? (M - row_start)
            : rows_per_gpu;


        size_t bytesA = local_rows * K * sizeof(float);
        size_t bytesB = K * N * sizeof(float);
        size_t bytesC = local_rows * N * sizeof(float);

        CHECK_CUDA(cudaMemcpyAsync(
            h_C + row_start * K,
            d_C[gpu],
            bytesC,
            cudaMemcpyDeviceToHost,
            streams[gpu]));
    }
}





/*
///////////////////////////////////////////////////////////////////////////////
// Example driver
///////////////////////////////////////////////////////////////////////////////
int main()
{
    

    size_t sizeA = (size_t)M * K;
    size_t sizeB = (size_t)K * N;
    size_t sizeC = (size_t)M * N;

    vector<float> A(sizeA);
    vector<float> B(sizeB);
    vector<float> C(sizeC);

    for (size_t i = 0; i < sizeA; ++i)
        A[i] = 1.0f;

    for (size_t i = 0; i < sizeB; ++i)
        B[i] = 1.0f;

    multi_gpu_gemm(
        A.data(),
        B.data(),
        C.data(),
        M,
        K,
        N);

    std::cout << "C[0] = "
              << C[0]
              << std::endl;

    return 0;
}
        cudaGetLastError();

        //---------------------------------------------------------------
        // Copy result back
        //---------------------------------------------------------------
        cudaMemcpyAsync(
      int rowsA      h_C + row_start * N,
            d_C[gpu],
            bytesC,
            cudaMemcpyDeviceToHost,
            streams[gpu]);
    }

    ///////////////////////////////////////////////////////////////////////
    // Synchronize all GPUs
    ///////////////////////////////////////////////////////////////////////
    for (int gpu = 0; gpu < NUM_GPUS; ++gpu)
    {h_B
        CHECK_CUDA(cudaSetDevice(gpu));
        CHECK_CUDA(cudaStreamSynchronize(streams[gpu]));
    }

    ///////////////////////////////////////////////////////////////////////
    // Cleanup
    ///////////////////////////////////////////////////////////////////////
    for (int gpu = 0; gpu < NUM_GPUS; ++gpu)
    {
        CHECK_CUDA(cudaSetDevice(gpu));

        cudaFree(d_A[gpu]);
        cudaFree(d_B[gpu]);
        cudaFree(d_C[gpu]);

        cudaStreamDestroy(streams[gpu]);
    }
}
*/


///////////////////////////////////////////////////////////////////////////////
// Example driver
///////////////////////////////////////////////////////////////////////////////
int main()
{

    size_t sizeA = (size_t)M * K;
    size_t sizeB = (size_t)K * N;
    size_t sizeC = (size_t)M * N;

    vector<float> h_A(sizeA);
    vector<float> h_B(sizeB);
    vector<float> h_C(sizeC);

    for (size_t i = 0; i < M; ++i){
        h_A[i*K+i] = 1.0f;
    }
    for (size_t i = 0; i < N; ++i){
        h_B[i*N+i] = 1.0f;
        h_B[3*N+0] = 1.0f;
    }


    const float start = clock();

    vector<float> h_B_transpose(sizeB);

    //The Transposition is bandwidth bound.
    #pragma omp parallel for
    for (size_t i = 0; i < N; i++){
        for(size_t j=0; j <K; j++){
            h_B_transpose[i*K+j] = h_B[j*K+i];
        }
    }
    cout << "B transposed" << endl;

    multi_gpu_gemm(h_A.data(),h_B_transpose.data(),h_C.data());


    const float stop = clock();


    cout << "duration "
              << stop-start
              << endl;


    for(int i = 0; i < 10;i++){
        for(int j = 0; j < 10; j++){
            cout << h_C[i*K+j];
        }
        cout << endl;
    }
    return 0;
}
