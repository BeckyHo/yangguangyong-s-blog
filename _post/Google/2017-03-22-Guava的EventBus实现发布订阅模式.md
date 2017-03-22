### Guava的EventBus实现发布订阅模式

> 这个月在项目中使用了Guava完成方法埋点（统计方法调用次数，业务埋点等）。体会到了Guava框架思想的强大，今天做个笔记记录

#### Guava介绍
Guava是一个Google基于JDK1.6类库集合的扩展项目，包括collections, caching, primitives support, concurrency libraries, common annotations, string processing, I/O等。这些高质量的API可以使你的Java代码更加优雅，更加简洁，让你工作更加轻松愉快。

#### EventBus方法调用次数监控实现

观察者模式实现一个类的方法监控

    public class MonitorManager {
		// 管理观察者
		private static Map<Pair<L, R>, Set<Class>> monitorHut = Maps.newHashMap();
		private static EventBus eventBus = new EventBus();
		
		// 注册一个订阅者，它的subscriber方法将会接收到事件
		@PostConstruct
		private void init() {
			eventBus.register(this);
		}
		
		// 订阅者接收到事件后，该方法将被调用
		@Subscribe
		public void handle(Event event) {
			// 通知观察者，它观察的方法被执行；达到埋点与业务代码解耦
		}
		
		// 给所有注册的订阅者推送一件事件，本例中handle方法将会被调用
		public void post(Event event) {
			eventBus.post(event);
		}
		
		// 观察者注册
		public static void register(String k1, String k2, Class<? extends Monitor> monitorType) {
			if(null == k1 || null == k2 || null == monitorType) {
				return;
			}
			
			Pair key = Pair.of(k1, k2);
			if(!monitorHut.containsKey(key)) {
				monitorHut.put(key, Sets.newHashSet());
			}
			monitorHut.get(key).add(monitorType);
		}
	}

	// 观察者实现
    public abstract class Monitor {
		
		public Monitor() {
			MonitorManager.register(getK1(), getK2(), this.getClass());
		}
		
		public abstract String getK1();
		
		public abstract String getK2();
		
		public abstract void monitor(Event event);
	}

	public class TestMonitor extends Monitor {
		public String getK1() {
			return "k1";
		}
		
		public String getK2() {
			return "k2";
		}
		
		public void monitor() {
			// 埋点逻辑处理
		}
	}

    // 测试类
	public class Test {
		// 使用AOP环绕通知在调用方法时将这个事件抛给MonitorManager
		public void hello() {
			// do something
		}
	}

比如现在我想要监控Test类的hello()方法调用次数，我只需要声明一个环绕通知，并将该事件抛给MonitorManager，让其调用post()方法，这样， TestMonitor的monitor方法就会得到调用。

以上只讲解了大致思路
