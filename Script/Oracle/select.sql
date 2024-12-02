-- 查看指定表所属用户
SELECT OWNER, TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME = '<TableName>'

-- 查看指定表的 DDL
SELECT DBMS_METADATA.GET_DDL('TABLE', '<TableName>', '<SchemaName>') AS DDL FROM DUAL

-- 分页查询第10到100行数据（Oracle 12c 以下）
-- 在循环分页获取数据时，由于伪列 ROWNUM 在每次循环中都是从1开始分配的，这会导致每次循环都会扫描整个表或索引直到找到符合条件的数据，从而导致性能问题
SELECT * FROM (SELECT a.*, ROWNUM rnum FROM (SELECT * FROM <TableName> ORDER BY CREATEDON) a WHERE ROWNUM <= 100) WHERE rnum >= 10

-- 分页查询，跳过前10行，获取接下来的100行数据（限 Oracle 12c 及以上）
SELECT * FROM <TableName> ORDER BY CREATEDON OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY

--  从 ALL_TAB_COLUMNS 视图查询指定表的列名
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS WHERE TABLE_NAME = '<TableName>' ORDER BY COLUMN_ID

-- 更新 ALL_TAB_STATISTICS 统计信息
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => '<SchemaName>',
    tabname => '<TableName>',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    method_opt => 'FOR ALL COLUMNS SIZE AUTO',
    cascade => TRUE
  );
END;
--  从 ALL_TAB_STATISTICS 视图查询指定表的行数（查询前需要先更新统计信息）
SELECT NUM_ROWS FROM ALL_TAB_STATISTICS WHERE OWNER = '<SchemaName>' AND TABLE_NAME = '<TableName>';

--  查询最新TIMESTAMP（可替换成其他字段）的所有数据
SELECT * FROM <TableName> WHERE "TIMESTAMP" = (SELECT MAX ("TIMESTAMP") FROM <TableName>)

--  查询指定TIMESTAMP（可替换为其他字段）内的所有数据
--  因为SQL中不区分大小写，为避免代表分钟的'mm'和代表月份的'MM'混淆，使用'mi'代表分钟
SELECT * FROM <TableName> WHERE "TIMESTAMP" > "TO_DATE" ('2023-01-10 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AND "TIMESTAMP" < "TO_DATE" ('2023-01-10 12:00:00', 'yyyy-mm-dd hh24:mi:ss')

--  查询指定TIMESTAMP（可替换为其他字段）内所有重复数据（指定重复字段）
SELECT
    *
FROM
    <TableName>
WHERE
    (STATION, "TIMESTAMP") IN (
        SELECT
            STATION,
            "TIMESTAMP"
        FROM
            <TableName>
        GROUP BY
            STATION,
            "TIMESTAMP"
        HAVING
            COUNT (*) > 1
    )
AND "TIMESTAMP" > "TO_DATE" (
    '2023-01-10 11:00:00',
    'yyyy-mm-dd hh24:mi:ss'
)
AND "TIMESTAMP" < "TO_DATE" (
    '2023-01-10 12:00:00',
    'yyyy-mm-dd hh24:mi:ss'
)

-- 查询指定TIMESTAMP（可替换为其他字段）内所有"STATION"字段值以'S1'或'S2'开头的数据
SELECT
    *
FROM
    <TableName>
WHERE
    (
        STATION LIKE 'S1%'
        OR STATION LIKE 'S2%'
    )
AND "TIMESTAMP" > "TO_DATE" (
    '2023-02-06 00:00:00',
    'yyyy-mm-dd hh24:mi:ss'
)
AND "TIMESTAMP" < "TO_DATE" (
    '2023-02-09 00:00:00',
    'yyyy-mm-dd hh24:mi:ss'
)

-- 查询指定TIMESTAMP（可替换为其他字段）内所有指定"STATION"值的数据，并根据TIMESTAMP倒序排列
SELECT
    *
FROM
    <TableName>
WHERE
    (
        STATION = 'S1'
    )
AND "TIMESTAMP" > "TO_DATE" (
    '2023-02-06 00:00:00',
    'yyyy-mm-dd hh24:mi:ss'
)
ORDER BY
    "TIMESTAMP" DESC

-- 报错：ORA-00376: 此时无法读取文件 583
-- 确认 ID 为 583 的文件的状态（正常是 "ONLINE"）
SELECT file_name, status FROM dba_data_files WHERE file_id = 583;
