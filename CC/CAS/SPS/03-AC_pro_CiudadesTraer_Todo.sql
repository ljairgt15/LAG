/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_CiudadesTraer
*/

CREATE OR ALTER PROCEDURE [dbo].[AC_pro_CiudadesTraer_Todo]
AS
BEGIN
	BEGIN TRY
		SELECT
			PA.ocupadopor,
			CI.nombre,
			PA.codigopais,
			CI.codigociudad
		FROM Ciudades CI
		LEFT JOIN paises PA ON CI.idpaises = PA.id
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
/*
EXEC [dbo].[AC_pro_CiudadesTraer_Todo]
*/