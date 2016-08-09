### Spring在Web项目中启动流程分析

#### 描述

前提: 在web.xml中添加如下配置

    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>

查看API可知，ContextLoaderListener继承ContextLoader类，实现ServletContextListener接口.

ServletContextListener是ServletContext类的监听器，当ServletContext初始化时会调用contextInitialized()方法，
ServletContext销毁时会调用contextDestroyed()方法. 这里让ContextLoaderListener实现ServletContextListener接口的
目的就是让Spring IoC容器随着ServletContext的初始化而初始化，ServletContext的销毁而销毁，并且我们会把
初始化的Ioc容器存储到ServletContext的属性中，这样在整个web项目中我们就可以使用Spring的Ioc容器了

#### 代码流程

ServletContext初始化时，调用ContextLoaderListener的contextInitialized(ServletContextEvent event)方法


    // Initialize the root web application context.
    @Override
    public void contextInitialized(ServletContextEvent event) {
        initWebApplicationContext(event.getServletContext());
    }

跟进去

    // 根据给定的contextClass和contextConfigLocation初始化web应用程序上下文(Ioc容器)
    public WebApplicationContext initWebApplicationContext(ServletContext servletContext) {
        // 先判断servletContext属性中是否已经存在IoC容器，如果存在，抛异常
    	if (servletContext.getAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE) != null) {
			throw new IllegalStateException(
					"Cannot initialize context because there is already a root application context present - " +
					"check whether you have multiple ContextLoader* definitions in your web.xml!");
		}

		Log logger = LogFactory.getLog(ContextLoader.class);
		servletContext.log("Initializing Spring root WebApplicationContext");
		if (logger.isInfoEnabled()) {
			logger.info("Root WebApplicationContext: initialization started");
		}
        // 记录初始化开始时间
		long startTime = System.currentTimeMillis();

		try {
			// Store context in local instance variable, to guarantee that
			// it is available on ServletContext shutdown.
            // private WebApplicationContext context 的声明
			if (this.context == null) {
                // 根据配置的contextClass属性名初始化一个IoC容器，如果未指定，就
                // 使用默认的WebApplicationContext类，使用反射生成IoC容器的实例
				this.context = createWebApplicationContext(servletContext);
			}
            // 返回的就是一个ConfigurableWebApplicationContext对象，它继承了WebApplicationContext接口
			if (this.context instanceof ConfigurableWebApplicationContext) {
				ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) this.context;
                // 刚初始化的IoC容器 active = false 表明还没有refresh
				if (!cwac.isActive()) {
					// The context has not yet been refreshed -> provide services such as
					// setting the parent context, setting the application context id, etc
					if (cwac.getParent() == null) {
						// The context instance was injected without an explicit parent ->
						// determine parent for root web application context, if any.
                        // 设置IoC容器的父IoC容器
						ApplicationContext parent = loadParentContext(servletContext);
						cwac.setParent(parent);
					}
                    // 初始化了IoC容器，接下来就是解析XML中配置的信息了(包括bean定义等)
					configureAndRefreshWebApplicationContext(cwac, servletContext);
				}
			}
            // 将该IoC容器保存到servlet上下文的属性中，这样就可以在web程序中访问到IoC容器，也就是Spring中配置的bean了
			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, this.context);

			ClassLoader ccl = Thread.currentThread().getContextClassLoader();
			if (ccl == ContextLoader.class.getClassLoader()) {
				currentContext = this.context;
			}
			else if (ccl != null) {
                // 将classloader和IoC容器映射到map中
				currentContextPerThread.put(ccl, this.context);
			}

			if (logger.isDebugEnabled()) {
				logger.debug("Published root WebApplicationContext as ServletContext attribute with name [" +
						WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE + "]");
			}
			if (logger.isInfoEnabled()) {
				long elapsedTime = System.currentTimeMillis() - startTime;
				logger.info("Root WebApplicationContext: initialization completed in " + elapsedTime + " ms");
			}
            // 返回IoC容器实例
			return this.context;
		}
		catch (RuntimeException ex) {
			logger.error("Context initialization failed", ex);
			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, ex);
			throw ex;
		}
		catch (Error err) {
			logger.error("Context initialization failed", err);
			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, err);
			throw err;
		}
	}

上面初始化IoC容器步骤中最重要的调用: configureAndRefreshWebApplicationContext(cwac, servletContext); 跟进去

    protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac, ServletContext sc) {
    	if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
			// The application context id is still set to its original default value
			// -> assign a more useful id based on available information
			String idParam = sc.getInitParameter(CONTEXT_ID_PARAM);
            // 设置IoC容器的ID
			if (idParam != null) {
				wac.setId(idParam);
			}
			else {
				// Generate default id...
				wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
						ObjectUtils.getDisplayString(sc.getContextPath()));
			}
		}

        // IoC容器中持有Servlet上下文引用
		wac.setServletContext(sc);
        // 得到配置的XML文件路径
		String initParameter = sc.getInitParameter(CONFIG_LOCATION_PARAM);
		if (initParameter != null) {
			wac.setConfigLocation(initParameter);
		}
        // 做一些初始化的配置
		customizeContext(sc, wac);
        // 加载并初始化XML配置
		wac.refresh();
	}

refresh()方法，跟进去

    @Override
    public void refresh() throws BeansException, IllegalStateException {
		synchronized (this.startupShutdownMonitor) {
			// Prepare this context for refreshing.
            // refresh前的准备, 记录开始时间和设置 active = true
			prepareRefresh();

			// Tell the subclass to refresh the internal bean factory.
			ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

			// Prepare the bean factory for use in this context.
			prepareBeanFactory(beanFactory);

			try {
				// Allows post-processing of the bean factory in context subclasses.
				postProcessBeanFactory(beanFactory);

				// Invoke factory processors registered as beans in the context.
				invokeBeanFactoryPostProcessors(beanFactory);

				// Register bean processors that intercept bean creation.
				registerBeanPostProcessors(beanFactory);

				// Initialize message source for this context.
				initMessageSource();

				// Initialize event multicaster for this context.
				initApplicationEventMulticaster();

				// Initialize other special beans in specific context subclasses.
				onRefresh();

				// Check for listener beans and register them.
				registerListeners();

				// Instantiate all remaining (non-lazy-init) singletons.
				finishBeanFactoryInitialization(beanFactory);

				// Last step: publish corresponding event.
				finishRefresh();
			}

			catch (BeansException ex) {
				// Destroy already created singletons to avoid dangling resources.
				destroyBeans();

				// Reset 'active' flag.
				cancelRefresh(ex);

				// Propagate exception to caller.
				throw ex;
			}
		}
	}

refresh()方法中就是加载xml，解析bean，完成bean的创建，注册到IoC容器等步骤。
