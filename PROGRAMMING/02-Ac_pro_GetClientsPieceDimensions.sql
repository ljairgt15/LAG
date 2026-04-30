/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-04-29		  57747			 Based on pro_ObtenerDimensionesPiezasClientes
*/

CREATE OR ALTER   PROCEDURE [dbo].[Ac_pro_GetClientsPieceDimensions]
    @IdClientes VARCHAR(MAX)
AS
BEGIN
	CREATE TABLE #idClientes
	(
		idCliente VARCHAR(16)
	)

	INSERT INTO #idClientes
	(
		idCliente
	)
	SELECT idCliente
	FROM
		OPENJSON(@IdClientes)
		WITH
		(
			idCliente VARCHAR(16) '$.idCliente'
		)

	SELECT 
		ROW_NUMBER() OVER (ORDER BY H.idCliente) AS id,
		H.idCliente,
		H.tipoPiezaInventario AS tipoPieza,
		AVG(H.largo/2.54) AS largo,
		AVG(H.alto/2.54) AS alto,
		AVG(H.ancho/2.54) AS ancho
	FROM HistoricoDimensiones H WITH(NOLOCK)
	INNER JOIN #idClientes C ON H.idCliente = C.idCliente
	GROUP BY H.idCliente, H.tipoPiezaInventario

END

/*
EXEC pro_ObtenerDimensionesPiezasClientes @IdClientes=N'[{"idCliente":"mhBQEBFmGwmE"},{"idCliente":"CLI0416427"},{"idCliente":"CLI012407"},{"idCliente":"mhBQEBFmGwmE"},{"idCliente":"CLI0420931"},{"idCliente":"CLI0116944"},{"idCliente":"CLI0120245"},{"idCliente":"CLI0421137"},{"idCliente":"CLI0420932"},{"idCliente":"CLI015247"}]'
*/