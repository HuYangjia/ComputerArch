
## 修改配置

> 为研究如何查找配置，最重要的是查看--help给出的信息
>
> ```
> huyangjia@huyangjia:~/Coding/CS_Arch/comparch25spring-gem5$ gem5-stable/build/X86/gem5.opt lab2/se.py --help
> ```
>
> 例如对于如何修改issueWidth，需要查看如下信息：
>
> ```
>   -P PARAM, --param PARAM
>                         Set a SimObject parameter relative to the root node. An extended Python multi range slicing syntax can be used for arrays. For example: 'system.cpu[0,1,3:8:2].max_insts_all_threads = 42' sets
>                         max_insts_all_threads for cpus 0, 1, 3, 5 and 7 Direct parameters of the root object are not accessible, only parameters of its children.
>   --list-cpu-types      List available CPU types
> ```
>
> 从这里发现，可以通过`--param system.cpu[0].issueWidth=8`完成修改


模仿这样的方式，可以通过相同的命令行参数指定需要的配置

| 命令                              | 对应的变量                |
| --------------------------------- | ------------------------- |
| --cpu-type=                       | cpu类型                   |
| --cpu-clock                       | cpu时钟                   |
| --caches                          | 启用cache                 |
| --l1d_size=,  --l1i_size=         | 确定L1Cache的大小特征     |
| --param=system.cpu[0].issueWidth= | 超标量CPU中的issue宽      |
| --l2cache --l2_size=              | 启用L2Cache并且确定其大小 |
| --cmd=                            | 运行的程序的路径          |

在时机的实验中，只设置了四个变量，分别是：`cpu_type`, `cpu_clock`, `L2cache & its size`,  `issueWidth`

所以在脚本文件中，特定的对齐进行处理。

```shell
#!/bin/bash

# 进入根目录，所有操作都在这里进行
cd /home/huyangjia/Coding/CS_Arch/comparch25spring-gem5

# 确定路径相关参数
FILE_PATH="/home/huyangjia/Coding/CS_Arch/comparch25spring-gem5/lab2/lab2-benchmark"
OUTPUT_DIR="/home/huyangjia/Coding/CS_Arch/comparch25spring-gem5/lab2/output"


# 创建输出目录以及5个子目录
mkdir -p ${OUTPUT_DIR}

for i in {1..7}; do
    mkdir -p "${OUTPUT_DIR}/${i}"
done

# 定义二进制文件数组,每个配置，需要运行5次实验，对应如下
EXE_FILES=(
    "lfsr"
    "merge"
    "mm"
    "sieve"
    "spmv"
)

# 定义实验配置
CONFIGS=(
    "DerivO3CPU 8 1GHz None"
    "MinorCPU - 1GHz None"
    "DerivO3CPU 2 1GHz None"
    "DerivO3CPU 8 4GHz None"
    "DerivO3CPU 8 1GHz 256kB"
    "DerivO3CPU 8 1GHz 2MB"
    "DerivO3CPU 8 1GHz 16MB"
)

# 遍历每个二进制文件和实验配置
for i in "${!CONFIGS[@]}"; do
    FACT_CONFIG=(${CONFIGS[i]})  # 将配置字符串分割为数组
    CPU_TYPE=${FACT_CONFIG[0]}
    ISSUE_WIDTH=${FACT_CONFIG[1]}
    CPU_CLOCK=${FACT_CONFIG[2]}
    L2_CACHE=${FACT_CONFIG[3]}

    # 构造基础命令
    CMD="gem5-stable/build/X86/gem5.opt lab2/se.py \
        --cpu-type=${CPU_TYPE} \
        --cpu-clock=${CPU_CLOCK} \
        --options=\"\" \
        --caches \
        --l1d_size=64kB \
        --l1i_size=64kB"  # 默认启用 L1 Cache，并设置 L1 数据和指令缓存大小

    # 构造需要处理的命令项目
    if [ "$ISSUE_WIDTH" != "-" ]; then
        CMD="$CMD --param=system.cpu[0].issueWidth=${ISSUE_WIDTH}"
    fi

    if [ "$L2_CACHE" != "None" ]; then
        CMD="$CMD --l2cache --l2_size=${L2_CACHE}"
    fi

    # 构造实验输出文件夹名称
    OUTPUT_FOLDERS="${OUTPUT_DIR}/$((i + 1))"

    # 到这里，CMD和输出目录除了要运行的EXE指令外，已经构造完成,可以通用用于5组实验

    for j in ${EXE_FILES[@]}; do
        # 构造实验输出文件夹名称
        OUTPUT_FOLDER="${OUTPUT_FOLDERS}/${j}"

        # 构造命令
        CMD="$CMD --cmd=${FILE_PATH}/${j}"

        # 执行命令
        echo "Running command: $CMD"
        $CMD

        # sleep 1
        # 将输出保存到文件夹
        mv m5out ${OUTPUT_FOLDER}

        # sleep 1
    done

done

```

分析如下：

1. 设置一些路径参数和必要的文件名和配置参数
2. 为之后的命令执行创建必须的文件夹
3. 模拟
   + 对每一种配置，除去运行文件名不同外，都相同，所以可以提前做好准备。在两个`For`循环之间实现
     + 对于一定有值的参数，直接将其复制进去，例如`cpu_type`
     + 对于特定的，使用`if`进行判断即可
   + 对于具体的可执行文件，增加文件名参数，执行命令，并将结果移动到指定文件夹
4. **attention**，本工程将`se.py`文件放置在`lab2/`下，需要修改`se.py`使其能够正常导入需要的库，同时执行目录是仓库的根目录，不是`lab2/`



到此，已经完成了脚本文件的配置



## 回答问题：

#### 1

仅能够使用`simSeconds`参数作为指标来比较不同系统配置之间的**整体性能**

原因：

1. 所有的CPU中，时钟频率不一样，所以使用时钟周期数，不能够正确反映系统的性能
2. 对于CPU常见的CPI，IPC等参数，不能够表现在真实的`benchmark`环境中的性能
3. 总结：
   + 对于相同的一个测试样例，能够评价测试的标准就是总体运行时间。
   + 对于多个测试样例，由于样例代码的特点，其实会导致不同CPU的性能体现不同。例如有大量非冲突的循环，或者多次跳转。所以，可以按照一定的权重加权，来比较CPU总体的性能。

下面是统计的数据。

对于测试样例`lfsr`，自高到低排序为：`4135672`

对于测试样例`merge`，自高到低排序为: `4156732`

…………

这里就已经体现了不同了

| 序号 | lfsr     | merge    | mm       | sieve    | spmv     |
| ---- | -------- | -------- | -------- | -------- | -------- |
| 1    | 0.010760 | 0.001782 | 0.003567 | 0.053452 | 0.029801 |
| 2    | 0.049915 | 0.004686 | 0.020427 | 0.055777 | 0.122008 |
| 3    | 0.010769 | 0.003087 | 0.007396 | 0.054155 | 0.029384 |
| 4    | 0.010532 | 0.000493 | 0.001493 | 0.050501 | 0.029684 |
| 5    | 0.015092 | 0.001820 | 0.003407 | 0.081543 | 0.026472 |
| 6    | 0.003950 | 0.001820 | 0.003407 | 0.025142 | 0.017853 |
| 7    | 0.003950 | 0.001820 | 0.003407 | 0.025142 | 0.013028 |

#### 2

1号是乱序8发射，2号是`MinorCPU`，3号是乱序2发射

从benchmark消耗的时间上来看，值得采用，因为1、3号性能都比2号优异

进一步，`lfsr`, `mm`, `spmv`性能超过很多，`merge`,`sieve`没有超过很多，主要差异在于测试样例的特性：

1. `lfsr`, `mm`, `spmv`都有大量可流水化操作和较少跳转的测试样例。这有利于乱序发挥性能。
2. `merge`,`sieve`则是计算密度低、跳转较多的测试样例，不利于乱序发挥流水的性能，性能提升有限。

#### 3

| 序号       | lfsr     | merge    | mm       | sieve    | spmv     |
| ---------- | -------- | -------- | -------- | -------- | -------- |
| 1（NONE）  | 0.010760 | 0.001782 | 0.003567 | 0.053452 | 0.029801 |
| 5 （256K） | 0.015092 | 0.001820 | 0.003407 | 0.081543 | 0.026472 |
| 6 （2M）   | 0.003950 | 0.001820 | 0.003407 | 0.025142 | 0.017853 |
| 7 （16M）  | 0.003950 | 0.001820 | 0.003407 | 0.025142 | 0.013028 |

总的来说分为两类

 `mm`,`spmv`，随着L2Cache的建立和容量变大，性能逐渐变好

`lfsr`,`merge`,`sieve`，对于256K的L2Cache，性能明显更差，2M和16M的L2Cache则对性能又较大的提升

观察benchmark特点：

1. `mm`,`spmv`涉及到调用矩阵的数据，空间局域性很好

2. `lfsr`,`merge`,`sieve`则又随机内存访问特性**或**内存跨度大的特性

3. 结合上面的分析关键差距在于，无较强`空间局域性`的benchmark，对内存访问的跨度大，而L2Cache**较小的情况下**，L2Cache替换频繁，而且L2Cache本身也有访问延迟，反而导致了性能的下降。

   在L2Cache变大的状况下，更替频繁而且存不下相邻数据的缺点被数量弥补，带来了性能提升



#### 4

Memory Regularity

指的是程序在内存访问模式上的一致性和可预测性。在访问内存时往往遵循一定的模式，比如按顺序访问数组元素、以固定步长访问数据等。这种规律性有助于硬件和编译器优化，例如预取数据、优化缓存行为等。（来自Web）

control regularity

指的是程序控制流的一致性和可预测性。具有高控制规律性的程序在执行时往往遵循固定的控制流路径，分支和跳转较少且可预测。这种规律性有助于分支预测和指令调度。对于流水线CPU，更高的分支预测准确率直接的影响了程序的性能（减少了冲刷流水线的次数）

例如for循环这样的大量的跳转指令

memory locality

分为内存访问的时间局域性和空间局域性。时间局域性指的是短时间内还会使用，空间局域性指的是临近空间的数据还会使用。

这两个的特点主要造成了更好的缓存利用率和更低的缓存缺失率，影响了Cache的性能的发挥。



#### 5

Memory Regularity

使用`system.mem_ctrls.avgGap`最能够体现。这个量展示了平均内存访问间隔的大小

按照定义，良好的`Memory Regularity`会表现出更好的内存访问的一致性和可预测性，而良好的可预测行带来更低的内存访问间隙

control regularity

使用`system.cpu.branchPred.condIncorrect`和`system.cpu.branchPred.condPredicted`最能够体现。这两个量的比例 展示了分支预测错误的比例。

良好的`control regularity`中，跳转指令应该是更加容易预测的，对应分支预测错误的比例小

memory locality

使用`system.cpu.dcache.demandHits::cpu.data  && system.cpu.dcache.demandAccesses::cpu.data`和 `system.cpu.icache.demandHits::cpu.inst  && system.cpu.dcache.demandAccesses::cpu.inst`体现。分别给出了icache和dcache的Hit比例

又良好时空局域性的benchmark中，miss几率应该更小



下面是为第6问组织的数据表格

 `system.mem_ctrls.avgGap`

| 序号 | lfsr      | merge      | mm        | sieve      | spmv      |
| ---- | --------- | ---------- | --------- | ---------- | --------- |
| 1    | 21826.38  | 785438.52  | 97854.27  | 34661.80   | 20590.72  |
| 2    | 101223.21 | 1968900.84 | 559469.05 | 36167.07   | 84284.13  |
| 3    | 21844.76  | 1370003.11 | 202907.85 | 35118.18   | 20300.73  |
| 4    | 21365.91  | 217505.74  | 41125.51  | 32748.26   | 20510.35  |
| 5    | 32203.61  | 961592.71  | 837000.49 | 56477.13   | 50391.70  |
| 6    | 116915.23 | 961592.71  | 848852.73 | 1524144.28 | 86072.99  |
| 7    | 117478.85 | 961592.71  | 848852.73 | 1524144.28 | 180891.96 |

$$\frac{system.cpu.branchPred.condIncorrect}{system.cpu.branchPred.condPredicted}$$



| Index | lfsr           | merge          | mm             | sieve          | spmv           |
| ----- | -------------- | -------------- | -------------- | -------------- | -------------- |
| 1     | 0.00166        | 0.07505        | 0.00406        | 0.000539       | 0.01504        |
| 2     | NaN (除数为零) | NaN (除数为零) | NaN (除数为零) | NaN (除数为零) | NaN (除数为零) |
| 3     | 0.00163        | 0.05353        | 0.00397        | 0.000529       | 0.01482        |
| 4     | 0.00167        | 0.07509        | 0.00406        | 0.000539       | 0.01502        |
| 5     | 0.00168        | 0.07503        | 0.00406        | 0.000539       | 0.01517        |
| 6     | 0.00168        | 0.07503        | 0.00406        | 0.000539       | 0.01513        |
| 7     | 0.00167        | 0.07503        | 0.00406        | 0.000539       | 0.01508        |



$$\frac{system.cpu.dcache.demandHits::cpu.data}{system.cpu.dcache.demandAccess::cpu.data}$$



| Index | lfsr    | merge   | mm      | sieve   | spmv    |
| :---- | :------ | :------ | :------ | :------ | :------ |
| 1     | 0.02539 | 0.99861 | 0.95541 | 0.64195 | 0.51352 |
| 2     | 0.50864 | 0.99587 | 0.98829 | 0.57876 | 0.78150 |
| 3     | 0.02425 | 0.99475 | 0.95364 | 0.64167 | 0.48152 |
| 4     | 0.02529 | 0.99764 | 0.94990 | 0.64200 | 0.48045 |
| 5     | 0.02539 | 0.99743 | 0.95066 | 0.64196 | 0.38761 |
| 6     | 0.02540 | 0.99743 | 0.95066 | 0.64202 | 0.31841 |
| 7     | 0.02539 | 0.99743 | 0.95066 | 0.64202 | 0.47942 |



#### 6

**Ifsr**

在于产生一个类似的随机数，其特点是变化大。然后访问这个随机数作为数组下标对应的内容

这样的设计下，有如下特点

1. Memory Regularity和memory locality差

   访问的地址变化大，且没有显式的规律，导致实际上测试了内存访问性能，特别是随机访问模式下的内存带宽和延迟

   表格3的命中率格外低可以体现

2. control regularity良好

   因为是For循环，循环`ITERS`，又`ITERS`次成功，1次失败

   表格2的Incorrect率很低可以体现



**merge**

归并算法的`benchmark`

这样的设计下，有如下特点

1. memory locality良好

   访问的数据都是数组的相邻部位，规律性好，局域性好

   表格3的极高的命中率可以说明

2. Memory Regularity差

   逻辑上，merge访问在归并和划分时达到最大，但是又大量函数栈和相应的判断和跳转操作，内存规律行不好

   表格1 值很大也能够说明

3. control regularity差

   同上，递归带来的函数栈和相应的跳转判断代价，是的控制不好判断

   表格2的值也反映了缺失了很高，7%，属于最大值

   

**mm**

矩阵乘法基准测试

三个特性都很好

固定的内存访问，三重For循环带来的控制性能好，相邻位置访问带来的空间局域性好

唯一的缺点是，按照行排列的数组在访问列时，带来了内存访问性能损失



**sieve**

找出小于或等于给定数 n 的所有素数。

1. control regularity良好

   因为是For循环

   表格2的Incorrect率最低可以体现

2. memory locality良好

   与之前两个数组不同的在于，对于素数，访问素数的倍数的位置的内存，例如对于7，访问7，14，21……7n

   内存跨度在大素数的倍数时很大，当素数超过cache line大小，等价于每次要重新访问(空间局域性极差)，但是素数太大，访问次数减少，形成展示出来的状况

3. Memory Regularity好

   如上分析，虽然空间局域性不是很好，但是访问很规律



**spmv**

稀疏矩阵-向量乘法的性能

1. Memory Regularity好

   访问很规律，而且由表1给出的结果很有说服力

2. memory locality较差

   稀疏矩阵，空间访问不连续，越稀疏，效果越差，50%的缺失率算中等。

3. control regularity较差

   同样是由于稀疏矩阵本身特性导致的

   相比之下，For循环跳转与不跳转的规律性和次数都远远不及矩阵乘法的优异



#### 7

我选择矩阵乘法`mm`

**微体系层面**，由表格3的数据，发现增加L2Cache的容量没有带来较大的性能提升。原因猜测在于，矩阵时按照**行**访问时，需要较大的L1Cache Line的长度。对于列访问，时间局域性极差，L2Cache无法承载大矩阵带来的内存访问缺失。

反而，增加L1Cache的大小可以有效增强。容纳更大的数组相邻元素，访问效率更高

**ISA层面**，

1. 对于矩阵乘，增加向量指令可以明显提高速率。增加乘加指令也可以提高速率。
2. 总的来说，由向量的乘加指令，速率会有较大提升。

**应用程序增强**

1. 合适的矩阵切割方法可以带来Cache访问的增强。
2. 将第二个矩阵换为列优先存储，能够极大带来性能提升。
3. 考虑使用循环展开来提高 Cache 利用率。