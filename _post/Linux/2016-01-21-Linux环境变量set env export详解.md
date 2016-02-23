#### Linux 环境变量 set env export 详解

set,env和export这三个命令都可以用来显示shell变量,区别

    [root@localhost root]# a=test
    [root@localhost root]# echo $a
    test
    [root@localhost root]# set |grep a
    a=test
    [root@localhost root]# env |grep a
    [root@localhost root]# export a
    [root@localhost root]# env |grep a
    a=test

* set 显示当前shell的变量，包括当前用户的变量
* env 显示当前用户的变量
* export 显示当前导出成用户变量的shell变量

每个shell都有自己特有的变量，这和用户变量是不同的。当前用户变量和你用什么shell无 关，不管你用什么shell都是存在的。比如HOME,SHELL等这些变量，但shell自己的变量，不同的shell是不同的，比如 BASH_ARGC， BASH等，这些变量只有set才会显示，是bash特有的。export不加参数的时候，显示哪些变量被导出成了用户变量，因为一个shell自己的变 量可以通过export “导出”变成一个用户变量。
