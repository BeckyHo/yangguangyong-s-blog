### Spring IoC 源码解析

目录:

* IoC 族
    * bean的定义
    * bean的读取器
* IoC容器的初始化
    * 资源设置和初始化解析器
    * bean加载过程
    * bean装配过程
    * 将bean注册到IoC容器中

#### IoC 族

Spring bean的创建是典型的工厂模式，这一系列的bean工厂为开发者管理对象间的依赖关系提供了很多便利和基础服务，
在Spring中有许多的IoC容器实现供用户选择和使用，其相互关系如下:

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/08/ioc01.png)

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

已经介绍了IoC容器，那么由IoC容器管理的bean在Spring中又是如何表示的了？

##### bean的定义

bean族的关系如下:

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/08/ioc02.png)

###### AttributeAccessor & AttributeAccessorSupport

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

###### BeanMetadataElement

BeanMetadataElement接口定义了可以获取配置文件资源的方法

* Object getSource();

###### BeanMetadataAttributeAccessor

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

###### BeanDefinition

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

###### AbstractBeanDefinition

AbstractBeanDefinition抽象类继承BeanMetadataAttributeAccessor，实现BeanDefinition接口. 也就是说，
我们在BeanDefinition中为bean定义的这些方法，在该类中都得到了默认的实现，比如:

    @Override
    public String getScope() {
        return this.scope; // 返回了scope属性
    }

    @Override
    public void setDependsOn(String[] dependsOn) {
        this.dependsOn = dependsOn; // 将该bean依赖的bean名称以String[]数组传入
    }

从该类中可知，它定义了一些属性，用来保存xml中配置的bean属性值，同时这些属性值也有默认值

###### RootBeanDefinition

RootBeanDefinition直接继承了AbstractBeanDefinition，官方API介绍:

> root bean 的定义代表运行在beanfactory中合并后的定义. 它可能继承多个已经定义好的bean, Spring2.5之后
> bean注册由GenericBeanDefinition代替. root bean 定义了一种运行时本质上是一致的bean

在xml中配置好了bean, IoC容器该如何解析这个xml了?

##### bean的读取器

bean的解析过程非常复杂，功能被分得很细，因为这里需要被扩展的地方很多，必须保证有足够的灵活性，以应对可能的变化。
bean的解析主要就是对spring配置文件的解析，这些解析类的关系如下:

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/08/ioc03.png)

###### BeanDefinitionReader

BeanDefinitionReader: 一个用来解析bean定义的简单接口，定义了两种加载bean的方法，传递Resource和String location参数两种方式

###### AbstractBeanDefinitionReader

AbstractBeanDefinitionReader: 实现了BeanDefinitionReader，EnvironmentCapable接口. 它提供通用的属性，比如bean factory的影响和class loader加载bean class的定义. 它的方法:

* public void setEnvironment(Environment environment);
* public int loadBeanDefinitions(Resource... resources);
* public int loadBeanDefinitions(String location);

可以根据Resource和String location加载指定的文件信息

EnvironmentCapable: 该接口表明组件所包含的Environment引用

###### BeanDefinitionDocumentReader

BeanDefinitionDocumentReader: 用来解析包含Spring bean定义的xml文件. 通常都会使用XmlBeanDefinitionReader类做真正的DOM文档解析. 它定义的方法有:

* void setEnvironment(Environment environment); // 设置读取bean定义的环境
* void registerBeanDefinitions(Document doc, XmlReaderContext readerContext); // 从给定的DOM中读取bean定义并将其注册到给定的reader context中

###### DefaultBeanDefinitionDocumentReader

DefaultBeanDefinitionDocumentReader: BeanDefinitionDocumentReader接口的默认实现. 根据spring-beans的DTD和XSD格式读取bean定义

###### XmlBeanDefinitionReader

XmlBeanDefinitionReader: 用来读取xml中定义的bean, 它定义了xml的校验规则

#### IoC容器的初始化

我们以ClassPathXmlApplicationContext为例来讲解IoC容器的初始化流程

##### 构造函数指定配置文件位置

    // 创建IoC容器, 从给定xml文件加载bean定义并自动刷新IoC容器
    public ClassPathXmlApplicationContext(String configLocation) throws BeansException {
        this(new String[]{configLocation}, true, null);  // 调用了另一个构造方法
    }

    // 根据指定的父IoC容器创建当前IoC容器, 并从给定xml文件中加载bean定义
    public ClassPathXmlApplicationContext(String[] configLocations, boolean refresh, ApplicationContext parent)
        throws BeansException {

        // 调用AbstractApplicationContext的构造方法设置父IoC容器
        super(parent);
        // 调用AbstractRefreshableConfigApplicationContext的setConfigLocations方法设置bean定义资源的文件路径
        setConfigLocations(configLocations);
        if(refresh) {
            // refresh
            refresh();
        }
    }

##### super(parent)方法

super(parent); 调用父容器方法设置bean资源解析器流程:

    // 被ClassPathXmlApplicationContext的构造方法调用
    public AbstractApplicationContext(ApplicationContext parent) {
        this();
        setParent(parent);
    }

    // 被设置父容器的构造方法调用
    public AbstractApplicationContext() {
        // 初始化资源解析类
        this.resourcePatternResolver = getResourcePatternResolver();
    }

    protected ResourcePatternResolver getResourcePatternResolver() {
        // AbstractApplicationContext继承了DefaultResourceLoader, 所以它是一个资源解析器
        // 它重写的getResource(String location)方法就是将我们配置的xml文件抓换为Resource对象
        return new PathMatchingResourcePatternResolver(this);
    }

    public PathMatchingResourcePatternResolver(ResourceLoader resourceLoader) {
        Assert.notNull(resourceLoader, "ResourceLoader must not be null");
        // 将当前ClassPathXmlApplicationContext对象作为资源解析器
        this.resourceLoader = resourceLoader;
    }

##### setConfigLocations(String[] locations)方法

setConfigLocations(String[] locations) 方法介绍

    public void setConfigLocations(String[] locations) {
        if(locations != null) {
            Assert.noNullElements(locations, "Config locations must not be null");
            this.configLocations = new String[locations.length];
            for(int i = 0; i < locations.length; i++) {
                // resolvePath()方法会将配置的路径转换为相对系统的路径, 比如相对于classpath的路径
                this.configLocations[i] = resolvePath(locations[i].trim());
            }
        } else {
            this.configLocations = null;
        }
    }

到此为止, Spring IoC容器已经指定好xml文件路径，初始化了xml文件解析类了. 下面接着看refresh方法
加载bean定义的流程.

##### refresh()方法

refresh()方法定义在父类AbstractApplicationContext中, 它定义了整个IoC容器对bean的加载解析过程

    @Override
    public void refresh() throws BeansException, IllegalStateException {
        synchronized (this.startupShutdownMonitor) {
            // 为容器刷新做准备, 设置刷新启动时间点, 激活容器标志位(flag = true), 执行属性初始化
            prepareRefresh();

            // 1. 更新IoC容器的bean factory, 如果已经存在beanFactory实例, 销毁它并重新创建一个beanFactory(DefaultListableBeanFactory)
            // 2. 配置beanFactory的一些特性, 比如是否允许bean定义重载, 是否允许循环引用
            // 3. 使用新创建的beanFactory赖在bean定义
            // 4. 返回新创建的beanFactory
            ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

            // 为beanFactory配置特性, 如类加载器, 事件处理器等
            prepareBeanFactory(beanFactory);

            try {
                // 为容器的某些子类指定特殊的bean post事件处理器
                postProcessBeanFactory(beanFactory);

                // 调用所有注册的beanfactorypostprocessor的bean
                invokeBeanFactoryPostProcessors(beanFactory);

                // 为bean factory注册bean post事件处理器
                // bean post processor是bean的后置处理器, 用于监听容器触发的事件
                registerBeanPostProcessors(beanFactory);

                // 初始化信息源, 和国际化有关
                initMessageSource();

                // 初始化容器事件传播器
                initApplicationEventMulticaster();

                // 调用子类bean的某些特殊方法
                onRefresh();

                // 为事件传播器注册事件监听器
                registerListeners();

                // 初始化所有剩余的单例bean
                finishBeanFactoryInitialization(beanFactory);

                // 初始化容器的生命周期事件处理器, 并发布容器的生命周期事件
                finishRefresh();
            } catch (BeansException ex) {
                // 销毁单例bean
                destroyBeans();
                // 取消refresh操作, 重置容器的flag标志
                cancelRefresh(ex);
                throw ex;
            }
        }
    }

##### refresh->obtainFreshBeanFactory()

refresh()方法调用了obtainFreshBeanFactory()方法, 跟进去:

    protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
        // 更新beanFactory, 加载定义的bean
        refreshBeanFactory();
        // 返回上一步创建的beanFactory
        ConfigurableListableBeanFactory beanFactory = getBeanFactory();
        if(logger.isDebugEnabled()) {
            logger.debug("Bean factory for " + getDisplayName() + ": " + beanFactory);
        }

        return beanFactory;
    }

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()

调用了子类AbstractRefreshableApplicationContext的refreshBeanFactory()方法实现，跟进去:

    @Override
    protected final void refreshBeanFactory() throws BeansException {
        // 检查beanFactory对象是否为null
        if(hasBeanFactory()) {
            // 如果已经存在beanFactory, 则先销毁IoC容器所有的beans
            destoryBeans();
            // 关闭beanFactory, 即 this.beanFactory = null;
            closeBeanFactory();
        }
        try {
            // 创建一个新的beanFactory
            DefaultListableBeanFactory beanFactory = createBeanFactory();
            // 设置beanFactory的序列化ID
            beanFactory.setSerializationId(getId());
            // 自定义beanFactory的特性. 如bean定义是否可以重写, 是否可以循环引用
            customizeBeanFactory(beanFactory);
            // 加载bean定义, 由AbstractXmlApplicationContext实现
            loadBeanDefinitions(beanFactory);
            synchronized(this.beanFactoryMonitor) {
                // 将新创建的beanFactory作为当前的beanFactory
                this.beanFactory = beanFactory;
            }
        } catch(IOException ex) {
            throw new ApplicationContextException("I/O error parsing bean definition source for " + getDisplayName(), ex);
        }
    }

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()->loadBeanDefinitions()

loadBeanDefinitions(DefaultListableBeanFactory beanFactory)在子类AbstractXmlApplicationContext中实现, 跟进去:

    @Override
    protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
        // 创建 bean定义读取器读取bean定义;
        // 初始化AbstractBeanDefinitionReader的resourceLoader = new PathMatchingResourcePatternResolver();
        // 初始化 environment = new StandardEnvironment();
        XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);

        beanDefinitionReader.setEnvironment(this.getEnvironment());
        // 自己作为资源解析器
        beanDefinitionReader.setResourceLoader(this);
        // 为bean读取器设置xml SAX解析器
        beanDefinitionReader.setEntityResolver(new ResourceEntityResolver(this));

        // 当bean读取器读取xml中定义的bean时, 启用xml校验机制
        initBeanDefinitionReader(beanDefinitionReader);
        // bean读取器加载bean定义
        loadBeanDefinitions(beanDefinitionReader);
    }

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()->loadBeanDefinitions()-> ...

调用了loadBeanDefinitions(XmlBeanDefinitionReader reader)方法, 跟进去:

    protected void loadBeanDefinitions(XmlBeanDefinitionReader reader) throws BeansException, IOException {
        // 该方法默认返回null数组
        Resource[] configResources = getConfigResources();
        if(configResources != null) {
            reader.loadBeanDefinitions(configResources);
        }
        // 在ClassPathXmlApplicationContext的构造方法中就已经设置好了xml文件路径, 所以直接取出来
        String[] configLocations = getConfigLocations();
        if(configLocations != null) {
            // 调用AbstractBeanDefinitionReader中定义的方法
            reader.loadBeanDefinitions(configLocations);
        }
    }

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()->loadBeanDefinitions()-> ...

bean读取器XmlBeanDefinitionReader调用了父类AbstractBeanDefinitionReader定义的方法, 跟进去:

    @Override
    public int loadBeanDefinitions(String... locations) throws BeanDefinitionStoreException {
        Assert.notNull(locations, "Location array must not be null");
        int counter = 0;
        for(String location : locations) {
            // 调用另一个重载的loadBeanDefinitions()方法
            counter += loadBeanDefinitions(location);
        }

        return counter;
    }

    @Override
    public int loadBeanDefinitions(String location) throws BeanDefinitionStoreException {
        return loadBeanDefinitions(location, null);
    }

    public int loadBeanDefinitions(String location, Set<Resource> actualResources) throws BeanDefinitionStoreException {
    	// 得到当前资源解析器, 由 PathMatchingResourcePatternResolver 实现
        ResourceLoader resourceLoader = getResourceLoader();
		if (resourceLoader == null) {
			throw new BeanDefinitionStoreException(
					"Cannot import bean definitions from location [" + location + "]: no ResourceLoader available");
		}

        // PathMatchingResourcePatternResolver 是 ResourcePatternResolver的实现类
		if (resourceLoader instanceof ResourcePatternResolver) {
			// Resource pattern matching available.
			try {
                // 使用PathMathing匹配配置文件路径, 如果配置
                // 以classpath: 开头, 返回一个ClassPathResource对象; 否则返回UrlResource对象
				Resource[] resources = ((ResourcePatternResolver) resourceLoader).getResources(location);
				// 加载封装在Resource中配置的bean
                int loadCount = loadBeanDefinitions(resources);
				if (actualResources != null) {
					for (Resource resource : resources) {
						actualResources.add(resource);
					}
				}
				if (logger.isDebugEnabled()) {
					logger.debug("Loaded " + loadCount + " bean definitions from location pattern [" + location + "]");
				}
				return loadCount;
			}
			catch (IOException ex) {
				throw new BeanDefinitionStoreException(
						"Could not resolve bean definition resource pattern [" + location + "]", ex);
			}
		}
		else {
			// Can only load single resources by absolute URL.
			Resource resource = resourceLoader.getResource(location);
			int loadCount = loadBeanDefinitions(resource);
			if (actualResources != null) {
				actualResources.add(resource);
			}
			if (logger.isDebugEnabled()) {
				logger.debug("Loaded " + loadCount + " bean definitions from location [" + location + "]");
			}
			return loadCount;
		}
	}

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()->loadBeanDefinitions()-> ...

loadBeanDefinitions(Resource... resources)方法, 跟进去:

    @Override
    public int loadBeanDefinitions(Resource... resources) throws BeanDefinitionStoreException {
        Assert.notNull(resources, "Resource array must not be null");
        int counter = 0;
        for(Resource resource : resources) {
            counter += loadBeanDefinitions(resource);
        }
        return counter;
    }

loadBeanDefinitions(Resource resource)在XmlBeanDefinitionReader中定义, 跟进去:

    @Override
    public int loadBeanDefinitions(Resource resource) throws BeanDefinitionStoreException {
        return loadBeanDefinitions(new EncodedResource(resource));
    }

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()->loadBeanDefinitions()-> ...

进入loadBeanDefinitions(EncodedResource encodedResource)方法:

    public int loadBeanDefinitions(EncodedResource encodedResource) throws BeanDefinitionStoreException {
    	Assert.notNull(encodedResource, "EncodedResource must not be null");
		if (logger.isInfoEnabled()) {
			logger.info("Loading XML bean definitions from " + encodedResource.getResource());
		}

        // 从ThreadLocal中得到它维护的Set集合
		Set<EncodedResource> currentResources = this.resourcesCurrentlyBeingLoaded.get();
		if (currentResources == null) {
			currentResources = new HashSet<EncodedResource>(4);
			this.resourcesCurrentlyBeingLoaded.set(currentResources);
		}
        // 如果该xml文件已经被添加到Set集合中, 抛出异常, 程序结束
        // 即每个配置文件只能被解析一次
		if (!currentResources.add(encodedResource)) {
			throw new BeanDefinitionStoreException(
					"Detected cyclic loading of " + encodedResource + " - check your import definitions!");
		}
		try {
            // 得到与该文件关联的输入流
			InputStream inputStream = encodedResource.getResource().getInputStream();
			try {
                // 生成该xml实体的 inputsource实例
				InputSource inputSource = new InputSource(inputStream);
				if (encodedResource.getEncoding() != null) {
                    // 设置编码, 防止乱码
					inputSource.setEncoding(encodedResource.getEncoding());
				}
                // 加载bean定义, 跟进去
				return doLoadBeanDefinitions(inputSource, encodedResource.getResource());
			}
			finally {
				inputStream.close();
			}
		}
		catch (IOException ex) {
			throw new BeanDefinitionStoreException(
					"IOException parsing XML document from " + encodedResource.getResource(), ex);
		}
		finally {
			currentResources.remove(encodedResource);
			if (currentResources.isEmpty()) {
				this.resourcesCurrentlyBeingLoaded.remove();
			}
		}
	}

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()->loadBeanDefinitions()-> ...->doLoadBeanDefinitions()

doLoadBeanDefinitions(InputSource inputSource, Resource resource)方法, 跟进去:

    protected int doLoadBeanDefinitions(InputSource inputSource, Resource resource)
    		throws BeanDefinitionStoreException {
		try {
            // 根据inputSource和resource属性生成xml文件的Document对象
			Document doc = doLoadDocument(inputSource, resource);
            // 调用父类定义好的register方法将Document对象注册到 reader context中
			return registerBeanDefinitions(doc, resource);
		}
		catch (BeanDefinitionStoreException ex) {
			throw ex;
		}
		catch (SAXParseException ex) {
			throw new XmlBeanDefinitionStoreException(resource.getDescription(),
					"Line " + ex.getLineNumber() + " in XML document from " + resource + " is invalid", ex);
		}
		catch (SAXException ex) {
			throw new XmlBeanDefinitionStoreException(resource.getDescription(),
					"XML document from " + resource + " is invalid", ex);
		}
		catch (ParserConfigurationException ex) {
			throw new BeanDefinitionStoreException(resource.getDescription(),
					"Parser configuration exception parsing XML from " + resource, ex);
		}
		catch (IOException ex) {
			throw new BeanDefinitionStoreException(resource.getDescription(),
					"IOException parsing XML document from " + resource, ex);
		}
		catch (Throwable ex) {
			throw new BeanDefinitionStoreException(resource.getDescription(),
					"Unexpected exception parsing XML document from " + resource, ex);
		}
	}

##### refresh->obtainFreshBeanFactory()->refreshBeanFactory()->loadBeanDefinitions()-> ...->doLoadBeanDefinitions()->registerBeanDefinitions()

进入registerBeanDefinitions(Document doc, Resource resource)方法中:

    public int registerBeanDefinitions(Document doc, Resource resource) throws BeanDefinitionStoreException {
    	BeanDefinitionDocumentReader documentReader = createBeanDefinitionDocumentReader();
		// 设置xml文件读取环境
        documentReader.setEnvironment(this.getEnvironment());
        // 得到当前DefaultListableBeanFactory维护的bean个数
        // 它用一个Map维护这定义的bean实例
		int countBefore = getRegistry().getBeanDefinitionCount();
        // 将xml中定义的bean 注册到XmlReaderContext中
		documentReader.registerBeanDefinitions(doc, createReaderContext(resource));
		return getRegistry().getBeanDefinitionCount() - countBefore;
	}

registerBeanDefinitions(Document doc, XmlReaderContext readerContext)实现, 跟进去:

    @Override
    public void registerBeanDefinitions(Document doc, XmlReaderContext readerContext) {
		this.readerContext = readerContext;
		logger.debug("Loading bean definitions");
        // 得到<beans></beans>结点
		Element root = doc.getDocumentElement();
        // 解析<beans></bean>结点中定义的bean
		doRegisterBeanDefinitions(root);
	}

##### ...

doRegisterBeanDefinitions(Element root)方法, 跟进去:

    protected void doRegisterBeanDefinitions(Element root) {
        // 得到<beans />结点中配置 name="profile"的属性值
    	String profileSpec = root.getAttribute(PROFILE_ATTRIBUTE);
        // 如果profile配置了属性值且设置了environment属性值, 直接抛异常
		if (StringUtils.hasText(profileSpec)) {
			Assert.state(this.environment != null, "Environment must be set for evaluating profiles");
			String[] specifiedProfiles = StringUtils.tokenizeToStringArray(
					profileSpec, BeanDefinitionParserDelegate.MULTI_VALUE_ATTRIBUTE_DELIMITERS);
			// 否则验证这些profile是否有效. 如果无效直接返回
            if (!this.environment.acceptsProfiles(specifiedProfiles)) {
				return;
			}
		}

		// Any nested <beans> elements will cause recursion in this method. In
		// order to propagate and preserve <beans> default-* attributes correctly,
		// keep track of the current (parent) delegate, which may be null. Create
		// the new (child) delegate with a reference to the parent for fallback purposes,
		// then ultimately reset this.delegate back to its original (parent) reference.
		// this behavior emulates a stack of delegates without actually necessitating one.
        BeanDefinitionParserDelegate parent = this.delegate;
        // 创建用于解析xml定义的状态委托类
		this.delegate = createDelegate(this.readerContext, root, parent);

		preProcessXml(root);
		parseBeanDefinitions(root, this.delegate);
		postProcessXml(root);

		this.delegate = parent;
	}

##### ...

状态委托类BeanDefinitionParserDelegate创建方法 createDelegate()实现:

    protected BeanDefinitionParserDelegate createDelegate(
    		XmlReaderContext readerContext, Element root, BeanDefinitionParserDelegate parentDelegate) {

		BeanDefinitionParserDelegate delegate = new BeanDefinitionParserDelegate(readerContext, this.environment);
		// 这里做了一些初始化操作, 比如 lazy-init, autowire, dependency 检查设置
        // 如果原来的DefaultBeanDefinitionDocumentReader中有 BeanDefinitionParserDelegate
        // 对象，则使用它的默认值， 否则使用系统的默认值, 这些值保存在DocumentDefaultsDefinition对象中(lazyInit, autowire, initMethod, destoryMethod等属性)
        delegate.initDefaults(root, parentDelegate);
		return delegate;
	}

创建并初始化好BeanDefinitionParserDelegate类后, 开始解析 <beans /> 标签

* preProcessXml(root); 目前该方法什么也没做
* parseBeanDefinitions(root, this.delegate); // 真正解析<beans />标签的地方
* postProcessXml(root); 该方法也什么都没做

parseBeanDefinitions(root, this.delegate)方法, 跟进去:

    // 解析根目录下的elements结点, 包括 "import", "alias", "bean"属性
    protected void parseBeanDefinitions(Element root, BeanDefinitionParserDelegate delegate) {
    	// 命名空间是否是默认的http://www.springframework.org/schema/beans, 也就是判断
        // 该结点是否是<beans />结点
        // 结点的命名空间属性是xmlns, 位于元素的开始标签中
        if (delegate.isDefaultNamespace(root)) {
            // 获取<beans />标签下定义的所有结点
			NodeList nl = root.getChildNodes();
			for (int i = 0; i < nl.getLength(); i++) {
				Node node = nl.item(i);
                // 如果该结点是Element结点, 也就是说该结点中配置有属性
				if (node instanceof Element) {
					Element ele = (Element) node;
                    // 判断该结点是否是<beans />结点
					if (delegate.isDefaultNamespace(ele)) {
                        // 是<beans />根结点
						parseDefaultElement(ele, delegate);
					}
					else {
                        // 不是<beans />根结点
						delegate.parseCustomElement(ele);
					}
				}
			}
		}
		else {
			delegate.parseCustomElement(root);
		}
	}

我们先看不是<beans />根结点的处理方式, 跟进去parseCustomElement(Element ele)方法

    public BeanDefinition parseCustomElement(Element ele) {
        return parseCustomElement(ele, null);
    }

parseCustomElement(Element ele, BeanDefinition containingBd)方法, 跟进去:

    public BeanDefinition parseCustomElement(Element ele, BeanDefinition containingBd) {
    	String namespaceUri = getNamespaceURI(ele);
        // 根据结点的命名空间名得到对应的命名空间处理类(xsd文件)
		NamespaceHandler handler = this.readerContext.getNamespaceHandlerResolver().resolve(namespaceUri);
		if (handler == null) {
            // 如果找不到对应的处理类, 报错
			error("Unable to locate Spring NamespaceHandler for XML schema namespace [" + namespaceUri + "]", ele);
			return null;
		}
        // 使用xsd文件验证用户配置的bean是否符合规范, 然后读取配置属性值
		return handler.parse(ele, new ParserContext(this.readerContext, this, containingBd));
	}

parse()方法在NamespaceHandlerSupport中实现, 跟进去:

    @Override
    public BeanDefinition parse(Element element, ParserContext parserContext) {
		return findParserForElement(element, parserContext).parse(element, parserContext);
	}

    private BeanDefinitionParser findParserForElement(Element element, ParserContext parserContext) {
    	String localName = parserContext.getDelegate().getLocalName(element);
		BeanDefinitionParser parser = this.parsers.get(localName);
		if (parser == null) {
			parserContext.getReaderContext().fatal(
					"Cannot locate BeanDefinitionParser for element [" + localName + "]", element);
		}
		return parser;
	}

从已经注册的map中根据结点名得到对应的bean解析器 BeanDefinitionParser. 没看到解析bean的代码？？

如果是默认的命名空间, 调用parseDefaultElement(ele, delegate)方法

    private void parseDefaultElement(Element ele, BeanDefinitionParserDelegate delegate) {
    	// 根据结点名称调用不同的方法解析结点
        if (delegate.nodeNameEquals(ele, IMPORT_ELEMENT)) {
			importBeanDefinitionResource(ele);
		}
		else if (delegate.nodeNameEquals(ele, ALIAS_ELEMENT)) {
			processAliasRegistration(ele);
		}
		else if (delegate.nodeNameEquals(ele, BEAN_ELEMENT)) {
			processBeanDefinition(ele, delegate);
		}
		else if (delegate.nodeNameEquals(ele, NESTED_BEANS_ELEMENT)) {
			// recurse
			doRegisterBeanDefinitions(ele);
		}
	}

我们关心的<bean> 结点，调用了processBeanDefinition(ele, delegate)方法, 跟进去:

    protected void processBeanDefinition(Element ele, BeanDefinitionParserDelegate delegate) {
    	// 根据<bean />结点的id, name属性创建AbstractBeanDefinition对象, 它持有BeanDefinition的引用
        // 生成的AbstractBeanDefinition其实是它的子类GenericBeanDefinition, 它设置了
        // bean的父类和className属性值(用于反射生成bean实例). 同时设置了bean的修饰符
        // 解析bean的元属性, 寻找重写的方法, 解析bean的<constructor-arg />结点, 解析bean的<property />结点等操作
        // 然后将表示bean的GenericBeanDefinition封装到BeanDefinitionHolder中并返回
        BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele);
		if (bdHolder != null) {
			bdHolder = delegate.decorateBeanDefinitionIfRequired(ele, bdHolder);
			try {
				// 最后将表示bean的BeanDefinition以 id <--> bean对象的方式注册到DefaultListableBeanFactory的
                // beanDefinitionMap属性中(一个Map对象), 完成IoC容器对bean的装配
				BeanDefinitionReaderUtils.registerBeanDefinition(bdHolder, getReaderContext().getRegistry());
			}
			catch (BeanDefinitionStoreException ex) {
				getReaderContext().error("Failed to register bean definition with name '" +
						bdHolder.getBeanName() + "'", ele, ex);
			}
			// Send registration event.
			getReaderContext().fireComponentRegistered(new BeanComponentDefinition(bdHolder));
		}
	}
