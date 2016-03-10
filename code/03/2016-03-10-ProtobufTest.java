import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

public class ProtobufTest {

  public static void main(String[] args) throws IOException {
    // 按照定义的数据结构，初始化一个Person信息
    PersonMsg.Person.Builder builder = PersonMsg.Person.newBuilder();
    builder.setId(1);
    builder.setName("HelloWorld");
    builder.setEmail("xiaoyi9210@126.com");
    builder.addFriends("Friend A");
    builder.addFriends("Friend B");
    PersonMsg.Person serialPerson = builder.build();

    // 将数据写到输出流，如网络输出流，这里就用ByteArrayOutputStream来代替
    // 将数据序列化后发送
    ByteArrayOutputStream byteOutput = new ByteArrayOutputStream();
    serialPerson.writeTo(byteOutput);

    // 将数据接收后反序列化
     byte[] byteArray = byteOutput.toByteArray();
     ByteArrayInputStream byteInput = new ByteArrayInputStream(byteArray);
     PersonMsg.Person desePerson = PersonMsg.Person.parseFrom(byteInput);

     System.out.println("id: " + desePerson.getId());
     System.out.println("name: " + desePerson.getName());
     System.out.println("email: " + desePerson.getEmail());
     System.out.print("friends: ");
     List<String> friends = desePerson.getFriendsList();
     for (String friend : friends) {
         System.out.print(friend + ", ");
     }
  }
}
