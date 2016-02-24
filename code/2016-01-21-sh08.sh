#!/bin/bash
# Program:
#       Let user input one, two, three and output inthe screen
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

function printit(){
    echo -n "Your choice is $1\n"
}

echo "This program will print your selection!"
case $1 in
    "one")
        printit 1
        ;;
    "two")
        printit 2
        ;;
    "three")
        printit 3
        ;;
    *)
        echo "Usage {one|two|three}"
        ;;
esac
