#include <cstdio>
#include <random>
void get_diff(double *Y, double *Y_unroll, char *name)
{
    printf("%s:", name);
    for (int i = 0; i < 10000; i++)
    {
        if (Y[i] != Y_unroll[i])
        {
            printf("in num %d, Y = %d, Y_unroll = %d\n", i, Y[i], Y_unroll[i]);
            return;
        }
    }
    printf("all equal\n");
}



void daxpy(double *X, double *Y, double alpha, const int N)
{
    for (int i = 0; i < N; i++)
    {
        Y[i] = alpha * X[i] + Y[i];
    }
}

void daxsbxpxy(double *X, double *Y, double alpha, double beta, const int N)
{
    for (int i = 0; i < N; i++)
    {
        Y[i] = alpha * X[i] * X[i] + beta * X[i] + X[i] * Y[i];
    }
}

void stencil(double *Y, double alpha, const int N)
{
    for (int i = 1; i < N-1; i++)
    {
        Y[i] = alpha * Y[i-1] + Y[i] + alpha * Y[i+1];
    }
}


void daxpy_unroll_4(double *X, double *Y, double alpha, const int N)
{
    // 循环展开即可,10000恰好是4的倍数
    for (int i = 0; i < N; i += 4)
    {
        Y[i]   = alpha * X[i]   + Y[i];
        Y[i+1] = alpha * X[i+1] + Y[i+1];
        Y[i+2] = alpha * X[i+2] + Y[i+2];
        Y[i+3] = alpha * X[i+3] + Y[i+3];
    }
}
void daxpy_unroll_6(double *X, double *Y, double alpha, const int N)
{
    int iter = N / 6;
    int left = N % 6;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 6;
        Y[k]   = alpha * X[k]   + Y[k];
        Y[k+1] = alpha * X[k+1] + Y[k+1];
        Y[k+2] = alpha * X[k+2] + Y[k+2];
        Y[k+3] = alpha * X[k+3] + Y[k+3];
        Y[k+4] = alpha * X[k+4] + Y[k+4];
        Y[k+5] = alpha * X[k+5] + Y[k+5];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] + Y[i];
    }
}
void daxpy_unroll_8(double *X, double *Y, double alpha, const int N)
{
    int iter = N / 8;
    int left = N % 8;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 8;
        Y[k]   = alpha * X[k]   + Y[k];
        Y[k+1] = alpha * X[k+1] + Y[k+1];
        Y[k+2] = alpha * X[k+2] + Y[k+2];
        Y[k+3] = alpha * X[k+3] + Y[k+3];
        Y[k+4] = alpha * X[k+4] + Y[k+4];
        Y[k+5] = alpha * X[k+5] + Y[k+5];
        Y[k+6] = alpha * X[k+6] + Y[k+6];
        Y[k+7] = alpha * X[k+7] + Y[k+7];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] + Y[i];
    }
}
void daxpy_unroll_12(double *X, double *Y, double alpha, const int N)
{
    int iter = N / 12;
    int left = N % 12;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 12;
        Y[k]   = alpha * X[k]   + Y[k];
        Y[k+1] = alpha * X[k+1] + Y[k+1];
        Y[k+2] = alpha * X[k+2] + Y[k+2];
        Y[k+3] = alpha * X[k+3] + Y[k+3];
        Y[k+4] = alpha * X[k+4] + Y[k+4];
        Y[k+5] = alpha * X[k+5] + Y[k+5];
        Y[k+6] = alpha * X[k+6] + Y[k+6];
        Y[k+7] = alpha * X[k+7] + Y[k+7];
        Y[k+8] = alpha * X[k+8] + Y[k+8];
        Y[k+9] = alpha * X[k+9] + Y[k+9];
        Y[k+10] = alpha * X[k+10] + Y[k+10];
        Y[k+11] = alpha * X[k+11] + Y[k+11];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] + Y[i];
    }
}
void daxpy_unroll_16(double *X, double *Y, double alpha, const int N)
{
    int iter = N / 16;
    int left = N % 16;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 16;
        Y[k]   = alpha * X[k]   + Y[k];
        Y[k+1] = alpha * X[k+1] + Y[k+1];
        Y[k+2] = alpha * X[k+2] + Y[k+2];
        Y[k+3] = alpha * X[k+3] + Y[k+3];
        Y[k+4] = alpha * X[k+4] + Y[k+4];
        Y[k+5] = alpha * X[k+5] + Y[k+5];
        Y[k+6] = alpha * X[k+6] + Y[k+6];
        Y[k+7] = alpha * X[k+7] + Y[k+7];
        Y[k+8] = alpha * X[k+8] + Y[k+8];
        Y[k+9] = alpha * X[k+9] + Y[k+9];
        Y[k+10] = alpha * X[k+10] + Y[k+10];
        Y[k+11] = alpha * X[k+11] + Y[k+11];
        Y[k+12] = alpha * X[k+12] + Y[k+12];
        Y[k+13] = alpha * X[k+13] + Y[k+13];
        Y[k+14] = alpha * X[k+14] + Y[k+14];
        Y[k+15] = alpha * X[k+15] + Y[k+15];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] + Y[i];
    }
}


void daxsbxpxy_unroll_4(double *X, double *Y, double alpha, double beta, const int N)
{
    // 与上一函数的差异不大
    for (int i = 0; i < N; i += 4)
    {
        Y[i]   = alpha * X[i]   * X[i]   + beta * X[i]   + X[i]   * Y[i];
        Y[i+1] = alpha * X[i+1] * X[i+1] + beta * X[i+1] + X[i+1] * Y[i+1];
        Y[i+2] = alpha * X[i+2] * X[i+2] + beta * X[i+2] + X[i+2] * Y[i+2];
        Y[i+3] = alpha * X[i+3] * X[i+3] + beta * X[i+3] + X[i+3] * Y[i+3];
    }
}
void daxsbxpxy_unroll_6(double *X, double *Y, double alpha, double beta, const int N)
{
    int iter = N / 6;
    int left = N % 6;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 6;
        Y[k]   = alpha * X[k]   * X[k]   + beta * X[k]   + X[k]   * Y[k];
        Y[k+1] = alpha * X[k+1] * X[k+1] + beta * X[k+1] + X[k+1] * Y[k+1];
        Y[k+2] = alpha * X[k+2] * X[k+2] + beta * X[k+2] + X[k+2] * Y[k+2];
        Y[k+3] = alpha * X[k+3] * X[k+3] + beta * X[k+3] + X[k+3] * Y[k+3];
        Y[k+4] = alpha * X[k+4] * X[k+4] + beta * X[k+4] + X[k+4] * Y[k+4];
        Y[k+5] = alpha * X[k+5] * X[k+5] + beta * X[k+5] + X[k+5] * Y[k+5];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] * X[i] + beta * X[i] + X[i] * Y[i];
    }
}
void daxsbxpxy_unroll_8(double *X, double *Y, double alpha, double beta, const int N)
{
    int iter = N / 8;
    int left = N % 8;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 8;
        Y[k]   = alpha * X[k]   * X[k]   + beta * X[k]   + X[k]   * Y[k];
        Y[k+1] = alpha * X[k+1] * X[k+1] + beta * X[k+1] + X[k+1] * Y[k+1];
        Y[k+2] = alpha * X[k+2] * X[k+2] + beta * X[k+2] + X[k+2] * Y[k+2];
        Y[k+3] = alpha * X[k+3] * X[k+3] + beta * X[k+3] + X[k+3] * Y[k+3];
        Y[k+4] = alpha * X[k+4] * X[k+4] + beta * X[k+4] + X[k+4] * Y[k+4];
        Y[k+5] = alpha * X[k+5] * X[k+5] + beta * X[k+5] + X[k+5] * Y[k+5];
        Y[k+6] = alpha * X[k+6] * X[k+6] + beta * X[k+6] + X[k+6] * Y[k+6];
        Y[k+7] = alpha * X[k+7] * X[k+7] + beta * X[k+7] + X[k+7] * Y[k+7];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] * X[i] + beta * X[i] + X[i] * Y[i];
    }
}

void daxsbxpxy_unroll_12(double *X, double *Y, double alpha, double beta, const int N)
{
    int iter = N / 12;
    int left = N % 12;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 12;
        Y[k]   = alpha * X[k]   * X[k]   + beta * X[k]   + X[k]   * Y[k];
        Y[k+1] = alpha * X[k+1] * X[k+1] + beta * X[k+1] + X[k+1] * Y[k+1];
        Y[k+2] = alpha * X[k+2] * X[k+2] + beta * X[k+2] + X[k+2] * Y[k+2];
        Y[k+3] = alpha * X[k+3] * X[k+3] + beta * X[k+3] + X[k+3] * Y[k+3];
        Y[k+4] = alpha * X[k+4] * X[k+4] + beta * X[k+4] + X[k+4] * Y[k+4];
        Y[k+5] = alpha * X[k+5] * X[k+5] + beta * X[k+5] + X[k+5] * Y[k+5];
        Y[k+6] = alpha * X[k+6] * X[k+6] + beta * X[k+6] + X[k+6] * Y[k+6];
        Y[k+7] = alpha * X[k+7] * X[k+7] + beta * X[k+7] + X[k+7] * Y[k+7];
        Y[k+8] = alpha * X[k+8] * X[k+8] + beta * X[k+8] + X[k+8] * Y[k+8];
        Y[k+9] = alpha * X[k+9] * X[k+9] + beta * X[k+9] + X[k+9] * Y[k+9];
        Y[k+10] = alpha * X[k+10] * X[k+10] + beta * X[k+10] + X[k+10] * Y[k+10];
        Y[k+11] = alpha * X[k+11] * X[k+11] + beta * X[k+11] + X[k+11] * Y[k+11];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] * X[i] + beta * X[i] + X[i] * Y[i];
    }
}
void daxsbxpxy_unroll_16(double *X, double *Y, double alpha, double beta, const int N)
{
    int iter = N / 16;
    int left = N % 16;

    for (int i = 0; i < iter; i++)
    {
        int k = i * 16;
        Y[k]   = alpha * X[k]   * X[k]   + beta * X[k]   + X[k]   * Y[k];
        Y[k+1] = alpha * X[k+1] * X[k+1] + beta * X[k+1] + X[k+1] * Y[k+1];
        Y[k+2] = alpha * X[k+2] * X[k+2] + beta * X[k+2] + X[k+2] * Y[k+2];
        Y[k+3] = alpha * X[k+3] * X[k+3] + beta * X[k+3] + X[k+3] * Y[k+3];
        Y[k+4] = alpha * X[k+4] * X[k+4] + beta * X[k+4] + X[k+4] * Y[k+4];
        Y[k+5] = alpha * X[k+5] * X[k+5] + beta * X[k+5] + X[k+5] * Y[k+5];
        Y[k+6] = alpha * X[k+6] * X[k+6] + beta * X[k+6] + X[k+6] * Y[k+6];
        Y[k+7] = alpha * X[k+7] * X[k+7] + beta * X[k+7] + X[k+7] * Y[k+7];
        Y[k+8] = alpha * X[k+8] * X[k+8] + beta * X[k+8] + X[k+8] * Y[k+8];
        Y[k+9] = alpha * X[k+9] * X[k+9] + beta * X[k+9] + X[k+9] * Y[k+9];
        Y[k+10] = alpha * X[k+10] * X[k+10] + beta * X[k+10] + X[k+10] * Y[k+10];
        Y[k+11] = alpha * X[k+11] * X[k+11] + beta * X[k+11] + X[k+11] * Y[k+11];
        Y[k+12] = alpha * X[k+12] * X[k+12] + beta * X[k+12] + X[k+12] * Y[k+12];
        Y[k+13] = alpha * X[k+13] * X[k+13] + beta * X[k+13] + X[k+13] * Y[k+13];
        Y[k+14] = alpha * X[k+14] * X[k+14] + beta * X[k+14] + X[k+14] * Y[k+14];
        Y[k+15] = alpha * X[k+15] * X[k+15] + beta * X[k+15] + X[k+15] * Y[k+15];
    }
    for (int i = N - left; i < N; i++)
    {
        Y[i] = alpha * X[i] * X[i] + beta * X[i] + X[i] * Y[i];
    }
}


void stencil_unroll_4(double *Y, double alpha, const int N)
{
    // 从1开始到N-2结束，总共N-2个元素
    int iter = (N - 2) / 4;
    int left = (N - 2) % 4;
    for (int i = 0; i < iter; i++)
    {
        int k = i * 4 + 1;
        Y[k]   = alpha * Y[k-1] + Y[k]   + alpha * Y[k+1];
        Y[k+1] = alpha * Y[k]   + Y[k+1] + alpha * Y[k+2];
        Y[k+2] = alpha * Y[k+1] + Y[k+2] + alpha * Y[k+3];
        Y[k+3] = alpha * Y[k+2] + Y[k+3] + alpha * Y[k+4];
    }
    for (int i = N - 1 - left; i < N - 1; i++)
    {
        Y[i] = alpha * Y[i-1] + Y[i] + alpha * Y[i+1];
    }
}

void stencil_unroll_6(double *Y, double alpha, const int N)
{
    // 从1开始到N-2结束，总共N-2个元素
    int iter = (N - 2) / 6;
    int left = (N - 2) % 6;
    for (int i = 0; i < iter; i++)
    {
        int k = i * 6 + 1;
        Y[k]   = alpha * Y[k-1] + Y[k]   + alpha * Y[k+1];
        Y[k+1] = alpha * Y[k]   + Y[k+1] + alpha * Y[k+2];
        Y[k+2] = alpha * Y[k+1] + Y[k+2] + alpha * Y[k+3];
        Y[k+3] = alpha * Y[k+2] + Y[k+3] + alpha * Y[k+4];
        Y[k+4] = alpha * Y[k+3] + Y[k+4] + alpha * Y[k+5];
        Y[k+5] = alpha * Y[k+4] + Y[k+5] + alpha * Y[k+6];
    }
    for (int i = N - 1 - left; i < N - 1; i++)
    {
        Y[i] = alpha * Y[i-1] + Y[i] + alpha * Y[i+1];
    }
}
void stencil_unroll_8(double *Y, double alpha, const int N)
{
    // 从1开始到N-2结束，总共N-2个元素
    int iter = (N - 2) / 8;
    int left = (N - 2) % 8;
    for (int i = 0; i < iter; i++)
    {
        int k = i * 8 + 1;
        Y[k]   = alpha * Y[k-1] + Y[k]   + alpha * Y[k+1];
        Y[k+1] = alpha * Y[k]   + Y[k+1] + alpha * Y[k+2];
        Y[k+2] = alpha * Y[k+1] + Y[k+2] + alpha * Y[k+3];
        Y[k+3] = alpha * Y[k+2] + Y[k+3] + alpha * Y[k+4];
        Y[k+4] = alpha * Y[k+3] + Y[k+4] + alpha * Y[k+5];
        Y[k+5] = alpha * Y[k+4] + Y[k+5] + alpha * Y[k+6];
        Y[k+6] = alpha * Y[k+5] + Y[k+6] + alpha * Y[k+7];
        Y[k+7] = alpha * Y[k+6] + Y[k+7] + alpha * Y[k+8];
    }
    for (int i = N - 1 - left; i < N - 1; i++)
    {
        Y[i] = alpha * Y[i-1] + Y[i] + alpha * Y[i+1];
    }
}
void stencil_unroll_12(double *Y, double alpha, const int N)
{
    // 从1开始到N-2结束，总共N-2个元素
    int iter = (N - 2) / 12;
    int left = (N - 2) % 12;
    for (int i = 0; i < iter; i++)
    {
        int k = i * 12 + 1;
        Y[k]     = alpha * Y[k-1]   + Y[k]     + alpha * Y[k+1];
        Y[k+1]   = alpha * Y[k]     + Y[k+1]   + alpha * Y[k+2];
        Y[k+2]   = alpha * Y[k+1]   + Y[k+2]   + alpha * Y[k+3];
        Y[k+3]   = alpha * Y[k+2]   + Y[k+3]   + alpha * Y[k+4];
        Y[k+4]   = alpha * Y[k+3]   + Y[k+4]   + alpha * Y[k+5];
        Y[k+5]   = alpha * Y[k+4]   + Y[k+5]   + alpha * Y[k+6];
        Y[k+6]   = alpha * Y[k+5]   + Y[k+6]   + alpha * Y[k+7];
        Y[k+7]   = alpha * Y[k+6]   + Y[k+7]   + alpha * Y[k+8];
        Y[k+8]   = alpha * Y[k+7]   + Y[k+8]   + alpha * Y[k+9];
        Y[k+9]   = alpha * Y[k+8]   + Y[k+9]   + alpha * Y[k+10];
        Y[k+10]  = alpha * Y[k+9]   + Y[k+10]  + alpha * Y[k+11];
        Y[k+11]  = alpha * Y[k+10]  + Y[k+11]  + alpha * Y[k+12];
    }
    for (int i = N - 1 - left; i < N - 1; i++)
    {
        Y[i] = alpha * Y[i-1] + Y[i] + alpha * Y[i+1];
    }
}
void stencil_unroll_16(double *Y, double alpha, const int N)
{
    // 从1开始到N-2结束，总共N-2个元素
    int iter = (N - 2) / 16;
    int left = (N - 2) % 16;
    for (int i = 0; i < iter; i++)
    {
        int k = i * 16 + 1;
        Y[k]     = alpha * Y[k-1]   + Y[k]     + alpha * Y[k+1];
        Y[k+1]   = alpha * Y[k]     + Y[k+1]   + alpha * Y[k+2];
        Y[k+2]   = alpha * Y[k+1]   + Y[k+2]   + alpha * Y[k+3];
        Y[k+3]   = alpha * Y[k+2]   + Y[k+3]   + alpha * Y[k+4];
        Y[k+4]   = alpha * Y[k+3]   + Y[k+4]   + alpha * Y[k+5];
        Y[k+5]   = alpha * Y[k+4]   + Y[k+5]   + alpha * Y[k+6];
        Y[k+6]   = alpha * Y[k+5]   + Y[k+6]   + alpha * Y[k+7];
        Y[k+7]   = alpha * Y[k+6]   + Y[k+7]   + alpha * Y[k+8];
        Y[k+8]   = alpha * Y[k+7]   + Y[k+8]   + alpha * Y[k+9];
        Y[k+9]   = alpha * Y[k+8]   + Y[k+9]   + alpha * Y[k+10];
        Y[k+10]  = alpha * Y[k+9]   + Y[k+10]  + alpha * Y[k+11];
        Y[k+11]  = alpha * Y[k+10]  + Y[k+11]  + alpha * Y[k+12];
        Y[k+12]  = alpha * Y[k+11]  + Y[k+12]  + alpha * Y[k+13];
        Y[k+13]  = alpha * Y[k+12]  + Y[k+13]  + alpha * Y[k+14];
        Y[k+14]  = alpha * Y[k+13]  + Y[k+14]  + alpha * Y[k+15];
        Y[k+15]  = alpha * Y[k+14]  + Y[k+15]  + alpha * Y[k+16];
    }
    for (int i = N - 1 - left; i < N - 1; i++)
    {
        Y[i] = alpha * Y[i-1] + Y[i] + alpha * Y[i+1];
    }
}


int main()
{
    const int N = 10000;
    double *X = new double[N], alpha = 0.5, beta = 0.1;
    double *Y = new double[N], *Y_unroll_4 = new double[N], *Y_unroll_6 = new double[N], *Y_unroll_8 = new double[N], *Y_unroll_12 = new double[N], *Y_unroll_16 = new double[N];

    //std::random_device rd;
    std::mt19937 gen(0);
    std::uniform_real_distribution<> dis(1, 2);
    for (int i = 0; i < N; ++i)
    {
        X[i] = dis(gen);
        Y[i] = dis(gen);
        Y_unroll_4[i] = Y[i];
        Y_unroll_6[i] = Y[i];
        Y_unroll_8[i] = Y[i];
        Y_unroll_12[i] = Y[i];
        Y_unroll_16[i] = Y[i];
    }

    daxpy(X, Y, alpha, N);
    daxpy_unroll_4(X, Y_unroll_4, alpha, N);
    daxpy_unroll_6(X, Y_unroll_6, alpha, N);
    daxpy_unroll_8(X, Y_unroll_8, alpha, N);
    daxpy_unroll_12(X, Y_unroll_12, alpha, N);
    daxpy_unroll_16(X, Y_unroll_16, alpha, N);
    get_diff(Y, Y_unroll_4, "daxpy_unroll_4");
    get_diff(Y, Y_unroll_6, "daxpy_unroll_6");
    get_diff(Y, Y_unroll_8, "daxpy_unroll_8");
    get_diff(Y, Y_unroll_12, "daxpy_unroll_12");
    get_diff(Y, Y_unroll_16, "daxpy_unroll_16");



    daxsbxpxy(X, Y, alpha, beta, N);
    daxsbxpxy_unroll_4(X, Y_unroll_4, alpha, beta, N);
    daxsbxpxy_unroll_6(X, Y_unroll_6, alpha, beta, N);
    daxsbxpxy_unroll_8(X, Y_unroll_8, alpha, beta, N);
    daxsbxpxy_unroll_12(X, Y_unroll_12, alpha, beta, N);
    daxsbxpxy_unroll_16(X, Y_unroll_16, alpha, beta, N);
    get_diff(Y, Y_unroll_4, "daxsbxpxy_unroll_4");
    get_diff(Y, Y_unroll_6, "daxsbxpxy_unroll_6");
    get_diff(Y, Y_unroll_8, "daxsbxpxy_unroll_8");
    get_diff(Y, Y_unroll_12, "daxsbxpxy_unroll_12");
    get_diff(Y, Y_unroll_16, "daxsbxpxy_unroll_16");
    
    
    stencil(Y, alpha, N);
    stencil_unroll_4(Y_unroll_4, alpha, N);
    stencil_unroll_6(Y_unroll_6, alpha, N);
    stencil_unroll_8(Y_unroll_8, alpha, N);
    stencil_unroll_12(Y_unroll_12, alpha, N);
    stencil_unroll_16(Y_unroll_16, alpha, N);
    get_diff(Y, Y_unroll_4, "stencil_unroll_4");
    get_diff(Y, Y_unroll_6, "stencil_unroll_6");
    get_diff(Y, Y_unroll_8, "stencil_unroll_8");
    get_diff(Y, Y_unroll_12, "stencil_unroll_12");
    get_diff(Y, Y_unroll_16, "stencil_unroll_16");

    return 0;
}
