
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

