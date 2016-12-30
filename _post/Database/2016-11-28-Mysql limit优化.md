### Mysql limit优化

好久没写文章了，自己变懒了，技术也退步了，现在的战斗力真是渣渣，难受~~~。 现在开始，我又回来啦，阿里还有好多优秀的技术
等着我去学习了，哈哈

上星期做了差旅报表需求，有个功能需要用到分页显示，第一反应就是order limit, 哈哈，然后我又想起了7月份面试cvte时被问到
limit优化时没有回答上来，现在是时候做个总结了。

#### 目录

* 需求
* limit语法
* limit原理分析与优化点分析
* limit优化实践

#### 需求

> 需求部分引用网络技术大咖

举例生活中常见的例子，微博评论列表的翻页，用户发表的微博，很多直播平台的直播列表等现象，都可以
抽象成为一个list数据类型，今天来讨论下如何优化数据库中这种常见的查询。

在数据量很少的时候，我们可以直接使用limit关键字达到目的，如:

    select * from TABLE_NAME limit offset, row;

在数据量比较小的时候，这种方法是可以使用的，但是当list的长度多大百万级别时，这种方式就不太适合了。
在数据量较大时，如果取到越后面的数据, offset越大，效率越低。

在业务中，获取list列表的方式常见有两种

##### 扶梯方式

扶梯方式在导航上通常只提供上一页/下一页这两种选择，或者只提供一种“更多/more”的方式，也有下拉
自动加载更多的方式，在技术上都可以归纳成扶梯方式。

扶梯方式在技术实现上比较简单及高效，根据当前页最后一条的偏移往后获取一页即可，可以使用以下
方法实现: 

    select * from TABLE_NAME where id > offset_id limit n;

##### 电梯方式

另外一种数据获取方式在产品上体现成精确的翻页方式，如1,2,3....n,同时在导航上也可以由用户输入直达
n页. 此时若继续使用以下sql

    select * from TABLE_NAME limit offset, n;

使用explain分析，当offset=10000，n=20时，实际上扫描了10020行记录。这是由mysql索引决定的。

mysql的索引数据结构是b+tree, 当使用电梯方式时，用户指定翻到第n页时候，并没有直接方法寻址到该
位置，而是需要从第一个结点逐个查找，当找到offset*page时候，才真正拿到我们想要的n行记录，所以这样
的效率很低。

#### limit语法

 mysql[官网](http://dev.mysql.com/doc/refman/5.7/en/limit-optimization.html)对limit的语法介绍， 示例：
 SELECT ... FROM single_table ... ORDER BY non_index_column [DESC] LIMIT [M,]N 总结如下:

 * 如果M为指定，返回前N行
 * 如果M指定，跳过前M行，返回之后的N行

**mysql下标从0开始**

#### limit原理分析与优化点分析

执行过程: 排序时有个大小为size的缓冲区，如果待排序的N行记录比缓冲区大小还小，服务器就可以避免文件合并
且可以在内存中完成排序:

* 扫描表, 将我们选择的每行记录对应的列插入到缓冲区的排序队列中，如果队列已满，删除队列中的最后一行
* 返回队列的前N行.(如果指定了M， 跳过前M行且返回后面的N行)

比如当我执行 select * from user order by id limit 1000, 1;时，它会取出前1001行记录排序，并返回1000
行后的那行，也就是最后一行。这就属于取出了很多没有用到的数据，而且，当我们取的数据越大，也就是M越大，
放到缓存队列中排序的也越多，当超过sort buffer的大小时，就不能在内存中进行了，这样会更慢。

所以优化的点是： 如何只取出我们想要的那部分数据并返回了？

#### limit优化实践

方式1: 使用where，比如 select * from user where id > 1000 order by id limit 2, 3; 这时的执行过程是：
取出id > 1000的行，从之后的第二行开始，返回三条记录，此时使用explain解释这条sql，发现它只扫描了
5条记录。

问题: 如何知道需要id > 1000之后的数据了？ 怎么记录这个1000?

可以这么做，在用户第一次翻页到某个offset时，在redis中直接保存该offset对应的id是多少，也就是[offset, id]对，当有其他请求
来查找offset之后的数据时，可以从该offset对应id的位置之后往后扫描。如果列表的数据发生了变化，需要及时将redis中保存的[offset, id]删除掉.

方式2: 使用"延迟关联"查询, 比如 select film_id, description from file order by title limit 50, 5; 如果这个表非常大, 可以将这个查询改写成下面的样子: select film_id, description from film inner join(select film_id from film order by title limit 50, 5) as lim using(film_id); 
这里的"延迟关联"将大大提升查询效率, 它让MySQL扫描尽可能少的页面, 获取需要访问的记录后再根据关联列回原表查询需要的所有列.

方式3: 使用索引覆盖扫描, 因为mysql中的数据是按照索引来排序的，我们可以利用这一点.
