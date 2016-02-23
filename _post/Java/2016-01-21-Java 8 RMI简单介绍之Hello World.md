### 本教程介绍如何使用Java RMI构造经典的分布式Hello World应用程序，当你读完本教程之后，你可能会提出一系列问题，你可以在[这里](https://docs.oracle.com/javase/8/docs/technotes/guides/rmi/faq.html)找到答案。

分布式Hello World例子中，客户端远程调用运行在另一台远程主机的服务器端方法，客户端将收到来自服务器端"Hello, workd!"的消息。

本教程包括以下步骤：
* 如何定义远程接口
* 服务器端的实现
* 客户端的实现
* 编译源文件
* 开启Java RMI注册表（registry），启动服务器端，运行客户端

本教程需要的示例代码：

1. [Hello.java](https://docs.oracle.com/javase/8/docs/technotes/guides/rmi/hello/Hello.java)   ------远程接口

2. [Server.java](https://docs.oracle.com/javase/8/docs/technotes/guides/rmi/hello/Server.java) ------实现远程接口的远程对象

3. [Client.java](https://docs.oracle.com/javase/8/docs/technotes/guides/rmi/hello/Client.java)  ------客户端的实现，调用远程接口方法

**注意：本教程剩下的篇幅中，`远程对象的实现`和`远程类`都是指`example.hello.Server`这个实现了远程接口的类。**

### 如何定义远程接口
远程类实现了远程接口。远程接口需要继承`java.rmi.Remote`接口并声明一套远程方法。远程方法除了抛出执行的异常之外，还需要在throws语句后面添加java.rmi.RemoteException异常（或者RemoteException的父类）。下面给出本教程定义的远程接口类example.hello.Hello。它只有一个远程方法sayHello，该方法返回字符串给调用者。


    package example.hello;

    import java.rmi.Remote;
    import java.rmi.RemoteException;

    public interface Hello extends Remote {
        public String sayHello() throws RemoteException;
    }

与本地方法调用相比，远程方法可能会由于很多原因导致失败（比如网络连接或者服务器端的问题），此时，远程方法将错误信息通过java.rmi.RemoteException抛出。

### 服务器端的实现
要实现Java rmi，服务器端实现类需要有一个main方法创建`远程类`实例，导出远程对象，在Java RMI注册表（registry）中将一个名称与该对象绑定在一起。包含这个main方法的类可能会实现自身，或者是其他类。

在这次示例中，服务器端的main方法定义在Server类中，同时它是实现了远程接口Hello，服务器端的main方法做了如下操作：
* 创建并导出远程对象
* 在Java RMI注册表（registry）中注册远程对象（就是绑定一个名称与该远程接口在一起）

下面是Server的代码，它描述了服务器端类需要遵循的代码模块：


    package example.hello;

    import java.rmi.registry.LocateRegistry;
    import java.rmi.registry.Registry;
    import java.rmi.server.UnicastRemoteObject;

    public class Server implements Hello {

        public Server() {
        }

        @Override
        public String sayHello() {
            return "Hello, world!";
        }

        public static void main(String args[]) {
            try {
                Server obj = new Server();
                Hello stub = (Hello) UnicastRemoteObject.exportObject(obj, 0);

                // Bind the remote object's stub in the registry
                Registry registry = LocateRegistry.getRegistry();
                registry.bind("Hello", stub);

                System.err.println("Server ready");
            } catch (Exception e) {
                System.err.println("Server exception: " + e.toString());
                e.printStackTrace();
            }
        }
    }

实现类Server实现了远程接口Hello，重写了远程方法sayHello。sayHello方法不用抛出任何异常，因为该方法不会抛出RemoteException异常，也不会抛出其他异常。
**注意：除了重写远程方法外，实现类还可以定义其他的方法，但是这些方法只能被本地虚拟机调用而不能被远程调用。**

### 创建并保存远程对象
服务器的main方法需要创建远程对象来提供远程服务，此外，远程对象必须在运行时能被Java RMI导出来接受来自远程的调用。实现代码如下：

    Server obj = new Server();
    Hello stub = (Hello) UnicastRemoteObject.exportObject(obj, 0);

静态方法UnicastRemoteObject.exportObject导出的远程对象能够接受匿名客户端TCP端口的远程方法调用，它会返回远程对象的桩（stub）给客户端。由于exprotObject方法的调用，为了远程对象能接受来自远程的调用，程序需要监听一个新的套接字或者使用一个共享的服务器套接字来返回实现相同远程接口的远程对象桩（stub），它包含了主机名和端口号，以便远程对象能够连接远程方法。

**Java RMI注册表（registry）注册远程对象**

一个调用者（客户端程序）想要调用远程对象的方法，必须要获得远程对象的桩（stub）。Java RMI提供注册表（registry）接口使得应用程序能够将远程对象与一个key绑定；此时客户端通过这个key就能得到与它绑定在一起的远程对象的桩（stub）。Java RMI注册表（registry）是一个简单的名称服务注册表，它允许客户端得到远程对象（远程对象的存根）的桩，通常，注册表仅在本地第一次获取远程对象时使用。

一旦在服务器端注册了远程对象，客户端可以通过绑定的key获得远程对象的桩，然后调用远程对象上的方法。

下面展示如何在服务器端获得本机名和默认端口的注册表（registry）并从该注册表中获取和key绑定在一起的远程对象桩（stub）。

    Registry registry = LocateRegistry.getRegistry();
    registry.bind("Hello", stub);

### 客户端的实现
客户端通过在服务器端注册表（registry）中绑定的key获得远程对象的桩（stub，也就是远程对象的实例），然后调用远程对象的sayHello方法，下面是客户端的实现代码：


    package example.hello;

    import java.rmi.registry.LocateRegistry;
    import java.rmi.registry.Registry;

    public class Client {

        private Client() {
        }

        public static void main(String[] args) {

            String host = (args.length < 1) ? null : args[0];
            try {
                Registry registry = LocateRegistry.getRegistry(host);
                Hello stub = (Hello) registry.lookup("Hello");
                String response = stub.sayHello();
                System.out.println("response: " + response);
            } catch (Exception e) {
                System.err.println("Client exception: " + e.toString());
                e.printStackTrace();
            }
        }
    }

客户端第一次调用LocateRegistry.getRegistry方法时，它会根据映射的主机名（hosts，这个参数可以通过命令行来给）获得在该注册表中注册的key对应的远程对象的存根（stub）。当没有指定主机名（hosts）时，本地ip就是这个主机名。最后，客户端调用远程对象的sayHello方法，这会导致以下行为发生：
* 客户端开启连接连接到给定的ip和端口服务器并初始化需要调用的数据。
* 服务器端接受外来连接，调度调用者，序列化数据返回给客户端。
* 客户端收到数据，反序列化这些数据给调用者。

### 编译源文件
注意：我的代码是放在F:/code/目录下，以下命令用到目录需要注意。
1. 通过以下命令编译源代码

    javac -d destDir Hello.java Server.java Client.java

    destDir是存放class文件的目录，我编译时的命令：javac -d .`*`.java

2. 启动Java RMI注册表（registry）；Windows平台下的命令：`start rmiregistry`.

    默认情况下，注册表的端口号是1099，如果要使用其他的端口号，在命令后面添加即可，如start rmiregistry 2011；相应的代码中也要修改端口号。

3. 启动服务器；Windows平台命令：`start java -classpath classDir -Djava.rmi.server.codebase=file:classDir/ example.hello.Server`.

    `classDir`是class文件的根目录，我的classDir=F:/code
    服务器端启动成功会输出Server ready信息

4. 运行客户端；Windows平台命令：`java -classpath classDir example.hello.Client`.

    `classDir`是class文件的根目录

    此时，客户端会有以下信息输出：**response: Hello, Workd!**

### 原文链接，点击[这里](https://docs.oracle.com/javase/8/docs/technotes/guides/rmi/hello/hello-world.html)
