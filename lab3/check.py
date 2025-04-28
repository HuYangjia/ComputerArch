def find_strings_in_file(file_path, strings_to_find, strings_to_exit):
    # 打开文件
    with open(file_path, 'r', encoding='utf-8') as file:
        # 遍历文件的每一行
        num = 0
        for line_number, line in enumerate(file, start=1):
            # 检查每个字符串是否在当前行
            flag = True
            for string in strings_to_find:
                if string not in line:
                    flag = False
                    break
            for string in strings_to_exit:
                if string in line:
                    flag = False
                    break
            
            if flag:
                # 如果所有字符串都在当前行，打印行号和内容
                print(f"Found in line {line_number}: {line.strip()}")
                num += 1
                
                
                if num == 100:
                    print("Found 10 lines, stopping search.")
                    break
                # break
                
        print(f"Total lines found: {num}")

# 文件路径
file_path = 'cache_trace.txt'
# 要查找的字符串列表
strings_to_find = [ 'access for WriteReq', '(M)', 'dcache']
# strings_to_exit = ['e (M)', 'c (O)', '6 (E)']
strings_to_exit = []

# 调用函数
find_strings_in_file(file_path, strings_to_find, strings_to_exit)
