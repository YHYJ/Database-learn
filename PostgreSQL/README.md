# README

PostgreSQL(PG)及其组件

---

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [PostgreSQL的安装和配置](#postgresql的安装和配置)
* [PostgreSQL的配件](#postgresql的配件)
    * [PgAdmin](#pgadmin)
        * [安装](#安装)
    * [Pgpool-II](#pgpool-ii)
        * [注意事项](#注意事项)
        * [下载源代码](#下载源代码)
        * [Pgpool-II的编译依赖](#pgpool-ii的编译依赖)
        * [编译安装Pgpool-II](#编译安装pgpool-ii)
        * [编译安装Pgpool-II函数](#编译安装pgpool-ii函数)
        * [使用Pgpool-II函数](#使用pgpool-ii函数)
        * [配置Pgpool-II](#配置pgpool-ii)
            * [pgpool.conf](#pgpoolconf)
            * [pcp.conf](#pcpconf)
            * [pool_passwd](#pool_passwd)
            * [pool_hba.conf](#pool_hbaconf)
            * [pgpool-ii.service](#pgpool-iiservice)
        * [测试Pgpool-II](#测试pgpool-ii)
            * [测试环境参数](#测试环境参数)
            * [配置PostgreSQL测试环境](#配置postgresql测试环境)
                * [配置主要节点(Primary)](#配置主要节点primary)
                * [配置备用节点(Standby)](#配置备用节点standby)
                * [测试PostgreSQL的SR](#测试postgresql的sr)
            * [配置Pgpool-II测试环境](#配置pgpool-ii测试环境)
            * [Pgpool-II负载均衡测试](#pgpool-ii负载均衡测试)
    * [PgBouncer](#pgbouncer)
        * [安装](#安装-1)
        * [作用](#作用)
        * [轻量级的体现](#轻量级的体现)
        * [三种连接池模型](#三种连接池模型)
        * [配置](#配置)
            * [配置PgBouncer服务](#配置pgbouncer服务)
            * [配置userlist.txt](#配置userlisttxt)

<!-- vim-markdown-toc -->

---

文档中使用的命令参数的作用请自行查看对应命令的`--help`输出

---

## PostgreSQL的安装和配置

参考[Install & Deploy](./file/install-and-deploy.md)

## PostgreSQL的配件

### PgAdmin

 Comprehensive design and management interface for PostgreSQL

#### 安装

```bash
# pacman -S pgadmin4
```

### Pgpool-II

Pgpool-II is a middleware that works between PostgreSQL servers and a PostgreSQL database client

> [Pgpool Wiki](https://www.pgpool.net/mediawiki/index.php/Main_Page)
>
> [Pgpool-II各命令简介](https://www.pgpool.net/docs/latest/en/html/reference.html)
>
> 提供Redhat系列发行版的安装包(rpm)，其他发行版需要编译，不支持Windows

#### 注意事项

编译Pgpool-II按照文档来就可以，但是使用Pgpool-II之前需要确保一下无误：

- 存在系统用户'postgres'和'pgpool'及对应的组

  如果PostgreSQL是从源安装的应该已经自动创建了名为'postgres'的系统用户和组

  如果PostgreSQL和Pgpool-II都是自行编译安装的，需要手动创建对应的用户和组

  使用以下命令查看：

  ```bash
  $ id username
  ```

  ![User & Group](https://gitee.com/YJ1516/MyPic/raw/master/picgo/user_and_group.png)

  上图可以看到用户'postgres'和'pgpool'及其同名组都是系统用户/组（<1000即为i系统用户/组）

  如果系统中没有某个系统用户及其同名组，使用以下命令添加：

  ```bash
  # useradd --system --no-create-home username
  ```

  > 将username替换为实际用户名

- 存在以下文件夹且权限归属正确：

  - `/var/run/postgresql` —— 归属：`postgres:postgres`；权限：775

    PostgreSQL的Unix doamin socket文件路径

    Pgpool-II的Unix domain socket文件路径，由配置文件pgpool.conf中的配置项`socket_dir`、`pcp_socket_dir`和`wd_ipc_socket_dir`定义

    > **注意：**该文件夹会在postgresql.service服务stop的时候被其删去，因为测试的时候需要这个文件夹并且测试用到的命令`pg_ctl`等使用的是普通用户的权限，所以需要手动创建该文件并修改权限和归属，命令如下：
    >
    > ```bash
    > # mkdir /var/run/postgresql
    > # chown postgres:postgres /var/run/postgresql
    > # chmod 775 /var/run/postgresql
    > ```

  - `/var/run/pgpool` —— 归属：`root:root`；权限：755

    Pgpool-II的pid文件路径，由配置文件pgpool.conf中的配置项`pid_file_name`定义

    > 该文件夹需要手动创建，命令如下：
    >
    > ```bash
    > # mkdir /var/run/pgpool
    > ```

#### 下载源代码

Redhat系列发行版可以使用`yum`命令参照Pgpool的[Yum Repository](https://www.pgpool.net/mediawiki/index.php/Downloads#pgpool-II_Yum_repository)进行安装

编译Pgpool-II的话不要从[Source](https://www.pgpool.net/mediawiki/index.php/Downloads#Source)下载打包好的源码，从[PostgreSQL's git repository](https://git.postgresql.org/gitweb)下载未经打包的

> *打包好的源码编译过程中一直报错`collect2: error: ld returned 1 exit status`并且怎么修改都没用，未经打包的源码编译时虽然也会报错，但修改后能够编译通过*

#### Pgpool-II的编译依赖

- GNU `make` 3.80或更高版本

  获取make版本：

  ```bash
  $ make --version
  ```

- ISO/ANSI C编译器，建议使用最新版本的GNU Compiler Collection，即`gcc`

- `gzip`和`tar`

- postgresql-libs和postgresql-devel

- `git`

- libmemcached

  可选依赖，取决于是否要开启Pgpool-II的内存缓存查询功能

#### 编译安装Pgpool-II

Pgpool-II源代码（clone得到pgpool2文件夹）和依赖都准备好之后开始编译安装

1. 进到pgpool2文件夹

   ```bash
   $ cd /path/to/pgpool2
   ```

2. 修改configure脚本

   因为Pgpool-II的configure里写死了`automake`的版本号，可能与进行编译的机器上安装的`automake`版本不符，会导致之后的编译失败，所以需要将`automake`版本重新指定为当前进行编译的机器的`automake`版本

   - 获取编译机的`automake`版本

     ```bash
     $ automake --version
     ```

     ![automake version](https://gitee.com/YJ1516/MyPic/raw/master/picgo/automake_version.png)

   - 编辑configure脚本

     使用编辑器打开configure文件，定位到变量**am__api_version的**定义位置之后，将其值修改为编译机的`automake`版本号之后保存修改并退出

     ![am__api_version](https://gitee.com/YJ1516/MyPic/raw/master/picgo/am__api_version.png)

     > **注意：**
     >
     > 1. **am__api_version**是两个下划线+一个下划线的格式
     > 2. 编译机的`automake`版本是*1.16.2*，将**am__api_version**的值修改为*1.16*或*1.16.2*都可以
     > 3. 如果**am__api_version**原值和编译机的`automake`版本一样当然不用修改

3. 配置编译参数

   执行以下命令配置编译参数：

   ```bash
   $ ./configure --with-memcached=/usr/include
   ```

   configure脚本有以下主要参数（其他参数请查看`./configure --help`）：

   - `--prefix=path`

     指定Pgpool-II的安装路径，默认值是`/usr/local`，建议使用默认值

   - `--with-pgsql=path`

     指定PostgreSQL的安装路径，默认由`pg_config`命令提供

   - `--with-openssl`

     开启OpenSSL支持，默认关闭

   - `--with-memcached=path`

     内存缓存查询功能，如果开启需要安装`libmemcached`并指定其头文件(.h)的路径，示例中配置开启

     > 不同系统的`libmemcached`安装位置可能不一样

4. 编译

   编译参数配置完成之后，执行以下命令进行编译：

   ```bash
   $ make
   ```

5. 安装

   编译完成之后，执行以下命令进行安装：

   ```bash
   # make install
   ```

   可执行文件安装在`/usr/local/bin`，配置文件在`/usr/local/etc`，动态链接库文件在`/usr/local/lib`

6. 加载动态链接库

   因为Pgpool-II的动态链接库安装在`/usr/local/lib`，系统不能自动加载该路径下的文件，需要手动配置

   > 不加载该动态链接库的话之后使用Pgpool-II函数会报错：
   >
   > ```bash
   > 错误:  无法加载库 "/usr/lib/postgresql/pgpool_adm.so": libpcp.so.1: 无法打开共享对象文件: 没有那个文件或目录
   > ```

   - 新建`/etc/ld.so.conf.d/pcp.conf`文件并编辑，写入以下内容：

     ```bash
     /usr/local/lib
     ```

     > 即`libpcp.so.1`的文件路径

   - 加载动态链接库

     ```bash
     # ldconfig
     ```

     运行该命令手动加载新的动态链接库，正确配置`/etc/ld.so.conf.d/pcp.conf`文件之后每次重启系统都会自动加载

#### 编译安装Pgpool-II函数

Pgpool-II函数不是必须安装的，但是官方强烈建议安装

pgpool2文件夹里自带了Pgpool-II函数的源码

1. 进到Pgpool-II函数的源码文件夹

   ```bash
   $ cd /path/to/pgpool2/src/sql
   ```

2. 编译

   ```bash
   $ make
   ```

3. 安装

   ```bash
   # make install
   ```

   安装路径是`/usr/lib/postgresql`：

   > 即PostreSQL的动态链接库路径，不同系统可能不一样

   - pgpool_adm.so
   - pgpool-recovery.so
   - pgpool-regclass.so

#### 使用Pgpool-II函数

1. 创建extension

   连接到PostgreSQL服务之后，执行以下指令创建extension：

   ```sql
   create extension pgpool_adm ;
   create extension pgpool_recovery ;
   create extension pgpool_regclass ;
   ```

2. 查看执行结果

   ```sql
   \x
   \df
   ```

   `\x`指令打开扩展显示以方便阅读；`\df`指令查看函数列表，有19行记录：

   ![函数列表](https://gitee.com/YJ1516/MyPic/raw/master/picgo/extension.png)

#### 配置Pgpool-II

Pgpool-II配置文件修改完成保存之后可以运行`pgpool reload`将改动的配置项热更新到pgpool进程

重要配置文件：

- pgpool.conf：用于设置Pgpool-II的模式、数据库的相关信息等
- pcp.conf：存储Pgpool-II的用户ID及其md5加密的密码，`pcp_*`命令用于管理查看节点信息
- pool_passwd：保存PostgreSQL的用户ID及其md5加密的密码
- pool_hba.conf：用于认证Pgpool-II的用户登录方式，如客户端IP限制等，类似于PostgreSQL的pg_hba.con文件

##### pgpool.conf

pgpool.conf是Pgpool-II的主配置文件，Pgpool-II安装的时候自带了多个不同后缀的示例文件，不同后缀代表不同的模式

> | 配置文件名                     | Pgpool-II模式              | 备注                            |
> | ------------------------------ | -------------------------- | ------------------------------- |
> | pgpool.conf.sample-stream      | Streaming replication mode |                                 |
> | pgpool.conf.sample-replication | Replication mode           |                                 |
> | pgpool.conf.sample-slony       | Slony mode                 |                                 |
> | pgpool.conf.sample-raw         | Raw mode                   |                                 |
> | pgpool.conf.sample-logical     | Logical replication mode   |                                 |
> | pgpool.conf.sample             | Streaming replication mode | 和pgpool.conf.sample-stream一样 |

1. 创建pgpool.conf

   ```bash
   # cp /usr/local/etc/pgpool.conf.sample-stream /usr/local/etc/pgpool.conf
   ```

   使用Streaming replication模式，这是最推荐且使用最广泛的模式

2. 编辑pgpool.conf

   以下所列是pgpool.conf中最基本的配置项，pgpool.conf的详细配置请看[config setting](https://www.pgpool.net/docs/latest/en/html/config-setting.html)和[example configs](https://www.pgpool.net/docs/latest/en/html/example-configs.html)

   - `listen_addresses`

     Pgpool-II主进程的监听地址，默认值'localhost'

   - `port`

     Pgpool-II主进程使用的端口，默认值9999

   - `socket_dir`

     Pgpool-II主进程的Unix domain socket文件的存储路径，默认值'/tmp'

     需要设置成和PostgreSQL的Unix domain socket文件同一路径，否则`pgpool`命令会报错

   - `pcp_listen_addresses`

     pcp进程的监听地址，默认值'*'

   - `pcp_port`

     pcp进程使用的端口，默认值9898

   - `pcp_socket_dir`

     pcp进程的Unix domain socket文件的存储路径，默认值'/tmp'

     需要设置成和PostgreSQL的Unix domain socket文件同一路径，否则`pcp_*`命令会报错

   - `backend_hostname*`

     PostgreSQL的监听地址。最后的'*'表示该参数可以有多个，取值从0开始递增

   - `backend_port*`

     PostgreSQL使用的端口。最后的'*'表示该参数可以有多个，取值从0开始递增

   - `backend_weight*`

     负载均衡模式下后端的权重。最后的'*'表示该参数可以有多个，取值从0开始递增

   - `backend_data_directory*`

     PostgreSQL的数据目录。最后的'*'表示该参数可以有多个，取值从0开始递增

   - `connection_cache`

     设置是否激活连接池。连接池里并没有template0、template1、postgres和regression这四个数据库的连接缓存

##### pcp.conf

pcp.conf是Pgpool-II的身份认证配置文件（与PostgreSQL的身份认证无关）

1. 创建pcp.conf

   ```bash
   # cp /usr/local/etc/pcp.conf.sample /usr/local/etc/pcp.conf
   ```

   

2. 生成内容

   pcp.conf配置项的格式为：

   ```bash
   username:[md5 encrypted password]
   ```

   使用以下命令自动生成md5加密后的密码：

   ```bash
   $ pg_md5 your_password
   ```

   > 不要加`--username`参数，否则是为pool_passwd生成配置内容并且会自动写入
   >
   > 将'your_password'替换为实际密码

   如果不想显式输入密码，使用以下命令：

   ```bash
   $ pg_md5 -p
   ```

   ![pg_md5](https://gitee.com/YJ1516/MyPic/raw/master/picgo/pg_md5.png)

3. 写入pcp.conf

   将用户ID及生成的md5密码组合成正确的格式后写入pcp.conf，例如假设用户ID为'test'，那么要写入的内容为：

   ```bash
   test:1060b7b46a3bd36b3a0d66e0127d0517
   ```

##### pool_passwd

存储PostgreSQL的用户ID及md5加密后的密码

使用以下命令自动生成ID密码对并写入pool_passwd：

```bash
# pg_md5 --md5auth --prompt --username=postgres
```

示例假设用户ID是'postgres'，密码是隐式输入的

命令执行完之后查看pool_passwd文件，生成的ID密码对已经写入进去了

如果还要增加其他用户ID,再次执行该命令并将`--username`设为对应ID，生成的ID密码对会自动追加到pool_passwd

##### pool_hba.conf

pool_hba.conf用于设定允许连接Pgpool-II的IP/Host、客户端的验证方式、允许连接的用户ID及允许其访问的数据库

pool_hba.conf原有内容如下：

```yaml
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD

# "local" is for Unix domain socket connections only
local   all         all                               trust
# IPv4 local connections:
host    all         all         127.0.0.1/32          trust
host    all         all         ::1/128               trust
```

> 因为这仅是测试，所以使用pool_hba.conf原有的内容即可，正式使用需要修改

##### pgpool-ii.service

创建Pgpool-II的服务文件，以便使用systemd进行管理

1. 创建`/etc/systemd/system/pgpool-ii.service`文件

   写入以下内容：

   ```toml
   [Unit]
   Description=PGPool-II Middleware Between PostgreSQL Servers And PostgreSQL Database Clients
   After=syslog.target network.target

   [Service]
   ExecStart=/usr/local/bin/pgpool -n

   [Install]
   WantedBy=multi-user.target
   ```

2. 管理pgpool-ii服务

   设置pgpool-ii服务开机自启：

   ```bash
   # systemctl enable pgpool-ii
   ```

   开启pgpool-ii服务：

   ```bash
   # systemctl start pgpool-ii
   ```

   停止pgpool-ii服务：

   ```bash
   # systemctl stop pgpool-ii
   ```

   重启pgpool-ii服务：

   ```bash
   # systemctl restart pgpool-ii
   ```

   查看pgpool-ii服务状态：

   ```bash
   $ systemctl status pgpool-ii
   ```

   禁止pgpool-ii服务开机自启：

   ```bash
   # systemctl disable pgpool-ii
   ```

#### 测试Pgpool-II

PostgreSQL开启Streaming Replication (SR)，Pgpool-II使用Streaming replication mode并开启负载均衡

**注意：**Pgpool-II的所有命令，如果有参数能够指定`hostname`的，都要加上这个参数，否则默认使用Unix Socket进行通讯，而尽管在配置文件pgpool.conf里配置了Unix domain socket文件的地址，命令中还是使用默认的Unix domain socket文件地址，导致出现以下报错：

```bash
ERROR: connection to socket "/tmp/.s.PGSQL.9898" failed with error "No such file or directory"
```

>  实际配置的.s.PGSQL.9898路径应该是`/var/run/postgresql/.s.PGSQL.9898`

所以要指定`hostname`以使用TCP/IP通讯

##### 测试环境参数

- 127.0.0.1:9999：pgpool主进程
- 127.0.0.1:9898：pcp进程
- 127.0.0.1:5433：PostgreSQL主要节点(Primary)，数据目录`data_5433`
- 127.0.0.1:5434：PostgreSQL次要节点(Standby)，数据目录`data_5434`

##### 配置PostgreSQL测试环境

开启PostgreSQL的SR，使用`pg_ctl`开启两个PostgreSQL用于测试

[参考PostgreSQL Wiki（注意有些描述已过时）](https://wiki.postgresql.org/wiki/Streaming_Replication)

首先使用以下命令创建两个数据目录：

```bash
$ mkdir data_5433 data_5434
```

###### 配置主要节点(Primary)

1. 初始化数据目录

   ```bash
   $ initdb --locale=en_US.UTF-8 --encoding=UTF8 --pgdata=./data_5433 --username=postgres
   ```

2. 编辑`data_5433/postgresql.conf`

   要修改的配置项有：

   - `listen_addresses`

     默认值是'localhost'，如果PostgreSQL主备节点和Pgpool-II不在同一台机器上，需要设为0.0.0.0

   - `port`

     默认值是5432，因为是主要节点，修改为5433

   - `wal_level`

     默认值是'replica'，其他允许的值为'minimal'、'logical'，因为测试中主要节点只是作为SR的来源，所以使用默认值'replica'，其他值的作用请自行测试

   - `max_wal_senders`

     默认值是10，测试保持默认值

   - `wal_keep_segments`

     默认值是10，可以适当增大，测试设为64

3. 编辑`data_5433/pg_hba.conf`

   因为Pgpool-II和PostgreSQL主备节点是在同一台机器上所以不用修改该文件，否则要修改

4. 启动主要节点

   ```bash
   $ pg_ctl --wait --pgdata=./data_5433 start
   ```

5. 创建用户

   在主要节点创建用户replication，密码是'password'，该用户具有**REPLICATION**和**LOGIN**权限：

   ```sql
   CREATE ROLE replication WITH REPLICATION PASSWORD 'password' LOGIN
   ```

###### 配置备用节点(Standby)

1. 从主要节点生成基本备份放置到备用节点

   **要确保备用节点的数据目录data_5434是一个空文件夹**

   ```bash
   $ pg_basebackup --pgdata=./data_5434 --format=p --wal-method=stream --write-recovery-conf --checkpoint=fast --progress --verbose --host=127.0.0.1 --port=5433  --username=replication
   ```

   该命令会获取主要节点整个数据目录并放置到备用节点

   > 有的教程说需要创建“恢复命令文件”recovery.conf，因为上述命令的`--write-recovery-conf`参数会自动生成恢复命令，不再需要该文件

2. 编辑`data_5434/postgresql.conf`

   要修改的配置项有：

   - `port`

     因为是从主要节点备份的，默认值是5433，修改为5434

3. 编辑`data_5434/pg_hba.conf`

   因为Pgpool-II和PostgreSQL主备节点是在同一台机器上所以不用修改该文件，否则要修改

4. 修改目录权限

   要想启动PostgreSQL，它的数据文件夹权限必须是**0700**，主要节点的数据目录`data_5433`已经通过`initdb`命令自动修改了权限，备用节点的数据目录`data_5434`需要手动修改权限：

   ```bash
   $ chmod 0700 data_5434
   ```

5. 启动备用节点

   ```bash
   $ pg_ctl --wait --pgdata=./data_5434 start
   ```

###### 测试PostgreSQL的SR

1. 测试SR功能

   - 在主要节点创建一个User和Database

     ```sql
     create user user_test ;
     create database db_test ;
     ```

     使用`\du`指令分别查看主备节点的角色列表：

     ![du](https://gitee.com/YJ1516/MyPic/raw/master/picgo/du.png)

     使用`\l`指令分别查看主备节点的数据库列表：

     ![l](https://gitee.com/YJ1516/MyPic/raw/master/picgo/l.png)

     左边是主要节点，右边是备用节点。可以看到只在主要节点执行了`CREATE`指令，右边的备用节点也出现了名为'user_test'的角色和名为'db_test'的数据库

   - 其他功能请自行测试

2. 查看SR进度

   使用以下命令查看：

   ```bash
   ps aux | grep sender
   ps aux | grep receiver
   ```

3. 查看SR状态

   在主要节点执行以下指令查看SR的状态：

   ```sql
   \x
   select * from pg_stat_replication ;
   ```

   `\x`指令打开扩展显示，否则输出的阅读性太差

   ![pg_stat_replication](https://gitee.com/YJ1516/MyPic/raw/master/picgo/pg_stat_replication.png)

   可以看到已经有一个备用节点连接了主要节点，其中：

   - `client_addr`是备用节点地址
   - `state`的值`streaming`代表使用的是流复制(SR)模式
   - `sync_state`的值`async`代表使用异步复制

##### 配置Pgpool-II测试环境

1. 配置pgpool.conf

   拷贝pgpool.conf.smple-stream作为配置文件pgpool.conf

   按照[配置Pgpool-II](#配置Pgpool-II)配置好基本参数之后就可以了，因为pgpool.conf.smple-stream一般是默认关闭Native Replication mode且开启了负载均衡，但还是检查一下以下配置项为好：

   - `replication_mode`

     是否开启Native Replication mode，默认值'off'，不能设为'on'

   - `load_balance_mode`

     是否开启负载均衡，默认值是'on'，不要设为'off'

2. 启动pgpool-ii服务

   ```bash
   # systemctl start pgpool-ii
   ```

3. 连接到Pgpool-II

   ```bash
   $ psql --host=127.0.0.1 --port=9999 --username=postgres --dbname=postgres
   ```

4. 查看Pgpool-II信息

   - 使用以下指令查看Pgpool-II的状态：

     ```sql
     show pool_nodes ;
     ```

     ![pool_nodes](https://gitee.com/YJ1516/MyPic/raw/master/picgo/pool_nodes.png)

     可以看到两个节点，其中：

     - `node_id`是节点编号，有节点0和节点1
     - `hostname`和`port`是节点的连接参数
     - `status`是节点状态，确保都是'up'
     - `lb_weight`是节点负载均衡权重，两个节点的权重是一样的
     - `role`是节点扮演的角色，节点0是主要(primary)节点，节点1是备用(standby)节点
     - `load_balance_node`值与节点的角色无关，当客户端进行连接的时候，Pgpool-II根据`lb_weight`选择一个节点进行负载均衡，被选中的就是'true'，未被选中的是'false'

   - 使用以下指令查看Pgpool-II的版本：

     ```sql
     show pool_version ;
     ```

     ![pool_version](https://gitee.com/YJ1516/MyPic/raw/master/picgo/pool_version.png)

   - 使用以下指令查看Pgpool-II的所有配置信息：

     ```sql
     pgpool show all ;
     ```

     ![pool_all_config](https://gitee.com/YJ1516/MyPic/raw/master/picgo/pool_all_conf.png)


##### Pgpool-II负载均衡测试

1. 在主要节点创建一个名为test的数据库

   ```sql
   create database test ;
   ```

2. 在主要节点执行以下命令来初始化test数据库

   ```bash
   $ pgbench --username=postgres --initialize --port=5433 test
   ```

   ![init_db](https://gitee.com/YJ1516/MyPic/raw/master/picgo/init_db.png)

3. 进行负载均衡测试

   ```bash
   $ pgbench --username=postgres --port=9999 --client=10 --jobs=10 --select-only --time=60 test
   ```

   ![pgbench](https://gitee.com/YJ1516/MyPic/raw/master/picgo/pgbench.png)

4. 查看测试结果

   - 连接Pgpool-II

     ```bash
     $ psql --host=127.0.0.1 --port=9999 --username=postgres --dbname=postgres
     ```

   - 查看节点信息

     ```sql
     show pool_nodes ;
     ```

     ![bench cnt](https://gitee.com/YJ1516/MyPic/raw/master/picgo/bench_cnt.png)

     如图每个节点的`select_cnt`现实的是分配给每个节点的`SELECT`数量，由于主备节点的权重一样，Pgpool-II会尝试分派相等数量的`SELECT`

### PgBouncer

PostgreSQL的轻量级连接池

#### 安装

```bash
# pacman -S pgbouncer
```

#### 作用

- 维护和PostgreSQL的连接的缓存，为连接请求分配空闲的连接进程，而不需要PostgreSQL一直fork新的进程徒增资源消耗
- 提高连接利用率（重用），避免连接过多导致数据库对资源消耗过大
- 对连接进行限制，防止恶意请求

#### 轻量级的体现

- 通过libevent进行socket通信，提高通信效率
- 使用C编写，每个连接仅消耗2kb内存

#### 三种连接池模型

- **session**：会话级连接。在生命周期内，连接池分配一个数据库连接，客户端断开连接时，连接池回收连接
- **transaction**：事务级连接。客户端每个事务结束时，连接池回收连接，再次执行事务时需要重新获取连接
- **statement**：语句级连接。执行完一个SQL语句时，连接池回收连接，再次执行SQL时需要重新获取连接。这种模式客户端需要设置*autocommit*模式

#### 配置

##### 配置PgBouncer服务

1. 创建`/var/log/pgbouncer`文件夹并修改归属为'pgbouncer:pgbouncer'

   ```bash
   # makedir /var/log/pgbouncer
   # chown pgbouncer:pgbouncer /var/log/pgbouncer
   ```

2. 创建配置文件pgbouncer.ini和用户列表文件userlist.txt

   ```bash
   # cp /usr/share/doc/pgbouncer/userlist.txt /etc/pgbouncer/userlist.txt
   # cp /usr/share/doc/pgbouncer/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
   ```

3. 修改`/etc/pgbouncer/pgbouncer.ini`中的配置项**unix_socket_dir**

   > 原始值是'/run/postgresql'，修改为'/run/pgbouncer'
   >
   > 该配置项定义了pgbouncer的Unix Socket文件位置，因为pgbouncer不属于postgresql组，没有`/run/postgresql`文件夹的操作权限，所以要改成它自己的`/run/pgbouncer`

以上三项配置完成之后，即可使用systemd启用并立即运行pgbouncer服务：

```bash
# systemctl enable --now pgbouncer
```

##### 配置userlist.txt

userlist.txt指定了能够连接PostgreSQL的用户ID，并配置了对应ID的密码（经过md5加密）

1. 修改`/etc/pgbouncer/pgbouncer.ini`中的配置项**auth_type**

   原始值是'trust'，修改为`md5`

   > 该参数定义了身份认证方法

2. 获取用户名及其对应的暗文密码

   有两种方式：

   - 使用`psql`

     ```bash
     $ psql --host=127.0.0.1 --port=5432 --username=postgres -c "SELECT concat('\"', usename, '\" \"', passwd, '\"') FROM pg_shadow"
     ```

     输出结果是已经经过md5加密后的暗文密码，可以直接使用

     通过修改'--username'参数的值可以获得指定用户名的暗文密码

   - 使用Python脚本

     ```python
     import hashlib

     username = ""
     password = ""

     md5 = hashlib.md5()
     md5.update((username + password).encode('UTF-8'))

     print('"{}" "{}"'.format(username, 'md5'+md5.hexdigest()))
     ```

     填写'username'和'password'的值并运行该脚本，输出结果就是userlist.txt需要的内容

3. 修改`/etc/pgbouncer/userlist.txt`

   获取到暗文密码之后，将之填入`/etc/pgbouncer/userlist.txt`中，需要和用户名一一对应，格式如下：

   ```yaml
   "postgres" "md53175bce1d3201d16594cebf9d7eb3f9d"
   ```

   > 这是PostgreSQL默认用户'postgres'及其密码'postgres'加密后的值
