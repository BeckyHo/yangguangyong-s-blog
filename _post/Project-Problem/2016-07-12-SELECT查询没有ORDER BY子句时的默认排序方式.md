### SELECT查询没有ORDER BY子句时的默认排序方式

场景：最近在code review时，看到竞技场排名load的sql语句: `SELECT * FROM ArenaRank WHERE ZoneId=?`,
首先我们的竞技场是按照排名从高到低存储在`ArenaRank`表中的，这条sql语句的目的也是将
竞技场的排名从数据库中load到内存中，方便排名的修改和访问。

但是，我突然记得，在什么地方看过这样一句话：

> 从表中抽取数据时，如果没有特别指定顺序，最终排列顺序便无从得知。即使是同一条select
> 语句，每次执行时排列顺序很可能发生改变，这时，便需要通过在select语句末尾添加order by
> 子句来明确指定排列顺序

想到上面这句话时，我的第一反应就是我们load竞技场排名的sql语句会不会有问题？会不会
出现多次select返回结果不一致，这样的话这个排名就会混乱，影响到后续的排名交换等业务逻辑。

下面的解释来自mysql![官方论坛](http://forums.mysql.com/read.php?21,239471,239688#msg-239688)

SELECT没有ORDER BY子句时的默认排序方式是什么？

* 不要依赖mysql的默认排序方式，也就是不能依赖缺失order by子句的select返回结果
* 如果你想排序，就指定order by子句吧
* group by加强了order by(这与标准语法冲突，可以使用order by null来避免冲突)不懂？？

`SELECT * FROM tbl` 这条语句会做表扫描，如果没有做任何delete/replace/update操作，select
将以插入数据顺序依次返回

如果你是在InnoDb表中做同样的查询，返回数据将以primary key排序，而不是以插入顺序。这是mysql
底层实现的，不会依赖插入等操作

___

再来看看我们项目中的select语句，首先，我们的表是InnoDB表，主键是(ZoneId, Rank),
也就是说，select还是会根据Rank字段有序的返回，而不是结果不确定，所以说`SELECT * FROM ArenaRank WHERE ZoneId=?`
是对的
