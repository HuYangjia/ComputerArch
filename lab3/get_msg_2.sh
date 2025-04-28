#!/bin/bash

# 进入根目录，所有操作都在这里进行
cd /home/yangjia/Coding/comparch25spring-gem5

# 确定路径相关参数
OUTPUT_DIR="/home/yangjia/Coding/comparch25spring-gem5/lab3/result2"


# 定义二进制文件数组,每个配置，需要运行5次实验，对应如下
EXE_FILES1=(
    "RandomRP"
)
EXE_FILES2=(
    "LIPRP"
    "NMRURP"
)
ASSOC1=(
    "ASSOC_4"
    "ASSOC_8"
    "ASSOC_16"
)
ASSOC2=(
    "ASSOC_4"
    "ASSOC_8"
)

name=$1
FILE="${OUTPUT_DIR}/${name}.txt"

echo -n > ${FILE}
# 遍历每个二进制文件和实验配置
for i in ${EXE_FILES2[@]}; do
    for j in ${ASSOC2[@]}; do
        NAME="${OUTPUT_DIR}/${i}/${j}/stats.txt"
        echo -n "${j}:${i}= " >> ${FILE}
        grep ${name} ${NAME} | sed -r "s/.*${name}\s+([0-9\.]+).*/\1/" >> ${FILE}
    done
done
# 遍历每个二进制文件和实验配置
for i in ${EXE_FILES1[@]}; do
    for j in ${ASSOC1[@]}; do
        NAME="${OUTPUT_DIR}/${i}/${j}/stats.txt"
        echo -n "${j}:${i}= " >> ${FILE}
        grep ${name} ${NAME} | sed -r "s/.*${name}\s+([0-9\.]+).*/\1/" >> ${FILE}
    done
done


