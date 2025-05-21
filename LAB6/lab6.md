# 实验问题（以这里为准）

1. 请问原始flash attention 算法中能否将内层循环改为对K矩阵操作？请说明你变动后算法Q、K、V、O矩阵的搬运过程及这样做的好处与坏处（提示：考虑softmax）
2. 原始flash attention算法中Q、K、V、O小块大小能如(Br,d/2)这样吗？请分析可能遇到的问题。
3. Single head Flash attention启动N个线程相比原始flash attention 算法对矩阵分块的复用有什么影响？请详细分析。
4. 你实现的Single head Flash attention运行速度比利用传统矩阵乘法实现的Single head Flash attention慢。请分析原因并给出改进方案及方案面临的困难。
