/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-04-29		  57747			 Based on pro_ReporteProgramacion_ListarInformacion
*/

CREATE OR ALTER PROCEDURE [dbo].[Ac_pro_GetProgrammingAnalyticsReport]
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
		--name
		Consignatario VARCHAR(512),
		ShipTo VARCHAR(256),
		--
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
		--Es coordinacion (Lo que se espera) o es Inventario (Lo que esta fisicamente)
		CabeceraCoordinacion BIT NULL,
		--No programable difiere de las otras tabla subsiguientes, por que esto viene de INVTEMPORAL para adelante 
		-- ahi si hay ese campo que sirve para identificar si se debe calcular el carrier o no
		-- cuando solo es coordinacion no hay esa distinción, por eso se deja en NULL y ni se crea ese campo en la tabla #InfoGuiaCoord
		Largo DECIMAL(9,3),
		Alto DECIMAL(9,3),
		Ancho DECIMAL(9,3),
		IdClienteConsignee VARCHAR(16),
		BillToConsigneeId VARCHAR(16),
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
		BillToConsigneeId VARCHAR(16),
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
		BillToConsigneeId VARCHAR(16),
		TipoPieza VARCHAR(8)
	)
	-- deserailizamos el json de guias para obtener un formato tabular y poder hacer los joins correspondientes
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
				IdClienteConsignee,
				BillToConsigneeId
			)
				SELECT 
					G.id AS Id,
					GC.id AS IdGuiaConsolidada,
					G.fechaEmbarque AS FechaEmbarque,
					CD.codigoIATA AS Origin,
					GC.nroGuia AS ShipmentNr,
					VCC.nombre AS Consignatario,
					--mismo dato
					VCC.nombre AS ShipTo, 
					G.idEmpresa AS IdEmpresa,
					VCC.ConsigneeId AS IdClienteFinal,
					COOR.id AS IdCoordinacion,
					'Test' AS CodigoBarra,
					'Test' AS CodigoBarraInv,
					COOR.totalCajasCoordinacion AS CajasCoordinadas,
					COOR.totalPiezasCoordinacion AS PiezasCoordinadas,
					1 AS CabeceraCoordinacion,
					VCC.ConsigneeId AS IdClienteConsignee,
					VCC.Id AS BillToConsigneeId
				FROM #idGuias guiasTemp 
				INNER JOIN Guias G WITH(NOLOCK) ON G.idGuiaConsolidada = guiasTemp.idGuias
				INNER JOIN Guias GC WITH(NOLOCK) ON G.idGuiaConsolidada = GC.id
				INNER JOIN Coordinaciones COOR WITH(NOLOCK) ON G.id = COOR.idGuia
				INNER JOIN Puertos p ON G.idPuertoOrigen = p.id
				INNER JOIN Ciudades CD ON p.idCiudad = CD.id
				INNER JOIN v_ClientsEntities VCC ON G.BillToConsigneeId = VCC.Id
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
				IdClienteConsignee,
				BillToConsigneeId
			)
				SELECT 
					G.id AS Id,
					G.fechaEmbarque AS FechaEmbarque,
					CD.codigoIATA AS Origin,
					G.nroGuia AS ShipmentNr,
					VCC.nombre AS Consignatario,
					--mismo dato
					VCC.nombre AS ShipTo,
					G.idEmpresa AS IdEmpresa,
					VCC.ConsigneeId AS IdClienteFinal,
					COOR.id AS IdCoordinacion,
					'Test' AS CodigoBarra,
					'Test' AS CodigoBarraInv,
					COOR.totalCajasCoordinacion AS CajasCoordinadas,
					COOR.totalPiezasCoordinacion AS PiezasCoordinadas,
					1 AS CabeceraCoordinacion,
					VCC.ConsigneeId AS IdClienteConsignee,
					VCC.Id AS BillToConsigneeId
				FROM  #idGuias guiasTemp 
				INNER JOIN guias G WITH(NOLOCK)ON G.id = guiasTemp.idGuias
				INNER JOIN Coordinaciones COOR WITH(NOLOCK) ON G.id = COOR.idGuia
				INNER JOIN Puertos p ON G.idPuertoOrigen = p.id
				INNER JOIN Ciudades CD ON p.idCiudad = CD.id
				INNER JOIN v_ClientsEntities VCC WITH(NOLOCK) ON G.BillToConsigneeId = VCC.Id
		END
	/*Informacion de InventarioTemporal*/
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
		BillToConsigneeId,
		TipoPieza
	)
	SELECT
		coordTemp.id,
		coordTemp.IdGuiaConsolidada,
		coordTemp.fechaEmbarque,
		coordTemp.Origin,
		coordTemp.ShipmentNr,
		coordTemp.Consignatario,
		ISNULL(VCS.nombre, coordTemp.ShipTo) AS ShipTo,
		tp.equivalencia AS FB,
		tr.nombre AS Carrier,
		inv.fecha_transportador AS ShippingDate,
		coordTemp.idEmpresa,
		ISNULL(VCS.ConsigneeId, coordTemp.IdClienteFinal) AS IdClienteFinal,
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
		coordTemp.BillToConsigneeId,
		ISNULL(inv.empaque,cb.tipoPiezaInventario) AS TipoPieza
	FROM #InfoGuiaCoord coordTemp
	INNER JOIN InventarioTemporalCliente inv WITH(NOLOCK) ON coordTemp.IdCoordinacion = inv.idCoordinacion
	INNER JOIN TiposDePieza tp WITH(NOLOCK) ON inv.empaque = tp.tipoPieza
	LEFT JOIN CodigosDeBarra cb WITH(NOLOCK) ON inv.idCoordinacion = cb.idCoordinacion AND inv.codigoPieza = cb.codigoBarra
	LEFT JOIN CodigosRelacionSistemas crs WITH(NOLOCK) ON crs.tipoEntidad='CARRIER' AND crs.idSistemaEntidad=100 AND inv.caja_transportador = crs.codigo  
	LEFT JOIN Transportes tr WITH(NOLOCK) ON crs.idEntidad = tr.id
	LEFT JOIN CodigosRelacionSistemas crss WITH(NOLOCK) ON crss.tipoEntidad='CLIENTE'  AND crss.idSistemaEntidad=100 AND inv.codigoCliente = crss.codigo
	LEFT JOIN V_ClientsEntities VCS WITH(NOLOCK) ON crss.EntityRelation = VCS.Id 

	/*Informacion de CodigosBarras*/
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
		BillToConsigneeId,
		TipoPieza
	)
	SELECT
		coordTemp.id,
		coordTemp.IdGuiaConsolidada,
		coordTemp.fechaEmbarque,
		coordTemp.Origin,
		coordTemp.ShipmentNr,
		coordTemp.Consignatario,
		ISNULL(VCS.nombre, coordTemp.ShipTo) AS ShipTo,
		tp.equivalencia AS FB,
		tr.nombre AS Carrier,
		cb.caja_fecha_transportador AS ShippingDate,
		coordTemp.idEmpresa,
		ISNULL(VCS.ConsigneeId, coordTemp.IdClienteFinal) AS IdClienteFinal,
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
		coordTemp.BillToConsigneeId,
		cb.tipoPiezaInventario AS TipoPieza
	FROM #InfoGuiaCoord coordTemp
	INNER JOIN CodigosDeBarra cb WITH(NOLOCK) ON coordTemp.IdCoordinacion = cb.idCoordinacion
	LEFT JOIN InventarioTemporalCliente inv WITH(NOLOCK) ON cb.idCoordinacion = inv.idCoordinacion AND cb.codigoBarra = inv.codigoPieza
	LEFT JOIN TiposDePieza tp WITH(NOLOCK) ON cb.tipoPiezaInventario = tp.tipoPieza
	LEFT JOIN CodigosRelacionSistemas crs WITH(NOLOCK) ON crs.tipoEntidad='CARRIER' AND crs.idSistemaEntidad=100 AND crs.codigo = cb.caja_transportador  
	LEFT JOIN Transportes tr WITH(NOLOCK) ON crs.idEntidad = tr.id
	LEFT JOIN CodigosRelacionSistemas crss WITH(NOLOCK) ON crss.tipoEntidad='CLIENTE' AND crss.idSistemaEntidad=100 AND crss.codigo = cb.codigoCliente  
	LEFT JOIN V_ClientsEntities VCS WITH(NOLOCK) ON crss.EntityRelation = VCS.Id 

	IF((SELECT COUNT(1) FROM #InfoCBTemporal)>0)
	BEGIN
		DELETE FROM coordTemp 
		FROM #CoordinacionesAux coordTemp
		INNER JOIN #InfoCBTemporal cbTemp ON coordTemp.IdInventarioTemp = cbTemp.IdInventarioTemp
		/*EQUIVALENTE
		DELETE FROM #CoordinacionesAux
		WHERE IdInventarioTemp IN (
			SELECT IdInventarioTemp FROM #InfoCBTemporal
		)
		*/

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
		BillToConsigneeId,
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
		BillToConsigneeId,
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
		BillToConsigneeId,
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
		BillToConsigneeId,
		TipoPieza
	FROM #InfoGuiaCoord

	DROP TABLE #InfoGuiaCoord,#CoordinacionesAux,#InfoCBTemporal,#idGuias

END

/*
EXEC pro_ReporteProgramacion_ListarInformacion  @IdGuias = '[{"idGUia":"GUI011492220"},{"idGUia":"GUI011492304"},{"idGUia":"GUI011500893"}]',@GuiaConsolidada=1
EXEC pro_ReporteProgramacion_ListarInformacion @IdGuias = '[{"idGUia":"GUI011500893"},{"idGUia":"GUI011492220"},{"idGUia":"GUI011492304"},{"idGUia":"GUI011492334"},{"idGUia":"GUI011492274"},{"idGUia":"GUI011450711"},{"idGUia":"GUI011493026"},{"idGUia":"GUI011492987"},{"idGUia":"GUI011492998"},{"idGUia":"GUI011493012"},{"idGUia":"GUI011493014"}]',@GuiaConsolidada=1
*/