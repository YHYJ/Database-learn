--  删除表中的重复行，每组重复数据只保留ROWID最小的行
DELETE
FROM
    TableName
WHERE
    (
        STATION,
        "TIMESTAMP"
    ) IN (
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
AND ROWID NOT IN (
    SELECT
        MIN (ROWID)
    FROM
        TableName
    GROUP BY
        STATION,
        "TIMESTAMP"
    HAVING
        COUNT (*) > 1
)
