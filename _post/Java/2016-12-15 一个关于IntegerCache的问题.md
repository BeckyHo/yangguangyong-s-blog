#### 问题描述
在一个方法内定义两个局部变量int a = 10; int b = 20; 要求调用method1()方法后，在原来方法中打印a和b，输出 a=100, b=200

    public static void main(String[] args) {
      int a = 10;
      int b = 20;
      method1(a, b);
      
      System.out.println("a="+a);  // 输出a=100
      System.out.println("b="+b);  // 输出b=200
    }
    
    private static void method1(int a, int b) {
      // 补充代码
    }

昨晚想了一晚上，实在想不出来怎么补充代码。如果是在c/c++中，直接传递变量的地址过来就可以改变变量的值，但是在java中不能传递原声数据类型的地址，怎么办了？今天在网上找了下答案，哈哈，找到了，现在做个总结。

#### 问题分析
想要让之后的输出打印a=100, b=200, 如果在变量上不能下手，那么想想在输出流上动手脚吧。System.setOut()方法可以重新分配输出流，放弃原来的标准输出流；我们重写新输出流的println方法并做点改变，即可达到我们的目的，比如：

    public static void method1(int a, int b) {
      System.setOut(new PrintStream(System.out, true){
        @Override
        public void println(String x) {
          super.println(x+'0');
        }            
      });
    }

在method1方法中为当前jvm重新分配了标准输出流，当调用System.out.println("a="+a)时，其实是在字符串"a=10"后面拼接一个0，也就是"a=100"，所以最终会输出a=100
___

还有一种解法，利用常量池。

要利用常量池，那么输出方法也需要做改变，不能使用println()，需要使用printf("%d", a)方法，思路如下: 使用printf("%d", a)打印a，会调用Integer的valueOf()方法将原声数据类型int转换为包装类Integer并打印，在转变过程中如果a>=-128且a<=127, 会用到Integer的常量池，也就是IntegerCache的cache属性。题目中a和b的大小都位于[-128, 127]之间，如果我们能修改常量池a, b对应下标的值，那么在使用printf("%d", a)打印a时，会打印cache中a对应下标的值，这不就可以了吗？哈哈，上代码：

    private static void method1(int a, int b) {
      Class cache = Integer.class.getDeclaredClasses()[0];
      Field c;
      try {
        // 获取Integer中定义的IntegerCache对象的Class
        c = cache.getDeclaredField("cache");
        c.setAccessible(true);
        // 得到IntegerCache中定义的cache，也就是我们所说的Integer常量池
        Integer[] array = (Integer[]) c.get(cache);

        /**
        * 常量池cache是个Integer数组，保存了-128到127之间的数字，cache[0] = -128
        * 由此可知cache[128] = 0. 那么10就是cache[138] = 100, 20就是cache[148] = 200
        **/
        array[138] = 100;
        array[148] = 200;         
      } cache(Exception e) {
        e.printStackTrace();                
      }
    }

这个时候，我们在调用System.out.printf("%d", 10); 会调用valueOf(10)方法，看看valueOf方法的实现：

    public static Integer valueOf(int i) {
      // low = -128, high = 127
      if( i >= IntegerCache.low && i <= IntegerCache.high) {
        return IntegerCache.cache[i + (-IntegerCache.low)];                
      }

      return new Integer(i);
    }
    
所以传10，会返回IntegerCache.cache[10 + 128] = IntegerCache.cache[138] = 100; 也就是我们刚刚修改的值喽。

___

其实还有一种做法，超级简单：

    private static void method1(int a, int b) {
      System.out.println("a="+100);
      System.out.println("b="+200);
      System.exit(0);
    }

怎么样，还不是会输出a=100, b=200; 没毛病吧，只有你想不到的，哈哈。
