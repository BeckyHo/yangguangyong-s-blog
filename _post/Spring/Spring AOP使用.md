#### 使用场景

Spring AOP在处理非业务逻辑时很实用，比如

* 调用方法前后的日志记录
* 权限查询
* 错误处理
* 懒加载

#### 实现原理
采用动态代理方式实现

#### AOP中常用术语
先介绍Spring AOP中常用的术语，有助于之后对AOP的理解：
* 切面(Aspect): 横切关注点(跨越应用程序多个模块的功能)被模块化的特殊对象
* 通知(Advice): 切面必须要完成的工作
* 目标(Target): 被通知的对象
* 代理(Proxy): 向目标对象应用通知之后创建的对象
* 连接点(Joinpoint): 程序执行的某个特定位置，如类某个方法调用前，调用后，方法抛出异常后等
* 切点(Pointcut): 每个类都拥有多个连接点，即连接点是程序类中客观存在的事务

#### Spring中AOP的使用表现形式--5种通知
AOP也就是面向切面编程，它可以在我们想要调用的某个方法前后做一些特殊化的操作，具体表现分为5中通知，分别是:
* 前置通知---@Before
* 后置通知---@After
* 返回通知---@AfterReturning
* 异常通知---@AfterThrowing
* 环绕通知---@Around

#### 使用这些通知的步骤
1. 把横切关注点的代码抽象到切面的类中；切面首先是一个IOC中的bean, 即加入@Component注解，切面还需要加入@Aspect注解
2. 在切面类中声明各种通知，比如在一个方法前加入@Before注解
3. 在配置文件中加入如下配置，它让AspectJ注解起作用，自动为匹配的类生成代理对象<aop:aspectj-autoproxy></aop:aspectj-autoproxy>

#### 几种使用介绍
前置通知： 在目标方法开始之前执行
    @Aspect
    @Component
    public class LoggingAspect {
      @Before("execution(public int com.taobao.trip.BtripApprove.add(int, int))")
      public void beforeMethod(JoinPoint joinPoint) {
          // 在目标方法之前做的操作
      }
    }

后置通知：在目标方法执行后(无论是否发生异常)执行的通知, 注解为@After. 在后置通知中还不能访问目标方法执行的结果
    @Aspect
    @Component
    public class LoggingAspect {
      @After("execution(public int com.taobao.trip.BtripApprove.add(int, int))")
      public void beforeMethod(JoinPoint joinPoint) {
          // 在目标方法之后做的操作
      }
    }
返回通知：在方法征程结束后执行的代码, 返回通知是可以访问到方法的返回值的
异常通知：在目标方法出现异常时会执行的代码, 可以访问到异常对象, 且可以指定在出现特定异常时在执行通知代码
环绕通知：环绕通知需要携带ProceedingJoinPoint类型的参数, 它类似于动态代理的全过程. ProceedingJoinPoint类型的参数可以决定是否执行目标方法, 且环绕通知必须有返回值, 返回值即为目标方法的返回值

#### 几种通知在动态代理invoke方法中的位置
    public Object invoke(Object proxy, Method method, Object[] args) {
      try {
        // 前置通知
        result = method.invoke(target, args);
        // 返回通知
      } catch(Exception e) {
        e.printStackTrace();
        // 异常通知
      }
      
      // 后置通知
    }
