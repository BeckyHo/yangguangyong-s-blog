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

#### JedisPool

Jedis客户端是单线程，当Jedis被很多实例调用时自然就不够用，此时就需要考虑使用池。
Jedis这里使用Apache的GenericObjectPool。实现起来也是很简单,将jedis保存在其中。
另外就是需要有个Factory来生成Jedis对象。这个Factory是JedisPoll类的一个内部类
JedisFactory继承自BasePoolableObjectFactory。重写了makeObject(),destroyObject(final Object obj),validateObject(final Object obj)三个方法。

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

初始化factory, 配置信息，完成初始化操作
