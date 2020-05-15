# README

PostgreSQL(PG)及其组件

---

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [安装和配置](#安装和配置)
* [PG的组件](#pg的组件)
    * [pgbouncer](#pgbouncer)
        * [作用](#作用)
        * [轻量级的体现](#轻量级的体现)
        * [三种连接池模型](#三种连接池模型)

<!-- vim-markdown-toc -->

---

该文档只记录在ArchLinux下安装配置PostgreSQL的过程

---

## 安装和配置

参考[Install & Deploy](./file/install-and-deploy.md)

## PG的组件

### pgbouncer

PG的轻量级连接池

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
