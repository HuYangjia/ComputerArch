# 体系结构Lab3

**PB22111665 胡揚嘉**

## 实现NMRU与配置修改

1. 在`src/mem/cache/replacement_policies/`路径下，实现`nmru_rp.cc`和`nmru_rp.hh`

   `nmru_rp.cc`：

   ```c++
   ReplaceableEntry*
   NMRU::getVictim(const ReplacementCandidates& candidates) const
   {
       assert(candidates.size() > 0);
   
       // 找到最近使用的，在之后确保其不会被选中
       ReplaceableEntry* last = candidates[0];
       for (const auto& candidate : candidates) {
           // Update victim entry if necessary
           if (std::static_pointer_cast<NMRUReplData>(
                       candidate->replacementData)->lastTouchTick >
                   std::static_pointer_cast<NMRUReplData>(
                       last->replacementData)->lastTouchTick) {
               last = candidate;
           }
       }
       ReplaceableEntry *victim = candidates[0];
   	
    	// 随机，找到一个替换对象。若发现是上面的最近使用的，重新找一个新的   
       if(candidates.size() > 1){
           int victimIndex;
           std::random_device rd;  // 用于获取种子
           std::mt19937 gen(rd()); // 使用Mersenne Twister算法生成随机数
           std::uniform_int_distribution<> dis(0, candidates.size()-1); // 定义分布范围
           do{
               victimIndex = dis(gen); 
           }while(candidates[victimIndex] == last);
           victim = candidates[victimIndex];
       }
   	
       // 未满，直接选取其位置填充，一定满足所有性质
       for (const auto& candidate : candidates) {
           if (std::static_pointer_cast<NMRUReplData>(
           candidate->replacementData)->lastTouchTick == Tick(0)) {
               victim = candidate;
               break;
           }
       }
   
       return victim;
   }
   ```

   `nmru_rp.hh`除去变量名几乎没有改变，略过

2. 同文档，在python中使用`c++`类

   ```python
   class NMRURP(BaseReplacementPolicy):
       type = 'NMRURP'
       cxx_class = 'gem5::replacement_policy::NMRU'
       cxx_header = "mem/cache/replacement_policies/nmru_rp.hh"
   ```

3. 同文档，注册。

   ```python
   Import('*')
   
   SimObject('ReplacementPolicies.py', sim_objects=[
       'BaseReplacementPolicy', 'DuelingRP', 'FIFORP', 'SecondChanceRP',
       'LFURP', 'LRURP', 'BIPRP', 'MRURP', 'RandomRP', 'BRRIPRP', 'SHiPRP',
       'SHiPMemRP', 'SHiPPCRP', 'TreePLRURP', 'WeightedLRURP', 'NMRURP'])
   
   Source('bip_rp.cc')
   Source('brrip_rp.cc')
   Source('dueling_rp.cc')
   Source('fifo_rp.cc')
   Source('lfu_rp.cc')
   Source('lru_rp.cc')
   Source('mru_rp.cc')
   Source('random_rp.cc')
   Source('second_chance_rp.cc')
   Source('ship_rp.cc')
   Source('tree_plru_rp.cc')
   Source('weighted_lru_rp.cc')
   Source('nmru_rp.cc')
   ```

   不同的是，发现不在`SimObject`中追加`'NMRURP'`，会导致编译报错，增加即可解决问题

   报错如下所示：

    ```
    build/X86/mem/cache/replacement_policies/nmru_rp.cc:35:10: fatal error: params/NMRURP.hh: No such file or directory
    
      35 | #include "params/NMRURP.hh"
    
       |      ^~~~~~~~~~~~~~~~~~
    
      compilation terminated.
    
      [SO Param] m5.objects.Prefetcher, AccessMapPatternMatching -> X86/params/AccessMapPatternMatching.hh
    
      scons: *** [build/X86/mem/cache/replacement_policies/nmru_rp.do] Error 1
    
      scons: building terminated because of errors.
    ```

4. 增加命令行可选参数：

   在`config/common`目录下，作以下操作。在`ObjectList.py`中加入

   ```
   repl_list = ObjectList(getattr(m5.objects, 'BaseReplacementPolicy', None))
   ```

   在`Options.py`中加入

   ```
   	parser.add_argument("--l1d_repl", action='store', type=str, default="LRURP",
                         choices=ObjectList.repl_list.get_names(),
                         help = "replacement policy for l1")
       parser.add_argument("--l2_repl", action='store', type=str, default="LRURP",
                         choices=ObjectList.repl_list.get_names(),
                         help = "replacement policy for l2")
   ```

   在`CacheConfig.py`中对`system.l2`和`dcache`的实例化过程进行修改，如下所示

   ```
   system.l2 = l2_cache_class(clk_domain=system.cpu_clk_domain,
                              size=options.l2_size,
                              assoc=options.l2_assoc,
                              replacement_policy=ObjectList.repl_list.get(options.l2_repl)())
   ```

   ```
   dcache = dcache_class(size=options.l1d_size,
                         assoc=options.l1d_assoc,
                         replacement_policy=ObjectList.repl_list.get(options.l1d_repl)())
   ```

## 模拟结果及分析

### Q1

脚本见代码文件

下面是表一`simTicks`的结果

| 替换策略 | ASSOC_4    | ASSOC_8    | ASSOC_16   |
| :------- | :--------- | :--------- | :--------- |
| LIPRP    | 1725086000 | 1725086500 | 1725109500 |
| NMRURP   | 1725635500 | 1725081000 | 1725082000 |
| RandomRP | 1725081000 | 1725088500 | 1725085000 |

> 1. 为什么不用`simSeconds`的结果：
>
>    因为实验发现，其保留六位小数，而且正好，所有配置的结果都是0.001749(四舍五入后)
>
>    这样没有办法进行比较
>
>    发现，其差别较小，`simSeconds`都在6位之后，使用`simTicks`能够得到好的比较效果
>
> 2. 为什么可以使用`simTicks`进行比较
>
>    因为所有CPU的时钟频率是相同的，时钟数和时间可以等价转化。

分析：

1. 最佳性能

   对于 `LIPRP` 策略，最佳是 `ASSOC_4`

   对于 `NMRURP` 策略，最佳的是 `ASSOC_8`

   对于 `RandomRP` 策略，最佳的是 `ASSOC_4`

   对于 `ASSOC_4` ，最佳的是 RandomRP

   对于 `ASSOC_8` ，最佳的是  NMRURP

   对于 `ASSOC_16` ，最佳的是 NMRURP

   对于全局，最佳的配置是 NMRURP + ASSOC_8的配置(恰好，这次模拟中，RandomRP + ASSOC_4的效果一样，但是多次实验中，前者更好 )

2. 分析：

   + 对于`RandomRP` 策略，根据数据，随着相连度的增大，其耗时先增大后减小

     说明，对于Random策略而言，随机剔除，相连度的增大，Miss率更大，更多有用的Cache line被替换出去了。

     解释：容量不变，相连度增大，Cache line的行数更少，所以一行内需要存储的memory的index范围更广。而假如有一个循环，本来被储存在两个Cache line(低相连度)，这样，可以复用的Cache line不需要进行替换（新的内容在其他的Cache line替换），导致Miss率降低。而如果内容集中在一个或少数几个Cacheline(高相连度)，随机替换导致之前的内容被替换，Miss率升高(4-8)

     当相连度进一步增加，数据的访问模式可能变得非常随机，这时`RandomRP`策略的随机特性反而成为优势。(8-16)(实际上，在某些次实验中，发现耗时是一直增大的，猜测上面的原因往往是主要原因)

   + 对于`LIPRP` 策略，随着相连度的增大，其耗时增大

     解释：BIP是LRU引入了概率性的MRU插入实现的，LIP也可以被视为BIP的一种特殊情况([来源]((https://blog.csdn.net/zhenz0729/article/details/136130725)))

     所以这里的影响因素还是来源于 **LRU**的思想

     因为LIP的替换策略基于LRU替换策略的基本原则，但在插入新块时将新块被插入到最近最少使用的位置，当新块被重复访问时，它们将逐渐向MRU位置移动，直到它们成为最近访问的块。**但是**，当一个新的块被加入进来之后，如果没有进行再次的访问，那么很有可能在下次就被替换掉了。这样在组相联的程度提升之后，可能同一个块的访问并没有那么频繁，也就是一个新块插入之后可能只访问了一次后面就访问别的地方了，在缓存发生替换时，未来可能还要访问的块就被替换掉了。所以随着相连度增大，耗时增大

   + 对于`NMRURP` 策略，随着相连度的增大，其耗时先减小，后增大

     而对于`NMRURP` 策略，其保证最近使用的块不被替换，其余块随机替换

     解释：相连度从8到16增大的原因同上，来源于Cacheline的减少，导致了冲突的增加

     减小的原因，是因为模仿LRU的思想，保留了最近使用的块，但是当相连度太小，**较新**的块也被替换，导致访存Miss率处于高位。而相连度稍微的增大，减缓了这个问题的影响。

     整体而言，NMRURP策略结合了随机访问和LRU是思想，在`mm`的benchmark中最容易取得较好的效果。



### Q2



`2.2GHz`的情况下：每个周期的长度 ≈ 454.545454… ps per 时钟周期

将`lookup time`转换为时钟周期，分别为(100ps, 500ps, 555ps) / (454.545454… ps per 时钟周期) = (0.220, 1.100, 1.222) cycles

向上取整(1, 2, 2) cycles

1. Random，修改 `tag latency = 1`，对 `assoc` 为4， 8， 16的情况进行实验模拟.脚本见代码文件`run_2_1.sh`
2. NMRU ，LIP,修改 `tag latency = 2`，对 `assoc` 为4， 8的情况进行实验模拟.脚本见代码文件`run_2_2.sh`



结果如下表格所示，也是将 `simTicks`作为参考数据



| ASSOC    | LIPRP      | NMRURP     | RandomRP   |
| -------- | ---------- | ---------- | ---------- |
| ASSOC_4  | 1581748350 | 1581744255 | 1579256770 |
| ASSOC_8  | 1581748805 | 1581748350 | 1579158490 |
| ASSOC_16 | NONE       | NONE       | 1579244030 |

分析

1. 在所有的ASSOC配置中，`RandomRP`策略都为最好

   在`RandomRP`策略下，ASSOC_8配置最好

2. 在该实验中，tag_latency带来的影响占据了**主导地位**

   由于RandomRP使用了更小的tag_latancy(近乎是其他两种策略的1/5，即使转换为tag_latentcy也有两倍的差距)，其总体性能更优。

   对于相联度而言，更大的相联度可以减少cache的miss rate，但可能会增大每次查询所需要的时间。从上面的结果中我们可以看到，assoc.=8是比较合理的更大相联度。



## MOESI行为分析

>  24个任务状态，总共找到了12个，只有一半:cry:

脚本命令如下：

```
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

```

> 希望在下一届能够避免的问题：
>
> 1. 直接的给出一些要求的实现细则
>    + ${GEM5} --debug-flags=Cache,CacheRepl，这个`--debug-flags`需要在最开头给出，而非在其他地方插入，这个bug困扰了很久
>    + --debug-flags=的参数需要`Cache,CacheRepl`，第一次只开了`Cache`导致找了好久，只能够找到1个的状态，后来经过提醒得以解决，我认为这个不应该成为阻碍。



1. 读命中

   ```
    326500: system.cpu0.icache: access for ReadReq [6e80:6ebf] IF hit state: 4 (S) writable: 0 readable: 1 dirty: 0 prefetched: 0 | tag: 0x6e secure: 0 valid: 1 | set: 0x2 way: 0
   ```

   一段icache的指令访问，缓存块的状态都是(S)。表示直接在icache中访问到需要的数据，然后取用

   直接读取，状态无需改变

2. 读缺失(I)

   ```
      1000: system.cpu0.icache: access for ReadReq [6100:613f] IF miss
      1000: system.cpu0.icache: handleTimingReqMiss coalescing MSHR for ReadReq [6100:613f] IF
      2500: system.l2: sendMSHRQueuePacket: MSHR ReadCleanReq [6100:613f] IF
      2500: system.l2: createMissPacket: created ReadSharedReq [6100:613f] IF from ReadCleanReq [6100:613f] IF
     71500: system.l2: recvTimingResp: Handling response ReadResp [6100:613f] IF
     71500: system.l2: Block for addr 0x6100 being updated in Cache
     71500: system.l2: Replacement victim: state: 0 (I) writable: 0 readable: 0 dirty: 0 prefetched: 0 | tag: 0xffffffffffffffff secure: 0 valid: 0 | set: 0x184 way: 0
     71500: system.l2: Block addr 0x6100 (ns) moving from  to state: 6 (E) writable: 1 readable: 1 dirty: 0 prefetched: 0 | tag: 0 secure: 0 valid: 1 | set: 0x184 way: 0
   ```

   这段内容，概括：cpu尝试从icache取值，miss。icache尝试在l2cache访问，也miss。

   然后l2cache **sendMSHRQueuePacket: MSHR ReadCleanReq** ，向总线发送请求包

   向总线发送读共享请求，根据总线的信号提示，转变为E。原始块的状态是I

3. 读缺失(S)

   ```
   297633000: system.cpu0.dcache: recvTimingResp: Handling response ReadExResp [ac9c0:ac9ff]
   297633000: system.cpu0.dcache: Block for addr 0xac9c0 being updated in Cache
   297633000: system.cpu0.dcache: Replacement victim: state: 4 (S) writable: 0 readable: 1 dirty: 0 prefetched: 0 | tag: 0xf0 secure: 0 valid: 1 | set: 0x7 way: 0
   297633000: system.cpu0.dcache: Create CleanEvict CleanEvict [3c1c0:3c1ff]
   297633000: system.cpu0.dcache: Block addr 0xac9c0 (ns) moving from  to state: 6 (E) writable: 1 readable: 1 dirty: 0 prefetched: 0 | tag: 0x2b2 secure: 0 valid: 1 | set: 0x7 way: 0
   ```

   

   向总线提交读共享请求，向总线报告替换块为干净块不用更新，替换进来的块根据总线响应信号转为(E)

4. 读缺失(O)

   向总线提交读共享请求，提交写回请求

5. 读缺失(M)

   向总线提交读共享请求，提交写回请求

6. 读缺失(E)

   向总线提交读共享请求，并且不需要写回，替换后，状态转变为E或者S

7. 写命中(E)

   ```
   363875500: system.cpu0.dcache: access for WriteReq [43ca8:43caf] hit state: 6 (E) writable: 1 readable: 1 dirty: 0 prefetched: 0 | tag: 0x10f secure: 0 valid: 1 | set: 0x2 way: 0
   ```

   写入内容，之后应该变成M`(Modified)`

8. 写命中(S)

   ```
   340511000: system.cpu3.dcache: access for WriteReq [3c2c8:3c2cb] hit state: 4 (S) writable: 0 readable: 1 dirty: 0 prefetched: 0 | tag: 0xf0 secure: 0 valid: 1 | set: 0xb way: 0
   ```

   向总线发出upgrade广播，是的不同的缓存中，持有本相同缓存块的缓存失效，然后根据总线信号，将其替换状态为E或者O

9. 写命中(O)

   ```
   340056500: system.cpu3.dcache: access for WriteReq [4024:4027] hit state: c (O) writable: 0 readable: 1 dirty: 1 prefetched: 0 | tag: 0x10 secure: 0 valid: 1 | set: 0 way: 0
   ```

   向总线发出upgrade广播，是的不同的缓存中，持有本相同缓存块的缓存失效。但是本身状态不变

10. 写命中(M)

    ```
     222000: system.cpu0.dcache: access for WriteReq [34dd8:34ddf] hit state: e (M) writable: 1 readable: 1 dirty: 1 prefetched: 0 | tag: 0xd3 secure: 0 valid: 1 | set: 0x7 way: 0
    ```

    这段内容，对于原始M状态的缓存块，写请求而且命中，直接写入，状态也仍然保持为M

11. 写缺失(I)

    ```
    88500: system.cpu0.dcache: access for WriteReq [34e08:34e0f] miss
      89500: system.cpu0.dcache: sendMSHRQueuePacket: MSHR WriteReq [34e08:34e0f]
      89500: system.cpu0.dcache: createMissPacket: created ReadExReq [34e00:34e3f] from WriteReq [34e08:34e0f]
      89500: system.l2: access for ReadExReq [34e00:34e3f] miss
      91000: system.l2: sendMSHRQueuePacket: MSHR ReadExReq [34e00:34e3f]
      91000: system.l2: createMissPacket: created ReadExReq [34e00:34e3f] from ReadExReq [34e00:34e3f]
    ```

    同样的，dcache和L2cache里面都没有副本，属于I状态，写请求访问失效。

    先向总线创建独占请求，在将替换块的状态改为E，然后进行写命中的操作

12. 写缺失(S)

    先向总线创建独占请求，在将替换块的状态改为E

13. 写缺失(O)

    先向总线创建独占请求，在将替换块的状态改为E

14. 写缺失(M)

    ```
     310000: system.cpu0.dcache: sendMSHRQueuePacket: MSHR WriteReq [329f8:329ff]
     310000: system.cpu0.dcache: createMissPacket: created ReadExReq [329c0:329ff] from WriteReq [329f8:329ff]
    
    ```

    先发送写回请求，在发送读取请求

15. 写缺失(E)

​	先向总线创建独占请求，在将替换块的状态改为E





总线相关的

1. 读缺失(S)

   总线接收其它缓存的读缺失请求，状态不变，将数据共享

2. 读缺失(O)

   从总线收到其他缓存的读缺失请求，状态不变，将数据共享

3. 读缺失(M)

   从总线收到其他缓存的读缺失请求，但是状态应该从M转变为O。然后类似`读缺失O`，将数据共享

4. 读缺失(E)

   ```
      2500: system.l2: sendMSHRQueuePacket: MSHR ReadCleanReq [6100:613f] IF
      2500: system.l2: createMissPacket: created ReadSharedReq [6100:613f] IF from ReadCleanReq [6100:613f] IF
     71500: system.l2: recvTimingResp: Handling response ReadResp [6100:613f] IF
     71500: system.l2: Block for addr 0x6100 being updated in Cache
     71500: system.l2: Block addr 0x6100 (ns) moving from  to state: 6 (E) writable: 1 readable: 1 dirty: 0 prefetched: 0 | tag: 0 secure: 0 valid: 1 | set: 0x184 way: 0
   
   ```

   从总线收到其他缓存的读缺失请求，但是状态应该从E转变为S。然后将数据共享

5. 无效

   收到总线的upgrade信号，将状态转为无效

6. 写缺失(S)

   收到总线的独占请求，将数据交还，状态转为I

7. 写缺失(M)

   收到总线的独占请求，将数据交还，状态转为I

8. 写缺失(O)

   收到总线的独占请求，将数据交还，状态转为I

9. 写缺失(E)

   收到总线的独占请求，将数据交还，状态转为I