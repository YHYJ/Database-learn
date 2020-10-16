#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
File: quick_start.py
Author: YJ
Email: yj1516268@outlook.com
Created Time: 2020-10-15 19:33:31

Description: Python操作TimescaleDB的示例程序

# TODO: 判断数据库中是否已存在某个表 <16-10-20, YJ-Work> #
"""

import psycopg2
from pgcopy import CopyManager


def createTable(conn):
    """创建数据表

    :conn: 数据库连接对象

    """
    # 创建关系表的SQL语句
    query_create_sensors_table = ("CREATE TABLE sensors "
                                  "(id SERIAL PRIMARY KEY, type VARCHAR(50), "
                                  "location VARCHAR(50));")
    # 创建普通表的SQL语句
    query_create_sensordata_table = ("CREATE TABLE sensor_data "
                                     "(time TIMESTAMPTZ NOT NULL, "
                                     "sensor_id INTEGER, "
                                     "temperature DOUBLE PRECISION, "
                                     "cpu DOUBLE PRECISION, "
                                     "FOREIGN KEY (sensor_id) REFERENCES "
                                     "sensors (id));")
    # 将普通表转换为超表的SQL语句
    query_create_sensordata_hypertable = (
        "SELECT create_hypertable('sensor_data', 'time');")

    # 创建数据库游标
    cur = conn.cursor()
    # 创建关系表sensors
    cur.execute(query_create_sensors_table)
    # 创建普通表sensor_data
    cur.execute(query_create_sensordata_table)
    # 将普通表sensor_data转换为超表
    cur.execute(query_create_sensordata_hypertable)
    # 提交更改
    conn.commit()
    # 关闭游标
    cur.close()


def insertData(conn):
    """在表中插入数据

    :conn: 数据库连接对象

    """
    # 待插入的数据
    sensors = [('a', 'fl'), ('a', 'ceiling'), ('b', 'floor'), ('b', 'ceiling')]

    # 插入数据的SQL语句
    query_insert_rows = "INSERT INTO sensors (type, location) VALUES (%s, %s);"

    # 创建数据库游标
    cur = conn.cursor()
    # 插入数据
    for sensor in sensors:
        try:
            data = (sensor[0], sensor[1])
            cur.execute(query_insert_rows, data)
        except (Exception, psycopg2.Error) as error:
            print(error.pgerror)
    # 提交更改
    conn.commit()
    # 关闭游标
    cur.close()


def insertDataFast(conn):
    """快速插入数据

    :conn: 数据库连接对象
    :returns: TODO

    """
    # 生成随机数据的SQL语句
    query_insert_rows_fast = ("SELECT generate_series("
                              "now() - interval '24 hour', "
                              "now(), "
                              "interval '5 minute') "
                              "AS time, "
                              "%s as sensor_id, "
                              "random()*100 AS temperature, "
                              "random() AS cpu")
    # 查询数据的SQL语句
    query_select_data = "SELECT * FROM sensor_data LIMIT %s;"

    # 创建数据库游标
    cur = conn.cursor()
    # 快速插入数据
    for id_ in range(1, 5):
        data = (id_, )
        cur.execute(query_insert_rows_fast, data)

        # 获取要插入的数据
        values = cur.fetchall()
        # 定义要插入的表(sensor_data)的列名
        cols = ('time', 'sensor_id', 'temperature', 'cpu')
        # 使用目标表创建CopyManager对象并插入数据
        mgr = CopyManager(conn, 'sensor_data', cols)
        mgr.copy(values)
    # 快速插入完成后提交更改
    conn.commit()
    # 检查数据是否成功插入
    num = (5, )
    cur.execute(query_select_data, num)
    print(cur.fetchall())
    # 关闭游标
    cur.close()


if __name__ == "__main__":
    host = '127.0.0.1'
    port = 5432
    username = 'postgres'
    password = 'postgres'
    dbname = 'postgres'

    CONNECTION = (
        "postgres://{username}:{password}@{host}:{port}/{dbname}").format(
            username=username,
            password=password,
            host=host,
            port=port,
            dbname=dbname)

    with psycopg2.connect(CONNECTION) as conn:
        # 创建数据表
        createTable(conn)
        # 在表中插入数据
        insertData(conn)
        # 使用pgcopy快速插入数据
        #  insertDataFast(conn)
        # 提交更改
        conn.commit()
