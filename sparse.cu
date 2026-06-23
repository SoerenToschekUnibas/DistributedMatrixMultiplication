#include <cuda_runtime.h>
#include <stdio.h>
#include <cstdlib>
#include <omp.h>

struct VectorEntry {
    int index;
    float value;
};


struct MatrixEntry {
    int row;
    int col;
    float value;
};


//Number of Rows and columns. Each matrix has M² nonzero coefficients (sparse entries).
#define M 512

#define VALUE_RANGE 2.0


/*
Try to parallelize sparse vector addition, such that the output of two ordered additions is again ordered.
The output is stored in a third buffer, to which we (generously) allocate 2*M entries, whereas U and V each only have M.

w = u +v 
Per-Thread we consider e.g. 16 coefficient of u; 16 oefficient of v; and 32 coeefficients in w.
*/
__global__ void vectorAdditionKernel(const VectorEntry u[], const VectorEntry v[], VectorEntry w[]){
    __shared__ int next_element_index;//Index so workstealing between the threads.
    const int index = blockIdx.x*blockDim.x + threadIdx.x;
    const int output_index = blockIdx.x*blockDim.y + threadIdx.x;
    
    
}





/*
Iterates over two separate vectors, each with its own iterator, and generates sequences of coordinate-indices,
such that we have exactly 256 entries (from both vectors), in each interval.
We assume that enough memory alloc has been allocated to the sequence of indices.
This partitioning can then be used to distribute the addition operation (which is very similar to a sorting operation),
to the threads (either CPU, or GPU).
*/
inline void vectorAdditionPartitioning(const VectorEntry u[], const int u_size, const VectorEntry v[], const int v_size, int* indices)
{
    int u_index = 0;
    int v_index = 0;
    int element_counter = 0;//how many nonzero coefficients we have in the current interval.

    int indices_index = 0;
    //After each loop iteration, we have the #elements, that lie behind the (next iteration) min(u_coord,v_coord)
    while(u_index<u_size && v_index < v_size){
        uint u_coord = u[u_index].index;
        uint v_coord = v[v_index].index;
        uint min_coord = min(u_coord,v_coord);
        
        if(element_counter>=32){
            //It could be, that we are adding 2 more elements in the next step so have to be careful.
            indices[indices_index] = min_coord;
            
            element_counter = 0;
            indices_index++;
        }

        if( u_coord == min_coord){
            printf("u eq.\n");
            u_index++;
            element_counter++;
        }
        if( v_coord == min_coord){
            printf("v eq.\n");
            v_index++;
            printf("v_index: %d\n",v_index);
            element_counter++;
        }
        
    }
    indices[0] = 12;
}


/*
Function on Host Code that first partitions which are then distributed among the GPU threads.
*/
void vectorAddition(const VectorEntry u[],const int u_size, const VectorEntry v[], const int v_size, VectorEntry w[]){
    int* indices = (int*) malloc(sizeof(int)*(((int) M/256)+1024));
    vectorAdditionPartitioning(u,u_size,v,v_size,indices);

    printf("\nindices: %d,%d,%d,%d  \n\n",indices[0],indices[1],indices[2],indices[3]);
}

/*
Partition a given sparse matrix in 4 blocks, so that they roughly countain the same number of elements. We will allocate these blocks to the GPUs,
and then all blocks are paired up.
|---------------|
|               |
|               |
|---------------|
|               |
|               |
|               |
|               |
|               |
|               |
|---------------|
|               |
|               |
|---------------|
|               |
|               |
|               |
|               |
|               |
|               |
|               |
|               |
|---------------|
Returns the index of the row i (Index with respect to the MatrixEntry Array, which can directly be used for the following memcpy operations)
The matrix is divided into blocks of 256 entries.
This function can run into a Memory-overflow, if not enough Mem. has been allocated to indices.
*/
inline void matrixPartitioning(const MatrixEntry A[], const int length_A, int indices[]){
    uint indices_index = 0;
    uint element_counter = 0;
    uint last_row = 0;
    uint start_of_row = 0; //Index (of A), where the current row starts. So we can set 
    for(uint i=0; i < length_A; i++){
        if(A[i].row!=last_row){
            start_of_row = i;
        }
        last_row = A[i].row;

        if(element_counter>=256){
            indices[indices_index] = start_of_row;
            indices_index++;
            element_counter = 0;
        }
        else{
            element_counter++;
        }
    }
}

/*We use a similar to the baseline implementation. 

Each thread will keep its own counter and own list.
*/
__global__
void sparseMatrixMatrixKernel(
    const MatrixEntry* A,
    int countA,
    const MatrixEntry* B,
    int countB,
    const MatrixEntry* C,
    int rowsC,
    int colsC,
    int* resultCounter
)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx >= countA)
        return;

    MatrixEntry a = A[idx];

    // A(i,k)
    int i = a.row;
    int k = a.col;
    float aval = a.value;

    // Search for all B(k,j)
    for (int bidx = 0; bidx < countB; ++bidx)
    {
        MatrixEntry b = B[bidx];

        if (b.row == k)
        {
            int j = b.col;
            float c = aval * b.value;

            //atomicAdd(&C[i * colsC + j], c);
            
            
        }
    }
}

void sparseMatMul(
    MatrixEntry* d_A,
    int nnzA,
    MatrixEntry* d_B,
    int nnzB,
    float* d_C,
    int rowsC,
    int colsC)
{
    
}


void BitonicSort(MatrixEntry* A){
    //The BitonicSorting of t
    
}



int main(){

    


    #ifdef SHORT
    MatrixEntry h_A[] = {
        {0,0,1.0f},
        {0,2,2.0f},
        {1,1,3.0f}
    };

    MatrixEntry h_B[] = {
        {0,1,4.0f},
        {1,0,5.0f},
        {2,1,6.0f}
    };


    #else

    
    MatrixEntry*  h_A = (MatrixEntry*) malloc(M*M*sizeof(MatrixEntry));

    uint current_row = 0;
    
    
    #pragma omp parallel 

    #pragma omp master
    printf( "number of OpenMP threads: %d\n", omp_get_num_threads());


    VectorEntry* v = (VectorEntry*) malloc(sizeof(VectorEntry)*M);
    VectorEntry* u = (VectorEntry*) malloc(sizeof(VectorEntry)*M);
    VectorEntry* w = (VectorEntry*) malloc(sizeof(VectorEntry)*2*M);
    {
        printf("\nu\n");
        uint counter = 0;
        for(int i = 0; i < M; i++){
            VectorEntry el;
            
            counter += rand()%64;
            el.index = counter;
            el.value = (float)rand()/(float)(VALUE_RANGE);
            
            u[i] = el;
            
            printf(" %d,", counter);
        }
    }

    {
        printf("\nv\n");
        uint counter = 0;
        for(int i = 0; i < M; i++){
            VectorEntry el;
            counter += rand()%64;
            el.index = counter;
            el.value = (float)rand()/(float)(VALUE_RANGE);
            
            v[i] = el;
            
            printf(" %d,", counter);
        }
    }

    vectorAddition(u,M,v,M,w);


    printf("number of teams: %d\n", omp_get_team_num());
    #pragma omp for
    for(int i = 0; i < M; i++){
        current_row +=  rand()%64;
        uint current_col = 0;
        for(int j = 0; j < M; j++){
            current_col += rand()%64;
            MatrixEntry entry;
            entry.row = current_row;
            entry.col = current_col;

            
            entry.value = (float)rand()/(float)(VALUE_RANGE);

            h_A[i*M+j] = entry;
            
        }
    }

    
    MatrixEntry* h_B = (MatrixEntry*) malloc(M*M*sizeof(MatrixEntry));

    #pragma omp parallel for
    for(int i = 0; i < M; i++){
        current_row +=  rand()%64;
        uint current_col = 0;
        for(int j = 0; j < M; j++){
            current_col += rand()%64;
            MatrixEntry entry;
            entry.row = current_row;
            entry.col = current_col;

            #define VALUE_RANGE 2.0
            entry.value = (float)rand()/(float)(VALUE_RANGE);

            h_A[i*M+j] = entry;

        }
    }

    #endif
    

    

    
    MatrixEntry* d_A;
    cudaMalloc(&d_A, sizeof(MatrixEntry)*M);
    #define COUNT_A 3

    MatrixEntry* d_B;
    cudaMalloc(&d_B, sizeof(MatrixEntry)*M);
    #define COUNT_B 3
    cudaMemcpy(&d_A,&h_A,sizeof(MatrixEntry)*M,cudaMemcpyHostToDevice);
    cudaMemcpy(&d_B,&h_B,sizeof(MatrixEntry)*M,cudaMemcpyHostToDevice);

    MatrixEntry* d_C;
    cudaMalloc(&d_C, sizeof(MatrixEntry)*M*2);

    int* counterPerThread;//For each thread, stores the length of the list of entries that have been appended.
    cudaMalloc(&counterPerThread,sizeof(int)*M);
    

    int threads = 256;
    int blocks = (COUNT_A + threads - 1) / threads;

    sparseMatrixMatrixKernel<<<blocks, threads>>>(
        d_A,
        M*M,
        d_B,
        M*M,
        d_C,
        M,
        M,
        counterPerThread
    );
    
    return 0;
}