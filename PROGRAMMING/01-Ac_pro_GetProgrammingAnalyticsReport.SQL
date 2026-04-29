/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-04-29		  57747			 Based on pro_ReporteProgramacion_ListarInformacion
*/

ALTER         PROCEDURE [dbo].[01-Ac_pro_GetProgrammingAnalyticsReport]
    @IdGuias VARCHAR(MAX),
	@GuiaConsolidada BIT
AS
BEGIN
	CREATE TABLE #idGuias
		(
			idGuias VARCHAR(16)
		);

	CREATE TABLE #InfoGuiaCoord
	(
		Id VARCHAR(16),
		IdGuiaConsolidada VARCHAR(16),
		FechaEmbarque DATETIME NULL,
		Origin VARCHAR(16),
		ShipmentNr VARCHAR(32),
		Consignatario VARCHAR(512),
		ShipTo VARCHAR(256),
		FB DECIMAL(18,3) NULL,
		Carrier VARCHAR(512),
		ShippingDate DATETIME NULL,
		IdEmpresa VARCHAR(16),
		IdClienteFinal VARCHAR(16),
		IdCoordinacion VARCHAR(16),
		CodigoBarra VARCHAR(16),
		CodigoBarraInv VARCHAR(16),
		IdInventarioTemp UNIQUEIDENTIFIER NULL,
		CajasCoordinadas DECIMAL(18,3) NULL,
		PiezasCoordinadas DECIMAL NULL,
		FbWh DECIMAL(18,3) NULL,
		IdCodigoBarra VARCHAR(16),
		EsInventarioTemporal BIT NULL,
		CabeceraCoordinacion BIT NULL,
		Largo DECIMAL(9,3),
		Alto DECIMAL(9,3),
		Ancho DECIMAL(9,3),
		IdClienteConsignee VARCHAR(16),
		TipoPieza VARCHAR(8)
	)

	CREATE TABLE #CoordinacionesAux
	(
		Id VARCHAR(16),
		IdGuiaConsolidada VARCHAR(16),
		FechaEmbarque DATETIME NULL,
		Origin VARCHAR(16),
		ShipmentNr VARCHAR(32),
		Consignatario VARCHAR(512),
		ShipTo VARCHAR(256),
		FB DECIMAL(18,3) NULL,
		Carrier VARCHAR(512),
		ShippingDate DATETIME NULL,
		IdEmpresa VARCHAR(16),
		IdClienteFinal VARCHAR(16),
		IdCoordinacion VARCHAR(16),
		CodigoBarra VARCHAR(16),
		CodigoBarraInv VARCHAR(16),
		IdInventarioTemp UNIQUEIDENTIFIER NULL,
		CajasCoordinadas DECIMAL(18,3) NULL,
		PiezasCoordinadas DECIMAL NULL,
		FbWh DECIMAL(18,3) NULL,
		IdCodigoBarra VARCHAR(16),
		EsInventarioTemporal BIT NULL,
		CabeceraCoordinacion BIT NULL,
		NoProgramable BIT NULL,
		Largo DECIMAL(9,3),
		Alto DECIMAL(9,3),
		Ancho DECIMAL(9,3),
		IdClienteConsignee VARCHAR(16),
		TipoPieza VARCHAR(8)
	)

	CREATE TABLE #InfoCBTemporal
	(
		Id VARCHAR(16),
		IdGuiaConsolidada VARCHAR(16),
		FechaEmbarque DATETIME NULL,
		Origin VARCHAR(16),
		ShipmentNr VARCHAR(32),
		Consignatario VARCHAR(512),
		ShipTo VARCHAR(256),
		FB DECIMAL(5,3) NULL,
		Carrier VARCHAR(512),
		ShippingDate DATETIME NULL,
		IdEmpresa VARCHAR(16),
		IdClienteFinal VARCHAR(16),
		IdCoordinacion VARCHAR(16),
		CodigoBarra VARCHAR(16),
		CodigoBarraInv VARCHAR(16),
		IdInventarioTemp UNIQUEIDENTIFIER NULL,
		CajasCoordinadas DECIMAL(18,3) NULL,
		PiezasCoordinadas DECIMAL NULL,
		FbWh DECIMAL(18,3) NULL,
		IdCodigoBarra VARCHAR(16),
		EsInventarioTemporal BIT NULL,
		CabeceraCoordinacion BIT NULL,
		NoProgramable BIT NULL,
		Largo DECIMAL(9,3),
		Alto DECIMAL(9,3),
		Ancho DECIMAL(9,3),
		IdClienteConsignee VARCHAR(16),
		TipoPieza VARCHAR(8)
	)

	INSERT INTO #idGuias
		(
			idGuias
		)
		SELECT idGuia
		FROM
			OPENJSON(@IdGuias)
			WITH
			(
				idGuia VARCHAR(16) '$.idGUia'
			);

	IF(@GuiaConsolidada = 1)
		BEGIN
			/*Informeacion de coordinaciones*/
			INSERT INTO #InfoGuiaCoord
			(
				Id,
				IdGuiaConsolidada,
				FechaEmbarque,
				Origin,
				ShipmentNr,
				Consignatario,
				ShipTo,
				IdEmpresa,
				IdClienteFinal,
				IdCoordinacion,
				CodigoBarra,
				CodigoBarraInv,
				CajasCoordinadas,
				PiezasCoordinadas,
				CabeceraCoordinacion,
				IdClienteConsignee
			)
				SELECT 
					g.id AS Id,
					gc.id AS IdGuiaConsolidada,
					g.fechaEmbarque AS FechaEmbarque,
					cd.codigoIATA AS Origin,
					gc.nroGuia AS ShipmentNr,
					cl.nombre AS Consignatario,
					ISNULL(cl.nombreClienteFinal,cl.nombre) AS ShipTo, 
					g.idEmpresa AS IdEmpresa,
					cl.id AS IdClienteFinal,
					coor.id AS IdCoordinacion,
					'Test' AS CodigoBarra,
					'Test' AS CodigoBarraInv,
					coor.totalCajasCoordinacion AS CajasCoordinadas,
					coor.totalPiezasCoordinacion AS PiezasCoordinadas,
					1 AS CabeceraCoordinacion,
					cl.id AS IdClienteConsignee
				FROM #idGuias guiasTemp 
				INNER JOIN Guias g WITH(NOLOCK) ON g.idGuiaConsolidada = guiasTemp.idGuias
				INNER JOIN Guias gc WITH(NOLOCK) ON g.idGuiaConsolidada = gc.id
				INNER JOIN Coordinaciones coor WITH(NOLOCK) ON g.id = coor.idGuia
				INNER JOIN Puertos p ON g.idPuertoOrigen = p.id
				INNER JOIN Ciudades cd ON p.idCiudad = cd.id
				INNER JOIN Clientes cl WITH(NOLOCK) ON g.idCliente = cl.id
		END
	ELSE
		BEGIN
			/*Informeacion de coordinaciones*/
			INSERT INTO #InfoGuiaCoord
			(
				Id,
				FechaEmbarque,
				Origin,
				ShipmentNr,
				Consignatario,
				ShipTo,
				IdEmpresa,
				IdClienteFinal,
				IdCoordinacion,
				CodigoBarra,
				CodigoBarraInv,
				CajasCoordinadas,
				PiezasCoordinadas,
				CabeceraCoordinacion,
				IdClienteConsignee
			)
				SELECT 
					g.id AS Id,
					g.fechaEmbarque AS FechaEmbarque,
					cd.codigoIATA AS Origin,
					g.nroGuia AS ShipmentNr,
					cl.nombre AS Consignatario,
					ISNULL(cl.nombreClienteFinal,cl.nombre) AS ShipTo,
					g.idEmpresa AS IdEmpresa,
					cl.id AS IdClienteFinal,
					coor.id AS IdCoordinacion,
					'Test' AS CodigoBarra,
					'Test' AS CodigoBarraInv,
					coor.totalCajasCoordinacion AS CajasCoordinadas,
					coor.totalPiezasCoordinacion AS PiezasCoordinadas,
					1 AS CabeceraCoordinacion,
					cl.id AS IdClienteConsignee
				FROM  #idGuias guiasTemp 
				INNER JOIN guias g WITH(NOLOCK)ON g.id = guiasTemp.idGuias
				INNER JOIN Coordinaciones coor WITH(NOLOCK) ON g.id = coor.idGuia
				INNER JOIN Puertos p ON g.idPuertoOrigen = p.id
				INNER JOIN Ciudades cd ON p.idCiudad = cd.id
				INNER JOIN Clientes cl WITH(NOLOCK) ON g.idCliente = cl.id
		END
	/*Informeacion de InventarioTemporal*/
	INSERT INTO #CoordinacionesAux
	(
		Id,
		IdGuiaConsolidada,
		FechaEmbarque,
		Origin,
		ShipmentNr,
		Consignatario,
		ShipTo,
		FB,
		Carrier,
		ShippingDate,
		IdEmpresa,
		IdClienteFinal,
		IdCoordinacion,
		CodigoBarra,
		CodigoBarraInv,
		IdInventarioTemp,
		CajasCoordinadas,
		PiezasCoordinadas,
		FbWh,
		IdCodigoBarra,
		NoProgramable,
		EsInventarioTemporal,
		CabeceraCoordinacion,
		Largo,
		Alto,
		Ancho,
		IdClienteConsignee,
		TipoPieza
	)
	SELECT
		coordTemp.id,
		coordTemp.IdGuiaConsolidada,
		coordTemp.fechaEmbarque,
		coordTemp.Origin,
		coordTemp.ShipmentNr,
		coordTemp.Consignatario,
		ISNULL(clf.nombreClienteFinal, ISNULL(clf.nombre, coordTemp.ShipTo)) AS ShipTo,
		tp.equivalencia AS FB,
		tr.nombre AS Carrier,
		inv.fecha_transportador AS ShippingDate,
		coordTemp.idEmpresa,
		ISNULL(clf.id, coordTemp.IdClienteFinal) AS IdClienteFinal,
		coordTemp.IdCoordinacion,
		cb.codigoBarra AS CodigoBarra,
		inv.codigoPieza AS CodigoBarraInv,
		inv.id AS IdInventarioTemp,
		tp.equivalencia AS CajasCoordinadas,
		1 AS PiezasCoordinadas,
		cb.equivalenciaFull AS FbWh,
		cb.id AS IdCodigoBarra,
		inv.noProgramable AS NoProgramable,
		1 AS esInventarioTemporal,
		0 AS CabeceraCoordinacion,
		(cb.largo/2.54) AS Largo,
		(cb.alto/2.54) AS Alto,
		(cb.ancho/2.54) AS Ancho,
		coordTemp.IdClienteConsignee AS IdClienteConsignee,
		ISNULL(inv.empaque,cb.tipoPiezaInventario) AS TipoPieza
	FROM #InfoGuiaCoord coordTemp
	INNER JOIN InventarioTemporalCliente inv WITH(NOLOCK) ON coordTemp.IdCoordinacion = inv.idCoordinacion
	INNER JOIN TiposDePieza tp WITH(NOLOCK) ON inv.empaque = tp.tipoPieza
	LEFT JOIN CodigosDeBarra cb WITH(NOLOCK) ON inv.idCoordinacion = cb.idCoordinacion AND inv.codigoPieza = cb.codigoBarra
	LEFT JOIN CodigosRelacionSistemas crs WITH(NOLOCK) ON crs.tipoEntidad='CARRIER' AND crs.idSistemaEntidad=100 AND inv.caja_transportador = crs.codigo  
	LEFT JOIN Transportes tr WITH(NOLOCK) ON crs.idEntidad = tr.id
	LEFT JOIN CodigosRelacionSistemas crss WITH(NOLOCK) ON crss.tipoEntidad='CLIENTE'  AND crss.idSistemaEntidad=100 AND inv.codigoCliente = crss.codigo 
	LEFT JOIN Clientes clf WITH(NOLOCK) ON crss.idEntidad = clf.id

	/*Informeacion de CodigosBarras*/
	INSERT INTO #InfoCBTemporal
	(
		Id,
		IdGuiaConsolidada,
		FechaEmbarque,
		Origin,
		ShipmentNr,
		Consignatario,
		ShipTo,
		FB,
		Carrier,
		ShippingDate,
		IdEmpresa,
		IdClienteFinal,
		IdCoordinacion,
		CodigoBarra,
		CodigoBarraInv,
		IdInventarioTemp,
		CajasCoordinadas,
		PiezasCoordinadas,
		FbWh,
		IdCodigoBarra,
		NoProgramable,
		EsInventarioTemporal,
		CabeceraCoordinacion,
		Largo,
		Alto,
		Ancho,
		IdClienteConsignee,
		TipoPieza
	)
	SELECT
		coordTemp.id,
		coordTemp.IdGuiaConsolidada,
		coordTemp.fechaEmbarque,
		coordTemp.Origin,
		coordTemp.ShipmentNr,
		coordTemp.Consignatario,
		ISNULL(clf.nombreClienteFinal, ISNULL(clf.nombre, coordTemp.ShipTo)) AS ShipTo,
		tp.equivalencia AS FB,
		tr.nombre AS Carrier,
		cb.caja_fecha_transportador AS ShippingDate,
		coordTemp.idEmpresa,
		ISNULL(clf.id,coordTemp.IdClienteFinal) AS IdClienteFinal,
		coordTemp.IdCoordinacion,
		cb.codigoBarra AS CodigoBarra,
		inv.codigoPieza AS CodigoBarraInv,
		inv.id AS IdInventarioTemp,
		tp.equivalencia AS CajasCoordinadas,
		1 AS PiezasCoordinadas,
		cb.equivalenciaFull AS FbWh,
		cb.id AS IdCodigoBarra,
		inv.noProgramable AS NoProgramable,
		1 AS esInventarioTemporal,
		0 AS CabeceraCoordinacion,
		(cb.largo/2.54) AS Largo,
		(cb.alto/2.54) AS Alto,
		(cb.ancho/2.54) AS Ancho,
		coordTemp.IdClienteConsignee AS IdClienteConsignee,
		cb.tipoPiezaInventario AS TipoPieza
	FROM #InfoGuiaCoord coordTemp
	INNER JOIN CodigosDeBarra cb WITH(NOLOCK) ON coordTemp.IdCoordinacion = cb.idCoordinacion
	LEFT JOIN InventarioTemporalCliente inv WITH(NOLOCK) ON cb.idCoordinacion = inv.idCoordinacion AND cb.codigoBarra = inv.codigoPieza
	LEFT JOIN TiposDePieza tp WITH(NOLOCK) ON cb.tipoPiezaInventario = tp.tipoPieza
	LEFT JOIN CodigosRelacionSistemas crs WITH(NOLOCK) ON crs.tipoEntidad='CARRIER' AND crs.idSistemaEntidad=100 AND crs.codigo = cb.caja_transportador  
	LEFT JOIN Transportes tr WITH(NOLOCK) ON crs.idEntidad = tr.id
	LEFT JOIN CodigosRelacionSistemas crss WITH(NOLOCK) ON crss.tipoEntidad='CLIENTE' AND crss.idSistemaEntidad=100 AND crss.codigo = cb.codigoCliente  
	LEFT JOIN Clientes clf WITH(NOLOCK) ON crss.idEntidad = clf.id

	IF((SELECT COUNT(1) FROM #InfoCBTemporal)>0)
	BEGIN
		DELETE FROM coordTemp 
		FROM #CoordinacionesAux coordTemp
		INNER JOIN #InfoCBTemporal cbTemp ON coordTemp.IdInventarioTemp = cbTemp.IdInventarioTemp

	INSERT INTO #CoordinacionesAux
		(Id,
		IdGuiaConsolidada,
		FechaEmbarque,
		Origin,
		ShipmentNr,
		Consignatario,
		ShipTo,
		FB,
		Carrier,
		ShippingDate,
		IdEmpresa,
		IdClienteFinal,
		IdCoordinacion,
		CodigoBarra,
		CodigoBarraInv,
		IdInventarioTemp,
		CajasCoordinadas,
		PiezasCoordinadas,
		FbWh,
		IdCodigoBarra,
		NoProgramable,
		EsInventarioTemporal,
		CabeceraCoordinacion,
		Largo,
		Alto,
		Ancho,
		IdClienteConsignee,
		TipoPieza)
	SELECT 
		Id,
		IdGuiaConsolidada,
		FechaEmbarque,
		Origin,
		ShipmentNr,
		Consignatario,
		ShipTo,
		FB,
		Carrier,
		ShippingDate,
		IdEmpresa,
		IdClienteFinal,
		IdCoordinacion,
		CodigoBarra,
		CodigoBarraInv,
		IdInventarioTemp,
		CajasCoordinadas,
		PiezasCoordinadas,
		FbWh,
		IdCodigoBarra,
		NoProgramable,
		EsInventarioTemporal,
		CabeceraCoordinacion,
		Largo,
		Alto,
		Ancho,
		IdClienteConsignee,
		TipoPieza
	FROM #InfoCBTemporal
	END

	SELECT
		NEWID() AS Id,
		Id AS IdGuia,
		IdGuiaConsolidada,
		FechaEmbarque,
		Origin,
		ShipmentNr,
		Consignatario,
		ShipTo,
		FB,
		Carrier,
		ShippingDate,
		IdEmpresa,
		IdClienteFinal,
		IdCoordinacion,
		CodigoBarra,
		CodigoBarraInv,
		IdInventarioTemp,
		CajasCoordinadas AS CajasCoordinadas,
		PiezasCoordinadas,
		FbWh AS FbWh,
		IdCodigoBarra,
		NoProgramable,
		EsInventarioTemporal,
		CabeceraCoordinacion,
		ISNULL(Largo,0) AS Largo,
		ISNULL(Alto,0) AS Alto,
		ISNULL(Ancho,0) AS Ancho,
		IdClienteConsignee,
		TipoPieza
	FROM #CoordinacionesAux
	UNION
	SELECT 
		NEWID() AS Id,
		Id AS IdGuia,
		IdGuiaConsolidada,
		FechaEmbarque,
		Origin,
		ShipmentNr,
		Consignatario,
		ShipTo,
		FB,
		Carrier,
		ShippingDate,
		IdEmpresa,
		IdClienteFinal,
		IdCoordinacion,
		CodigoBarra,
		CodigoBarraInv,
		IdInventarioTemp,
		CajasCoordinadas  AS CajasCoordinadas,
		PiezasCoordinadas,
		FbWh AS FbWh,
		IdCodigoBarra,
		NULL AS NoProgramable,
		EsInventarioTemporal,
		CabeceraCoordinacion,
		ISNULL(Largo,0) AS Largo,
		ISNULL(Alto,0) AS Alto,
		ISNULL(Ancho,0) AS Ancho,
		IdClienteConsignee,
		TipoPieza
	FROM #InfoGuiaCoord

	DROP TABLE #InfoGuiaCoord,#CoordinacionesAux,#InfoCBTemporal,#idGuias

END

/*
EXEC pro_ReporteProgramacion_ListarInformacion  @IdGuias = '[{"idGUia":"GUI011492220"},{"idGUia":"GUI011492304"},{"idGUia":"GUI011500893"}]',@GuiaConsolidada=1
EXEC pro_ReporteProgramacion_ListarInformacion @IdGuias = '[{"idGUia":"GUI011500893"},{"idGUia":"GUI011492220"},{"idGUia":"GUI011492304"},{"idGUia":"GUI011492334"},{"idGUia":"GUI011492274"},{"idGUia":"GUI011450711"},{"idGUia":"GUI011493026"},{"idGUia":"GUI011492987"},{"idGUia":"GUI011492998"},{"idGUia":"GUI011493012"},{"idGUia":"GUI011493014"}]',@GuiaConsolidada=1
*/