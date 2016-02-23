@@ -0,0 +1,114 @@
### 非阻塞Socket通信
本文通过ServerSocketChannel配合Selector实现非阻塞Socket通信。先介绍几个重要的概念：
* Server:接受请求的应用程序
* Client:发送请求到Server的应用程序
* SocketChannel:Client和Server通信的信道，它由服务器端IP地址和端口号所标识。SocketChannel使用Buffer来传输数据
* Selector:非阻塞通信中重要的对象，它监听已经注册的SocketChannel并序列化请求，找出满足要求的信道
* SelectionKey:Selector用来区分请求的对象，每个key代表一个客户端请求

客户端发送请求到服务器端，Selector筛选请求并创建对应的key，每个Selector实例可以监听很多套接字（Channel），当监听的Channel中有我们感兴趣的操作（比如客户端尝试连接，或者读写操作）发生时，Selector通知应用程序来处理这个请求。Selector会创建SelectionKey的实例，每个Key都持有应用程序的请求信息（包括请求类型）。请求类型有以下几种：
* 尝试连接(OP_CONNECT)
* 接收连接(OP_ACCEPT)
* 读/写操作(OP_READ/OP_WRITE)

服务器端读取消息实现模板代码如下：

    // Create the server socket channel
    ServerSocketChannel server = ServerSocketChannel.open();
    // set no blocking I/O
    server.configureBlocking(false);
    // host-port
    server.bind(new InetSocketAddress(host, port));
    // Create the selector
    Selector selector = Selector.open();
    // Recording server to selector(type: OP_ACCEPT)
    server.register(selector, SelectionKey.OP_ACCEPT);
    // Infinite loop
    while(true) {
    // Waiting for events
    selector.select();
    // Get keys
    Set<SelectionKey> keys = selector.selectedKeys();
    Iterator<SelectionKey> iter = keys.iterator();
    // For each keys
    while(iter.hasNext()) {
      SelectionKey sk = iter.next();
      // Remove the current key
      iter.remove();
      // a client required a connection
      if(sk.isAcceptable()) {
        // get client socket channel
        SocketChannel client = server.accept();
        // No blocking I/O
        client.configureBlocking(false);
        client.register(selector, SelectionKey.OP_READ);
        continue;
      }

      // the server is ready to read(or client has write something to channel)
      if(sk.isReadable()) {
        SocketChannel client = (SocketChannel)sk.channel();
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        int lenclient.read(buffer);
        if(len <= 0) {
          // end read operate....
          client.close();
        }
        buffer.flip();
        String tmp = new String(buffer.array(), 0, len);
        System.out.println(tmp);
      }
    }

客户端发送消息实现模板：

    // Create client SocketChannel
    SocketChannel client = SocketChannel.open();
    // no blocking I/O
    client.configureBlocking(false);
    // Connection to host-port
    client.connect(new InetSocketAddress(host, port));
    // Create selector
    Selector selector = Selector.open();
    // Record to selector(type:OP_CONNECT)
    client.register(selector, SelectionKey.OP_CONNECT);
    // Waiting for the connection
    while(running) {
    int count = selector.select(500);
    if(count == 0) {
      // no channel
      continue;
    }

    Set<SelectionKey> keys = selector.selectedKey();
    Iterator<SelectionKey> iter = keys.iterator();
    while(iter.hasNext) {
      SelectionKey sk = iter.next();
      // remove from ready set
      iter.remove();
      if(sk.isConnectable()) {
        SocketChannel client = (SocketChannel)sk.channel();
        // must have this step
        if(client.isCOnnectionPending()) {
          channel.finishConnect();
        }

        // When connect, the write operate have been ready
        // so, you can write data to channel
        ByteBuffer buffer = Bytebuffer.allocate(1024);
        Scanner scan = new Schanner(System.in);
        while(scan.hasNextLine()) {
          String tmp = scan.nextLine();
          // end judgment
          if(tmp == null || tmp.length() == 0){
            client.close();
            sk.cancel();
            break;
          }
          buffer.clear();
          buffer.put(tmp.getBytes());
          buffer.flip();
          client.write(buffer);
        }
      }
    }
