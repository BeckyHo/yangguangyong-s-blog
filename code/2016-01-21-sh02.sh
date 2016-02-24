#!/bin/bash
# Program:
#       User can input 2 integer to cross by!
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

#1. 让使用者输入文件名，并且判断使用者是否真的有输入字符串？
echo -e "The program will show you that filename is exist which input by you.\n\n"
read -p "Input a filename: " filename
test -z $filename && echo "You MUST input a filename." && exit 0
#2. 判断档案是否存在？
test ! -e $filename && echo "The filename $filename DO NOT exist" && exit 0
#3. 开始判断档案类型与属性
test -f $filename && filetype="regulare file"
test -d $filename && filetype="directory"
test -r $filename && perm="readable"
test -w $filename && perm="$perm writable"
test -x $filename && perm="$perm executable"
#4. 开始输出信息
echo "The filename: $filename is a $filetype"
echo "And the permission are : $perm"
