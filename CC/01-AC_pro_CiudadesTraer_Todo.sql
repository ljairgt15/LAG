/*    
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_CiudadesTraer_Todo
*/

CREATE OR ALTER PROCEDURE [dbo].[AC_pro_CiudadesTraer_Todo]
AS
BEGIN
		SELECT
		PA.ocupadopor,
		CI.nombre,
		PA.codigopais,
		CI.codigociudad
		FROM	ciudades CI
		LEFT JOIN paises PA ON CI.idpaises = PA.id
END

/*
EXEC [dbo].[AC_pro_CiudadesTraer_Todo]
*/
