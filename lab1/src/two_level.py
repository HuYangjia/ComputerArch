# 导入m5模块和所有的对象
import m5
from m5.objects import *
from caches import *  # 这个是自己定义的文件


# # 将common文件夹添加到路径中
m5.util.addToPath('../gem5-stable/configs/')  # 调整路径以匹配实际位置
from common import SimpleOpts


# get ISA for the default binary to run. This is mostly for simple testing
isa = str(m5.defines.buildEnv['TARGET_ISA']).lower()

# Default to running 'hello', use the compiled ISA to find the binary
# grab the specific path to the binary
thispath = os.path.dirname(os.path.realpath(__file__))
default_binary = os.path.join(thispath, '../gem5-stable/',
    'tests/test-progs/hello/bin/', isa, 'linux/hello')
print(default_binary)

# Binary to execute
SimpleOpts.add_option("binary", nargs='?', default=default_binary)

# Finalize the arguments and grab the args so we can pass it on to our objects
args = SimpleOpts.parse_args()
system = System()

# 创建并且设置时钟域
system.clk_domain = SrcClockDomain()
system.clk_domain.clock = '1GHz'
# 创建电压域
system.clk_domain.voltage_domain = VoltageDomain()

# 创建内存，并且设置内存的大小
system.mem_mode = 'timing'
system.mem_ranges = [AddrRange('512MB')]

# 创建CPU
system.cpu = TimingSimpleCPU()

# 创建L1Cache
system.cpu.icache = L1ICache(args)
system.cpu.dcache = L1DCache(args)

# 用 helper 函数将缓存连接到 CPU 端口
system.cpu.icache.connectCPU(system.cpu)
system.cpu.dcache.connectCPU(system.cpu)


# 创建L2Cache相关总线和连接接口
system.l2bus = L2XBar()

system.cpu.icache.connectBus(system.l2bus)
system.cpu.dcache.connectBus(system.l2bus)

# 创建L2Cache并且连接到总线
system.l2cache = L2Cache(args)
system.l2cache.connectCPUSideBus(system.l2bus)
system.membus = SystemXBar()
system.l2cache.connectMemSideBus(system.membus)

# 将 PIO 和中断端口连接到内存总线
system.cpu.createInterruptController()
system.cpu.interrupts[0].pio = system.membus.mem_side_ports
system.cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
system.cpu.interrupts[0].int_responder = system.membus.mem_side_ports

system.system_port = system.membus.cpu_side_ports

# 创建一个内存控制器并将其连接到 membus 的这个系统
system.mem_ctrl = MemCtrl()
system.mem_ctrl.dram = DDR3_1600_8x8()
system.mem_ctrl.dram.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports

# 创建进程并且syscall仿真

# for gem5 V21 and beyond
system.workload = SEWorkload.init_compatible(args.binary)

process = Process()
process.cmd = [args.binary]
system.cpu.workload = process
system.cpu.createThreads()

root = Root(full_system = False, system = system)
m5.instantiate()


print("Beginning simulation!")
exit_event = m5.simulate()

print('Exiting @ tick {} because {}'
      .format(m5.curTick(), exit_event.getCause()))