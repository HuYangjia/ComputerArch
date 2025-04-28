CompArch-H

2025年春季学期中科大计算机体系结构H，仅供参考

## 如何组织代码

已知，助教给的代码在git.ustc.edu.cn上，但是我想要在github上管理代码，那么我应该怎么做呢？

1. 首先，你需要在github上创建一个新的仓库
2. 将助教的代码地址设置为远程仓库的地址，这样你就可以在本地的仓库中fetch助教的代码了。
   1. `git remote add upstream`
   2. `git fetch upstream`
   3. `git merge upstream/master`
   4. 查看远程仓库的命令：`git remote -v`
3. 效果：
   我是直接将助教的代码clone到本地，然后将其push到github上的，所以我的工作分支的名字是`Yangjia`
   ```shell
   $ git remote -v
   Yangjia git@github.com:HuYangjia/ComputerArch.git (fetch)
   Yangjia git@github.com:HuYangjia/ComputerArch.git (push)
   origin  https://git.ustc.edu.cn/YiranXu/comparch25spring-gem5.git (fetch)
   origin  https://git.ustc.edu.cn/YiranXu/comparch25spring-gem5.git (push)
   ```
   
   > 通常，origin是默认的远程仓库名称，指的是克隆的原始仓库。
   >
   > 可以如下解决问题：
   >
   > 1. **添加GitHub仓库为远程仓库**：
   >    - `git remote add origin git@github.xxx`
   > 2. **添加助教的仓库为上游仓库**：
   >    - `git remote add upstream xxxx`
   > 3. **同步上游仓库的代码**：
   >    - `git fetch upstream`
   >    - `git merge upstream/master`



## 往年参考

> 感谢前辈的贡献

https://github.com/0auv0/CompArch-H-/

https://github.com/xjh389336645/calab-gem5/