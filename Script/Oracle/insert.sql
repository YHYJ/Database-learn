--  插入带DATE类型的数据
INSERT INTO TableName (
	STATION,
	"TIMESTAMP",
)
VALUES
	(
		'85070A',
		"TO_DATE" (
			'2023-01-10 11:59:17',
			'yyyy-mm-dd hh24:mi:ss'
		)
	)
