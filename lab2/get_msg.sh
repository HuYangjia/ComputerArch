#!/bin/bash

# 进入根目录，所有操作都在这里进行
cd /home/yangjia/Coding/comparch25spring-gem5

# 确定路径相关参数
OUTPUT_DIR="/home/yangjia/Coding/comparch25spring-gem5/lab2/output"


# 定义二进制文件数组,每个配置，需要运行5次实验，对应如下
EXE_FILES=(
    "lfsr"
    "merge"
    "mm"
    "sieve"
    "spmv"
)

name=$1
FILE="${OUTPUT_DIR}/${name}.txt"

echo -n > ${FILE}
# 遍历每个二进制文件和实验配置
for i in ${EXE_FILES[@]}; do
    for j in {1..7}; do
        NAME="${OUTPUT_DIR}/${j}/${i}/stats.txt"
        echo -n "${j}:${i}= " >> ${FILE}
        grep ${name} ${NAME} | sed -r "s/.*${name}\s+([0-9\.]+).*/\1/" >> ${FILE}
    done
done
