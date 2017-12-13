USE _DATABASE_NAME_;
GO
SELECT * FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE';
GO

-- OR SELECT * FROM sys.objects

SELECT * FROM sys.objects
WHERE EXISTS(
	SELECT * FROM MASTER.INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_TYPE = 'PROCEDURE'
	);
GO

SELECT name, type
FROM dbo.sysobjects
WHERE type IN (
    'P', -- stored procedures
    'FN', -- scalar functions 
    'IF', -- inline table-valued functions
    'TF' -- table-valued functions
)
ORDER BY type, name

select * from information_schema.columns;
go
select * from sys.types;
go
select * from sys.objects;
go

