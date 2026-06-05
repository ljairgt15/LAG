/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-04-29		  57747			 Initial Code - Add EntityRelationId column to HistoricoDimensiones
*/
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'HistoricoDimensiones'
    AND TABLE_SCHEMA = 'dbo'
    AND COLUMN_NAME = 'EntityRelationId'
)
BEGIN
    ALTER TABLE [dbo].[HistoricoDimensiones]
    ADD [EntityRelationId] VARCHAR(16) NULL;
 
    PRINT 'Column EntityRelationId added to HistoricoDimensiones table successfully.'
END
ELSE
BEGIN
    PRINT 'Column EntityRelationId already exists in HistoricoDimensiones table.'
END
 