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
        * [配置pgpool-II](#配置pgpool-ii)
            * [添加系统用户](#添加系统用户)
            * [pcp.conf](#pcpconf)
            * [pgpool.conf](#pgpoolconf)
            * [watchdog](#watchdog)
            * [pgpool-ii.service](#pgpool-iiservice)
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

**确保：**

- 有系统用户`postgres`和`pgpool`

	```bash
	# useradd --system --no-create-home pgpool
	```

	> 如果PG是从源安装的，应该已经自动创建系统用户postgres
	>
	> pgpool是编译安装的，需要手动添加系统用户pgpool

- 登录用户已添加到`postgres`和`pgpool`组

	```bash
	# usermod -aG postgres,pgpool yj
	```

	> 为了运行命令时不必总是要切换用户，将登录用户添加到组（登录用户以'yj'为例）

- 以下文件夹的属组和权限正确：

	- `/var/run/pgpool` —— 属组：`pgpool`；权限：`775`

		```bash
		# chown pgpool:pgpool /var/run/pgpool -R
		# chmod 775 /var/run/pgpool -R
		```

		> pgpool的pid文件路径，由pgpool.conf中的参数`pid_file_name`定义

	- `/var/run/postgresql`—— 属组：`postgres`；权限：`775`

		```bash
		# chown postgres:postgres /var/lib/postgres -R
		# chmod 775 /var/run/pgpool -R
		```

		> PG的domain socket文件路径
		>
		> pgpool的domain socket文件路径，由pgpool.conf中的参数`socket_dir`、`pcp_socket_dir`、`wd_ipc_socket_dir`定义

	- `/var/lib/postgres` —— 属组：`postgres`；权限：`755`

		```bash
		# chown postgres:postgres /var/run/postgresql -R
		```

		> PG文件和数据存储路径

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

#### 配置pgpool-II

##### 添加系统用户

添加一个系统用户**pgpool**：

```bash
# useradd --system --no-create-home pgpool
```

##### pcp.conf

pcp.conf是pgpool的身份认证配置文件，该文件包含用于pgpool Communication Manager的用户ID和密码（区别于PostgreSQL的用户）

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

	> 将'your_password'替换为自定义密码

	如果不想显式输入密码，使用以下命令：

	```bash
	$ pg_md5 -p
	```

4. 将用户名及生成的加密后的密码写入pcp.conf，例如：

	```yaml
	pgpool:ba777e4c2f15c11ea8ac3be7e0440aa0
	```

##### pgpool.conf

pgpool.con是pgpool-II的主配置文件，根据模式不同，有不同的后缀名，选择一种模式的配置文件用来创建pgpool.conf，这里使用默认的pgpool.conf.sample

**修改pgpool.conf中的参数后，运行`pgpool reload`将新的参数值（除了明确要求必须重启pgpool的参数）加载到进程（包括所有子进程）**

模式说明：

| 配置文件                           | 模式                       |
| ---------------------------------- | -------------------------- |
| pgpool.conf.sample-stream          | streaming replication mode |
| pgpool.conf.sample-replication     | native replication mode    |
| pgpool.conf.sample-slony（已过时） | master slave               |
| pgpool.conf.sample-raw             | raw mode                   |
| pgpool.conf.sample-logical         | logical replication mode   |

1. 创建pgpool.conf

	```bash
	# cp /usr/local/etc/pgpool.conf.sample /usr/local/etc/pgpool.conf
	```

2. 编辑pgpool.conf：

	至少需要设置`backend_hostname`和`backend_port`参数才能启动pgpool-II

	> 默认`backend_hostname0`和`backend_post0`应该能够连接到使用默认参数的PG

3. 具体参数配置请看[config setting](https://www.pgpool.net/docs/latest/en/html/config-setting.html)

	需要把其中值为**nobody**的参数都修改为具体的值

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
	$ systemctl enable --now pgpool-ii
	```

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
