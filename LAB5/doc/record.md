#define Blocksize (32)
#define Matsize (4096)
#define Verifysize (1024)
#define T (64)
#define U (16)
#define S (T/U)

N:  4096  time1: 220.779098511  time2: 129.223144531 time3: 102.211441040

#define Matsize (4096)
#define Verifysize (1024)
#define T (64)
#define U (8)
#define S (T/U)

N:  4096  time1: 228.304718018  time2: 132.822448730 time3: 192.542633057

#define Blocksize (32)
#define Matsize (4096)
#define Verifysize (1024)
#define T (64)
#define U (4)
#define S (T/U)

N:  4096  time1: 237.374603271  time2: 128.459655762 time3: 343.517883301

+ 发现，随着S的变大，时间变长。这与我最开始的预期是相反的。
  + 每个线程需要执行N/S次小矩阵相乘，得到的结果累和为最后的结果。
  + 那么实验S=1时，看看情况怎么样


#define Blocksize (32)
#define Matsize (4096)
#define Verifysize (1024)
#define T (64)
#define U (64)
#define S (T/U)

N:  4096  time1: 214.284988403  time2: 124.956993103 time3: 42.935607910

+ 确实每次只算1个乘法，循环N次，反而快了。
  + 猜测是否是因为S=1时，share memory的使用率更高了。
+ 试验增大T，保持T=U

#define Blocksize (32)
#define Matsize (4096)
#define Verifysize (1024)
#define T (128)
#define U (128)
#define S (T/U)

N:  4096  time1: 230.449707031  time2: 132.513336182 time3: 36.778862000

#define Blocksize (32)
#define Matsize (4096)
#define Verifysize (1024)
#define T (256)
#define U (256)
#define S (T/U)

N:  4096  time1: 228.954910278  time2: 135.071868896 time3: 72.533760071

+ 发现T增大，性能没有再增加了，查看自己的GPU的配置
  + Registers per Block: 65536
  + 合理怀疑是寄存器的使用率过高了
+ 补充试验T=32，研究规律

#define Blocksize (32)
#define Matsize (4096)
#define Verifysize (1024)
#define T (32)
#define U (32)
#define S (T/U)

N:  4096  time1: 225.183517456  time2: 132.310424805 time3: 84.149772644

+ 符合预期，