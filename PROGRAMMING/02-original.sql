/*
VERSION			AUTOR					FECHA				 HU					CAMBIO                                                                                   
  1			Cristhian Cuichan			15/03/2024		  CC 37016  		Codigo inicial para listar informacion de los pesos de las dimensiones de piezas historicos
*/

ALTER   PROCEDURE [dbo].[pro_ObtenerDimensionesPiezasClientes]
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