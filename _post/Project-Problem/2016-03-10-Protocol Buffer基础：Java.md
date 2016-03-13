### Protocol Buffer基础: Java

__原文来自[官网](https://developers.google.com/protocol-buffers/docs/javatutorial#advanced-usage)__

本教程给Java程序员提供基本的关于protocol buffer使用步骤。通过该教程的简单示例程序，让你知道：
* 如何在.proto文件中定义消息格式
* 使用protocol buffer编译
* 使用Java的protocol buffer API读写消息

本教程不会全面的指导你如何使用protocol buffer. 更多细节参考信息，点击[Protocol Buffer Language Guide](https://developers.google.com/protocol-buffers/docs/proto), 还有[Java API Reference](https://developers.google.com/protocol-buffers/docs/reference/java/index.html), [Java Generated Code Guide](https://developers.google.com/protocol-buffers/docs/reference/java-generated)和[Encoding Reference](https://developers.google.com/protocol-buffers/docs/encoding)

#### 为什么使用Protocol Buffer

我们接下来使用一个非常简单的“addressbook(通讯薄)”示例，它可以从文件中读取人员的详细联系方式，也可以将修改的数据写入该文件中。每个人在addressbook中有name, ID, email address和phone number这几个属性

你该如何序列化和获得这种结构化的数据了？下面有一些解决方法：
* 使用Java序列化。这应该是默认的使用方法了，但它有许多众所周知的问题，并且当你要把数据分享给C++或Python等其他语言时，这种方式性能不是很好
* 你也可以发明一种专门序列化数据为字符串的方法————比如把4编译成“12：3：-23：67”字符串。这是简单且很灵活的方法，尽管它需要一次性编码和解析代码
* 序列化数据到XML中。这种方法是非常有吸引力的因为XML对于人类来说可读性非常高，并且有许多语言提供了构建XML的库。然而，众所周知，XML对空间的要求非常高，且在编码/解码过程性能不是很好。还有，操作一个XML DOM树显然比操作单个类更复杂

Protocol buffers是灵活的，高效的，自动化解决该问题。使用protocol buffers, 你需要编写.proto文件来描述你想要存储的数据结构。然后，protocol buffer编译器会创建一个类，该类实现了自动编码和解析protocol buffers的二进制格式的数据。生成的类为属性提供了getter/setter方法来组成了protocol buffer并且更加关心读写细节，此时它把protocol buffer的读写操作看作一个单元。更重要的是，protocol buffer格式支持继承以前的格式，也就是说，现在的代码照样可以从以前的格式中读取数据

#### 在哪里找到示例代码

示例代码在源代码包里，在“examples”目录下，[Download in here](https://developers.google.com/protocol-buffers/docs/downloads.html)

#### 定义Protocol数据格式

要创建你的address book应用程序，首先你必须从.proto文件开始。定义.proto文件是很简单的：你添加想要序列化的 message 数据结构，然后指定名称和message属性的类型。这里给出.proto文件定义你的message, addressbook.proto

    package tutorial;

    option java_package = "com.example.tutorial";
    option java_outer_classname = "AddressBookProtos";

    message Person {
        required string name = 1;
        required int32 id = 2;
        optional string email = 3;

        enum PhoneType {
            MOBILE = 0;
            HOME = 1;
            WORK = 2;
        }

        message PhoneNumber {
            required string number = 1;
            optional PhoneType type = 2 [default = HOME];
        }

        repeated PhoneNumber phone = 4;
    }

    message AddressBook {
        repeated Person person = 1;
    }

正如你所看到的，它的语法和C++或Java很像。让我们看看文件的每个部分是什么。

.proto文件以package声明开始，这有效防止不同项目之间的命名冲突。在Java中，package被用作Java包，除非你明确指定一个java package, 比如我们这里。即使你提供了java package, 你也应该定义一个正常的package来避免protocol buffer中的命名冲突。

声明了package之后，你可以看到两个Java specific选项：java_package和java_outer_classname. java_package指定你的Java代码的package,也就是存放生成的java代码。如果你没有明确的指定，它的默认值就是package的值. java_outer_classname选项定义了包含该文件下的所有类。如果你不指定java_outer_classname，它将由文件名生成。例如，“my_proto.proto”默认使用MyProto作为生成的类名称。

也就是说，package是防止protocol buffer命名冲突的； java_package相当于java程序中的package,如果你不指定，默认值就是前面的package; java_outer_classname就是生成的Java类名称

接下来，你可以定义你的message. 一个message包括很多属性。有很多标准简单数据类型可以作为属性的类型，包括bool, int32, float, double和string.你也可以自己定义一个message的数据类型并让该类型作为另一个message的属性类型————例如上面的Person Message包含了PhoneNumber message, 同时AddressBook message包含Person message.你可以定义message中嵌套其他的message————就像上面看到的，PhoneNumber类型定义在Person中。如果你的属性值已经预先确定为某些值时，你可以定义enum类型来列举这些值————上面例子你想要指定你的phone number是MOBILE, HOME或WORK之一

每个元素后面的"=1"， "=2"标识是属性在二进制编码中唯一的“tag”.Tag号码在1～15之间编码时要求至少高于数字一个字节，作为最优解你可以一般地使用这些Tag.每个repeated的属性需要从编码这些Tag号码， 所以repeated修饰的属性通常是最优解的候选人

每个属性必须要使用以下之一来修饰：
* required: 属性的值必须要提供，否则消息会被认为是"uninitialized". 尝试构建一个uninitialized消息将会抛出RuntimeException异常。解析一个uninitialized消息将会抛出IOException异常。除了这些，required修饰的属性与optional属性一样
* optional: 属性可以设置值，也可以不设置值。如果optional属性的值没有设置，那就会使用一个默认值。对于那些简单的类型，你可以执行你期望的默认值，就像我们给phone number type属性设置的默认值那样。否则，系统将会给它指定默认值:数字类型的属性默认值是0，string类型是空字符串， bool是false.对于内嵌的message,默认值总是"default instance"或者"prototype", 这种message没有任何属性。如果optional属性没有明确的设置值，调用属性的get方法总是返回属性的默认值
* repeated: 该属性可能会重复任何次数（包括0次）。属性值的重复出现顺序将会被保存在protcol buffer中。就像一个动态的数组中元素是重复的一样

在这里你将会找到如何完整的编写.proto文件的教程————包括所有可能的属性类型，[点击这里](https://developers.google.com/protocol-buffers/docs/proto).

#### 编译Protcol Buffers

现在你有了.proto文件，下一步你需要做的是生成类来读写AddressBook消息。为了生成类，你需要在.proto文件目录下运行protocol buffer编译器 protoc：

* 如果你没有安装编译器，[点击下载](https://developers.google.com/protocol-buffers/docs/downloads.html)并读取README
* 现在运行编译器，指定源文件目录（就是你应用程序代码的地方，如果你不指定，那么就是用当前目录），目标目录（就是你存放生成的代码，通常都是用$SRC_DIR），还有.proto文件的路径

这次示例中，你可以这样做...

   protoc -I=$SRC_DIR -- java\_out=$DST_DIR $SRC_DIR/addressbook.proto

因为你想要Java类，你使用了 --java_out 选项

这会在你指定的目标路径中生成com/example/tutorial/AddresBookProtos.java

#### Pritocol Buffer API

让我们找找生成的代码，看看编译器给你生成的类和方法。打开AddressBookProtos.java，你可以看到它定义类名为AddressBookProtos, 符合我们在addressbook.proto中定义的。每个类有自己的Builder类，使用它可以创建自己的实例。在下面的Builders vs Messages章节里你可以发现更多关于builders的定义

messages和builders都会为message中的每个属性生成getter或setter方法；messages只有getter方法，但builders既有getter，也有setter.下面给出Person类的一些访问属性的方法：

    // required string name = 1;
    public boolean hasName();
    public String getName();

    // required int32 id = 2;
    public boolean hasId();
    public int getId();

    // optional string email = 3;
    public boolean hasEmail();
    public String getEmail();

    // repeated .tutorial.Person.PhoneNumber phone = 4;
    public List<PhoneNumber> getPhoneList();
    public int getPhoneCount();
    public PhoneNumber getPhone(int index);

同时，Person.Builder也有getter和setter

    // required string name = 1;
    public boolean hasName();
    public java.lang.String getName();
    public Builder setName(String value);
    public Builder clearName();

    // required int32 id = 2;
    public boolean hasId();
    public int getId();
    public Builder setId(int value);
    public Builder clearId();

    // optional string email = 3;
    public boolean hasEmail();
    public String getEmail();
    public Builder setEmail(String value);
    public Builder clearEmail();

    // repeated .tutorial.Person.PhoneNumber phone = 4;
    public List<PhoneNumber> getPhoneList();
    public int getPhoneCount();
    public PhoneNumber getPhone(int index);
    public Builder setPhone(int index, PhoneNumber value);
    public Builder addPhone(PhoneNumber value);
    public Builder addAllPhone(Iterable<PhoneNumber> value);
    public Builder clearPhone();

上面的代码风格和JavaBean为每个属性生成getter/setter的风格很像。每个属性都有getter方法，当属性被设置值时has方法会返回true. 最后，每个属性还有clear方法，如果属性值没有被设置那么会返回空的状态值。

repeated修饰的属性会有额外的方法————Count方法（就是返回列表长度的简写）， getter和setter方法可以在列表的任意下标获得指定的元素值，add方法会添加新的元素到列表中，addAll方法会添加其他容器的所有元素到这个列表中。

注意这些访问属性的方法是用的是骆驼命名规则（当方法名包括多个单词时，每个单词的首字母要大写），尽管.proto文件是用小写字符和下划线组成的。这个转变过程由protocol buffer的编译器自动转换，所以生成的类符合标准java代码风格。在.proto文件的属性名应该尽量只使用小写字符和下划线；这样在生成的代码中会确保有好的名称。点击[style guide](https://developers.google.com/protocol-buffers/docs/style)查看更多关于如何编写符合规范的.proto文件

想知道更多关于protocol buffer编译器生成准确的属性定义，点击[Java generated code reference](https://developers.google.com/protocol-buffers/docs/reference/java-generated)

#### 枚举和内部类

生成的Person代码内嵌有PhoneType枚举类型：

    public static enum PhoneType {
        MOBILE(0, 0),
        HOME(1, 1),
        WORK(2, 2),
        ;
        ...
    }

内部类Person.PhoneNumber如你所愿，他被自动生成在Person中了。

#### Builders vs Messages

由protocol buffer编译器生成的message类内容是不变的。一旦message对象被创建，它是不能被修改的，就像Java中的String对象。要创建message, 首先你要先构建builder, 设置任何你想要设置的属性值，然后调用builders的buid()生成message对象。

你也许已经注意到builder的每个修改message的方法都会返回另一个builder对象。返回的builder对象其实与你调用方法的builder对象是同一个builder.这种返回的好处是你可以在一行代码中调用好几个setter方法，就像StringBuilder的append()方法一样。

下面给出示例教你如何创建Person对象：

    Person john =
        Person.newBuilder()
            .setId(1234)
            .setName("John Doe")
            .setEmail("jdoe@example.com")
            .addPhone(
                Person.PhoneNumber.newBuilder()
                    .setNumber("555-4321")
                    .setType(Person.PhoneType.HOME))
            .build();

#### 标准Message方法

每个message和builder类都包括一系列的方法来检查或操作所有的message,这些方法包括：
* isInitialized(): 检查是否所有required修饰的属性已经设置了值
* toString(): 返回人们易读的message，这在debug模式时特别有用
* mergeFrom(Message other): (builder仅有的)当前message的内容和其他message的内容合并，required/optional修饰的属性被重写，repeated修饰的属性相当于几何的或操作
* clear(): (builder仅有的)清除所有的属性值，回到空状态

以上方法实现Message和Message.Builder接口，并被messages和builders使用。想要知道更多信息，可以点击[complete API documentation for Message](https://developers.google.com/protocol-buffers/docs/reference/java/com/google/protobuf/Message)

#### 序列化和反序列化（Parsing and Serialization）

最后，每个protocol buffer类都有方法读写message二进制格式数据，这些方法包括：

* byte[] toByteArray(): 序列化message并返回包含原始字节的byte数组
* static Person parseFrom(byte[] data): 从给定的byte数组中解析message
* void writeTo(OutputStream output): 序列化消息并将其写入OutputStream
* static Person parseFrom(InputStream input): 从InputStream中读取message

以上提供了两对方法来解析和序列化message. 想要更多的解析和序列化方法对，可以点击[Message API reference](https://developers.google.com/protocol-buffers/docs/reference/java/com/google/protobuf/Message)查看完整方法列表

#### 写数据(Writing A Message)

现在，让我们尝试使用你的protocol buffer类。你想要你的address book应用程序做的第一件事就是写入个人信息到你的addressbook文件中。为了能写入数据，你需要创建并设置protocol buffer类的属性值，然后将它们写入输出流（outputstream）.

下面给出的程序示例是从文件中读取AddressBook对象，然后添加一个新的Person到这个AddressBook对象中，并把修改的AddressBook数据回写入文件中。下面的代码中由protocol buffer编译器生成的代码是突出显示的：

import com.example.tutorial.AddressBookProtos.AddressBook;
import com.example.tutorial.AddressBookProtos.Person;
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.PrintStream;

class AddPerson {
  // This function fills in a Person message based on user input.
  static Person PromptForAddress(BufferedReader stdin,
                                 PrintStream stdout) throws IOException {
    Person.Builder person = Person.newBuilder();

    stdout.print("Enter person ID: ");
    person.setId(Integer.valueOf(stdin.readLine()));

    stdout.print("Enter name: ");
    person.setName(stdin.readLine());

    stdout.print("Enter email address (blank for none): ");
    String email = stdin.readLine();
    if (email.length() > 0) {
      person.setEmail(email);
    }
while (true) {
      stdout.print("Enter a phone number (or leave blank to finish): ");
      String number = stdin.readLine();
      if (number.length() == 0) {
        break;
      }

      Person.PhoneNumber.Builder phoneNumber =
        Person.PhoneNumber.newBuilder().setNumber(number);

      stdout.print("Is this a mobile, home, or work phone? ");
      String type = stdin.readLine();
      if (type.equals("mobile")) {
        phoneNumber.setType(Person.PhoneType.MOBILE);
      } else if (type.equals("home")) {
        phoneNumber.setType(Person.PhoneType.HOME);
      } else if (type.equals("work")) {
        phoneNumber.setType(Person.PhoneType.WORK);
      } else {
        stdout.println("Unknown phone type.  Using default.");
      }

      person.addPhone(phoneNumber);
    }

    return person.build();
  }
// Main function:  Reads the entire address book from a file,
  //   adds one person based on user input, then writes it back out to the same
  //   file.
  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("Usage:  AddPerson ADDRESS_BOOK_FILE");
      System.exit(-1);
    }

    AddressBook.Builder addressBook = AddressBook.newBuilder();

    // Read the existing address book.
    try {
      addressBook.mergeFrom(new FileInputStream(args[0]));
    } catch (FileNotFoundException e) {
      System.out.println(args[0] + ": File not found.  Creating a new file.");
    }

    // Add an address.
    addressBook.addPerson(
      PromptForAddress(new BufferedReader(new InputStreamReader(System.in)),
                       System.out));

    // Write the new address book back to disk.
    FileOutputStream output = new FileOutputStream(args[0]);
    addressBook.build().writeTo(output);
    output.close();
  }
}

#### 读数据(Reading A Message)

当然，如果你从来不使用addressbook中的信息那么这个通讯薄就没用了！下面的示例读取被上面代码创建的数据并将所有信息打印出来：

import com.example.tutorial.AddressBookProtos.AddressBook;
import com.example.tutorial.AddressBookProtos.Person;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.PrintStream;

class ListPeople {
  // Iterates though all people in the AddressBook and prints info about them.
  static void Print(AddressBook addressBook) {
    for (Person person: addressBook.getPersonList()) {
      System.out.println("Person ID: " + person.getId());
      System.out.println("  Name: " + person.getName());
      if (person.hasEmail()) {
        System.out.println("  E-mail address: " + person.getEmail());
      }

      for (Person.PhoneNumber phoneNumber : person.getPhoneList()) {
        switch (phoneNumber.getType()) {
          case MOBILE:
            System.out.print("  Mobile phone #: ");
            break;
          case HOME:
            System.out.print("  Home phone #: ");
            break;
          case WORK:
            System.out.print("  Work phone #: ");
            break;
        }
        System.out.println(phoneNumber.getNumber());
      }
    }
}

  // Main function:  Reads the entire address book from a file and prints all
  //   the information inside.
  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("Usage:  ListPeople ADDRESS_BOOK_FILE");
      System.exit(-1);
    }

    // Read the existing address book.
    AddressBook addressBook =
      AddressBook.parseFrom(new FileInputStream(args[0]));

    Print(addressBook);
  }
}

#### 扩展Protocol Buffer(Extending a Protocol Buffer)

当你发布你操作protocol buffer代码之后，你早晚会想要优化protocol buffer的定义。如果你想要你的new buffers向后兼容，或者你的old buffers向前兼容————你必须确定这样做，下面给出一些新版本的protocol buffer规则你需要去遵守：
* 你不可以改变已经存在的属性下标
* 你不可以添加或删除任何required修饰的属性
* 你可以删除optional或repeated修饰的属性
* 你可以添加新的optional或repeated修饰的属性，但是你必须使用新的下标（意思是这些下标从来没有在protocol buffer中使用过，即使是已经删除了的属性使用过的下标）

对于这些规则这里有一些[特殊情况](https://developers.google.com/protocol-buffers/docs/proto.html#updating)，不过这些情况很少使用。

如果你遵守这些规则，old code将会很高兴的读取新message并忽略任何新的属性。对于old code, 被删除的optional属性将会给它们一个默认值， 而repeated的属性将会是空列表（或者空数组，空集合等）。new code也会很好的读取old message. 但是请注意，新的optional属性在old message中是不存在的，所以你需要使用has_方法明确的检查下他们是否被set，或者是否在.proto文件的下标后使用[ default = value ]提供了默认值.如果没有给optional属性提供默认值，那么前面讲过的属性类型默认值将会被使用；对于string, 它的默认值是空字符串. 而booleas，它的默认值是false. 对于数值类型，默认值是0. 记住如果你新增了repeated属性，在new code中没有方法确定这个repeated属性是否为空，或者是否被设置了属性？因为它没有has_方法

#### 高级用法(Advanced Usage)

除了提供getter/setter方法和序列化外，protocol buffer还有很更好的用处。想要找打其他有用的用法你可以访问[Java API reference](https://developers.google.com/protocol-buffers/docs/reference/java/index.html)

一旦key在protocol message类中被使用，你可以使用迭代器（iterate）来操作这些属性值而不用往指定的类型中写入值。这是很有用的方式来使用反射从protocol buffer转换或者转变为其他格式，比如XML，或者JSON. 反射更先进的用法可能是找出两个message中相同的type属性的不同，或者开发一种正则表达式protocol buffer message, 这样你就可以根据编写的正则表达式来匹配message内容。使用你的想象力，来使得protocol buffer更加的被广泛使用

反射在Message和Message.Builder接口中提供
