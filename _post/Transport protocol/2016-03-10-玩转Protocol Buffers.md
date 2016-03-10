### 玩转Protocol Buffers

#### Protocol Buffers(protobuf)是什么
>protocol buffers是google提供的一种将结构化数据进行序列化和反序列化
>的方法；其优点是语言中立，平台中立，可扩展性好，目前在google内部大
>量用于数据存储，通讯协议等方面。protobuf在功能上类似XML，但是序列化>后的数据更小，解析更快，使用上更简单。用户只要按照proto语法在.proto>文件中定义好数据的结构，就可以使用protobuf提供的工具（protoc）自动
>生成处理数据的代码，使用这些代码就能在程序中方便的通过各种数据流读
>写数据；protobuf目前支持Java,C++和Python3种语言；另外，protobuf还提>供了很好的向后兼容，即旧版本的程序可以正常处理新版本的数据，新版本
>的程序也能正常处理旧版本的数据

#### 如何使用Protocol Buffers

有两种方法使用protocol buffers, 一种是通过google提供的工具根据.proto文件生成对应的类，然后使用这个类提供的方法来序列化和反序列化需要传输的数据，达到前后端交流的目的；另一种方法是使用DynamicMessage这个类来序列化和反序列化

先介绍第一种方法

##### 使用Google提供的工具使用protobuf

###### 工具的下载

下载地址：[点击这里](https://developers.google.com/protocol-buffers/docs/downloads?hl=zh-cn)，选择linux版或者window版，我下载的是window版，解压会得到一个protoc.exe可执行文件，它可以根据我们定义的.proto文件生成java类

###### 编写.proto文件

首先编写.proto文件，定义protobuf数据结构；它的语法与java的很相似，查看protobuf与各语言的数据类型定义关系，[点击这里](https://developers.google.com/protocol-buffers/docs/proto?hl=zh-cn#scalar)

我们的proto示例（PersonMsg.proto）：

    message person {
        required int32 id = 1;
        required string name = 2;
        optional string email = 3;
        repeated string friends = 4;
    }

关于required, optional repeated使用选择，官网是这样说的
>你应该使用以下三个之一来指定你的消息属性：
>
>required: 一个完整的消息格式必须要有required修饰过的属性值
>
>optional: 一个完整的消息格式可以没有或者有一个optional修饰过的属性值（但是不能多于一个）
>
>repeated: 在一个完整的消息格式中repeated修饰过的属性可以重复出现任
>何次数（包括0次）.重复出现值的顺序将会得到保留

还有复杂的.proto文件，比如import其他类型，定义枚举等，这里不介绍

###### 使用Google提供的工具protoc.exe生成Java代码

将proto.exe拷贝到与.proto同一个目录，打开cmd进入该目录，运行命令：

    protoc.exe --java_out=F:/code PersonMsg.proto

其中F:/code表示存放生成的java文件路径， person.proto是我们刚才编写的.proto文件；这时在我们指定的F:/code目录下会生成PersonMsg.java文件

###### 序列化和反序列化

大部分情况下，序列化和反序列化是分开的；比如在我们项目中，前端将序列化的数据传送到后端，后端通过反序列化得到得到前端传过来的数据，但是我们的示例中把这两个过程写在了一起；

首先创建一个java项目，把生成的PersonMsg.java放到它对应的package下，如果没有就是default package；接着导入protobuf-java-2.5.0.jar包；最后写测试类，代码：[点击这里](http://www.google.com)
