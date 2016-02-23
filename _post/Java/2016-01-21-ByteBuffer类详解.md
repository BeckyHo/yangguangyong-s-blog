### ByteBuffer类详解

**ByteBuffer的实现/继承关系**

> ByteBuffer是一个抽象类，它继承Buffer，实现Comparable接口；它的具体实现类有
> HeapByteBuffer和DirectByteBuffer，其中ByteBuffer的allocate(int capacity)
> 方法返回 HeapByteBuffer，而allocateDirect(int capacity)方法返回
> DirectByteBuffer；
>
> HeapByteBufferR/DirectByteBufferR分别继承HeapByteBuffer/DirectByteBuffer，
> 这两个子类维护的buffer内容是只读的。

**Buffer的三个参数介绍**

* capacity: 表示Buffer能够存储的元素上限，capacity不能为负且不会改变
* limit: 是Buffer中第一个不能读取或写入的元素下标，也就是说读写操作的下标不能大于或等于limit，limit不能为负且不会大于capacity
* position:是Buffer中第一个可读或可写入的元素下标，操作过程中position总是指向下一个将要读取或写入的元素下标，position不能为负且不会大于或等于limit

**三个属性的关系为：0<= position <= limit <= capacity**

除了定义在Buffer中的三个属性，还有存储数据的byte[] hb数组，纪录某一瞬间状态的
mark属性和偏移量offset。mark定义在Buffer中，hb数组和offset偏移量定义在
ByteBuffer中。

**ByteBuffer的创建**

`allocate(int capacity)初始化ByteBuffer流程`

    public static ByteBuffer allocate(int capacity) {
        if(capacity < 0)
        throw new IllegalArgumentException();
        return new HeapByteBuffer(capacity, capacity);
    }

    HeapByteBuffer(int cap, int lim) {
        super(-1, 0, lim, cap, new byte[cap], 0);
    }

    ByteBuffer(int mark, int pos, int lim, int cap, byte[] hb, int offset) {
        super(mark, pos, lim, cap);
        this.hb = hb;
        this.offset;
    }

    Buffer(int mark, int pos, int lim, int cap) {
        if(cap < 0)
            throw new IllegalArgumentException("Negative capacity: " + cap);
        this.capacity = cap;
        limit(lin);
        position(pos);
        if(mark >= 0) {
            if(mark > pos)
                throw new IllegalArgumentException("mark > position: (" + mark + " > " + pos + ") ");
        this.mark = mark;
        }
    }

以上就是通过allocate(int capacity)初始化ByteBuffer流程，初始化后mark = -1, position = 0, limit = capacity,
    hb = new byte[capacity],offset = 0

`wrap(byte[] array)通过已有的byte数组创建ByteBuffer`

    public static ByteBuffer wrap(byte[] array) {
        return wrap(array, 0, array.length);
    }

    public static ByteBuffer wrap(byte[] array, int offset, int length) {
        try {
            return new HeapByteBuffer(array, offset, length);
        } catch(IllegalArgumentException x) {
            throw new IndexOutOfBoundsException();
        }
    }

    HeapByteBuffer(byte[] buf, int off, int len) {
        super(-1, off, off + len, buf.length, buf, 0);
    }

    ByteBuffer(int mark, int pos, int lim, int cap, byte[] hb, int offset) {
        super(mark, pos, lim, cap);
        this.hb = hb;
        this.offset = offset;
    }

使用wrap()方式最终调用方法和allocate()是一样的，只不过前者是我们传递byte数组，后者是自己new一个byte数组。

***读写操作put(byte b)和get()***

`put(byte b)流程`

    ByteBuffer b = ByteBuffer.allocate(15);
    b.put((byte) 1); // 执行流程如下

    public ByteBuffer put(byte x) {
        hb[ix(nextPutIndex())] = x;
        return this;
    }

    nextPutIndex()方法实现
    final int nextPutIndex() {
        if(position >= limit)
            throw new BufferOverflowException();
        return position++;
    }

首先检查position的值是否越界，如果越界就抛异常；然后返回当前position值在执行position++来指向下一次存储元素的下标。

    ix()方法实现
    protected int ix(int i) {
        return i + offset;
    }

因为offset的初始值是0，所以这个方法相当于返回position目前的值，offset的作用在缓冲区分片中体现出来。

**由以上可知，put(byte x)方法是在当前position的位置上存储元素x，所以每调用一次 put方法，position的值都要+1来指向下一次存储元素的下标；当position的值超过limit时，抛出异常，put方法执行失败。**

***byte get()流程***

    public byte get() {
        return hb[ix(nextGetIndex())];
    }

    final int nextGetIndex() {
        if(position >= limit)
            throw new BufferUnderflowException();
        return position++;
    }

与nextPutIndex()方法实现一样，都要先检查当前position的值是否正确，position>=limit抛异常，get失败；否则返回position，在执行position++操作，指向下一次将要获取的元素的下标。

不管是put还是get,它们都是从当前position下标开始操作的。所以说，当我们刚执行完put操作，想要从hb数组中读取元素时，需要将position的值设置为0，表示从头开始读取刚才put的值。那就需要调用flip()方法来实现读写之间的转换了。

除了flip()方法可以修改position值外，还有clear()和rewind()方法。

***flip()方法实现***

    public final Buffer flip() {
        limit = position;
        position = 0;
        mark = -1;
        return this;
    }

flip()方法设置limit等于当前position值并将position设置为0，清除标志位mark。这使得我们在读取hb数组中数据时只会读取到有效的数据。

***clear()方法***

    public final Buffer clear() {
        position = 0;
        limit = capacity;
        mark = -1;
        return this;
    }

clear()方法就是讲所有的属性值清除并恢复到刚初始化前的状态。

***rewind()方法***

    public final Buffer rewind() {
        position = 0;
        mark = -1;
        return this;
    }

rewind()方法将position置0，清空mark。在管道执行write或get操作之前调用该方法，假设limit已经被正确的设置。

**复制缓冲区**

方法：public ByteBuffer duplicate();实现代码如下

    public ByteBuffer duplicate() {
        return new HeapByteBuffer(hb, this.markValue(), this.position(),                   this.limit(), this.capacity(), offset);
    }

从实现代码可知，新的buffer和原来的buffer共享同一个buffer数组，在原buffer中修改数据会在新的buffer中得到体现。但是它们各自维护着自己的mark, position, limit, capacity和offset属性。

***缓冲区分片***

    public ByteBuffer slice() {
        return new HeapByteBuffer(hb, -1, 0, this.remaining(),
            this.remaining(), this.position() + offset);
    }

缓冲区分片就是在现有的缓冲区中，创建新的子缓冲区，子缓冲区和父缓冲区共享数据，但它们各自维护自己的mark, position, limit和capacity。注意，此时子缓冲区的开始下
标应该是父缓冲区此时的position + offset，如果此时父缓冲区的position=2,那么子缓
冲区在共享数据中的下标就是从2开始；因为每次put/get操作都返回offset + position。
这时offset的作用就体现出来了。

***只读缓冲区***

    public ByteBuffer asReadOnlyBuffer() {
        return new HeapByteBufferR(hb, this.markValue(), this.position(),                  this.limit(), this.capacity(), offset);
    }

注意此时不在是new HeapByteBuffer，而是HeapByteBufferR，多了一个R，表示它维护的缓冲区是只读的。新缓冲区和原来的缓冲区共享相同的数据，但不能通过HeapByteBufferR往缓冲区中增加数据，此时如果调用put(byte b)方法会抛出异常，看看它的put方法实现

    public ByteBuffer put(byte x) {
        throw new ReadOnlyBufferException();
    }
直接抛出异常。
