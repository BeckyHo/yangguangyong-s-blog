#!/bin/bash
# Program:
#       Show "Hello" from $1...
# History:
# 2016/08/24    yangguangyong 1026720797@qq.com First release
PATH=/bin:sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/shell
export PATH

case $1 in
    "hello")
        echo "hello, how are you?"
        ;;
    "")
        echo "You MUST input parameters, ex> $0 someword"
        ;;
    *)
        echo "Usage $0 {hello}"
        ;;
esac
