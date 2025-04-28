GEM5=/home/yangjia/Coding/comparch25spring-gem5/gem5-stable/build/X86/gem5.opt
SRC=/home/yangjia/Coding/comparch25spring-gem5/lab2/lab2-benchmark/mm
RESULT_DIR=/home/yangjia/Coding/comparch25spring-gem5/lab3/result2
TARGET=/home/yangjia/Coding/comparch25spring-gem5/lab3/se.py

# rm -rf ${RESULT_DIR}/*

for REPL in NMRURP LIPRP; do
    mkdir -p ${RESULT_DIR}/${REPL}
done

# cd $GEM5

for REPL in NMRURP LIPRP; do
    for ASSOC in 4 8;do
        CMD="${GEM5} ${TARGET} --cmd=${SRC} --cpu-type=DerivO3CPU \
            --l1d_size=64kB --l1i_size=64kB --l1d_repl=${REPL} --l1d_assoc=${ASSOC} --caches \
            --l2_size=2MB --l2cache --l2_repl=${REPL} \
            --sys-clock=2.2GHz --cpu-clock=2.2GHz --mem-type=DDR3_1600_8x8\
            --param=system.cpu[0].issueWidth=8
            "
        # sleep 1
        ${CMD}
        cp -r m5out/ ${RESULT_DIR}/${REPL}/ASSOC_${ASSOC}/
    done
done