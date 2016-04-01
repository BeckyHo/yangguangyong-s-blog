### Mysql区分空字符串和NULL

声明：以下测试是在mysql5.7版本上做的测试

#### 先给出结论

Mysql中使用 `NULL` 和 `空字符串` 时，差别在于：

* 使用LENGTH函数返回时，`NULL`的长度就是NULL; `空字符串`的长度是 0
* 升序排序时，`NULL` 排在 `空字符串` 的前面
* 使用COUNT(column)时，`NULL` 不会被计算进去，而 `空字符串` 会被计算进去
* WHERE子句查询时，`NULL` 的判断是 IS NULL 和 IS NOT NULL，而 `空字符串` 可以使用 `=`, `<>`, `<`, `>`比较运算符
