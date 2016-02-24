#!/bin/bash
# Program:
#       Use loop to try find your input.
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

sum=0
for (( i=0; i<=100; i++ ))
do
    sum=$(($sum+$i))
done
echo "The result 1+2+3+...+100 is ==> $sum"
