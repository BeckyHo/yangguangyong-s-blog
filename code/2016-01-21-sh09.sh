#!/bin/bash
# Program:
#       Use loop to try find your input.
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

while [ "$yn" != "yes" ] && [ "$yn" != "YES" ]
do
        read -p "Please input yes/YES to stop this program: " yn
done
