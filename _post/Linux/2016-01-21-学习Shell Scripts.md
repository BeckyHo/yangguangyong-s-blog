### 学习Shell Scripts

介绍shell script的语法与编写scripts的一些约定

#### 什么是 Shell scripts?

> shell scrip是针对shell所写的【脚本】；其实，shell
> script是利用shell的功能所写的一个【程序（program）】，这个程序是使用纯
> 文字文件，将一些shell的语法与指令写在里面，搭配正则表达式，管线命令与
> 数据流重导向等功能，以达到我们所想要的处理目的

#### 编写shell script注意事项

在写shell script的时候我们需要遵守一些约定，这使得我们后期维护这些shell脚本时更加的方便，具体注意事项，[点击这里](http://www.google.com)

#### 如何运行一个shell script脚本

假设程序文件名是`shell.sh`，那么如何执行这个shell脚本了？可以有以下几种方法
* 将`shell.sh`加上可读与可执行（rx）的权限，然后就能够以`./shell.sh`来执行了（如何修改文件的权限？[点击这里]()）
* 直接以`sh shell.sh`的方式来直接执行即可

#### shell script语法详解

这部分将介绍shell script的基础语法，以帮助我们编写自己的shell脚本

##### 数值运算

shell script支持整数的算术运算，这些运算有：+，-，\*，/，%等等；在数字运算上，我们可以使用【declare -i total=$firstnu*$secnu】,也可以使用下面的这种方式来进行运算（推荐使用下面这种方式）：

`var=$((运算内容))`

示例：输入两个数，计算两个数相乘并输出结果

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh01.sh)

##### 学会使用判断式

之前说过，通过`$?`，结合`&&`及`||`来作一些简单的逻辑判断，但是在复杂的判断处理中，我们可以通过`test`这个指令来判断，比如判断/shell目录是否存在时，使用:

    [root@linux~]# test -e /shell && echo "exist" || echo "Not exist"

`test`使用查询（test -e filename）

|   测试的标志  |   代表意义    |
|---------------|---------------|
||`关于filename类型的判断`         |
|   -e          |   该【filename】是否存在？   |
|   -f          |   该【filename】是否为文件？ |
|   -d          |   该【filename】是否为目录？    |
|   -b          |   该【filename】是否为一个block device装置？    |
|   -c          |   该【filename】是否为一个character device装置？    |
|   -S          |   该【filename】是否为一个Socket文件？    |
|   -p          |   该【filename】是否为一个FIFO文件？    |
|   -L          |   该【filename】是否为一个连接档？    |
|   -d          |   该【filename】是否为目录？    |
||`关于filename的权限判断`         |
|   -r          |   判断该filename是否具有【可读】的属性？    |
|   -w          |   判断该filename是否具有【可写】的属性？    |
|   -x          |   判断该filename是否具有【可执行】的属性？    |
|   -u          |   判断该filename是否具有【SUID】的属性？    |
|   -g          |   判断该filename是否具有【可读】的属性？    |
|   -k          |   判断该filename是否具有【Sticky bit】的属性？    |
|   -s          |   判断该filename是否为【非空白文件】？    |
||`两个文件之间的比较，如:test file1 -nt file2`    |
|   -nt         |   (newer than)判断file1是否比file2新 |
|   -ot         |   (order than)判断file1是否比file2旧 |
|   -ef         |   判断file1与file2是否为同一文件，可用在判断hard link的判定上。主要意义在判定两个文件是否均指向同一个inode|
||`关于两个整数之间的判定，如:test n1 -eq n2`              |
|   -eq         |   两数值相等（equal)  |
|   -ne         |   两数值不等（not equal)  |
|   -gt         |   n1大于n2(greater than)  |
|   -lt         |   n1小于n2(less than)  |
|   -ge         |   n1大于等于n2(greater than or equal)  |
|   -le         |   n1小于等于n2(less than or equal)  |
||`判定字符串的数据`|
|   test -z string  |   判定字符串是否为0？若string为空字符串，则为true |
|   test -n string  |   判定字符串是否非为0？若string为空字符串，则为false |
|   test str1 = str2  |   判定str1是否等于str2，若相等，则回传true |
|   test str1 != str2   |   判定str1是否不等于str2，若相等，则回传false|
||`多重条件判定，例如：test -r filename -a -x filename`|
|   -a  |   (add)两状况同时成立，例如test-r file -a -x file, 则file同时具有r与x权限时，才回传true    |
|   -o  |   (or)两状况任何一个成立，例如test-r file -o -x file, 则file同时具有r与x权限时，才回传true    |
|   !  |   反相状态，如test ! -x file，当file不具有x时，回传true    |

示例：让用户输入一个文件/路径，我们判断：
* 这个文件/路径是否存在，若不存在则给予【filename does not exist】的信息，并中断程序
* 若这个文件/路径存在，则判断他是个文件或目录，结果输出【filename is regular file】或【filename is directory】
* 判断一下，使用者的身份对这个文件/目录所拥有的权限，并输出权限数据

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh02.sh)

##### 利用判断符号[ ]

除了使用test之外，我们还可以利用判断符号`[]`来进行数据的判断呢，举例来说，如果我想要知道$HOME这个变量是否为空，可以这样做：

    [root@linux~]# [-z "$HOME" ]

使用判断符号需要注意以下要点：
* 在中括号[]内的每个组件都需要有空格来分隔
* 在中括号内的变量，最好都以双引号来设定
* 在中括号内的常数，最好都以单引号或双引号来设定

示例：
* 当执行一个程序的时候，这个程序会让使用者选择Y或者N
* 如果使用者输入Y或y时，就显示【OK, continue】
* 如果使用者输入N或n时，就显示【Oh, interrupt!】
* 如果不是Y/y/Y/n之内的其他字符，就显示【I do not know what is your choise】

利用中括号，&&与||来实现吧！

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh03.sh)

##### Shell Script的预设变量（$0, $1...）

其实，在我们执行一个shell script时，这个shell script李卖弄就已经帮我们做好一些可用的变量了，变量的对应是这样的：

    /path/to/scriptname   opt1   opt2  opt3  opt4 ...
            $0             $1     $2    $3   $4   ...

执行的文件名为$0，第一个接的参数就是$1啊，所以，只要我们在script里面善用$1的话，就可以很简单的立即下达某些指令功能了！

示例：假设我要执行一个script，执行后，会自动列出自己的名称，还有后面接的前三个参数，该怎么做了？

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh04.sh)

##### 条件判断式

条件判断式有两种，分别是：if...then和case...esac

###### 利用 if ... then

这个 if ... then是最常见的条件判断式了，简单的说，就是当符合某个条件判断的时候，就给予进行某项工作，我们可以简单的这样看：

    if [ 条件判断式 ]; then
        当条件判断式成立时，可以进行的指令工作内容；
    fi

至于条件判断式的判断方法，与前一小节的介绍相同，`特别的是，如果我有多个条件要判断时，除了将多个条件写入一个中括号内的情况之外，我还可以用多个中括号来隔开哦，而括号与括号之间，则以&&或||来隔开，它们的意义是：`
* && 代表 AND
* || 代表OR

___所以，要记得区分使用中括号的判断式中，&&与||在与指令下达的意义是不同的，比如[这个例子sh03.sh]()可以改写成这样：___

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh05.sh)

___更复杂的if then语法___

    if [ 条件判断式 ]; then
        当条件判断式成立时，可以进行的指令工作内容
    else
        当条件判断式不成立时，可以进行的指令工作内容
    fi

或者

    if [ 条件判断式一 ]; then
        当条件判断式一成立时，可以进行的指令工作内容
    elif [ 条件判断式二 ]; then
        当条件判断式而成立时，可以进行的指令工作内容
    else
        当条件判断式一与二均不成立时，可以进行的指令工作内容
    fi

此时上面这个[例子](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh05.sh)可以改写成这样：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh06.sh)

###### 利用 case .... esac 判断

if .... then .... fi对变量的判断中，是以比对的方式来分辨的，如果符合状态就进行某些行为，并且透过较多层次（就是elif....）的方式来进行多个变量的程序代码编写；万一我的变量内容确定在几个常量之中的其中一个，那么我只要针对这两个变量来设定状况就好了啊，用什么方法来设计了？就用case ... in ... esac吧

语法

    case $变量名称 in
        "第一个变量内容")
            程序段
            ;;
        "第二个变量内容")
            程序段
            ;;
        \*)
            不包括第一个变量内容与第二个变量内容的其他程序执行段
            exit 1
            ;;
    esac

`注意：每一个变量内容的程序段最后都需要两个分号（;;）来代表该程序段的结束`

示例：判断第一个参数$1是否为hello
* 如果是的话，就显示“hello, how are you”
* 如果没有加任何参数，就提示使用者必须要使用hello参数
* 如果不是hello参数，就提示只能使用这个参数

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh07.sh)

一般来说，使用【case $变量 in】这个语法中，当中的那个$边变量可以分为两种取得方式：

* 直接下达方式，比如参数$1
* 交互式，通过read命令读取

##### 利用function功能

其实，函数可以在shell script当中做出一个类似自定执行指令的东西，最大的功能是，可以简化我们很多的程序代码

语法

    function fname() {
        程序段
    }

那个fname就是我们自定的执行指令名称，而程序段就是我们要执行的内容了，要注意的是，在shell script当中，function的设定一定要在程序的最前面，这样才能够在执行时被找到可用的程序段哦

示例：让使用者能够输入one, two, three，并且将使用者的变量显示到屏幕上，如果不是one, two, three时，就告知使用者只能有这三种选择

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh08.sh)

上面例子中，我们使用了function的内建变量，它的内建变量与shell script很类似，函数名称代表$0，而后续接的变量也是以$1,$2...来取代的～

当你输入【./sh11-3.sh one】就会出现【You choice is 1】的字样，为什么是1呢？因为在程序段落中，我们是写了【printit 1】那个1就会成为function当中的$1

##### 循环（loop）

除了if...then...fi这种条件判断式之外，循环可能是程序当中最重要的一环了；循环可以不断的执行某个程序段落，直到使用者设定的条件达成为止

###### while do done, until do done

一般来说，循环最常见的就是地下这两种状态了：

    while [ condition ]
    do
        程序段落
    done

这种方式中，while是【当....时】，所以，这种方式说的是【当condition条件成立时，就进行循环，直到condition的条件不成立才停止】的意思

    until [ condition ]
    do
        程序段落
    done

这种方式恰恰与while相反，它说的是【当condition条件成立时，就终止循环，否则就持续进行循环的程序段】是否刚好相反啊，我们以while来做个练习好了，假设我要让使用者输入yes或者是YES才结束程序的执行，否则就一直进行告知使用者输入字符串

示例代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh09.sh)

###### for...do...done

相对于while, until的循环方式是必须要【符合某个条件】的状态，for这种语法，则是【已经知道要进行几次循环】的状态，它的语法是：

    for (( 初始值; 限制值; 执行步骤 ))
    do
        程序段
    done

这种语法适合于数值方式的运算当中，在for后面的括号内的三串内容意义为：
* 初始值：某个变量在循环当中的起始值，直接以类似 i=1 设定好
* 限制值：当变量的值在这个限制值的范围内，就继续进行循环，例如 i<=100
* 执行步骤：每作一次循环时，变量的变化量，例如 i=i+1

示例：使用for循环来进行1累加到100的循环

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh10.sh)

###### for循环除了可以在数值方面使用外，还可以用在非数值方面，例如

    for var in con1 con2 con3 ...
    do
        程序段
    done

以上面的例子来说，这个$var的变量内容在循环工作时：
* 第一次循环时，$var的内容为con1
* 第二次循环时，$var的内容为con2
* 第三次循环时，$var的内容为con3
* ....

示例：我想要让使用者输入某个目录，然后我找出某目录内的文件名的权限呢

代码：[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/code/2016-01-21-sh11.sh)
##### shell script的追踪与debug

shell script在执行之前，最怕的就是出现问题了，那么我们如何debug呢？有没有办法不需要通过直接执行该script就可以来判断是否有问题呢？ 当然有了，我们直接以bash的相关参数来进行判断吧

    [root@linux~]# sh [-nvx] script.sh

参数

    -n  #不要执行script，仅查询语法的问题
    -v  #在执行script前，先将script的内容输出到屏幕上
    -x  #将使用到的script内容显示到屏幕上，这是很有用的参数
