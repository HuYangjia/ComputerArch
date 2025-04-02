#!/bin/bash
# filepath: /home/xyang/arch/lab2/evalute.sh

# 进入 gem5 所在目录
cd /home/huyangjia/Coding/CS_Arch/comparch25spring-gem5/gem5-stable

# 定义二进制文件路径
BINARY_PATH="/home/huyangjia/Coding/CS_Arch/comparch25spring-gem5/lab2/lab2-benchmark/"  # 替换为实际的二进制文件路径
OUTPUT_DIR="/home/huyangjia/Coding/CS_Arch/comparch25spring-gem5/lab2/output"        # 输出结果存放目录

# 创建输出目录
mkdir -p $OUTPUT_DIR

for i in {1..7}; do
    mkdir -p "${OUTPUT_DIR}/${i}"
done

# 定义二进制文件列表
BINARIES=("lfsr" "merge" "mm" "sieve" "spmv")

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
for BINARY in "${BINARIES[@]}"; do
    for i in "${!CONFIGS[@]}"; do
        CONFIG=(${CONFIGS[i]})  # 将配置字符串分割为数组
        CPU_TYPE=${CONFIG[0]}
        ISSUE_WIDTH=${CONFIG[1]}
        CPU_CLOCK=${CONFIG[2]}
        L2_CACHE=${CONFIG[3]}

        # 构造实验输出文件夹名称
        OUTPUT_FOLDER="${OUTPUT_DIR}/$((i + 1))/${BINARY}"

        # 构造命令
        CMD="build/X86/gem5.opt configs/example/se.py \
            --cpu-type=${CPU_TYPE} \
            --cpu-clock=${CPU_CLOCK} \
            --cmd=${BINARY_PATH}/${BINARY} \
            --options=\"\" \
            --caches \
            --l1d_size=64kB \
            --l1i_size=64kB"  # 默认启用 L1 Cache，并设置 L1 数据和指令缓存大小

        # 如果有 Issue Width 参数，则添加到命令中
        if [ "$ISSUE_WIDTH" != "-" ]; then
            CMD="$CMD --param=system.cpu[0].issueWidth=${ISSUE_WIDTH}"
        fi

        # 如果有 L2 Cache，则添加相关参数
        if [ "$L2_CACHE" != "None" ]; then
            CMD="$CMD --l2cache --l2_size=${L2_CACHE}"
        fi

        # 打印当前实验信息
        echo "Running experiment: ${BINARY}-$((i + 1))"
        echo "Command: $CMD"

        # 运行实验并将输出保存到文件夹
        eval $CMD
        mv m5out $OUTPUT_FOLDER

    done
done

echo "All experiments completed. Results are saved in $OUTPUT_DIR."