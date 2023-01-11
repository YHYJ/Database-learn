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
	"TO_DATE" (
		'2023-01-10 00:00:00',
		'yyyy-mm-dd hh24:mi:ss'
	) < "TIMESTAMP"
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
