# 体系结构Lab4

**PB22111665 胡揚嘉**



## 实验过程展示

1. 编译`arm`指令集架构下的`gem5`

   使用命令：`python3 which scons build/ARM/gem5.opt`

2. 修改daxpy:

   对于循环展开，由于需要不同的展开次数的对比，所以对于每个循环，每分别给出了展开`4,6,8,12,16`总计5中种情况的代码，并且集中在一个文件中进行测试。

   为了验证正确性，我增加函数`get_diff`实现

   ```cpp
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
   
   //下面是main的片段
   {
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
   }
   ```

   1. 每个展开，使用不同的`Y_unroll_x`去处理，然后分别于标准结果进行对比，给出结论

   2. 由于`get_diff`函数会影响性能分析，所以重新创建文件`daxpy_test_correct.cc`，并且在`X86`(本机环境下)进行测试。（逻辑上，使用gem5也可以，但是为了性能和实验考量）

      结果如下：

      ```bash
      daxpy_unroll_4:all equal
      daxpy_unroll_6:all equal
      daxpy_unroll_8:all equal
      daxpy_unroll_12:all equal
      daxpy_unroll_16:all equal
      daxsbxpxy_unroll_4:all equal
      daxsbxpxy_unroll_6:all equal
      daxsbxpxy_unroll_8:all equal
      daxsbxpxy_unroll_12:all equal
      daxsbxpxy_unroll_16:all equal
      stencil_unroll_4:all equal
      stencil_unroll_6:all equal
      stencil_unroll_8:all equal
      stencil_unroll_12:all equal
      stencil_unroll_16:all equal
      ```

      验证，循环展开确实不会影响结果

3. 编译`daxpy.cc`,pass

4. 分别对原始情况，修改HPI配置，修改g++优化参数三种情况进行仿真，结果记录在`result/`中

5. 提取`simTicks`,`system.cpu_cluster.cpus.numInsts`,`CPI`三个指标，用于后面的探究



## 性能的探究和问题的证明

**cpi**指标

| Index               | normal   | hpi_change | hpi_plus_O3 |
| -----               | -------- | ---------- | ----------- |
| daxpy               | 1.777314 | 1.777314   | 1.822548    |
| daxpy_unroll_4      | 2.005099 | 2.005099   | 1.978017    |
| daxpy_unroll_6      | 2.108254 | 2.108254   | 2.913548    |
| daxpy_unroll_8      | 2.091105 | 2.091105   | 2.050536    |
| daxpy_unroll_12     | 2.165813 | 2.165813   | 2.143927    |
| daxpy_unroll_16     | 2.182283 | 2.182283   | 2.220584    |
| daxsbxpxy           | 2.096203 | 2.012890   | 2.057140    |
| daxsbxpxy_unroll_4  | 2.256338 | 2.176849   | 1.462746    |
| daxsbxpxy_unroll_6  | 2.336423 | 2.256033   | 1.767537    |
| daxsbxpxy_unroll_8  | 2.327816 | 2.245540   | 1.475061    |
| daxsbxpxy_unroll_12 | 2.385227 | 2.302910   | 1.572645    |
| daxsbxpxy_unroll_16 | 2.392696 | 2.308082   | 1.404914    |
| stencil             | 1.961879 | 1.961879   | 2.211520    |
| stencil_unroll_4    | 1.851097 | 1.825500   | 3.225703    |
| stencil_unroll_6    | 1.928203 | 1.909718   | 3.699886    |
| stencil_unroll_8    | 1.900633 | 1.886552   | 4.276221    |
| stencil_unroll_12   | 1.941131 | 1.931416   | 4.415144    |
| stencil_unroll_16   | 1.936918 | 1.929538   | 4.552544    |


**simTicks**指标
| Index               | normal   | hpi_change | hpi_plus_O3 |
| -----               |----------|------------|-------------|
| daxpy               | 35552500 | 35552500   | 18235500    |
| daxpy_unroll_4      | 35096250 | 35096250   | 14846500    |
| daxpy_unroll_6      | 35157250 | 35157250   | 18257750    |
| daxpy_unroll_8      | 34647000 | 34647000   | 12193000    |
| daxpy_unroll_12     | 34764000 | 34764000   | 12095500    |
| daxpy_unroll_16     | 34452250 | 34452250   | 12163250    |
| daxsbxpxy           | 62895000 | 60395250   | 28297500    |
| daxsbxpxy_unroll_4  | 62057750 | 59871500   | 17379250    |
| daxsbxpxy_unroll_6  | 62327000 | 60182500   | 18444250    |
| daxsbxpxy_unroll_8  | 61847750 | 59661750   | 14764250    |
| daxsbxpxy_unroll_12 | 62138750 | 59994250   | 15102500    |
| daxsbxpxy_unroll_16 | 61702250 | 59520250   | 13624500    |
| stencil             | 49045500 | 49045500   | 33172250    |
| stencil_unroll_4    | 45126500 | 44502500   | 32285250    |
| stencil_unroll_6    | 43393250 | 42977250   | 33952000    |
| stencil_unroll_8    | 42180750 | 41868250   | 36133000    |
| stencil_unroll_12   | 41662000 | 41453500   | 36837750    |
| stencil_unroll_16   | 40875750 | 40720000   | 37072500    |

**numInsts**指标

| Index               | normal | hpi_change | hpi_plus_O3 |
| -----               |--------|------------|-------------|
| daxpy               | 80014  | 80014      | 40022       |
| daxpy_unroll_4      | 70014  | 70014      | 30023       |
| daxpy_unroll_6      | 66704  | 66704      | 25066       |
| daxpy_unroll_8      | 66275  | 66275      | 23785       |
| daxpy_unroll_12     | 64205  | 64205      | 22567       |
| daxpy_unroll_16     | 63149  | 63149      | 21910       |
| daxsbxpxy           | 120017 | 120017     | 55023       |
| daxsbxpxy_unroll_4  | 110015 | 110015     | 47525       |
| daxsbxpxy_unroll_6  | 106705 | 106705     | 41740       |
| daxsbxpxy_unroll_8  | 106276 | 106276     | 40037       |
| daxsbxpxy_unroll_12 | 104206 | 104206     | 38413       |
| daxsbxpxy_unroll_16 | 103151 | 103151     | 38791       |
| stencil             | 99997  | 99997      | 59999       |
| stencil_unroll_4    | 97513  | 97513      | 40035       |
| stencil_unroll_6    | 90018  | 90018      | 36706       |
| stencil_unroll_8    | 88772  | 88772      | 33799       |
| stencil_unroll_12   | 85851  | 85851      | 33374       |
| stencil_unroll_16   | 84414  | 84414      | 32573       |



回答问题：

1. 证明循环展开优化不会影响最终结果：上面展示实验过程的函数`get_diff`实现部分已经证明，并且给出测试结果：

   ```bash
   daxpy_unroll_4:all equal
   daxpy_unroll_6:all equal
   daxpy_unroll_8:all equal
   daxpy_unroll_12:all equal
   daxpy_unroll_16:all equal
   daxsbxpxy_unroll_4:all equal
   daxsbxpxy_unroll_6:all equal
   daxsbxpxy_unroll_8:all equal
   daxsbxpxy_unroll_12:all equal
   daxsbxpxy_unroll_16:all equal
   stencil_unroll_4:all equal
   stencil_unroll_6:all equal
   stencil_unroll_8:all equal
   stencil_unroll_12:all equal
   stencil_unroll_16:all equal
   ```

   如此可以验证，循环展开确实不会影响结果

   > 不使用sum累加的原因，不排除由于随机数导致的过程不一样，结果一样的例外，逐个相比较更加合理

2. 查看`simTicks`指标的`normal`列，观察不循环优化，和不同大小的循环优化的结果：

   均能够发现：循环优化后的总运行时间都小于未优化的性能。

   结论是:循环优化确实提升了性能

3. 显然，循环展开能够减少控制hazard。展开N次，大体上，跳转次数是原始的$$\frac{1}{N}$$

   这样减少了控制hazard

   展开次数的选择，应该根据`simTicks`指标的`normal`列，观察不同的函数在那种展开下性能最好，下面是一些相关的探究

   |           | normal | unroll_4 | unroll_6 | unroll_8 | unroll_12 | unroll_16 |
   | --------- | ------ | -------- | -------- | -------- | --------- | --------- |
   | daxpy     | 80014  | 70014    | 66704    | 66275    | 64205     | 63149     |
   | daxsbxpxy | 120017 | 110015   | 106705   | 106276   | 104206    | 103151    |
   | stencil   | 99997  | 97513    | 90018    | 88772    | 85851     | 84414     |

   观察可得：

   1. daxpy在展开[4,16]中，`simTicks`持续减小，选择16最佳
   2. daxsbxpxy在展开[4,16]中，`simTicks`持续减小，选择16最佳
   3. stenci在展开[4,16]中，`simTicks`持续减小，选择16最佳

   事实上，在补充实验展开32测试次数后，发现CPI增长过大，导致最终效果不如不展开

   在当下的实验设置下，3个循环都以展开16次为最佳。

   没有展开，跳转指令多，控制hazard大，cpi低，但是执行指令条数多

   过度展开，数据hazard增大，cpi变大

   综上，二者都会极大的影响性能

4. 观察`numInsts`指标的`normal`和`hpi_change`列，二者没有差别，说明增大硬件不能够改变需要执行的指令数量，这也非常符合直觉。

   观察`cpi`指标的`normal`和`hpi_change`列。在展开次数较多的情况下，cpi降低，在展开次数较少的情况下，cpi不变。这说明，增大硬件，如果当下的执行的瓶颈在于并行数量太大，硬件是瓶颈，则增大硬件，增大并行数量，减少阻塞，减少cpi

   综上二者，`numInsts`一定不变，`cpi`酌情变化，可以得到对于最终性能的影响。

   综上，增加硬件减少浮点数并行执行的结构hazard。

5. 我选择的是`simTicks`指标，因为当时钟频率相同时，其与执行时间成正比。而benchmark的效果比较，本来就应该以执行时间作为比较对象的。故选择`simTicks`指标时有意义的。

6. 查看`simTicks`指标的`normal`列和`hpi_plus_O3`列

   结果说明是有意义的。

   编译器的O3优化确实极大的提高了性能(50%)。手动循环展开确实提高性能的程度不高。(25%)

   但是`手动循环展开 + 编译器O3`优化(75%)，在单纯的O3优化基础上，又极大的提高了性能，

   所以结论是：手动优化是有意义的