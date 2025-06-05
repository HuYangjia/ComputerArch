#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cuda_profiler_api.h>
#define smalloc(type,ptr,num) if(!(ptr=(type *)malloc(sizeof(type)*(num)))) exit(1)
#define Verifylen (1024)
// #define Seqlen (262144)
#define Seqlen (524288)
#define AD (32)
#define AT (64)

__global__ void Single_head_flash_atten(float *Q,float *K,float *V,float *O,unsigned l,float softmax_scale){ //unsigned d,

    // 一个block处理结果O数组的AT行，总共有l/AT个block并行处理
    // 一个thread处理结果O数组的一行，对应自己Block的第i行
    // 每个thread重复矩阵计算l/AT次

    // 每个thread负责
    // 1. 将自己的Q那一行搬入share memory中
    // 2. 将本次循环中的自己的那一列K和那一列V搬入share memory中

    __shared__ float Qshare[AT][AD]; // 每个block的share memory中存储AT行Q
    __shared__ float Kshare[AD][AT]; // 每个block的share memory中存储AT列K
    __shared__ float Vshare[AT][AD]; // 每个block的share memory中存储AT行V

    // 中间结果寄存器
    float S[AT]; // 中间S矩阵的一行
    float Ssum = 0.0f; // S矩阵的一行的和
    float sum[AD]; // 结果O矩阵的一行


    unsigned i=blockIdx.x*blockDim.x+threadIdx.x; //当前线程处理的O数组的第i行
    unsigned index = threadIdx.x; // 当前线程在block中的位置

    // 1. 将自己的Q那一行搬入share memory中
    for(unsigned j = 0; j < AD; j++){
        Qshare[index][j] = Q[i*AD + j];
        sum[j] = 0.0f; // 初始化结果O矩阵的一行
    }

    for(unsigned loop = 0; loop < l/AT; loop++){ // 每个线程循环l/AT次
        // Ssum = 0.0f; // 每次循环前清空Ssum FIXME: 这里不需要每次循环都清空Ssum，因为它是累加的
        // 2. 将本次循环中的自己的那一列K和那一列V搬入share memory中
        for(unsigned j = 0; j < AD; j++){
            Kshare[j][index] = K[(index + loop*AT)*AD + j]; // K的第index+loop*AT列
            Vshare[index][j] = V[(index + loop*AT)*AD + j]; // V的第index+loop*AT行
        }
        __syncthreads(); // 确保所有线程都完成了share memory的搬运
        // 3. 计算S矩阵
        for(unsigned j = 0; j < AT; j++){
            S[j] = 0.0f; // 初始化S矩阵的一行
            for(unsigned k = 0; k < AD; k++){
                S[j] += Qshare[index][k] * Kshare[k][j]; // Q*KT
            }
            S[j] = exp(S[j] * softmax_scale); // softmax
            Ssum += S[j]; // 累加S矩阵的一行的和
        }
        // 4. 计算O矩阵的一行
        for(unsigned j = 0; j < AD; j++){
            for(unsigned k = 0; k < AT; k++){
                sum[j] += S[k] * Vshare[k][j] ; // O[i][j] = S[i][k] * V[k][j] / Ssum
            }
        }
        __syncthreads(); // 确保所有线程都完成了S和O的计算
    }
    // 5. 将结果写回O矩阵
    for(unsigned j = 0; j < AD; j++){
        O[i*AD + j] = sum[j] / Ssum; // 除以Ssum
    }
    
    return ;
}

__global__ void Single_head_flash_atten1(float *Q,float *K,float *V,float *O,unsigned l,float softmax_scale)
{
    __shared__ float Qshare[AT][AD];
    __shared__ float Kshare[AT][AD];  // 改为[AT][AD]布局
    __shared__ float Vshare[AT][AD];
    
    unsigned i = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned index = threadIdx.x;
    
    // 1. 加载Q行到共享内存
    for(unsigned j = 0; j < AD; j++) {
        Qshare[index][j] = Q[i*AD + j];
    }
    
    // 中间结果寄存器
    float sum[AD] = {0.0f}; // 结果O矩阵的一行
    float Ssum = 0.0f;
    float max_val = -1e20f; // 初始化最大值
    
    // 第一阶段：找到全局最大值
    for(unsigned loop = 0; loop < l/AT; loop++) {
        // 2. 加载K和V的当前块
        for(unsigned j = 0; j < AD; j++) {
            // 修正K矩阵加载
            Kshare[index][j] = K[(index + loop*AT)*AD + j];
            Vshare[index][j] = V[(index + loop*AT)*AD + j];
        }
        __syncthreads();
        
        // 3. 计算当前块的最大值
        for(unsigned j = 0; j < AT; j++) {
            float val = 0.0f;
            for(unsigned k = 0; k < AD; k++) {
                val += Qshare[index][k] * Kshare[j][k]; // Q_i · K_j
            }
            val *= softmax_scale;
            if(val > max_val) max_val = val;
        }
        __syncthreads();
    }
    
    // 第二阶段：计算稳定的softmax
    for(unsigned loop = 0; loop < l/AT; loop++) {
        // 重新加载K和V的当前块
        for(unsigned j = 0; j < AD; j++) {
            Kshare[index][j] = K[(index + loop*AT)*AD + j];
            Vshare[index][j] = V[(index + loop*AT)*AD + j];
        }
        __syncthreads();
        
        // 4. 计算S矩阵
        for(unsigned j = 0; j < AT; j++) {
            float val = 0.0f;
            for(unsigned k = 0; k < AD; k++) {
                val += Qshare[index][k] * Kshare[j][k]; // Q_i · K_j
            }
            float s = expf(val * softmax_scale); // 稳定的softmax
            Ssum += s;
            
            // 5. 累加到O矩阵
            for(unsigned k = 0; k < AD; k++) {
                sum[k] += s * Vshare[j][k]; // 使用正确的V索引
            }
        }
        __syncthreads();
    }
    
    // 6. 归一化并写入结果
    for(unsigned j = 0; j < AD; j++) {
        O[i*AD + j] = sum[j] / Ssum;
    }
}

__host__ void single_head_atten_base(float *Q,float *K,float *V,float *O,unsigned l,float softmax_scale){
    unsigned i,j,k;
    float *S,*Ssum;
    smalloc(float,S,l*l);
    smalloc(float,Ssum,l);
    for(i=0;i<l;i++){
        Ssum[i]=0;
        for(j=0;j<l;j++){
            S[i*l+j]=0;
            for(k=0;k<AD;k++){
                S[i*l+j]+=Q[i*AD+k]*K[k+j*AD]; //Q* KT
            }
            S[i*l+j]=exp(S[i*l+j]*softmax_scale);//
            Ssum[i]+=S[i*l+j];
        }
    }
    
    for(i=0;i<l;i++){
        for(j=0;j<AD;j++){
            O[i*AD+j]=0;
            for(k=0;k<l;k++){
                O[i*AD+j]+=S[i*l+k]*V[k*AD+j]/Ssum[i];
            }
        }
    }
    free(S);free(Ssum);
}

__host__ void gen_QKV(float **phQ,float **phK,float **phV,unsigned l,unsigned d){
    float *hQ,*hK,*hV;
    smalloc(float,hQ,l*d);
    smalloc(float,hK,l*d);
    smalloc(float,hV,l*d);
    unsigned i;
    for (i = 0; i < l*d; i++){
        hQ[i] = 1.0*rand()/RAND_MAX;
        hK[i] = 1.0*rand()/RAND_MAX;
        hV[i] = 1.0*rand()/RAND_MAX;
    }
    *phQ=hQ;*phK=hK;*phV=hV;
}
__host__ unsigned compare(float *pred_,float *true_, unsigned n){
    unsigned i;
    float relative_error;
    for(i=0;i<n;i++){
        relative_error=fabs((pred_[i]-true_[i])/true_[i]);
        if(relative_error>=1e-5){
            printf("In line %d not equal! relative error: %12.9lf pred: %12.9f true: %12.9f\n",
                i, relative_error,pred_[i],true_[i]);
            return 1;
        }
    }
    printf("equal!\n");
    return 0;
}



int prinMat(float *A,int m,int n,FILE *fp){
	int i,j;
	for(i=0;i<m;i++){
		fprintf(fp,"%4d:",i);
		for(j=0;j<n;j++){
			fprintf(fp,"%12.9f ",A[i*n+j]);
		}
		fprintf(fp,"\n");
	}
    return 0;
}

int main(void){
    float *dQ,*dK,*dV,*dO,*hQ,*hK,*hV,*hO,*Obase;
    const unsigned Vl=Verifylen,Pl=Seqlen;
    const float softmax_scale=1/sqrt(AD);
    unsigned i;
    gen_QKV(&hQ,&hK,&hV,Vl,AD);
    smalloc(float,hO,Vl*AD);
    smalloc(float,Obase,Vl*AD);
    cudaMalloc(&dQ, sizeof(float)*(Vl*AD));
    cudaMalloc(&dK, sizeof(float)*(Vl*AD));
    cudaMalloc(&dV, sizeof(float)*(Vl*AD));
    cudaMalloc(&dO, sizeof(float)*(Vl*AD));
    cudaMemcpy(dQ, hQ, sizeof(float)*(Vl*AD), cudaMemcpyHostToDevice);
    cudaMemcpy(dK, hK, sizeof(float)*(Vl*AD), cudaMemcpyHostToDevice);
    cudaMemcpy(dV, hV, sizeof(float)*(Vl*AD), cudaMemcpyHostToDevice);
    dim3 gridsize(Vl/AT),blocksize(AT);
    Single_head_flash_atten <<<gridsize,blocksize>>>(dQ,dK,dV,dO,Vl,softmax_scale);
    cudaMemcpy(hO, dO, sizeof(float)*(Vl*AD), cudaMemcpyDeviceToHost);
    single_head_atten_base(hQ,hK,hV,Obase,Vl,softmax_scale);
    cudaDeviceSynchronize();
    unsigned flag=0;
    flag|=compare(hO,Obase,Vl*AD);
    if(flag){
        printf("test fail!\n");
        exit(0);
    }
    printf("test pass!\n");
    free(hQ);free(hK);free(hV);free(hO);free(Obase);
    cudaFree(dQ);cudaFree(dK);cudaFree(dV);cudaFree(dO);

    gen_QKV(&hQ,&hK,&hV,Pl,AD);
    cudaMalloc(&dQ, sizeof(float)*(Pl*AD));
    cudaMalloc(&dK, sizeof(float)*(Pl*AD));
    cudaMalloc(&dV, sizeof(float)*(Pl*AD));
    cudaMalloc(&dO, sizeof(float)*(Pl*AD));
    cudaMemcpy(dQ, hQ, sizeof(float)*(Pl*AD), cudaMemcpyHostToDevice);
    cudaMemcpy(dK, hK, sizeof(float)*(Pl*AD), cudaMemcpyHostToDevice);
    cudaMemcpy(dV, hV, sizeof(float)*(Pl*AD), cudaMemcpyHostToDevice);
    gridsize={Pl/AT};blocksize={AT};
    
    
    cudaEvent_t start, stop;
    float Time1 = 0.0,temp=0;
    const unsigned loopnum=10;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    for(i=0;i<loopnum;i++){
        cudaEventRecord(start, 0);
        Single_head_flash_atten <<<gridsize,blocksize>>>(dQ,dK,dV,dO,Pl,softmax_scale);
        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&temp, start, stop);
        Time1+=temp;temp=0;
        cudaDeviceSynchronize();
    }
    
    printf("l: %5.d   time: %12.9f\n",Pl,Time1/loopnum);
    free(hQ);free(hK);free(hV);
    cudaFree(dQ);cudaFree(dK);cudaFree(dV);cudaFree(dO);

}