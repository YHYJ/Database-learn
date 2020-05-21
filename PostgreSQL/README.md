# README

PostgreSQL(PG)及其组件

---

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [PG安装和配置](#pg安装和配置)
* [PG的插件](#pg的插件)
    * [pgadmin](#pgadmin)
        * [安装](#安装)
    * [pgpool-II](#pgpool-ii)
        * [安装pgpool-II](#安装pgpool-ii)
            * [下载源文件](#下载源文件)
            * [依赖](#依赖)
            * [编译安装](#编译安装)
        * [安装pgpool-II相关函数](#安装pgpool-ii相关函数)
        * [使用pgpool-II函数](#使用pgpool-ii函数)
        * [pgpool-II的配置文件](#pgpool-ii的配置文件)
            * [pool_passwd](#pool_passwd)
            * [pcp.conf](#pcpconf)
            * [pool_hba.conf](#pool_hbaconf)
            * [pgpool.conf](#pgpoolconf)
            * [watchdog](#watchdog)
            * [pgpool-ii.service](#pgpool-iiservice)
        * [测试pgpool-II](#测试pgpool-ii)
            * [配置PG启用Streaming Replication(SR)](#配置pg启用streaming-replicationsr)
                * [配置主节点(Master)](#配置主节点master)
                * [配置从节点(Slave)](#配置从节点slave)
            * [配置pgpool-II](#配置pgpool-ii)
            * [负载均衡测试](#负载均衡测试)
    * [pgbouncer](#pgbouncer)
        * [安装](#安装-1)
        * [作用](#作用)
        * [轻量级的体现](#轻量级的体现)
        * [三种连接池模型](#三种连接池模型)
        * [配置](#配置)
            * [成功运行pgbouncer服务需要的配置](#成功运行pgbouncer服务需要的配置)
            * [配置userlist.txt](#配置userlisttxt)

<!-- vim-markdown-toc -->

---

对于文档中命令参数不理解的，请自行查看对应命令的`--help`输出

**确保：**

- 有系统用户`postgres`和`pgpool`

	```bash
	# useradd --system --no-create-home pgpool
	```

	如果PG是从源安装的，应该已经自动创建系统用户postgres
	
	pgpool是编译安装的，需要手动添加系统用户pgpool

- 有以下文件夹且属性和权限正确：

	- `/var/run/pgpool` —— 属组：`root:root`；权限：`755`

		pgpool的pid文件路径，由pgpool.conf中的参数`pid_file_name`定义
		
	- `/var/run/postgresql`—— 属组：`postgres:postgres`；权限：`775`
	
  ```bash
	  # chown postgres:postgres /var/run/postgresql
  # chmod 775 /var/run/postgresql
	```

	  PG的domain socket文件路径
	
	  pgpool的domain socket文件路径，由pgpool.conf中的参数`socket_dir`、`pcp_socket_dir`、`wd_ipc_socket_dir`定义
	
  > 为了测试时候方便改了属性和权限，不该也可以，只是使用`pg_ctl`操作测试PG的时候需要root权限
	
	- `/var/lib/postgres` —— 属组：`postgres:postgres`；权限：`755`
	
	```bash
		# chown postgres:postgres /var/lib/postgres
	# chmod 775 /var/lib/postgres
	```
	
		PG文件和数据存储路径

---

## PG安装和配置

参考[Install & Deploy](./file/install-and-deploy.md)

## PG的插件

### pgadmin

PG管理工具

#### 安装

```bash
# pacman -S pgadmin4
```

---

### pgpool-II

Pgpool-II is a middleware that works between PostgreSQL servers and a PostgreSQL database client

[pgpool Wiki](https://www.pgpool.net/mediawiki/index.php/Main_Page)

redhat发行版可以直接下载安装包，其他发行版需要编译，不支持Windows

#### 安装pgpool-II

##### 下载源文件

**不要从[下载页面](https://www.pgpool.net/mediawiki/index.php/Downloads)下载打包后的pgpool，到[这里](https://www.pgpool.net/mediawiki/index.php/Source_code_repository)下载pgpool的源代码**

*因为第一个连接下载下来的代码编译过程中一直报错`collect2: error: ld returned 1 exit status`并且怎么修改都没用，第二个虽然也会报错，但修改后能够编译通过*

**下载之后解压并cd到得到的文件夹**

##### 依赖

- GNUX make 3.80或更高版本

	> 测试make版本：
	>
	> ```bash
	> make --version
	> ```

- ISO/ANSI C编译器，建议使用最新版本的`gcc`

- `gzip`和`tar`

- `postgresql-libs`和`postgresql-devel`

- 因为需要clone源代码，也需要`git`

pgpool-II源代码和依赖都准备好之后开始编译

##### 编译安装

0. 修改`configure`文件

	因为configure文件里写死了automake的版本号，可能会与进行编译的机器上安装的automake版本不符，会导致之后编译失败，所以需要修改configure文件重新指定automake版本：

	- 确定编译机automake版本：

		```bash
		$ automake --version
		```

		> 例如我的automake的版本是*1.16.2*，使用1.16或者1.16.2都可以

	- 编辑`configure`文件

		打开configure文件，定位到变量**`am__api_version=`**行，将其值修改为1.16（或1.16.2）之后保存退出

1. 配置编译参数

	```bash
	$ ./configure --with-memcached=/usr/include
	```

	`configure`脚本有以下主要参数可以自定义：

	- `--prefix=path`

		指定pgpool-II的安装路径，默认是`/usr/local`

	- `--with-pgsql=path`

		指定PG的安装路径，默认由`pg_config`提供

	- `--with-openssl`

		开启openssl支持，默认关闭

	- `--with-memcached=path`

		如果开启内存缓存查询功能，需要**安装`libmemcached`**并指定其头文件安装路径

	> 其他参数请见`./configure --help`

2. 编译

	```bash
	$ make
	```

3. 安装

	```bash
	# make install
	```

	安装完成之后，以默认`--prefix`参数为例，可执行文件在`/usr/local/bin`，配置文件在`/usr/local/etc`

#### 安装pgpool-II相关函数

pgpool函数不是必须安装的，但是强烈建议安装**pgpool_adm**, **pgpool-regclass**, **pgpool-recovery**

下载的pgpool-II源代码里有安装文件，路径是`/path/to/pgpool2/src/sql`，进入该路径之后，执行编译安装

1. 编译

	```bash
	$ make
	```

2. 安装

	```bash
	# make install
	```

安装路径是`/usr/lib/postgresql`：

- pgpool_adm.so
- pgpool-recovery.so
- pgpool-regclass.so

**注意：加载插件需要libpcp.so.1，该文件的安装路径是`/usr/local/lib/libpcp.so.1`**

如果插件无法加载且报错如下：

```bash
错误:  无法加载库 "/usr/lib/postgresql/pgpool_adm.so": libpcp.so.1: 无法打开共享对象文件: 没有那个文件或目录
```

需要手动加载一下libpcp.so.1，步骤如下：

1. 编辑`/etc/ld.so.conf.d/pcp.conf`文件，写入以下内容：

	文件名不用非得是pcp.conf，可以自定义（只要后缀名是`.conf`即可），因为是libpcp.so文件的路径配置文件所以叫pcp.conf

	```bash
	/usr/local/lib
	```

	> 即libpcp.so.1的文件路径

2. 加载动态链接库

	```bash
	# ldconfig
	```

	之后每次重启，系统都会自动加载该文件

#### 使用pgpool-II函数

执行以下指令创建extension：

```sql
create extension pgpool_adm ;
create extension pgpool_recovery ;
create extension pgpool_regclass ;
```

extension创建完成之后使用`\df`指令查看函数列表，有19行记录（**因为输出结果太宽就不贴图了，请自行查看，作为对比，此时slave节点函数列表有0行记录**）

#### pgpool-II的配置文件

关键配置文件：

- pool_passwd：用于保存PG相应的用户ID及md5密码
- pcp.conf：用于管理查、看节点信息，如加入新节点。该文件主要存储pgpool的用户ID及md5形式的密码
- pool_hba.conf：用于认证pgpool的用户登录方式，如客户端IP限制等，类似于postgresql的pg_hba.conf文件
- pgpool.conf：用于设置pgpool的模式，主从数据库的相关信息等

##### pool_passwd

保存PostgreSQL（不是pgpool的）的用户ID及md5格式的密码

```bash
# pg_md5 --md5auth --prompt --username=postgres
```

该命令会自动生成md5暗文密码和用户ID组合成*username:md5_password*的格式并写入pool_passwd文件

##### pcp.conf

pcp.conf是pgpool的身份认证配置文件（与PG的身份认证无关），该文件包含用于pgpool Communication Manager（pcp_*命令）的用户ID和密码

**执行pgpool的用户必须有读取pcp.conf的权限**

1. 创建pcp.conf：

	```bash
	# cp /usr/local/etc/pcp.conf.sample /usr/local/etc/pcp.conf
	```

2. 内容格式为：

	```yaml
	username:[md5 encrypted password]
	```

3. 生成`[md5 encrypted password]`：

  ```bash
  $ pg_md5 your_password
  ```

  > 因为加参数的话生成的是pool_passwd的内容，所以不能加参数
  >
  > 将'your_password'替换为密码

  如果不想显式输入密码，使用以下命令：

  ```bash
  $ pg_md5 -p
  ```

4. 将用户ID（这里是pgpool）及生成的加密后的密码写入pcp.conf，例如：

	```yaml
	pgpool:ba777e4c2f15c11ea8ac3be7e0440aa0
	```

##### pool_hba.conf

pool_hba.conf用于设定允许连接pgpool的IP/hostname、客户端的验证方式、允许的用户名和允许访问的数据库

> 因为测试是在一台机器上进行的，所以使用文件中自带的配置信息就行

##### pgpool.conf

pgpool.con是pgpool-II的主配置文件，根据模式不同，有不同的后缀名，选择一种模式的配置文件用来创建pgpool.conf

模式说明：

| 配置文件                       | 模式                       |
| ------------------------------ | -------------------------- |
| pgpool.conf.sample-stream      | Streaming replication mode |
| pgpool.conf.sample-replication | Replication mode           |
| pgpool.conf.sample-slony       | Slony                      |
| pgpool.conf.sample-raw         | Raw mode                   |
| pgpool.conf.sample-logical     | Logical replication mode   |

**修改pgpool.conf中的参数后，运行`pgpool reload`将新的参数值（除了明确要求必须重启pgpool的参数）加载到进程（包括所有子进程）**

1. 创建pgpool.conf

  ```bash
  # cp /usr/local/etc/pgpool.conf.sample-replication /usr/local/etc/pgpool.conf
  ```

2. 编辑pgpool.conf：

  至少需要设置`backend_hostname`和`backend_port`参数才能启动pgpool-II

  > 默认`backend_hostname0`和`backend_post0`应该能够连接到使用默认参数的PG

3. 具体参数配置请看[config setting](https://www.pgpool.net/docs/latest/en/html/config-setting.html)和[example configs](https://www.pgpool.net/docs/latest/en/html/example-configs.html)

  **需要把其中值为**nobody**的参数修改为具体要求的值**

  主要需要修改的配置项有：

  - 连接选项 -- pgpool进程的连接设置
  	- `listen_addresses`

  		> pgpool主进程的监听地址

  	- `port`

  		> pgpool进程使用的端口

  	- `socket_dir`

  		> pgpool进程的domain socket文件的存储路径，**设置成和PG的domain socket文件同一路径，否则PG的命令无法连接pgpool的端口**

  - 连接选项 -- pcp(pgpool Communication Manager)进程的连接设置

  	- `pcp_listen_addresses`

  		> pcp进程的监听地址

  	- `pcp_port`

  		> pcp进程使用的端口

  	- `pcp_socket_dir`

  		> pcp进程的domain socket文件的存储路径，**设置成和PG的domain socket文件同一路径**

  - 后端连接设置

  	- `backend_hostname`

  		> PG使用的监听地址

  	- `backend_port`

  		> PG使用的端口

  	- `backend_data_directory`

  		> PG的数据库集群路径

  	以上三个参数都可以在后面增加数字来表示后端连接编号，形如`backend_hostname0`、`backend_hostname1`，仅使用一个PG数据库则后缀0，增加一个PG后缀数字+1

  - 连接池设置

  	- `connection_cache`

  		> 设置是否激活连接池，连接池里并没有template0、template1、postgres和regression这四个数据库的连接缓存

##### watchdog

[Tutorial watchdog](https://www.pgpool.net/docs/latest/en/html/tutorial-watchdog.html)

##### pgpool-ii.service

创建pgpool的service文件，以便用systemd管理服务

1. 创建`/etc/systemd/user/pgpool-ii.service`，写入以下内容：

	```toml
	[Unit]
	Description=PGPool-II Middleware Between PostgreSQL Servers And PostgreSQL Database Clients
	After=syslog.target network.target
	
	[Service]
	ExecStart=/usr/local/bin/pgpool -n
	
	[Install]
	WantedBy=multi-user.target
	```

2. 使用以下命令设置pgpool-ii开机自启并立即启动：

	```bash
	$ systemctl enable --user --now pgpool-ii
	```

    > 因为文件权限修改过，这里使用user权限管理即可，也可以测试一下使用root权限管理，应该可以

#### 测试pgpool-II

> 开启PG的Streaming Replication，配置pgpool连接PG并开启负载均衡

[pgpool-II各命令简介](https://www.pgpool.net/docs/latest/en/html/reference.html)

注意事项：

pgpool-II的所有命令，有参数能够指定`hostname`的都写上这个参数，否则使用的是Unix Socket通讯，而尽管在pgpool.conf里配置了domain socket文件地址，命令还是使用的默认路径查找domain socket文件，所以要指定hostname使用TCP/IP Socket

> 127.0.0.1:9999：pgpool主进程
>
> 127.0.0.1:5433：Master节点，数据目录`data_5433`
>
> 127.0.0.1:5434：Slave节点，数据目录`data_5434`

##### 配置PG启用Streaming Replication(SR)

使用本机（和pgpool-II在同一个机器上）开启两个PG服务用于测试

[参考PostgreSQL Wiki](https://wiki.postgresql.org/wiki/Streaming_Replication)（注意有些描述已过时）

首先创建两个文件夹：

```bash
$ mkdir data_5433 data_5434
```

###### 配置主节点(Master)

1. 初始化数据集

	```bash
	$ initdb --locale=en_US.UTF-8 --encoding=UTF8 --pgdata=./data_5433 --username=postgres
	```

2. 编辑postgresql.conf

	要修改的配置项有：

	- listen_addresses

		> 默认值是localhost，如果主从节点和pgpool不在同一台机器上，需要设为0.0.0.0

	- port

		> 默认值是5432，因为是主节点，修改为5433

	- wal_level

		> 默认值是replica，其他值为minimal、logical，因为测试中主节点只是作为SR的来源，所以使用默认值replica，其他值的作用请自行测试

	- max_wal_senders

		> 默认值是10，测试保持默认值

	- wal_keep_segments

		> 默认值是10，可以适当增大，测试设为64

3. 编辑pg_hba.conf

	因为pgpool和主从节点都是在一台机器上所以不用修改该文件，否则要修改

4. 启动主节点

	```bash
	$ pg_ctl --wait --pgdata=./data_5433 start
	```

5. 创建用户

	创建具有REPLICATION权限的用户replication，密码是'password'，并允许其登录

	```sql
	CREATE ROLE replication WITH REPLICATION PASSWORD 'password' LOGIN
	```

###### 配置从节点(Slave)

1. 从主节点生成基本备份

	要确保从节点数据目录`data_5434`是空文件夹

	```bash
	$ pg_basebackup --pgdata=./data_5434 --format=p --wal-method=stream --write-recovery-conf --checkpoint=fast --progress --verbose --host=127.0.0.1 --port=5433  --username=replication
	```

	> 该命令会从主节点获取PG的整个数据目录并放置到从节点
	>
	> 有的教程说需要创建恢复命令文件recovery.conf，因为上述命令的`--write-recovery-conf`参数会自动生成恢复命令，不再需要该文件

2. 编辑postgresql.conf

	要修改的配置项有：

	- port

		> 修改为5434

3. 编辑pg_hba.conf

	因为pgpool和主从节点都是在一台机器上所以不用修改该文件，否则要修改

4. 修改目录权限

	`data_5434`文件夹权限要求必须是0700，如果不是请使用以下命令修改

	```bash
	chmod 0700 data_5434
	```

5. 启动从节点

	```bash
	$ pg_ctl --wait --pgdata=./data_5434 start
	```

6. 测试SR功能

	- 在节点创建一个user和database

		```sql
		create user user_test ;
		create database db_test;
		```

		然后分别使用`\du`和`\l`指令在主节点和从节点查看。可以看到两个节点都有了user_test用户和db_test数据库

	- 其他功能请自行测试

7. 查看SR进度

	使用以下命令查看

	```bash
	ps aux | grep sender
	ps aux | grep receiver
	```

8. 查看SR状态

	在主节点执行以下指令查看SR的状态

	```sql
	\x
	select * from pg_stat_replication;
	```

	> 第一行指令设置打开扩展显示，否则输出的阅读性太差

	

##### 配置pgpool-II

1. 配置基本参数

  使用pgpool.conf.sample-replication作为配置文件

  按照[pgpool-II的配置文件](#pgpool-II的配置文件)配置好基本参数之后，还需要在pgpool.conf中配置Replication相关参数

  - master_slave_mode

  	> 默认值是off，需要修改为on

  - master_slave_sub_mode

  	>  默认值是stream，确保不是其他值

  - load_balance_mode

  	>  默认值是on，确保不是off

2. 启动pgpool-II服务

	```bash
	# systemctl start pgpool-ii.service
	```

3. 连接到pgpool

	```bash
	psql --host=127.0.0.1 --port=9999 --username=postgres --dbname=postgres
	```

4. 使用pgpool-II

	使用以下指令查看pgpool状态：

	```sql
	show pool_nodes ;
	```

	> 示例配置了两个PG，查询结果应该有两行，确保都是**status**列都是**up**

	使用以下指令查看pgpool版本：

	```sql
	shoe pool_version ;
	```

	使用以下指令查看pgpool的所有配置信息：

	```sql
	pgpool show all ;
	```

##### 负载均衡测试

1. 在主节点执行初始化test数据库

	```bash
	pgbench --username=postgres --initialize --port=5433 test
	```

2. 进行负载均衡测试

	```bash
	pgbench --username=postgres --port=9999 --client=10 --jobs=10 --select-only --time=60 test
	```

3. 查看结果

	执行以下指令：

	```sql
	show pool_nodes ;
	```

	`select_cnt`就是每个节点分配的`SELECT`的数量，如果pgpool.conf中配置项`backend_weight0`和`backend_weight1`的值相等，pgpool-II将尝试分配相等数量的SELECT，因此该列数字应该相差无几

---

### pgbouncer

PG的轻量级连接池

#### 安装

```bash
# pacman -S pgbouncer
```

#### 作用

1. 维护和PG的连接的缓存，为连接请求分配空闲的连接进程，而不需要PG一直fork新的进程徒增资源消耗
2. 提高连接利用率（重用），避免连接过多导致数据库资源消耗过大
3. 对连接进行限制，防止恶意请求

#### 轻量级的体现

1. 通过libevent进行socket通信，提高通信效率
2. 使用C编写，每个连接仅消耗2kb内存

#### 三种连接池模型

1. **session**：会话级连接。在生命周期内，连接池分配一个数据库连接，客户端断开连接时，连接池回收连接
2. **transaction**：事务级连接。客户端每个事务结束时，连接池回收连接，再次执行事务时需要重新获取连接
3. **statement**：语句级连接。执行完一个SQL语句时，连接池回收连接，再次执行SQL时需要重新获取连接。这种模式客户端需要设置*autocommit*模式

#### 配置

##### 成功运行pgbouncer服务需要的配置

1. 创建`/var/log/pgbouncer`文件夹并修改属组为'pgbouncer'：

    ```bash
    # makedir /var/log/pgbouncer
    # chown pgbouncer:pgbouncer /var/log/pgbouncer
    ```

2. 创建配置文件和userlist文件：

    ```bash
    # cp /usr/share/doc/pgbouncer/userlist.txt /etc/pgbouncer/userlist.txt
    # cp /usr/share/doc/pgbouncer/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
    ```

3. 修改`/etc/pgbouncer/pgbouncer.ini`中的配置项**unix_socket_dir**：

    > 原始值是'/run/postgresql'，修改为'/run/pgbouncer'
    >
    > 该配置项定义了pgbouncer的Unix Socket文件位置，因为pgbouncer不属于postgresql组，没有`/run/postgresql`文件夹的操作权限，所以要改成它自己的`/run/pgbouncer`

以上三项配置完成之后，即可使用systemd启用并运行pgbouncer服务：

```bash
# systemctl enable --now pgbouncer
```

##### 配置userlist.txt

userlist.txt文件指定了能够连接PG的用户，并配置了对应用户的密码（经过md5加密）

1. 修改`/etc/pgbouncer/pgbouncer.ini`中的配置项**auth_type**：

    > 原始值是'trust'，修改为`md5`
    >
    > 该参数定义了身份认证方法

2. 获取用户名及其对应的暗文密码：

    有两种方式，第一种需要安装`psql`工具：

    ```bash
    $ psql --host=127.0.0.1 --port=5432 --username=postgres -c "SELECT concat('\"', usename, '\" \"', passwd, '\"') FROM pg_shadow"
    ```

    > 输出结果是已经经过md5加密后的暗文密码，可以直接使用
    >
    > 通过修改'--username'参数的值可以获得指定用户名的暗文密码

    第二种获取方式通过执行Python代码生成，需要明确知道用户名及其对应密码：

    ```python
    import hashlib

    username = ""
    password = ""

    md5 = hashlib.md5()
    md5.update((username + password).encode('UTF-8'))

    print('"{}" "{}"'.format(username, 'md5'+md5.hexdigest()))
    ```

3. 修改`/etc/pgbouncer/userlist.txt`：

    获取到暗文密码之后，将之填入`/etc/pgbouncer/userlist.txt`中，需要和用户名一一对应，例如：

    ```text
    "postgres" "md53175bce1d3201d16594cebf9d7eb3f9d"
    ```

    > 这是PG默认用户"postgres"及其密码"postgres"加密后的值
