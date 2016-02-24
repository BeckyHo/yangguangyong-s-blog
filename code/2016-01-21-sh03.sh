#!/bin/bash
# Program:
#       This program will show user's choice
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

read -p "Please input (Y/N): " yn
[ "$yn" == "Y" -o "$yn" == "y" ] && echo "OK, continue" && exit 0
[ "$yn" == "N" -o "$yn" == "n" ] && echo "Oh, interrupt!" && exit 0
echo "I do not know what is your choise" && exit 0
