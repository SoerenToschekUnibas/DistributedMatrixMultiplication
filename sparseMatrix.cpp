#include <stdio.h>
#include <stdlib.h>
#include <iostream>
using namespace std;

/*
A single sparse element, in a sparse vector. Therefore it has only one index.*/
struct Element {
    int index;
    float value;
};

/*
Used as either a column or a row.
Assumes that an array of the given length is in memory.
*/
struct SparseVector {
    int index; //If this is a row, this is the row index.
    int length;
    vector<Element> coefficients;
    //pointer. 
};

/*
Datatype to represent a sparse matrix.
Can be either stored as list of rows;
Or list of rows.
*/
struct SparseMatrix{
    bool rowMajor; //If true this stored in Row-Major order.
    //If rowMajor is true, each list is a row.
    //SparseVector lists[];//Used as either rows or columns
};

/*
Store matrix as subset of sparse matrices.
*/






double sparseDotProduct(const vector<Element>& u, const vector<Element>& v){
    // The index within the std::vector; 
    uint index_u = 0;
    uint index_v = 0;
    
    double result = 0.0;

    //Since the dot-product is symmetric, this code should also be symmetric w.r.t. u & v.
    while( index_u < u.size() && index_v < v.size()) {
        if( u[index_u].index == v[index_v].index){
            result += u[index_u].value * v[index_v].value;
        }
        else if(u[index_u].index < v[index_v].index) index_u++;
        else if(u[index_u].index > v[index_v].index) index_v++;
    }

    return result;
}



void TransposeMatrix(){
    
}



int main()
{
    vector<Element> u;
    vector<Element> v;
    
    struct Element u_init[] = {
        {.index=3, .value=3.3},
        {.index=6, .value=1.0},
        {.index=7, .value=1.0},
        {.index=8, .value=1.0},
        {.index=12, .value=3.3},
        {.index=21, .value=23.31},
        {.index=32, .value=2.32},
        {.index=600, .value=1.0},
        {.index=1024, .value=0.4}
    };
    for (int i = 0; i < sizeof(u_init) / sizeof(u_init[0]); i++) {
        u.push_back(u_init[i]);
    }
    
    struct Element v_init[] = {
        {.index=0, .value=1.0},
        {.index=3, .value=0.1},
        {.index=4, .value=0.3},
        {.index=6, .value=0.25},
        {.index=15, .value=0.22},
        {.index=16, .value=1.0},
        {.index=20, .value=1.0},
        {.index=500, .value=1.5},
        {.index=501, .value=0.32},
        {.index=1024, .value=0.3},
    };
    for (int i = 0; i < sizeof(v_init) / sizeof(v_init[0]); i++) {
            v.push_back(v_init[i]);
        }
    
    


    //vector<Element> res = sparseDotProduct(u,v);
    /*
    for (int i=0; i<res.size(); i++)
    {
        
        cout <<" "<< res[i].index << "\t," << res[i].value << endl;

        cout <<"\n";
    }

    */
    return 0;
}
