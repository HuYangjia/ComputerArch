# import os
# import sys

# # 进入根目录，所有操作都在这里进行
# os.chdir("/home/yangjia/Coding/comparch25spring-gem5")

# # 确定路径相关参数
# OUTPUTDIR = "/home/yangjia/Coding/comparch25spring-gem5/lab2/output"

# # 定义二进制文件数组,每个配置，需要运行5次实验，对应如下
# EXEFILES = [
#     "lfsr",
#     "merge",
#     "mm",
#     "sieve",
#     "spmv"
# ]

# def read_line(file_path, line_number):
#     with open(file_path, 'r') as file:
#         lines = file.readlines()
#         if line_number <= len(lines):
#             return lines[line_number - 1].strip()
#     return None

# def main(name1, name2, name3):
#     filepath = os.path.join(OUTPUTDIR, name3)

#     # 清空文件内容
#     with open(filepath, 'w') as file:
#         pass

#     # 遍历每个二进制文件和实验配置
#     k = 0
#     for i in EXEFILES:
#         for j in range(1, 8):
#             file1 = os.path.join(OUTPUTDIR, name1)
#             file2 = os.path.join(OUTPUTDIR, name2)

#             k += 1   
#             data1 = read_line(file1, k)
#             data2 = read_line(file2, k)
            
#             print(data1)
#             print(data2)
#             # 尝试进行除法运算
#             try:
#                 result = float(data1) / float(data2)
#                 output_data = f"{result}\n"
#             except (ValueError, ZeroDivisionError):
#                 output_data = "error\n"
            
#             # 写入到文件
#             with open(filepath, 'a') as outputfile:
#                 outputfile.write(output_data)

# if __name__ == "__main__":
#     if len(sys.argv) != 4:
#         print("Usage: python script.py <name1> <name2> <name3>")
#         sys.exit(1)
    
#     name1 = sys.argv[1]
#     name2 = sys.argv[2]
#     name3 = sys.argv[3]
    
#     main(name1, name2, name3)

# TODO: FIXME: retry the fark code