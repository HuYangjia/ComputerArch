#!/bin/bash

# 进入根目录，所有操作都在这里进行
cd /home/yangjia/Coding/comparch25spring-gem5

# 确定路径相关参数
FILE_PATH="/home/yangjia/Coding/comparch25spring-gem5/lab2/lab2-benchmark"
OUTPUT_DIR="/home/yangjia/Coding/comparch25spring-gem5/lab2/output"


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
