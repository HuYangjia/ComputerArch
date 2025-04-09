AttributeError: Class System has no parameter issue_width

AttributeError: Not allowed to set issue_width on 'SimObjectVector'

AttributeError: Class AtomicSimpleCPU has no parameter issue_width

fatal: DerivO3CPU must be used with caches

AttributeError: Class O3CPU has no parameter issue_width

因为将文件放置在了lab2下，所有增加se.py路径

chmod +x ./run.sh 

遇见问题：stats.txt文件中没有数据

复现，报错为：`build/X86/sim/syscall_desc.hh:209: fatal: Syscall 334 out of range`

`https://askubuntu.com/questions/1427882/syscall-issues-compiling-x86-c-code-for-gem5-using-ubuntu-22-04`可能的处理方案

解决了334的错误，还有318的

`build/X86/sim/syscall_desc.hh:209: fatal: Syscall 318 out of range`

Ifsr.c: 测试的是内存访问性能，特别是随机访问模式下的内存带宽和延迟
merge.c: 归并排序（Merge Sort）算法的性能。
mm.c: 矩阵乘法基准测试
sieve.c: 找出小于或等于给定数 n 的所有素数。
spmv.c: 测试稀疏矩阵-向量乘法（Sparse Matrix-Vector Multiplication，简称SPMV）的性能。