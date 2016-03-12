### 玩转Protocol Buffers 2

这次介绍我们项目中是如何使用protobuf的，这是protobuf的另一种使用

前一个版本中我们使用的是protocol buffers提供的工具生成了可序列化和反序列化的类，这次我们使用DynamicMessage（protocol buffers官方提供的API）来实现序列化和反序列化

protocol buffers Java API [点击这里](https://developers.google.com/protocol-buffers/docs/reference/java/)

#### DynamicMessage介绍

查看DynamicMessage API提供的方法，它的父类AbstractMessageLite提供了多个序列化的方法；如：
* toByteArray(): 将消息序列化为byte数组并返回
* toByteString(): 将消息序列化为ByteString并返回
* writeTo(OutputStream output): 序列化消息并写入output流中

因此，我们只要初始化了DynamicMessage实例，就可以使用这些序列化方法；那如何初始化DynamicMessage了？

DynamicMessage有一个静态内部类Builder，专门用来初始化DynamicMessage的；那如何得到DynamicMessage.Builder的实例了？DynamicMessage的静态方法newBuilder(Descriptors.Descriptor type)就返回一个DynamicMessage.Builder实例

所以说，只要有Descriptors.Descriptor，我们就得到DynamicMessage.Builder，也就得到了DynamicMessage实例

那这个Descriptors.Descriptor是什么了？

Descriptors.Descriptor: 一个静态内部类，它描述了消息的类型

从API中，我们发现一个类：Descriptors.FileDescriptor，它可以描述.proto文件中定义的任何类型，这些类型包括在其他.proto文件中描述的所有消息和文件描述；并且FileDescriptor提供了方法findMessageTypeByName(String name)返回了Descriptors.Descriptor，这不正是我们想要的吗？

#### 如何初始化Descriptors.FileDescriptor

Descriptors.FileDescriptor的静态方法buildFrom返回一个FileDescriptor实例，需要参数有：
* DescriptorProtos.FileDescriptorProto proto
* Descriptors.FileDescriptor[] dependencies

那这两个参数有什么作用了？

DescriptorProtos.FileDescriptorProto proto: API介绍，它描述了一个.proto文件，举个例子来说把，我在achieve目录下定义的AchieveInfo.proto文件如下：

    message AchieveInfo {
        required int32 achieveId = 1;
        required bool hasGainBonus = 2;
    }

下面是我程序断点得到的FileDescriptorProto实例内容，它代表的就是上面定义的proto文件：

    name: "achieve/AchieveInfo.proto"
    message_type {
        name: "AchieveInfo"
        field {
            name: "achieveId"
            number: 1
            label: LABEL_REQUIRED
            type: TYPE_INT32
        }
        field {
            name: "hasGainBonus"
            number: 2
            label: LABEL_REQUIRED
            type: TYPE_BOOL
        }
    }

可以看出，它详细的描述了我们定义的proto文件，包括文件名，消息类型（消息名称，属性字段的类型和出现编号，是required, optional或repeated）

获得FileDescriptorProto的代码：

    FileDescriptorSet fdSet = FileDescriptorSet.parseFrom(new FileInputStream(file));
    List<FileDescriptorProto> fdpList = fdSet.getFileList();

就是说，根据这个proto的文件对象file得到FileDescriptorSet，然后就可以得到FileDescriptorProto的列表喽

Descriptors.FileDescriptor[] dependencies

FileDescriptor是FileDescriptorProto的一个属性，通常情况下都为null

就是说，我们根据proto的文件对象file得到FileDescriptorSet，通过getFileList方法可以得到FileDescriptorProto，然后就可以调用FileDescriptor的静态方法buildFrom方法生成FileDescriptor实例喽

#### 序列化和反序列化

经过以上步骤，我们就可以初始化DynamicMessage对象了，然后就可以调用它的toByteArray()方法序列化发给客户端的数据；调用它的静态方法parseFrom()反序列化客户端发过来的消息了
