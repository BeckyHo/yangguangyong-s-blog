#!/bin/bash
# Program:
#       The program will show it's name and first 3 parameters.
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

echo "The script name is ==> $0"
[ -n "$1" ] && echo "The 1st paramter is ==> $1" || exit 0
[ -n "$2" ] && echo "The 2st paramter is ==> $2" || exit 0
[ -n "$3" ] && echo "The 1st paramter is ==> $3" || exit 0
