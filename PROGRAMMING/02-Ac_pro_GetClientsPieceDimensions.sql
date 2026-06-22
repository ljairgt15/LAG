/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-04-29		  57747			 Based on pro_ObtenerDimensionesPiezasClientes
*/

CREATE OR ALTER PROCEDURE [dbo].[Ac_pro_GetClientsPieceDimensions]
    @RelationIds VARCHAR(MAX)
AS
BEGIN
	CREATE TABLE #RelationIds
	(
		EntityRelationId VARCHAR(16)
	)

	INSERT INTO #RelationIds
	(
		EntityRelationId
	)
	SELECT EntityRelationId
	FROM
		OPENJSON(@RelationIds)
		WITH
		(
			EntityRelationId VARCHAR(16) '$.EntityRelationId'
		)

	SELECT 
		H.EntityRelationId AS EntityRelationId,
		H.tipoPiezaInventario AS tipoPieza,
		AVG(H.largo/2.54) AS largo,
		AVG(H.alto/2.54) AS alto,
		AVG(H.ancho/2.54) AS ancho
	FROM HistoricoDimensiones H WITH(NOLOCK)
	INNER JOIN #RelationIds C ON H.EntityRelationId = C.EntityRelationId
	GROUP BY H.EntityRelationId, H.tipoPiezaInventario

END

/*
EXEC pro_ObtenerDimensionesPiezasClientes @RelationIds=N'[{"EntityRelationId":"mhBQEBFmGwmE"},{"EntityRelationId":"CLI0416427"},{"EntityRelationId":"CLI012407"},{"EntityRelationId":"mhBQEBFmGwmE"},{"EntityRelationId":"CLI0420931"},{"EntityRelationId":"CLI0116944"},{"EntityRelationId":"CLI0120245"},{"EntityRelationId":"CLI0421137"},{"EntityRelationId":"CLI0420932"},{"EntityRelationId":"CLI015247"}]'
*/