#include <stdio.h>
#include <cuda_runtime.h>

int main() {
    cudaDeviceProp prop;
    int deviceCount;
    cudaGetDeviceCount(&deviceCount);

    for (int i = 0; i < deviceCount; ++i) {
        cudaGetDeviceProperties(&prop, i);
        printf("Device %d: %s\n", i, prop.name);
        printf("  Compute Capability: %d.%d\n", prop.major, prop.minor);
        printf("  MultiProcessor Count: %d\n", prop.multiProcessorCount);
        printf("  Shared Memory per Block: %zu bytes\n", prop.sharedMemPerBlock);
        printf("  Registers per Block: %d\n", prop.regsPerBlock);
        printf("  Threads per Block: %d\n", prop.maxThreadsPerBlock);
        printf("  Max Threads Dim: (%d, %d, %d)\n", prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
        printf("  Max Grid Dim: (%d, %d, %d)\n", prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2]);
        printf("  Warp Size: %d\n", prop.warpSize);
        printf("  Max Threads per SM: %d\n", prop.maxThreadsPerMultiProcessor);
        printf("  Max Threads per Block: %d\n", prop.maxThreadsPerBlock);
        printf("  Clock Rate: %d kHz\n", prop.clockRate);
        printf("  Total Constant Memory: %zu bytes\n", prop.totalConstMem);
        printf("  Total Global Memory: %zu bytes\n", prop.totalGlobalMem);
        printf(" regsPerBlock: %d\n", prop.regsPerBlock);
        printf("--------------------------------------------------\n");
    }

    return 0;
}


// (base) huyangjia@huyangjia:~/Coding/CS_Arch/comparch25spring-gem5/LAB5$ ./a.out 
// Device 0: NVIDIA GeForce RTX 3060 Laptop GPU
//   Compute Capability: 8.6
//   MultiProcessor Count: 30
//   Shared Memory per Block: 49152 bytes
//   Registers per Block: 65536
//   Threads per Block: 1024
//   Max Threads Dim: (1024, 1024, 64)
//   Max Grid Dim: (2147483647, 65535, 65535)
//   Warp Size: 32
//   Max Threads per SM: 1536
//   Max Threads per Block: 1024
//   Clock Rate: 1425000 kHz
//   Total Constant Memory: 65536 bytes
//   Total Global Memory: 6441926656 bytes
//  regsPerBlock: 65536
// --------------------------------------------------