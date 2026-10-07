/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_Convenios001Traer_Todo
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_Convenios001Traer_Todo]
AS
BEGIN
	BEGIN TRY
		SELECT
		CC01.id,
		CC01.idaerolineas,
		CC01.paisorigen,
		CC01.codigoempresas,
		CC01.destino,
		CC01.fechainicial,
		CC01.fechafinal,
		CC01.codigofacturador,
		CC01.cedulalog,
		CC01.versionfila,
		CC01.vigente,
		CC01.notas,
		CC01.tipo,
		CC01.adicional
		FROM	convenioscodigo001 CC01
		WHERE	CC01.vigente = 1
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
GO
/*
EXEC [dbo].[AC_pro_Convenios001Traer_Todo]
*/