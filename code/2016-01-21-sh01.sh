#!/bin/bash
# Program:
#       User can input 2 integer to cross by!
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH
echo -e "You SHOULD input 2 number, I will cross they! \n"
read -p "first number: " firstnu
read -p "second number: " secnu
total=$(($firstnu*$secnu))
echo -e "\nThe number $firstnu * $secnu is ==> $total"
