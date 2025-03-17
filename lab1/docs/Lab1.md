# Lab1 实验报告

**PB22111665 胡揚嘉**

> 实验代码在lab1/src文件夹中


## 1. 配置实验环境，编译gem5

### 实验步骤

1. 解压缩gem5源码包
2. 按照教程推荐，安装依赖

   ```shell
   sudo apt install build-essential git m4 scons zlib1g zlib1g-dev libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev python-dev python
   ```

   实际上，这里面的`python, python-dev`不需要再次安装，报错，但是不影响进程

   ```
   E: Package 'python-dev' has no installation candidate
   E: Package 'python' has no installation candidate
   ```
3. 编译，查看发现自己有16个核

   ```shell
   scons build/X86/gem5.opt -j15 CPU_MODELS=AtomicSimpleCPU,TimingSimpleCPU,O3CPU,MinorCPU
   ```

### 成功编译gem5截图

![](./compile_done.png)



## 脚本文件编写和测试

### 结果

`simple.py`的结果

![](./simple_re.png)

`two_level.py`的结果

![](./two_level_done.png)

### 收获与反思

在编写`two_level`时，一直报错，显示`NameError: name 'SimpleOpts' is not defined`.

但是不会看报错栈回显，一直默认是`two_level.py`报错，反复修改地址导入无法解决

最后注意到是在`caches.py`内报错，发现对需要参数的情况，使用了`SimpleOpts`文件的内容，但是没有导入（文档未明确提到）

最后得以解决。
