# Python-Quick-Start

Quick Start: Python and TimescaleDB

---

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [0. 首先](#0-首先)
* [1. 连接到TimescaleDB](#1-连接到timescaledb)
* [2. 创建一个关系表](#2-创建一个关系表)
* [3. 生成一个超表](#3-生成一个超表)
* [4. 在表中插入数据](#4-在表中插入数据)
* [5. 执行查询语句](#5-执行查询语句)
* [6. 文档](#6-文档)

<!-- vim-markdown-toc -->

---

使用Python快速上手TimescaleDB

---

## 0. 首先

1. 安装TimescaleDB，可以本地安装或者使用docker镜像

2. 安装psycopg2

   psycopg2是适用于Python的TimescaleDB适配器

   ```bash
   pip install psycopg2
   ```

## 1. 连接到TimescaleDB

1. 导入psycopg2

   ```python
   import psycopg2
   ```

2. 构建连接字符串

   需要以下字段：

   - host：数据库服务地址
   - port：数据库服务端口
   - username：用户名
   - password：用户密码
   - database：数据库名

   使用以上字段构建连接字符串，需要符合[libpq connection string](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)要求

   ```python
   CONNECTION = "postgres://username:password@host:port/dbname"
   ```

   > 如果使用的是hosted版本的TimescaleDB，或者需要SSL连接则使用以下字段：
   >
   > ```python
   > CONNECTION = "postgres://username:password@host:port/dbname?sslmode=require"
   > ```
   >
   > 或者也可以直接在连接字符串中指定每个参数值，但**注意，该方法仅用于测试开发，生产环境中勿用**：
   >
   > ```python
   > CONNECTION = "dbname =tsdb user=tsdbadmin password=secret host=host.com port=5432 sslmode=require"
   > ```

3. 连接到数据库

   使用psycopg2的[连接函数](https://www.psycopg.org/docs/module.html?highlight=connect#psycopg2.connect)创建数据库会话：

   ```python
   with psycopg2.connect(CONNECTION) as conn:
       # Call the function that needs the database connection
       func_1(conn)
   ```

   > 也可以创建如下连接对象，并根据需要对该对象执行操作：
   >
   > ```python
   > conn = psycopg2.connect(CONNECTION)
   > insert_data(conn)
   > cur = conn.cursor()
   > ```

## 2. 创建一个关系表

1. 构建SQL语句

   创建一个字符串，该字符串内容是用来创建关系表的SQL语句

   以下示例创建了一个名为sensor的表，表中有id、type和location列：

   ```python
   query_create_sensors_table = "CREATE TABLE sensors (id SERIAL PRIMARY KEY, type VARCHAR(50), location VARCHAR(50));"
   ```

2. 执行SQL语句并提交更改

   接下来打开游标执行步骤1中定义的SQL语句，并且提交更改以使之持久化，完成后关闭游标：

   ```python
   cur = conn.cursor()
   # see definition in Step 1
   cur.execute(query_create_sensors_table)
   conn.commit()
   cur.close()
   ```

## 3. 生成一个超表

超表(hypertable)由具有列名称和类型的标准架构定义，其中至少一列指定时间值

在TimescaleDB中，主要由[hypertable][hypertable]和数据进行交互，它是跨所有空间和时间间隔的单个连续表的抽象，因此可以通过标准SQL查询它

用户与TimescaleDB几乎所有的交互都与超表有关（创建表和索引、更改表、插入数据、查询数据等都可以（并且应该）在超表上执行）

1. 构建SQL语句

   1. `CREATE TABLE`语句

      创建一个变量，其值是用于创建表的`CREATE TABLE`语句（注意超表应有强制时间列）：

      ```python
      # create sensor_data hypertable
      query_create_sensordata_table = """CREATE TABLE sensor_data (
                                              time TIMESTAMPTZ NOT NULL,
                                              sensor_id INTEGER,
                                              temperature DOUBLE PRECISION,
                                              cpu DOUBLE PRECISION,
                                              FOREIGN KEY (sensor_id) REFERENCES sensors (id)
                                              );"""
      ```

   2. `SELECT`

      创建一个变量，其值是用于将上一步骤创建的普通表转换为超表的`SELECT`语句：

      **注意，必须按照[create_hypertable docs](https://docs.timescale.com/latest/api#create_hypertable)的要求指定要转换为超表的表名及其时间列名称作为两个参数**

      ```python
      query_create_sensordata_hypertable = "SELECT create_hypertable('sensor_data', 'time');"
      ```

2. 执行SQL语句

   执行以上两个SQL语句并提交更改：

   ```python
   cur = conn.cursor()
   cur.execute(query_create_sensordata_table)
   cur.execute(query_create_sensordata_hypertable)
   # commit changes to the database to make changes persistent
   conn.commit()
   cur.close()
   ```

## 4. 在表中插入数据

- 使用psycopg2插入一行数据

   以下是在表中插入数据的典型方法，该示例将数据插入到名为sensors的关系表中：

   ```python
   SQL = "INSERT INTO sensors (type, location) VALUES (%s, %s);"
   sensors = [('a','floor'),('a', 'ceiling'), ('b','floor'), ('b', 'ceiling')]
   cur = conn.cursor()
   for sensor in sensors:
       try:
           data = (sensor[0], sensor[1])
           cur.execute(SQL, data)
       except (Exception, psycopg2.Error) as error:
           print(error.pgerror)
   conn.commit()
   ```

- 使用pgcopy快速插入数据

   但是如果需要更快的性能可以使用pgcopy

   > 使用pip安装pgcopy

   1. 导入pgcopy库

      ```python
      from pgcopy import CopyManager
      ```

   2. 以下示例为插入数据

      ```python
      # insert using pgcopy
      def fast_insert(conn):
          cur = conn.cursor()

          # for sensors with ids 1-4
          for id in range(1, 4, 1):
              data = (id, )
              # create random data
              simulate_query = ("SELECT generate_series(now() - "
                                "interval '24 hour', now(), interval '5 minute') "
                                "AS time, %s as sensor_id, random()*100 "
                                "AS temperature, random() AS cpu")
              cur.execute(simulate_query, data)
              values = cur.fetchall()

              # define columns names of the table you're inserting into
              cols = ('time', 'sensor_id', 'temperature', 'cpu')

              # create copy manager with the target table and insert!
              mgr = CopyManager(conn, 'sensor_data', cols)
              mgr.copy(values)

          # commit after all sensor data is inserted
          # could also commit after each sensor insert is done
          conn.commit()

          # check if it worked
          cur.execute("SELECT * FROM sensor_data LIMIT 5;")
          print(cur.fetchall())
          cur.close()
      ```

      > 1. 获取要插入数据库的数据
      >
      >     示例中是随机生成的
      >
      > 2. 定义要向其中插入数据的表的列
      >
      >     定义要向其中插入数据的表的列名，示例中使用的是上面“生成超表”部分中创建的`sensor_data`超表，该超表由名为`time`，`sensor_id`，`temperature`和`cpu`的列组成，在字符串元组cols中定义这些列名称
      >
      > 3. 使用目标表及其列定义实例化CopyManager
      >
      >     实例化一个CopyManager的对象名为mgr，参数是数据库连接会话、超表名、列名的元组
      >
      >     然后使用CopyManager的复制功能将数据搞笑的插入数据库
      >
      > 4. 数据插入完成后提交更改
      >
      > 4. 检测数据是否成功插入

## 5. 执行查询语句

1. 构建查询的SQL语句

   ```python
   query = "SELECT * FROM sensor_data LIMIT 5;"
   ```

2. 执行查询语句

   ```python
   cur = conn.cursor()
   cur.execute(query)
   ```

3. 获取查询返回的结果

   使用`fetchall()`或`fetchmany()`获取查询返回的所有结果行

   下面的示例只是简单地逐行打印查询结果，注意`fetchall()`的结果是一个元组列表，因此可以进行相应的处理：

   ```python
   cur = conn.cursor()
   query = "SELECT * FROM sensor_data LIMIT 5;"
   cur.execute(query)
   for i in cur.fetchall():
       print(i)
   cur.close()
   ```

## 6. 文档

有关psycopg2的文档请看[psycopg2 documentation](https://www.psycopg.org/docs/usage.html)
