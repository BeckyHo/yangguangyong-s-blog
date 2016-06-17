### Spring对JDBC的封装

#### spring提供的三个操作类

spring提供了三个类来操作数据库，分别是：

1. org.springframework.jdbc.core.JdbcTemplate
2. org.springframework.jdbc.core.support.JdbcDaoSupport
3. org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate

通过源代码可知，JdbcDaoSupport和NamedParameterJdbcTemplate都是对JdbcTemplate的包装。例如JdbcDaoSupport的代码段：

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/jdbcDaoSupport.png)

JdbcDaoSupport持有JdbcTemplate实例，可以通过设置数据源(DataSource)来初始化JdbcTemplate， 又或者

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/jdbcDaoSupport2.png)

可以直接在配置文件中配置一个JdbcTemplate实例来初始化JdbcDaoSupport.jdbcTemplate属性


NamedParameterJdbcTemplate的源代码，也是持有一个JdbcTemplate属性（JdbcTemplate是JdbcOperations接口的唯一实现），我们可以在构造
方法中传入数据源或者一个JdbcTemplate实例来初始化它

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/namedparameterJdbcTemplate1.png)

#### JdbcTemplate方法详解

JdbcTemplate的方法中使用的是回调方式来获得数据库中的数据，三个主要回调接口是ResultSetExtractor, RowMapper和RowCallbackHandler。

##### ResultSetExtractor接口

JdbcTemplate.query(String sql, ResultSetExtractor<T> rse);方法就需要一个ResultSetExtractor来接收查询出的数据, 代码流程

对参数的包装：

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/rowCallbackHandler1.png)

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/rowCallbackHandler2.png)

调用另一个query方法，真正执行查询逻辑：

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/rowCallbackHandler3.png)

进入到execute方法中：

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/rowCallbackHandler4.png)

在圈住的地方调用query方法中匿名内部类的doInPreparedStatement方法，在该方法中首先执行

    // 得到查询结果
    rs = ps.executeQuery();
    ResultSet rsToUser = rs;
    // 把查询到的ResultSet作为参数，回调我们对ResultSetExtractor接口实现的extractData()方法
    return rse.extractData(rsToUser);

所以extractData()中的ResultSet是原封不动的从数据库中查出来的ResultSet, 需要我们自己移动rs的光标做判断`while(rs.next())`，从中取出数据

##### RowMapper接口

RowMapper接口也有一个mapRow(ResultSet rs, int rowNum)方法，这个ResultSet与ResultSetExtractor方法中的ResultSet最大的区别就是
不需要我们移动rs的光标，因为它已经帮你做好的光标的移动操作，你可以直接从rs中取数据就可以了。代码流程

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/rowMapper1.png)

声明方法内部类QueryStatementCallback, 实例作为execute()方法参数，进入execute()方法

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/rowMapper2.png)

调用QueryStatementCallback的doInStatement方法，回到query方法的方法内部类的doInStatement方法中

    rs = stmt.executeQuery(sql);
    ResultSet rsToUser = rs;
    rse.extractData(rsToUser);

调用ResultSetExtractor的extractData方法，注意这个rst并不是我们实现的RowMapper的子类，而是被包装成一个RowMapperResultSetExtractor类，
进入这个类的extractData()方法中

![](https://github.com/yangguangyong/yangguangyong-s-blog/blob/master/assets/2016/06/rowMapper3.png)

看到没？这个extractData已经在对查询到的ResultSet做了简单的处理（移动了它的光标，并传递当前数据行号给我们），所以我们在
RowMapper的子类mapRow方法中不需要移动ResultSet的光标，直接读取里面的数据


##### RowCallbackHandler接口

这个接口也被包装成了一个RowCallbackHandlerResultSetExtractor对象，在它的extractData方法中也对查询到的ResultSet做了光标移动，
所以这个接口的实现类得到的ResultSet也是可以直接使用的，不用做`rs.next()`判断
