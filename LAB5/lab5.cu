#include<stdio.h>
#include<stdlib.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cuda_profiler_api.h>
#define smalloc(type,ptr,num) if(!(ptr=(type *)malloc(sizeof(type)*(num)))) exit(1)
#define Blocksize (32)
#define Matsize (4096)
#define Verifysize (1024)
#define T (64)
#define U (16)
#define S (T/U)
__global__ void Matmul1(float *A,float *B,float *C,unsigned N){
    unsigned row=blockIdx.y*blockDim.y+threadIdx.y;
    unsigned col=blockIdx.x*blockDim.x+threadIdx.x;
    unsigned k;
    float sum=0;
    for(k=0;k<N;k++){
        sum+=A[row*N+k]*B[k*N+col];
    }
    C[row*N+col]=sum;  
}

__global__ void Matmul2(float *A,float *B,float *C,unsigned N){// A,B with padding
    unsigned tx=threadIdx.x,ty=threadIdx.y;
    unsigned bx=blockIdx.x,by=blockIdx.y;
    unsigned row=by*blockDim.y+ty;
    unsigned col=bx*blockDim.x+tx;
    __shared__ float Asub[Blocksize][Blocksize],Bsub[Blocksize][Blocksize];
    float sum=0;   
    unsigned kk,k;
    for(kk=0;kk<N;kk+=Blocksize){
        Asub[ty][tx]=A[row*N+(kk+tx)];
        Bsub[ty][tx]=B[(kk+ty)*N+col];
        __syncthreads();
        for(k=0;k<Blocksize;k++){
            sum+=Asub[ty][k]*Bsub[k][tx];
        }
        __syncthreads();
    }
    C[row*N+col]=sum;
}

__global__ void Matmul3(float *A,float *B,float *C,unsigned N)
    // 计算每个block的起始位置
    // 每个block有64(T)个线程，默认一个Block解决T*S这样一个块的计算
    // 反推出grid中的block数，第一维是N / U, 第二维是N / T，默认可整除
    // 每个thread的职责
    // 循环N / S次完成任务
    // 1. 将S个数据从A中取出，放入自己的register中
    // 2. 合作将S*U个数据从B中取出，放入block的shared memory中，每个thread负责U个点位的数据(因为这里S=4， U=16，S*U=T)
{
    // unsigned tx = threadIdx.x; // 这里我的Block维度是(1, 64)，所以tx=0。实际保证后面用不到这个tx数据
    unsigned ty = threadIdx.y; // ty也是标识目前的thread在block中的位置的唯一标识
    unsigned bx = blockIdx.x;
    unsigned by = blockIdx.y;
    unsigned row = by*blockDim.y + ty;
    // unsigned col = bx*blockDim.x + tx;
    __shared__ float Bsub[S][U];
    float Areg[S];
    float sum[U] = {0.0f};

    unsigned loop_count;
    for(loop_count = 0; loop_count < N; loop_count += S){
        // 一次循环中，赋值一次shared memory和register，同时计算一次矩阵乘法
        // 1. 将S个数据从A中取出，放入自己的register中

        #pragma unroll
        for(int i = 0; i < S; i++){
            Areg[i] = A[row*N + loop_count + i];
        }

        // 2. 合作将S*U个数据从B中取出，放入block的shared memory中，每个thread负责1个点位的数据(因为这里S=4， U=16，S*U=T)
        Bsub[ty / U][ty % U] = B[(loop_count + ty / U) * N + ty % U + bx * U];
        __syncthreads();
        // 3. 计算一行的点
        // #pragma unroll
        for(int i = 0; i < U; i++){
            // 对于负责的一行的每一点
            for(int j = 0; j < S; j++){
                // 计算出这一行的点
                sum[i] += Areg[j] * Bsub[j][i];
            }
        }
        __syncthreads();
    }
    // 4. 将结果放入C中
    for(int i = 0; i < U; i++){
        C[row*N + bx*U + i] = sum[i];
    }
}

__host__ void matmubase(float *A,float *B,float *C,unsigned N){
    unsigned i,j,k;
    for(i=0;i<N;i++){
        for(j=0;j<N;j++){
            C[i*N+j]=0;
            for(k=0;k<N;k++){
                C[i*N+j]+=A[i*N+k]*B[k*N+j];
            }
        }
    }
}

__host__ void gen_mat(float **pA,float **pB,unsigned N){
    float *A,*B;
    smalloc(float,A,N*N);
    smalloc(float,B,N*N);
    unsigned i;
    for (i = 0; i < N*N; i++){
        A[i] = 1.0*rand()/RAND_MAX;
        B[i] = 1.0*rand()/RAND_MAX;
    }
    *pA=A;*pB=B;
}

__host__ unsigned compare(float *pred_,float *true_, unsigned n){
    unsigned i;
    float relative_error;
    for(i=0;i<n;i++){
        relative_error=fabs((pred_[i]-true_[i])/true_[i]);
        if(relative_error>=1e-6){
            printf("not equal! relative error: %12.9lf pred: %12.9f true: %12.9f\n",
                relative_error,pred_[i],true_[i]);
            return 1;
        }
    }
    printf("equal!\n");
    return 0;
}


int main(void){
    const unsigned PN=Matsize,VN=Verifysize;
    float *hA,*hB,*hC1,*hC2, *hC3,*dA,*dB,*dC1,*dC2,*dC3,*Cbase;
    gen_mat(&hA,&hB,VN);
    smalloc(float,Cbase,sizeof(float)*VN*VN);
    smalloc(float,hC1,sizeof(float)*VN*VN);
    smalloc(float,hC2,sizeof(float)*VN*VN);
    smalloc(float,hC3,sizeof(float)*VN*VN);
    cudaMalloc(&dA,sizeof(float)*VN*VN);
    cudaMalloc(&dB,sizeof(float)*VN*VN);
    cudaMalloc(&dC1,sizeof(float)*VN*VN);
    cudaMalloc(&dC2,sizeof(float)*VN*VN);
    cudaMalloc(&dC3,sizeof(float)*VN*VN);
    cudaMemcpy(dA, hA, sizeof(float)*VN*VN, cudaMemcpyHostToDevice);
    cudaMemcpy(dB, hB, sizeof(float)*VN*VN, cudaMemcpyHostToDevice);

    dim3 gridsize(VN/Blocksize,VN/Blocksize),blocksize(Blocksize,Blocksize);
    dim3 gridsize3(VN/U, VN/T), blocksize3(1, T);
    Matmul1 <<<gridsize ,blocksize >>>(dA,dB,dC1,VN);
    Matmul2 <<<gridsize ,blocksize >>>(dA,dB,dC2,VN);
    Matmul3 <<<gridsize3 ,blocksize3 >>>(dA,dB,dC3,VN);
    cudaMemcpy(hC1, dC1, sizeof(float)*VN*VN, cudaMemcpyDeviceToHost);
    cudaMemcpy(hC2, dC2, sizeof(float)*VN*VN, cudaMemcpyDeviceToHost);
    cudaMemcpy(hC3, dC3, sizeof(float)*VN*VN, cudaMemcpyDeviceToHost);
    matmubase(hA,hB,Cbase,VN);
    cudaDeviceSynchronize();

    int flag=0;
    flag|=compare(hC1,Cbase,VN*VN);
    flag|=compare(hC2,Cbase,VN*VN);
    flag|=compare(hC3,Cbase,VN*VN);
    if(flag){
        printf("error!\n");
        exit(1);
    }
    printf("pass!\n");
    free(hA);free(hB);free(hC1);free(hC2);free(hC3);free(Cbase);
    cudaFree(dA);cudaFree(dB);cudaFree(dC1);cudaFree(dC2);cudaFree(dC3);


    gen_mat(&hA,&hB,PN);
    cudaMalloc(&dA,sizeof(float)*PN*PN);
    cudaMalloc(&dB,sizeof(float)*PN*PN);
    cudaMalloc(&dC1,sizeof(float)*PN*PN);
    cudaMalloc(&dC2,sizeof(float)*PN*PN);
    cudaMalloc(&dC3,sizeof(float)*PN*PN);
    cudaMemcpy(dA, hA, sizeof(float)*PN*PN, cudaMemcpyHostToDevice);
    cudaMemcpy(dB, hB, sizeof(float)*PN*PN, cudaMemcpyHostToDevice);

    gridsize={PN/Blocksize,PN/Blocksize};blocksize={Blocksize,Blocksize};
    gridsize3={PN/U, PN/T}; blocksize3={1, T};

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float Time1 = 0.0,Time2=0.0,Time3=0.0,temp=0;
    const unsigned loopnum=10;
    unsigned i;
    for(i=0;i<loopnum;i++){

        cudaEventRecord(start, 0);
	    Matmul1 <<<gridsize,blocksize>>>(dA,dB,dC1,PN);
        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&temp, start, stop);
        Time1+=temp;temp=0;

        cudaDeviceSynchronize();
        

        cudaEventRecord(start, 0);
	    Matmul2 <<<gridsize,blocksize>>>(dA,dB,dC2,PN);
        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&temp, start, stop);
        Time2+=temp;temp=0;

        cudaDeviceSynchronize();
        
        cudaEventRecord(start, 0);
	    Matmul3 <<<gridsize3,blocksize3>>>(dA,dB,dC3,PN);
        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&temp, start, stop);
        Time3+=temp;temp=0;

        cudaDeviceSynchronize();
    }
    
    printf("N: %5.d  time1: %12.9f  time2: %12.9f time3: %12.9f\n"
            ,PN,Time1/loopnum,Time2/loopnum,Time3/loopnum);
    free(hA);free(hB);
    cudaFree(dA);cudaFree(dB);cudaFree(dC1);cudaFree(dC2);

}