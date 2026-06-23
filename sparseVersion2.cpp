#include <stdio.h>
#include <vector>
#include <stdlib.h>
#include <iostream>
#include <omp.h>
#include <chrono>

#define NUM_RAND_ROWS 4096
#define NUM_RAND_COLS 4096
#define NUM_THREADS 8

using namespace std;
using namespace std::chrono;

struct MatrixElement{
    int row;
    int col;
    double value;
};
void matrix_row_partition(const vector<MatrixElement> A, int* indices){
    const int elements_per_thread = A.size() / NUM_THREADS;
    int current_elements = 0; //how many elements we have counted currently.
    int indices_idx = 0;//Where we are currently in the indices array.
    for(int i = 0; i < NUM_THREADS; i++){
        current_elements += elements_per_thread;
        
        indices[i] = A[i*elements_per_thread].row;
    }


}

void matrix_multiplication(const vector<MatrixElement> A, const vector<MatrixElement> B, vector<MatrixElement>& C) {

    vector<MatrixElement> A_parts[NUM_THREADS];
    vector<MatrixElement> B_parts[NUM_THREADS];
        
    #pragma omp parallel
    #pragma omp sections
    {
        
        #pragma omp section
        {
            //Split up the matrix A along the rows, in contiguous blocks.
            //Not exact Load balancing.
            
            int current_elements = 0; //how many elements we have counted currently.
            
            for(int i = 0; i < NUM_THREADS; i++){
                A_parts[i].reserve(A.size() / NUM_THREADS+1024); //Reserve some extra space to avoid reallocation.
            }
            int current_thread = 0;
            int current_row = A[0].row;
            int current_row_start = 0;//Index, where the first element of the current row starts.
            for (const auto& elem : A){
                if(current_elements>= A.size() / NUM_THREADS){
                    current_row = elem.row;
                    current_elements = 0;
                    current_thread++;
                }
                A_parts[current_thread].push_back(elem);
                current_elements++;
            }
            
            cout << "A_parts[1] size: " << A_parts[1].size() << endl;
            for(int i = 0; i<10; i++){
                cout << A_parts[1].at(i).row << ", " << A_parts[1].at(i).col << ", " << A_parts[1].at(i).value << endl;
            }
        }

        #pragma omp section
        {
            //Now do the same for matrix B, but split along the columns.
            

            for(int i = 0; i < NUM_THREADS; i++){
                B_parts[i].reserve(B.size() / NUM_THREADS+1024); //Reserve some extra space to avoid reallocation.
            }
            for (const auto& elem : B){
                B_parts[elem.col % NUM_THREADS].push_back(elem);
            }
        }
    }

    //Each Thread can now compute the dot pro

    for(int timestep = 0; timestep < NUM_THREADS; timestep++){
        #pragma omp parallel for
        for(int thread_id = 0; thread_id < NUM_THREADS; thread_id++){
            //Each thread computes the dot product of its assigned rows and columns.
            const auto& A_part = A_parts[thread_id];
            const auto& B_part = B_parts[(thread_id + timestep) % NUM_THREADS];

            //Compute the dot product of A_i and B_j and store in C_i_j
            for(const auto& a_elem : A_part){
                //TODO: add hint for branch prediction.
                if(a_elem.col-timestep % NUM_THREADS != 0) continue; //Skip elements that are not in the current timestep's column partition.
                
                for(const auto& b_elem : B_part){
                    if(a_elem.col == b_elem.row){
                        //Find the corresponding element in C and update it.
                        //This is a naive approach. In practice, you would want to use a more efficient data structure.
                        MatrixElement element = {a_elem.row, b_elem.col, a_elem.value * b_elem.value};

                        C.push_back(element);
                    }
                }
            }
        }
        //Implicit barrier.
    }

    //Now we can copy back the results from C_parts to C.

    cout << "copy back results." << endl;
    for(int thread_id = 0; thread_id < NUM_THREADS; thread_id++){
        for(const auto& elem : C){
            C.push_back(elem);
        }
    }

}   


int main(){

    vector<MatrixElement> identityMatrix;
    vector<MatrixElement> B;
    vector <MatrixElement> random_A;
    vector<MatrixElement> random_B;

    {
        int rand_row = 0;
        for(int i = 0; i < NUM_RAND_ROWS;i++){
            int rand_col = 0;

            for(int j = 0; j < NUM_RAND_COLS; j++){
                rand_col += rand()%128;
                struct MatrixElement random_elem = {rand_row, rand_col, static_cast<double>(rand()) / RAND_MAX};
                random_A.push_back(random_elem);
            }
            rand_row += rand()%128;
        }
    }

    {
        int rand_row = 0;
        for(int i = 0; i < NUM_RAND_ROWS;i++){
            int rand_col = 0;

            for(int j = 0; j < NUM_RAND_COLS; j++){
                rand_col += rand()%128;
                struct MatrixElement random_elem = {rand_row, rand_col, static_cast<double>(rand()) / RAND_MAX};
                random_B.push_back(random_elem);
            }
            rand_row += rand()%128;
        }
    }

    
    for(int i = 0; i < 8192; i++){
        struct MatrixElement a_ii = {i,i,1.0}; //the diagonal 1.0 entries, of the identity matrix.
        identityMatrix.push_back(a_ii);
        B.push_back(a_ii);
        if(i==3){
            struct MatrixElement el = {i,12,2.0};
            B.push_back(el);
        }
    }

    vector<MatrixElement> C;
    auto start = high_resolution_clock::now();


    auto stop = high_resolution_clock::now();
    matrix_multiplication(identityMatrix,random_matrix,C);

    auto duration = duration_cast<microseconds>(stop - start);

    cout << "duration: " <<duration.count() << endl;
    //print the first 10 coefficients of C.
    cout << "Result matrix C" << endl;
    for(int i = 0; i < 10; i++){
        cout << C[i].row << ", " << C[i].col << ", " << C[i].value << endl;
    }
}