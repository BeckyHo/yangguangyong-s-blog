### Jedis/BinaryJedis 解析

Jedis是Redis为Java语言提供的连接Redis代码，我们最常用到的两个类是Jedis和BinaryJedis.
首先看看两个类的继承/实现结构图

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedis01.png)

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedis02.png)

通过源码可知，设置/读取redis数据时可以传递String类型参数，也可以传递byte数组。最终调用了
Protocol的sendCommand()方法实现与redis服务端的交互

#### redis如何连接服务器

redis客户端连接服务器是在Connection中完成的，通过源码可知，Connection维护一个Socket（socket客户端实现），
一个RedisOutputStream和RedisInputStream(属于java i/o族中的装饰者,继承了FilterOutputStream)

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/conn_attri.png)

socket初始化

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/conn_attri_init.png)

#### redis断开服务器连接

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/conn_close.png)

先flush写的缓冲区，然后关闭socket连接

#### Jedis命令执行流程

以Jedis#set(final String key, final String value)为例, 流程为:

Jedis#set(key, value) ---> Client#set(key, value) ---> BinaryClient#set(key, value) --->
Connection#sendCommand(ProtocolCommand cmd, byte[]... args) ---> Protocol#sendCommand(RedisOutputStream os, byte[] command, byte[]... args)

从流程中可知, 最终使用Connection提供的RedisOutputStream类将数据写到redis服务器端, 完成set操作. 看下代码

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedis_set.png)

Jedis#set()方法, 调用Client实例的set方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/client_set.png)

在Client中，使用SafeEncoder对key/value编码得到byte数组，调用父类BinaryClient
的set()方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/binaryclient_set.png)

BinaryClient继承Connection, 该set()方法中调用Connection的sendCommand()方法, 跟进去

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/conn_set.png)

从该方法可知, 它调用了Protocol的sendCommand()方法, 并传递了RedisOutputStream实例

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/protocol_set.png)

查看Protocol可知，最终所有的set方法都会调用sendCommand(final RedisOutputStream os, final byte[] command, final byte[]... args)，
该方法中，使用Connection中初始化的RedisOutputStream属性将数据写入到redis的服务器端，完成set操作

总体流程如下, socket建立连接并初始化RedisInputStream/RedisOutputStream类, get操作就是使用input流读取数据; set操作就是使用output写入数据

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/proto_info.png)

通过以上分析, 整个redis的客户端类都已经清楚了. 到此, 我们可以给客户端做个划分

* 原生客户端: BinaryClient, 它继承Connection. 封装了redis的所有命令. 它是redis客户端的二进制版本, 所有参数都是byte[]数组.BinaryClient通过父类Connection的sendCommand调用Protocol的sendCommand往redis发送命令; Client可以看作BinaryClient的高级版本, 方法参数都是String类型, 并通过SafeEncoder转换成byte数组, 在调用父类BinaryClient对应的方法
* Jedis客户端: 平时我们都使用Jedis类封装的客户端, 它通过调用Client的方法, 在调用BinaryClient方法来完成操作; 此外还有BinaryJedis, 它调用的是BinaryClient的方法完成操作


#### JedisPool

Jedis客户端是单线程, 当Jedis被很多实例调用时自然就不够用, 此时就需要考虑使用池.
Jedis这里使用Apache的GenericObjectPool. 实现起来也是很简单, 将jedis保存在其中.
另外就是需要有个Factory来生成Jedis对象--JedisFactory实现apache的PooledObjectFactory. 重写了makeObject(),destroyObject(final Object obj),validateObject(final Object obj)等方法.

JedisPool继承关系

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedispool.png)

##### JedisPool初始化

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedispool1.png)

JedisPool构造方法中根据给定的参数初始化JedisFactory工厂，用来创建池中的jedis实例，给定
poolConfig和factory，调用JedisPoolAbstract的构造方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedispool2.png)

JedisPoolAbstract构造方法中调用父类Pool的构造方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedispool3_1.png)

Pool的构造方法调用initPool()方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedispool3.png)

initPool()方法中，先判断当前jedis池是否为null, 如果不为null, 先关闭当前jedis池, 然后
重新初始化一个新的jedis池, 也就是GenericObjectPool对象

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/jedispool4.png)

调用GenericObjectPool的构造方法, 完成初始化操作

这里要讲解一下, GenericObjectPool的基本属性

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/genericObjectPool_attri.png)

它维护三个主要属性:
* allObjects: 将生成的对象put到这个map属性中, 每个对象都有唯一标识符作为key与之对应
* createCount: 一个AtomicLong对象, 用来记录当前创建了多少个对象. 当pool中没有空闲对象需要创建新对象时, 需要判断当前createCount是否小于maxTotal(最大维护的对象个数)
* idleObjects: 一个阻塞队列, 保存当前空闲的对象, 若队列中有空闲对象, 每次都使用队列中的第一个对象(也是最活跃的对象)

#### 从JedisPool中获取Jedis对象

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/pool_jedis01.png)

调用JedisPool的getResource()方法, 它调用父类的getResource()方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/pool_jedis02.png)

Pool的getResource()方法, 调用GenericObjectPool的borrowObject()方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/pool_jedis03.png)

GenericObjectPool的borrowObject方法的一部分, 当空闲队列中没有对象时, 调用create()方法创建新的对象

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/pool_jedis04.png)

create()方法中, 最终调用factory的makeObject()方法创建新的对象, 然后createCount计数器加1, 也将新对象保存到allObjects中

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/07/pool_jedis05.png)

makeObject()方法, 也就是JedisFactory实现PooledObjectFactory<T>并重写的方法, 当需要新的redis实例时, 都会在这里创建新的redis实例
