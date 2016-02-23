#### 认识 BASH SHELL

##### 简介

早年的Unix年代，发展者众多，所以由于shell依据发展者的不同就有许多的版本，例如常听到的Bourne Shell (sh)、在Sun里头预设的C Shell、商业上常用的K Shell、还有TCSH等等，每一种Shell都各有其特点。至于Linux使用的这一种版本就称为Bourne Again Shell(简称bash)，这个Shell是Bourne Shell的增强版本，也是基准于GNU的架构下发展出来的。

##### 命令介绍

***Bash Shell内建命令：type***

为方便Shell操作，bash已经内建了很多指令了，如何知道这个指令是外部指令，或者是内建在bash当中的了？使用type这个指令来观察即可知道结果

语法(注意，以后的语法介绍中[]内表示可选的参数)

    [root@linux~]# type [-tpa] name
参数

    不加任何参数时，则type会显示出那个name是外部指令还是bash内建的指令
    -t  #加入-t参数时，type会将name以底下这些字眼显示出它的意义
        file: 表示为外部指令
        alias: 表示该指令为领命别名所设定的名称
        builtin: 表示该指令为bash内建的指令功能
    -p  #如果后面接的name为指令时，会显示完整文件名（外部指令）或显示为内建命令
    -a  #会将由PATH变量定义的路径中，将所有含有name的指令都列出来，包含alias

***指令的下达***

语法

    [root@linux~]# command [-options] parameter1 parameter2 ...
                    指令      选项       参数1     参数2

说明
* 一行指令中第一个输入的绝对是【指令（command）】或【可执行文件】
* command为指令的名称，例如变换路径的指令为cd 等等
* 中括号[]并不存在于世纪的指令中，而加入参数设定时，通常为 - 号，例如-h；有时候完整参数名称会输入 -- 符号，例如 --help
* parameter1 parameter2 ...为依附在option后面的参数，或者是command的参数
* command, -options, parameter1...这几个咚咚中间以空格来区分，不论空几格，shell都视为一格
* 按下[Enter]按键后，该指令就立刻执行，[Enter]按键为<CR>字符，他代表着一行指令的开始启动
* 指令太长的时候，可以使用 \ 符号来跳脱[Enter]符号，使指令连续到下一行。注意！ \后就立刻接特殊字符
* 在Linux系统中，英文大小写字母是不一样的，举例来说，cd与CD并不同

***Shell的变量功能***

利用echo这个指令来取用变量，但是，变量在被取用时，前面必须要加上$才行；举例来说，要知道PATH的内容，可以 echo $PATH 或者 echo ${PATH} 都可以

如何设定或者修改某个变量的内容？用等号（=）链接变量与它的内容就好了，比如 name=yangguangyong 变量在设定时，需要符合以下规则：
* 变量与变量内容以等号【=】来链接
* 等号【=】两边不能直接接空格符
* 变量名称只能是英文字母与数字，但是数字不能是开头字符
* 若变量内容有空格符可以使用双引号【"】或者单引号【'】来将变量内容结合起来，但两者是有区别的，后面会讲到
* 必要时需要以跳脱字符来将特殊符号变成一般符号
* 在一串指令中，还需要藉由其它的指令提供的信息，可以使用quote【\` 数字1左边的那个键喽】，因为被quote包括的指令优先被执行
* 若该变量为扩增变量内容时，则需以双引号及$变量名称，如"$PAHT":/home为在变量PATH后累加:/home内容
* 若该变量需要在其它子程序执行，则需要以export来使变量变成环境变量
* 取消变量的方法为 unset 变量名称

***环境变量的功能***

使用env, export和set都可以查阅当前环境变量，三者具体区别，[点击这里](https://github.com/yangguangyong/yangguangyong.github.io/blob/master/_posts/2016-02-19-Linux%20%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F%20set%20env%20export%20%E7%BB%86%E8%A7%A3.md)

***变量键盘读取，数组与宣告：read, array与declare***

read

要读取来自键盘输入的变量，就是用read这个指令了，语法

    [root@linux~]# read [-pt] variable

参数

    -p  #后面可以接提示字符
    -t  #后面可以接等待的【秒数】，使得程序不会一直等待使用者啦

实例1

    [root@linux~]# read name
    yangguangyong  <== 程序会停在这里等待你输入内容
    [root@linux~]# echo $name
    yangguangyong

实例2：10秒内输入自己的大名，否则程序继续执行

    [root@linux~]# read -p "Please keyin your name in 10 second: " -t 10 name
    Please keyin your name in 10 second: yangguangyong <==与上面一样
    [root@linux~]# echo $name
    yangguangyong

declare

declare和typeset两者作用一样，都是在宣告变量的属性，语法

    [root@linux~]# declare [-aixr] variable

参数

    -a  #将后面的variable定义成为数组(array)
    -i  #将湖面接的variable定义成为整数数字
    -x  #用法与export一样，就是将后面的variable变成环境变量
    -r  #将一个variable的变量设定成为readonly，该变量不可被更改内容，也不能unset

实例1：让变量sum存储100+300+50的加法结果

    [root@linux~]# sum=100+300+50
    [root@linux~]# echo $sum
    100+300+50 <==居然不是计算的结果450 ？？？
    [root@linux~]# declare -i sum=100+300+50 <==使用declare将sum声明成一个整数数字
    [root@linux~]# echo $sum
    450

实例2：让sum变成环境变量

    [root@linux~]# declare -x sum <==作用与export是一样的

实例3：让sum变成只读属性，不可更改

    [root@linux~]# declare -r sum
    [root@linux~]# sum=test
    -bash: sum: readonly variable

***指令别名设定：alias, unalias***

使用alias可以给一个指令取一个别名，之后执行这个别名与执行这个指令效果是一样的；例如 alias lm='ls -l | more' 之后我们执行lm，相当于执行ls -l | more这个指令了

执行alias也可以查看当前系统的所有别名，当不想要某个别名的时候，使用unalias就可以取消这个别名，例如unalias lm就取消了lm的别名设置

***历史指令 history***

如何查询我们曾经下达过的指令呢？ 就使用 history 喽，语法

    [root@linux~]# history [n]
    [root@linux~]# history [-c]
    [root@linux~]# history [-raw] histfiles

参数

    n   #数字，意思是【要列出最近的n笔指令列表】的意思
    -c  #将目前的shell中的所有history内容全部消除
    -a  #将目前新增的history指令新增入histfiles中，若没有加histfiles，则预设写入~/.bash_history
    -r  #将histfiles的内容读到目前这个shell的history记忆中
    -w  #将目前的history记忆内容写入histfiles中

实例1：列出目前内存内的所有history记忆

    [root@linux~]# history
    #前面省略
    1017    man bash
    1018    ll
    1019    history
    1020    history
    #列出的信息当中，共分两栏，第一栏为该指令在这个shell当中的代码
    #另一个则是指令本身的内容哦喔，至于会秀出几笔指令纪录，则与HISTSIZE有关

实例2：列出目前最近3笔资料

    [root@linux~]# history 3
    1019    history
    1020    history
    1021    history 3


实例3：立刻将目前的资料写入histfile当中

    [root@linux~]# history -w
    #在预设的情况下，会将历史纪录写入~/.bash_history当中
    [root@linux~]# echo $HISTSIZE
    1000

##### 数据流重导向

指令执行过程中数据传输情况：在执行命令的时候，这个指令可能会由文件读入资料，经过处理后，再将数据输出到屏幕上，standard output和standard error代表标准输出与标准错误输出，预设下他们都是输出到屏幕上来的，但是我们可以将它们的结果传送到其他不同的地方，而不是屏幕上，传送的目标通常是文件或者装置，传送的命令如下：
* 标准输入：代码为0，使用<或<<
* 标准输出：代码为1，使用>或>>
* 标准错误输出：代码为2，使用2>或2>>

实例1：将ls -l的输出结果存储下来

    [root@linux~]# ls -l / > ~/rootfile
    #本来ls -l / 会将根目录的数据列出到屏幕上
    #现在我使用了 > ~/rootfile后，则本来应该在屏幕上出现的数据
    #就会被【重新导向】到~/rootfile文件内了，就可以将该数据储存

如果我再次下达ls -l / > ~/rootfile后，rootfile之前储存的数据会被覆盖掉，而不是在原来的内容后累加，是的，因为rootfile文件的建立方式是：
* 该档案（本例中是~/rootfile）若不存在，系统会自动的将它建立起来，但是
* 当这个文件存在的时候，那么系统就会先将这个文件内容清空，然后再将数据写入
* 也就是若以 > 输出到一个以存在的文件中，呵呵，那个文件就会被覆盖掉喽

如果我想要将数据累加，不想要将旧的数据删除，那该如何是好？ 利用 >> 就好啦；例如上面的例子中，就变成 ls -l / >> ~/rootfile，若文件以存在，则数据会在文件的最下方累加进去

Linux执行结果中，可以约略的分成正确输出与错误输出两种数据，那么如何将这两种输出结果区分开来了？在数据的重导向方面，正确的写法应该是1>与2>才对，但是如果只有>则是以1>来进行数据输出的，那个1>是输出正确数据，2>则是错误数据输出项目，也就是说：
* 1> 是将正确的数据输出到指定的地方去
* 2> 是将错误的数据输出到指定的地方去

好了，那么如何将数据输出到不同的地方去了？ 可以这么写：

    [root@linux~]# find /home -name testing > list_right 2> list_error

那如果将正确数据和错误的数据都输出到同一个文件中了？那就是下面这种喽

    [root@linux~]# find /home-name testing > list 2>&1

##### 指令执行的判断依据【;】, 【&&】,【||】

例如，某些时候，我们希望一次执行多个指令，例如关机时，希望我们可以先执行两次sync,然后才shutdown计算机，可以这样做呀

    [root@linux~]# sync; sync; shutdown -h now

在指令与指令中间利用分好（;）来隔开，这样一来，分好前的指令执行完毕后，就会立刻接着执行后面的指令了

当我想要在某个目录下建立一个文件，也就是说，如果该目录存在的话，我才建立这个文件，如果不存在，那就算了~~~，那该如何写呢？ 可以利用&&来实现啊

    [root@linux~]# ls /tmp && touch /tmp/shell

是否记得之前谈过的变数【$?】呢？如果指令执行结果没有错误信息，那就会回传$?=0，如果有错误，那回传值就不是0啊，利用这样的判断，我们可以利用&&来决定，当&&前面的指令执行结果为正确，就可以接着执行后续的指令，否则就给予略过

【||】的判断刚好相反，当前面的指令返回的$?不为0时，才会执行后面的指令

##### 管道命令（pipe）

有时候，我们希望从输出的数据中经过几道手续之后才能得到我们所想要的格式，那该如何来设定？这就牵扯到管道命令问题了，管道命令使用的是【|】这个界定符号。

假设我们想要知道/etc/底下有多少个文件，那么可以利用ls /etc来查阅，不过，因为/etc底下的文件太多，导致一口气就将屏幕塞满了，不知道前面输出的内容是啥，此时，我们可以通过less指令的协助，利用：

    [root@linux~]# ls -al /etc | less

如此一来，利用ls指令输出后的内容，就能够被less读取，并且利用less的功能，我们就能够前后翻动相关的信息了

管道命令【|】仅能处理经由前面一个指令传来的正确信息，也就是standard output的信息，对于standard error并没有直接处理的能力。每个管道的前后部分都是指令，后一个指令的输入乃是前一个指令的输出

***两个常用的撷取命令：cut和grep***

撷取命令，就是将一段数据经过分析后，取出我们所想要的，或者是，经过分析关键词，取得我们所想要的那一行。需要注意的是，一般来说，撷取信息通常是针对一行一行来分析的，并不是整篇信息分析的喔

cut命令

这个指令可以将一段信息的某一段给他切出来，注意处理的信息是以行尾单位喔

语法

    [root@linux~]# cut -d '分隔字符' -f fields
    [root@linux~]# cut -c 字符区间

参数

    -d  #后面接分隔字符，与-f一起使用
    -f  #依据-d的分隔字符将一段信息分割成为数段，用-f取出第几段的意思
    -c  #以字符的单位取出固定字符区间

实例1：将PATH变量取出，我要找出第三个路径

    [root@linux~]# echo $PATH
    /bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/X11R6/bin:/usr/games
    [root@linux~]# echo $PATH | cut -d ':' -f 5
    #嘿嘿，如此一来，就会出现/usr/local/bin这个目录名称！
    #因为我们是以 : 作为分隔符，第五个就是/usr/local/bin啊！
    #那么如果想要列出第3与第5呢？就是这样：
    [root@linux~]# echo $PATH | cut -d ':' -f 3,5

实例2：将export输出的信息，取得每行第12个字符以后的所有字符串

    [root@linux~]# export
    declare -x HISTSIZE="1000"
    declare -x INPUTRC="/etc/inputrc"
    declare -x KDEDIR="/usr"
    declare -x LANG="zh_TW.big5"
    .......其他省略.......
    [root@linux~]# export " cut -c 12-
    HISTSIZE="1000"
    INPUTRC="/etc/inputrc"
    KDEDIR="/usr"
    LANG="zh-TW.big5"
    ......其他省略......
    #知道怎么回事了吧？ 用 -c 可以处理比较具有格式的输出数据！
    #我们还可以指定某个范围的值，例如第12-20的字符串，就是cut -c 12-20

实例3：用last将这个月登入者的信息中，仅留下使用者大名

    [root@linux~]# last
    yangguangyong tty1 10.18.15.140 Wed May 13 19:07
    zhangfan      tty1 10.18.15.196 Wed May 14 19:07
    #用last可以取得最近一个月登入主机的使用者信息
    #而我们可以利用空格符的间隔，取出第一个信息，就是使用者账号喽！

grep命令

grep是分析一行信息，若当中有我们需要的信息，就将该行拿出来

语法

    [root@linux~]# grep [-acinv] '搜寻字符串' filename

参数

    -a  #将binary文件以text文件的方式搜寻数据
    -c  #计算找到'搜寻字符串的次数'
    -i  #忽略大小写的不同，所以大小写视为相同
    -n  #顺便输出行号
    -v  #反向选择，亦即显示出没有'搜寻字符串'内容的那一行
