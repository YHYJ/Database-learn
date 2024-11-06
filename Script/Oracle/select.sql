--  从 all_tab_columns 视图查询指定表的列名
SELECT COLUMN_NAME FROM all_tab_columns WHERE TABLE_NAME = 'TableName' ORDER BY COLUMN_ID

--  从 all_tab_statistics 视图查询指定表的行数（估算）
SELECT
    NUM_ROWS
FROM
    ALL_TAB_STATISTICS
WHERE
    OWNER = 'SchemaName'
    AND TABLE_NAME = 'TableName';

--  查询最新TIMESTAMP（可替换成其他字段）的所有数据
SELECT
    *
FROM
    TableName
WHERE
    "TIMESTAMP" = (
        SELECT
            MAX ("TIMESTAMP")
        FROM
            TableName
    )

--  查询指定TIMESTAMP（可替换为其他字段）内的所有数据
--  因为SQL中不区分大小写，为避免代表分钟的'mm'和代表月份的'MM'混淆，使用'mi'代表分钟
SELECT
    *
FROM
    TableName
WHERE
    "TIMESTAMP" > "TO_DATE" (
        '2023-01-10 00:00:00',
        'yyyy-mm-dd hh24:mi:ss'
    )
AND "TIMESTAMP" < "TO_DATE" (
    '2023-01-10 12:00:00',
    'yyyy-mm-dd hh24:mi:ss'
)

--  查询指定TIMESTAMP（可替换为其他字段）内所有重复数据（指定重复字段）
SELECT
    *
FROM
    TableName
WHERE
    (STATION, "TIMESTAMP") IN (
        SELECT
            STATION,
            "TIMESTAMP"
        FROM
            TableName
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
    TableName
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
    TableName
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
SELECT
    file_name,
    status
FROM
    dba_data_files
WHERE
    file_id = 583;
