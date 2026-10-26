/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Sp generic
*/


CREATE  OR ALTER PROCEDURE [dbo].[pro_LogError]
AS
BEGIN
    --====================================        
    DECLARE @MENSAJE_ERROR NVARCHAR(4000);
    DECLARE @NUMERO_ERROR INT;
    DECLARE @ERROR_SEVERITY INT;
    DECLARE @ERROR_STATE INT;
    --====================================    

		SELECT @MENSAJE_ERROR = ERROR_MESSAGE(),
               @NUMERO_ERROR = ERROR_NUMBER(),
               @ERROR_SEVERITY = ERROR_SEVERITY(),
               @ERROR_STATE = ERROR_STATE();
			   
	INSERT INTO [dbo].[LogErrores] 
	SELECT GETDATE(), ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE()

    RAISERROR(@MENSAJE_ERROR, @ERROR_SEVERITY, @ERROR_STATE);

END


GO


