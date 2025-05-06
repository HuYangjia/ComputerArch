#!/bin/bash

# 进入根目录，所有操作都在这里进行
cd /home/yangjia/Coding/comparch25spring-gem5/lab4

# 确定路径相关参数
OUTPUT_DIR="/home/yangjia/Coding/comparch25spring-gem5/lab4/result"


# 检查3个实验配置的结果
FILE_NAMES=(
    "normal"
    "hpi_change"
    "hpi_plus_O3"
)

name=$1
FILE="${OUTPUT_DIR}/${name}.txt"

echo -n > ${FILE}

for i in ${FILE_NAMES[@]}; do
    NAME="${OUTPUT_DIR}/${i}/stats.txt"
    echo "$i" >> ${FILE}
    grep ${name} ${NAME} | sed '1d;$d' | sed -r "s/.*${name}\s+([0-9\.]+).*/\1/" >> ${FILE}
    echo "" >> ${FILE}
done


# 遍历每个二进制文件和实验配置
for i in ${EXE_FILES[@]}; do
    for j in ${ASSOC[@]}; do
        NAME="${OUTPUT_DIR}/${i}/${j}/stats.txt"
        echo -n "${j}:${i}= " >> ${FILE}
        grep ${name} ${NAME} | sed -r "s/.*${name}\s+([0-9\.]+).*/\1/" >> ${FILE}
    done
done
