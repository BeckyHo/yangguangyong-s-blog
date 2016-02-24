#!/bin/bash
# Program:
#       This program will show then user's choice
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

read -p "Please input (Y/N): " yn
if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
    echo "OK, continue"
    exit 0
fi
if [ "$yn" == "N" ] || [ "$yn" == "n" ]; then
    echo "Oh, interrupt!"
    exit 0
fi
echo "I do not know what is your choise" && exit 0
