DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql = @sql + 'DROP TRIGGER [' + OBJECT_SCHEMA_NAME(object_id) + '].[' + name + ']; '
FROM sys.triggers
WHERE parent_class_desc = 'OBJECT_OR_COLUMN'

PRINT @sql


EXEC sp_executesql @sql;