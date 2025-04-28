GEM5=/home/yangjia/Coding/comparch25spring-gem5/gem5-stable/build/X86/gem5.debug
SRC=/home/yangjia/Coding/comparch25spring-gem5/lab3/demo
RESULT_DIR=/home/yangjia/Coding/comparch25spring-gem5/lab3/result3
TARGET=/home/yangjia/Coding/comparch25spring-gem5/lab3/se.py

rm -rf ${RESULT_DIR}/*



CMD="${GEM5} --debug-flags=Cache,CacheRepl  ${TARGET} --cmd=${SRC} --cpu-type=O3CPU --num-cpus=4 \
    --l1d_size=1kB --l1i_size=1kB --l1d_repl=LRURP --l1d_assoc=1 --l1i_assoc=4 --caches \
    --l2_size=128kB --l2cache --l2_assoc=4 --l2_repl=LRURP \
    --sys-clock=2GHz --cpu-clock=2GHz --mem-type=DDR3_1600_8x8 \
    --param=system.cpu[0].issueWidth=8 
    \
    "
# sleep 1
${CMD} > cache_trace.txt
cp -r m5out/ ${RESULT_DIR}/
