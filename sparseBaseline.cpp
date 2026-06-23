#include <stdio.h>
#include <vector>
#include <stdlib.h>
#include <iostream>
#include <omp.h>



#include <chrono>
using namespace std::chrono;



using namespace std;


//Elements that are stored within a submatrix
struct MatrixElement {
    uint row;
    uint col;
    float value;
};






struct Element{
    uint index;
    float value;
};


//Class for storing sparse matrix as addition of (perhaps overlapping) matrix patches.
//Each patch has a set of row indices; and a set of column indices.

float sparseDotProduct(const vector<Element>& u, const vector<Element>& v){
    uint u_index = 0;
    uint v_index = 0;

    float result = 0.0;
    while(u_index < u.size() && v_index < v.size()){
        if(u[u_index].index== v[v_index].index){
            result += u[u_index].value * v[v_index].value;
            u_index++;
            v_index++;
        }
        else if(u[u_index].index < v[v_index].index){
            u_index++;

        }
        else if(u[u_index].index > v[v_index].index){
            v_index++;

        }
    }

    return result;
}

/*
Sparse Matrix Multiplication. Later to be used as the base case, for a patch-based sparse matrix multiplication method.
We assume that the entries are stored in the list according to some ordering. We assume that one of the matrix is stored in row major order.

The output must be stored in 
*/
vector<Element> sparseMatrixVector(const vector<MatrixElement>& A, const vector<Element>& v){
    uint A_index = 0;
    

    
    vector<Element> result;
    result.reserve(2<<5);
    //The result is a vector to which we append the coefficients.
    
    //For Matrix Vector Multiplication, its best if the matrix is stored in Row-Major order.
    
    #pragma omp parallel
    while(A_index < A.size()){
        //the v_index has to catch up with the A_index. If it passes it. We jump to the next A.

        uint v_index = 0;
        float acc = 0.0; //The accumulator tracks the sum for the current row; If A_index progresses to another row,
        //the content is appended to the resulting vector.

        //Check if we either reach the end of the row of A; or the end of the vector v.

        const uint  current_row = A[A_index].row;//By setting this equality, we ensure that the loop runs at least once.
        while(A[A_index].row==current_row && v_index < v.size()){
            if(A[A_index].col== v[v_index].index){//We find a coefficient that matches an entry in the vector. 
                acc += A[A_index].value * v[v_index].value;
                A_index++;
                v_index++;
            }
            else if(A[A_index].col < v[v_index].index){
                A_index++;

            }
            else if(A[A_index].col > v[v_index].index){
                v_index++;

            }
        }
        
        //Sparsity is also considered, for the cases where the accumulator is 0.
        if(acc>0){
            struct Element c = {current_row,acc};
            result.push_back(c);
        }

        //Case: we have reached the end of vector v; but not necessarily exhausted the entire row.
        //We have to jump to the next Row of A.
        if(v_index==v.size()){
            while(A[A_index].row==current_row){
                A_index++;
            }
        }
        
    }
    //Thus we iterate over the vector v multiple times.
    return result;
}



/*
sparse FMA.

In the sparse setting, the accumulate operation cannot be performed in-place, (unless ignore the order).
New non-zero coefficients have to added in-between the existing coefficients. 
So we allocate a new index entirely.
*/
vector<Element> sparseFMAMatrixVector(const vector<Element>& u, const vector<MatrixElement>& A, const vector<Element>& v){
    uint A_index = 0;
    
    uint u_index = 0; //The insertion point for the addition of u with a single sparse entry.
    
    vector<Element> result; //We know that the result has less entries, than the sum of u and v.
    result.reserve(2<<5);
    //The result is a vector to which we append the coefficients.
    
    //For Matrix Vector Multiplication, its best if the matrix is stored in Row-Major order.
    
    while(A_index < A.size()){
        //the v_index has to catch up with the A_index. If it passes it. We jump to the next A.

        uint v_index = 0;
        float acc = 0.0; //The accumulator tracks the sum for the current row; If A_index progresses to another row,
        //the content is appended to the resulting vector.

        //Check if we either reach the end of the row of A; or the end of the vector v.

        const uint  current_row = A[A_index].row;//By setting this equality, we ensure that the loop runs at least once.
        while(A[A_index].row==current_row && v_index < v.size()){
            if(A[A_index].col== v[v_index].index){//We find a coefficient that matches an entry in the vector. 
                acc += A[A_index].value * v[v_index].value;
                A_index++;
                v_index++;
            }
            else if(A[A_index].col < v[v_index].index){
                A_index++;

            }
            else if(A[A_index].col > v[v_index].index){
                v_index++;

            }
        }
        
        //Sparsity is also considered, for the cases where the accumulator is 0.
        while(current_row>u[u_index].index){
                result.push_back(u[u_index]);
                u_index++;
        }
        
            
        float value;
        if(current_row==u[u_index].index){
            value = u[u_index].value+acc;
            
        }
        else{
            value = acc;
        }

        struct Element c = {current_row,value};
        if(value!=0.0){
            result.push_back(c);
        }

        //Case: we have reached the end of vector v; but not necessarily exhausted the entire row.
        //We have to jump to the next Row of A.
        if(v_index==v.size()){
            while(A[A_index].row==current_row){
                A_index++;
            }
        }
        
    }

    while(u.size()>u_index){
                result.push_back(u[u_index]);
                u_index++;
        }
    //Thus we iterate over the vector v multiple times.
    return result;
}

/*
This is the matrix multiplication, without transposing one of the matrices.
Therefore, Assuming both matrices are row-major; we have to iterate over B many multiple times.
But
*/
vector<MatrixElement> sparseMatrixMatrix(const vector<MatrixElement>& A, const vector<MatrixElement>& B){
    uint A_index = 0;
    

    
    vector<MatrixElement> result;
    result.reserve(2<<5);
    //The result is a vector to which we append the coefficients.
    
    //For Matrix Vector Multiplication, its best if the matrix is stored in Row-Major order.
    
    //Super naive   O(m_A * m_B) implementation;  
    //where m_A is the #nonzero coefficients in A; and m_B = #nonzero coefficients in B.
    while(A_index < A.size()){
        //the v_index has to catch up with the A_index. If it passes it. We jump to the next A.

        uint B_index = 0;
        float acc = 0.0; //The accumulator tracks the sum for the current row; If A_index progresses to another row,
        //the content is appended to the resulting vector.

        //Check if we either reach the end of the row of A; or the end of the vector v.

        const uint  current_row = A[A_index].row;//By setting this equality, we ensure that the loop runs at least once.
        for(auto iter = B.begin(); iter < B.end(); iter++){
            if(A[A_index].col == iter->row){
                float prod = A[A_index].value * iter->value;
                
                struct MatrixElement c = {current_row,iter->col,prod};
                result.push_back(c);
            }

        }   

        A_index++;
        
    }
    //Thus we iterate over the vector v multiple times.
    return result;
}


int main(){

    vector<Element> u;
    vector<Element> v;



    //u.emplace_back(3,20.0);
    
    #ifdef SHORT
    struct Element u0 = {0,0.242};
    struct Element u1 = {4,0.242};
    struct Element u2 = {12,3.0};
    struct Element u3 = {13,0.343};
    
    u.push_back(u0);
    u.push_back(u1);
    u.push_back(u2);
    u.push_back(u3);
    #else

    for(uint i = 0; i < 2<<23; i++){
        struct Element u0 = {8*i,1.0};
        u.push_back(u0);
    }
    #endif

    #ifdef SHORT
    struct Element v0 = {0,1.0};
    struct Element v1 = {2,-2.0};
    struct Element v2 = {12,1.5};
    struct Element v3 = {13,1.5};
    
    v.push_back(v0);
    v.push_back(v1);
    v.push_back(v2);
    v.push_back(v3);
    #else

    for(uint i = 0; i < 2<<18; i++){
        struct Element u0 = {16*i+1,1.0};
        u.push_back(u0);
    }

    #endif

    
    vector<MatrixElement> identityMatrix;
    vector<MatrixElement> B;
    for(uint i = 0; i < 128; i++){
        struct MatrixElement a_ii = {i,i,1.0}; //the diagonal 1.0 entries, of the identity matrix.
        identityMatrix.push_back(a_ii);
        B.push_back(a_ii);
        if(i==3){
            struct MatrixElement el = {i,12,2.0};
            B.push_back(el);
        }
    }


    #ifndef SHORT
    auto start = high_resolution_clock::now();

    #endif

    vector<Element> res_vec = sparseFMAMatrixVector(u,identityMatrix,v);


    cout << "test left shift: " << (2<<10) << endl;

    #ifndef SHORT
    auto stop = high_resolution_clock::now();

    auto duration = duration_cast<microseconds>(stop - start);

    
    cout << "duration count: " <<duration.count() << endl;

    #endif
    
    
    #ifdef SHORT
    cout << "u" << endl;
    for(auto iter =  u.begin(); iter < u.end(); iter++){
        cout << iter->index << " " << iter->value << endl;
    }
    cout << endl <<  endl;

    cout << "v" << endl;
    for(auto iter =  v.begin(); iter < v.end(); iter++){
        cout << iter->index << " " << iter->value << endl;
    }

    cout << "res. vector " << endl;
    
    for(auto iter = res_vec.begin(); iter < res_vec.end(); iter++){
        cout << iter->index << ", " << iter->value << endl;
    }
    #else

    #endif



    #ifdef SHORT
    vector<MatrixElement> result_matrix = sparseMatrixMatrix(identityMatrix,B);
    cout << "result" << endl;
    for(auto iter =  result_matrix.begin(); iter < result_matrix.end(); iter++){
        cout << iter->row <<", " << iter->col <<" " << iter->value << endl;
    }

    cout << endl << endl;

    #endif



    
}