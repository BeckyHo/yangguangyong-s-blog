### Spring IoC 源码解析

目录:

* IoC 族
* IoC容器的初始化
    * 资源加载器和定位
    * bean加载过程
    * bean装配过程
    * IoC容器中注册bean
* IoC容器依赖注入
    * 从IoC容器中获取bean
    * 创建bean对象
    * 对bean对象属性依赖注入值

#### IoC族

Spring bean的创建是典型的工厂模式，这一系列的bean工厂为开发者管理对象间的依赖关系提供了很多便利和基础服务，
在Spring中有许多的IoC容器实现供用户选择和使用，其相互关系如下:

![ioc01]()

BeanFactory作为最顶层的接口，它定义了IoC容器的基本功能和规范，比如我们熟悉的以下方法

* Object getBean(String name) throws BeansException
* <T> T getBean(Class<T> requiredType) throws BeansException
* boolean containsBean(String name)
* boolean isSingleton(String name) throws NoSuchBeanDefinitionException

同时，为了扩展IoC容器的功能，BeanFactory有三个字接口:

* ListableBeanFactory: 表示这些bean是用列表管理的
* HierarchicalBeanFactory: 表示这些bean是有继承关系的，每个bean有可能会有父bean
* AutowireCapableBeanFactory: 定义了bean的创建，装配方法

这四个接口共同定义了IoC容器中bean的集合，bean之间的关系以及bean的行为.

BeanFactory只定义了IoC容器的基本行为，想要得到具体的对象，我们需要看具体IoC容器实现. Spring
提供了很多IoC容器的实现，如被放弃的XmlBeanFactory, 我们熟悉的ClassPathXmlApplicationContext,
FileSystemXmlApplicationContext等都是IoC容器的具体实现.

已经介绍了IoC容器，那么由IoC容器管理的bean在Spring中又是如何表示的了？ bean族的关系如下:

![ico02]()

AttributeAccessor接口定义了一组操作元素据的方法，比如:

* void setAttribute(String name, Object value)
* Object getAttribute(String name)
* Object removeAttribute(String name)
* boolean hasAttribute(String name)

key/value对的实现应该是基于Map实现的，果然，查看它的实现类AttributeAccessorSupport中维护一个Map对象

    private final Map<String, Object> attributes = new LinkedHashMap<String, Object>(0);

    // setAttribute()方法的实现
    @Override
    public void setAttribute(String name, Object value) {
        Assert.notNull(name, "Name must not be null");  // 判断name不能为null
        if(value != null) {
            this.attributes.put(name, value);
        } else {
            removeAttribute(name); // 将name的key删除掉
        }
    }

BeanMetadataElement接口定义了可以获取配置文件资源的方法

* Object getSource();

BeanMetadataAttributeAccessor实现了BeanMetadataElement接口，继承AttributeAccessorSupport。通过它的
方法可知，操作都是基于BeanMetadataAttribute对象，该对象定义如下:

    private final String name;
    private final Object value;
    private Object source;

除了维护一对key-value属性外，还维护一个Object对象，表示该key-value的来源，也就是该key-value是属于哪个对象的.
也就是说，通过BeanMetadataAttributeAccessor我们可以追踪到定义的数据源，看看它的方法:

    public void addMetadataAttribute(BeanMetadataAttribute attribute) {
        super.setAttribute(attribute.getName(), attribute);
    }

将该BeanMetadataAttribute对象保存到AttributeAccessorSupport的Map对象中

BeanDefinition继承AttributeAccessor, BeanMetadataElement. 也就是说，除了我们在它的两个父类
中定义的设置属性，获取属性，获取资源等方法外，BeanDefinition还增加了以下方法，比如:

* String getParentName(); // 获取父bean的名称.在IoC族中，我们说HierarchicalBeanFactory表明bean之间是有继承关系的，所以这里，如果bean有父bean，我们就可以得到父bean的名称
* void setBeanClassName(String beanClassName); // 设置bean的名称，该方法会覆盖之前bean的名称
* String getScope(); // 获取bean的范围. scope取值有prototype, singleton, session和request
* void setLazyInit(boolean lazyInit); // 设置bean的延迟加载
* void setDependsOn(String[] dependsOn); // 设置当前bean依赖的所有beans. 比如当前bean属性为另一个bean，所以它依赖其他的bean
* void setAutowireCandidate(boolean autowireCandidate);// 设置当前bean是否会被自动装配到其他bean中, 也就是其他bean依赖了它
* void setPrimary(boolean primary); // 该bean是否是java的8个原生类型之一(int, double等)
* boolean isSingleton(); // 该bean是否是单例的

从BeanDefinition提供的方法可知，这些方法返回的参数与我们在xml中对bean的属性设置几乎一一对应，也就是说: bean对象在Spring中是以BeanDefinition接口来描述的

AbstractBeanDefinition抽象类继承BeanMetadataAttributeAccessor，实现BeanDefinition接口. 也就是说，
我们在BeanDefinition中为bean定义的这些方法，这该类中都得到了默认的实现，比如:

    @Override
    public String getScope() {
        return this.scope; // 返回了scope属性
    }

    @Override
    public void setDependsOn(String[] dependsOn) {
        this.dependsOn = dependsOn; // 将该bean依赖的bean名称以String[]数组传入
    }

从该类中可知，它定义了一些属性，用来保存xml中配置的bean属性值，同时这些属性值也有默认值

RootBeanDefinition直接继承了AbstractBeanDefinition，官方API介绍:

> root bean 的定义代表运行在beanfactory中合并后的定义. 它可能继承多个已经定义好的bean, Spring2.5之后
> bean注册由GenericBeanDefinition代替. root bean 定义了一种运行时本质上是一致的bean

在xml中配置好了bean, IoC容器该如何解析这个xml了?

bean的解析过程非常复杂，功能被分得很细，因为这里需要被扩展的地方很多，必须保证有足够的灵活性，以应对可能的变化。
bean的解析主要就是对spring配置文件的解析，这些解析类的关系如下:

![ico03]()

BeanDefinitionReader: 一个用来解析bean定义的简单接口，定义了两种加载bean的方法，传递Resource和String location参数两种方式

AbstractBeanDefinitionReader: 实现了BeanDefinitionReader，EnvironmentCapable接口. 它提供通用的属性，比如bean factory的影响和class loader加载bean class的定义. 它的方法:

* public void setEnvironment(Environment environment);
* public int loadBeanDefinitions(Resource... resources);
* public int loadBeanDefinitions(String location);
