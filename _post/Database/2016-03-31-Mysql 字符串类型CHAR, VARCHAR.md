### Mysql 字符串类型CHAR, VARCHAR

声明：以下测试是在mysql5.7版本上做的测试

#### VARCHAR

VARCHAR类型用于存储可变长字符串，是最常见的字符串数据类型。它比定长类型更节省空间，因为它仅使用必要的空间（越短的字符串使用越少的空间）。有一种情况例外，如果Mysql表使用ROW_FORMAT=FIXED创建的话（静态表），每一行都会使用定长存储

VARCHAR需要使用1或2个额外字节记录字符串的长度，如果列的最大长度小于或等于255字节，则只使用1个字节表示，否则使用2个字节。

VARCHAR节省了存储空间，所以对性能也有帮助。但是由于是变长的，在UPDATE时可能使行变得比原来更长，这就导致需要做额外的工作，如果一个行占用的空间增长，并且在页内没有更多的空间可以存储，在这种情况下，InnoDB需要分裂页来使行可以放进页内

在5.0或者更高版本，Mysql在存储和检索时会`保留末尾空格`，但是在之前的版本中，Mysql会剔除末尾空格

##### 下面情况下使用 VARCHAR 是合适的

* 字符串列的最大长度比平均长度大很多
* 列的更新少（碎片不是问题）
* 使用了UTF8这样复杂的字符集，每个字符都使用不同的字节数进行存储

#### CHAR

CHAR类型是定长的，Mysql总是根据定义的字符串长度分配足够的空间。当存储CHAR值时，Mysql会`删除所有的末尾空格`.

CHAR适合存储很短的字符串，或者所有值都接近同一个长度。例如，CHAR非常适合存储密码的MD5值，因为这是一个定长的值。对于经常变更的数据，CHAR也比VARCHAR更好，因为定长的CHAR类型不容易产生碎片

示例

char_col是CHAR类型

    mysql> CREATE TABLE char_test(char_col CHAR(10))ENGINE=INNODB;
    mysql> INSERT INTO char_test(char_col) VALUES
        -> ('string1'), ('   string2'), ('string3   ');

检索数据，发现string3末尾的空格被截断了

当char_col是VARCHAR类型是，检索数据，string3末尾的空格被保留
