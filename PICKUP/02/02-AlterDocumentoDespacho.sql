/*    
VERSION     MODIFIEDBY          MODIFIEDDATE    HU      MODIFICATION
1           Jair Gomez          2026-02-05      57731   Initial Code - Add EntityReferenceId column to DocumentosDespacho
*/
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'DocumentosDespacho'
    AND TABLE_SCHEMA = 'dbo'
    AND COLUMN_NAME = 'EntityReferenceId'
)
BEGIN
    ALTER TABLE [dbo].[DocumentosDespacho]
    ADD [EntityReferenceId] VARCHAR(16) NULL;
 
    PRINT 'Column EntityReferenceId added to DocumentosDespacho table successfully.'
END
ELSE
BEGIN
    PRINT 'Column EntityReferenceId already exists in DocumentosDespacho table.'
END
 