package ctgu.jagent;

import java.io.File;
import java.io.FileOutputStream;
import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.IllegalClassFormatException;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;

public class CustomAgent implements ClassFileTransformer {

	public static void premain(String agentArgs, Instrumentation inst) {
		inst.addTransformer(new CustomAgent());
	}

	public byte[] transform(ClassLoader loader, String className, Class<?> classBeingRedefined,
			ProtectionDomain protectionDomain, byte[] classfileBuffer) throws IllegalClassFormatException {
		if (!className.startsWith("java") && !className.startsWith("sun")) {
			int lastIndexOf = className.lastIndexOf("/") + 1;
			String fileName = className.substring(lastIndexOf) + ".class";
			exportClassToFile("F:/code/", fileName, classfileBuffer);

			System.out.println(className + "---> EXPORT SUCCESS!");

		}

		return classfileBuffer;
	}

	private void exportClassToFile(String dirPath, String fileName, byte[] data) {
		try {
			File file = new File(dirPath + fileName);
			if (!file.exists()) {
				file.createNewFile();
			}

			FileOutputStream fos = new FileOutputStream(file);
			fos.write(data);
			fos.close();
		} catch (Exception e) {
			System.out.println("exception occured while doing some file operation");
			e.printStackTrace();
		}
	}
}
