ALTER PROCEDURE [dbo].[pro_ObtenerDatosEmbarquesPorCliente](
	@IdCliente VARCHAR(16),
	@Filtro INT,
	@PIndex INT
)
AS
BEGIN
	DECLARE @VIdCliente VARCHAR(16) = @IdCliente,
			@index INT,
			@tipoCliente VARCHAR(64),
			@COUNT INT = 20,
			@OrderBy VARCHAR(128),
			@Selectcmd NVARCHAR(MAX),
			@RangoFecha DATE,
			@nombreGrupo VARCHAR(256),
			@IdCatCancelado UNIQUEIDENTIFIER,
			@IdCatRequerida UNIQUEIDENTIFIER,
			@IdCatConfirmada UNIQUEIDENTIFIER,
			@totalguias INT,
			@pending VARCHAR(16) = 'PENDING',
			@local VARCHAR(16) = 'LOCAL',
			@destino VARCHAR(16) = 'DESTINO',
			@origen VARCHAR(16) = 'ORIGEN',
			@Final VARCHAR (16) = NULL,
			@Consignee VARCHAR (16) = NULL,
			@Consolidador VARCHAR (16) = NULL

	SELECT 
	@RangoFecha = DATEADD(MM, -2, GETDATE()),
	@index=	CASE 
				WHEN @PIndex = 1 THEN 0 
				ELSE @PIndex 
			END 
	/* LLENADO DE VARIABLES PARA ORDENES LOCALES*/
	BEGIN
		SELECT @IdCatConfirmada = id 
		FROM Catalogos C 
		WHERE C.identificador = 'CONFIRMADA' 
		AND  C.codigo = 'EstadosOrdenesLocales'
		
		SELECT @IdCatCancelado = id 
		FROM Catalogos C 
		WHERE C.identificador = 'CANCELLED' 
		AND  C.codigo = 'EstadosOrdenesLocales'
		
		SELECT @IdCatRequerida = id 
		FROM  Catalogos C 
		WHERE  C.identificador = 'REQUERIDA' 
		AND  C.codigo = 'EstadosOrdenesLocales'
	END

	/* CREACION DE TABLAS TEMPORALES */
	BEGIN
		CREATE TABLE #ClientesShipping(
			[idClienteB] [VARCHAR](16)
		)

		CREATE TABLE #origenesUnificados(
			[nroGuia] [VARCHAR](64),
			[idGuia] [VARCHAR](64),
			[idGuiaDistribuida] [VARCHAR](32),
			[idGuiaConsolidada] [VARCHAR](32),
			[idClienteConsolidador] [VARCHAR](16),
			[idPo] [UNIQUEIDENTIFIER],
			[OriginDate] [DATETIME],
			[DestinyDate] [DATETIME],
			[idEmpresa] [VARCHAR](32),
			[status] [VARCHAR](32),
			[esTransmitida] [BIT],
			[idTransporte] [VARCHAR](16),
			[idCiudadOrigen] [VARCHAR](32),
			[idCiudadDestino] [VARCHAR](32),
			[idClienteFinal] [VARCHAR](16),
			--[idClienteConsignatario] [VARCHAR](16),
			[idTraficoEncabezado] [VARCHAR](32),
			[idTraficoEmbarque] [UNIQUEIDENTIFIER],
			[totalPiezasHouse] [DECIMAL](18,3),
			[manual] [BIT],
			[idTransporteOrigen] [VARCHAR](32),
			[idModoTRansporte] [UNIQUEIDENTIFIER],
			[tipoRecalculo] [VARCHAR](32),
			[tipoGuia] [VARCHAR](32),
			[tipoGuiaHija] [VARCHAR](32),
			[totalPiezasCoordinacion] [DECIMAL](18,3),
			[totalPiezasRecepcion] [DECIMAL](18,3),
			[FechaEmbarque] [DATETIME],
			[idReserva] [VARCHAR](32),
			[codigoOrigen] [VARCHAR](16),
			[codigoDestino] [VARCHAR](16)
		)
		
		CREATE TABLE #nroGuias (
			[nroGuia] [VARCHAR](64),
			[idCliente] [VARCHAR](32),
			[tipoRecalculo] [VARCHAR](32),
			[tipoGuia] [VARCHAR](32), 
			[fechaEmbarque] [DATETIME]
		)
	
		CREATE TABLE #piezasAgrupadasPorEstado (
			[nroGuia] [VARCHAR](32),
			[idGuia] [VARCHAR](32),
			[idClienteConsolidado] [VARCHAR](16),
			[idClienteConsigne] [VARCHAR](16),
			[idClienteFinal] [VARCHAR](16),
			[estadoPieza] [VARCHAR](16),
			[totalPiezas] [INT],
			[totalPiezasPod] [INT],
			[orden] [INT],
			[fullbox] [DECIMAL](18,3),
			[fullboxPod] [DECIMAL](18,3),
			[tipoRecalculo] [VARCHAR](32)
		)	

		CREATE TABLE #GuiasShipping(
			[idEmpresa] [VARCHAR](32),
			[nroGuia] [VARCHAR](32),
			[idGuia] [VARCHAR](64),
			[idCliente] [VARCHAR](16),
			[nombre] [VARCHAR](512),
			[totalPieces] [INT],
			[detailPieces] [VARCHAR](MAX),
			[status] [INT],
			[manual] [BIT],
			[typeCarrier] [VARCHAR](32),
			[IdOriginPlace] [VARCHAR](32),
			[origin] [VARCHAR](128),
			[IdDestinyPlace] [VARCHAR](32),
			[destiny] [VARCHAR](128),
			[OriginDate] [DATETIME],
			[DestinyDate] [DATETIME],
			[tipoRecalculo] [VARCHAR](32),
			[tipoGuia] [VARCHAR](32),
			[estadoReserva] [VARCHAR](32),
			[pcsCoordinadas] [INT],
			[pcsRecibidas] [INT],
			[estadoGuia] [VARCHAR](32),
			[ciudadActual] [VARCHAR](64),
			[tipoCliente] [VARCHAR](32),
			[traficosListado] [VARCHAR](MAX),
			[nombreTransporte] [VARCHAR](1028),
			[totalGuias] [INT],
			[fechaEmbarque] [DATETIME],
			[type][VARCHAR](16),
			[color][VARCHAR](16),
			[detalleRecalculado][VARCHAR](16),
			[cupo][DECIMAL](18,3),
			[codigoIataOrigen][VARCHAR](16),
			[codigoIataDestino][VARCHAR](16),
			[validarCupo] [BIT]
		)
	
		CREATE TABLE #totalTemporal(
			[idTraficoEncabezado] [VARCHAR](64),
			[totalTraficos] [INT],
			idGuia [VARCHAR](64)
		)

		CREATE TABLE #traficosDetalleCompletoTemp(
			id [VARCHAR](16), 
			idGuia [VARCHAR](64),
			idTraficoEncabezado [VARCHAR](16),  
			idPuertoOrigen [VARCHAR](16), 
			idPuertoDestino [VARCHAR](16), 
			cantidadParciales [INT], 
			orden [INT],
			fechaSalida [DATE],
			horaSalida [VARCHAR](16),
			statusSalida  [VARCHAR](16),
			fechaLlegada [DATE],
			horaLlegada [VARCHAR](16),
			statusLlegada [VARCHAR](16),
			fechaCambio [DATETIME]
		)

		CREATE TABLE #traficoRecalculado(
			idTraficoEncabezado [VARCHAR](16),
			totalTraficos [INT],
			totalPiezasGuia [INT],
			IdPuertoDestino [VARCHAR](16),
			idPuertoDestinoInicial [VARCHAR](16),
			idPuertoDestinoActual [VARCHAR](16),
			idPuertoDestinoActualEspecial [VARCHAR](16),
			idGuia [VARCHAR](64)
		)

		CREATE TABLE #traficoActualizar(
			idTraficoEncabezado [VARCHAR](16),
			IdPuertoDestino [VARCHAR](16),
			idPuertoDestinoActual [VARCHAR](16),
			idPuertoDestinoActualEspecial [VARCHAR](16),
			idPuertoDestinoInicial [VARCHAR](16),
			tipoFlujo [VARCHAR](16),
			totalTraficos [INT],
			[status] [INT],
			idGuia [VARCHAR](64)
		)
	
		CREATE TABLE #TraficosTotalEstados(
			[idTraficoEncabezado] [VARCHAR](16),
			idPuertoDestino [VARCHAR](16),
			[departed] [INT],
			[departedParcial] [INT],
			[pendingOrigin] [INT],
			[pendingDestino] [INT],
			[arrived] [INT],
			[delayed] [INT],
			[missing] [INT],
			[readyPickUp] [INT],
			[releasedPpq] [INT],
			[totaLPiezasTrafico] [INT]
		)
	
		CREATE TABLE #CoordinacionesTemp(
			[id] [VARCHAR](16),
			[idExportador] [VARCHAR](16),
			[idGuia] [VARCHAR](16),
			[totalPiezasCoordinacion] [DECIMAL](18,3),
			[totalCajasCoordinacion] [DECIMAL](18,3),
			[totalPiezasRecepcion] [DECIMAL](18,3),
			[totalCajasRecepcion] [DECIMAL](18,3),
			[abierto] [BIT]
		)
	
		CREATE TABLE #CodigoDeBarraTemp(
			[id] [VARCHAR](16),
			[idGuia] [VARCHAR](16),
			[idCoordinacion] [VARCHAR](16),
			[pesoNeto] [DECIMAL](18,3),
			[equivalenciaFull] [DECIMAL](18,3),
			[checkOut] [BIT],
			[checkIn] [BIT],
			[status] [VARCHAR](32),
			[codigoBarra] [VARCHAR](16)
		)	

		DECLARE @informacionPiezas TABLE(
			[orden]  INT NOT  NULL,
			[nombre] VARCHAR(32)NOT NULL
		)

		DECLARE @resumenDestino TABLE(
			nroGuia VARCHAR(32)NOT NULL,
			idClienteConsolidado VARCHAR(16) NULL,
			pending  INT NOT  NULL,
			receibed  INT NOT  NULL,
			dispatched  INT NOT  NULL,
			delivered  INT NOT  NULL,
			lost  INT NOT  NULL,
			hold  INT NOT  NULL,
			short  INT NOT  NULL,
			[standBy]  INT NOT  NULL
		)

		DECLARE @resumenOrigen TABLE(
			idGuia VARCHAR(32)NOT NULL,
			idClienteConsolidado VARCHAR(16)NOT NULL,
			reservado  INT NOT  NULL,
			coordinado  INT NOT  NULL,
			recibido  INT NOT  NULL,
			despachado  INT NOT  NULL,
			entregado  INT NOT  NULL,
			entregadoP  INT NOT  NULL
		)
	END 
		
	 /* LLENADO DE CLIENTES RELACIONADOS*/
	BEGIN 
		SELECT  @tipoCliente = cat.identificador 
		FROM  DetalleEntidades DetI 
		INNER JOIN Catalogos cat ON cat.id = DetI.idCatalogo
		WHERE  DetI.idEntidad = @VIdCliente

		IF @tipoCliente = 'CLIENTE'
			BEGIN 
				INSERT INTO #ClientesShipping (idClienteB) 
				VALUES(@VIdCliente)

				SELECT TOP 1 @nombreGrupo = C.nombre
				FROM GrupoClientes GC
				INNER JOIN Clientes C ON C.ID = GC.idGrupoCliente
				WHERE GC.idCliente = @VIdCliente
			END
		ELSE
			BEGIN 
				INSERT INTO #ClientesShipping (idClienteB) 
				SELECT idCliente 
				FROM GrupoClientes 
				WHERE idGrupoCliente = @VIdCliente

				SELECT @nombreGrupo = nombre 
				FROM Clientes 
				WHERE id = @VIdCliente
			END	
	END
	
	/*ABSTRACCION DE G/ORDENES LOCALES QUE PERTENECEN AL USUARIO LOGUEADO*/
	BEGIN
		/*ORDENES LOCALES*/
		INSERT INTO #origenesUnificados 
		(nroGuia,idGuia,idpo,idClienteConsolidador,OriginDate,DestinyDate,idEmpresa, idCiudadOrigen, idCiudadDestino, idClienteFinal, tipoRecalculo, tipoGuia, FechaEmbarque, codigoOrigen, codigoDestino)
		SELECT DISTINCT
			OL.nroOrden AS nroGuia,
			OL.id AS idGuia,
			poEnc.id,
			OL.idCliente AS idClienteConsolidador,
			OL.fechaEntrega AS OriginDate, 
			OL.fechaEntrega AS DestinyDate,
			[poEnc].idEmpresa AS idEmpresa,
			puerto.idCiudad AS origin,
			puerto2.idCiudad AS destiny,
			[poEnc].idCliente AS idClienteFinal, 
			@local AS tipoRecalculo,
			'' AS tipoGuia,
			OL.fechaEntrega,
			puerto.codigo AS codigoOrigen,
			puerto2.codigo AS codigoDestino
		FROM OrdenesLocales OL WITH (NOLOCK)
			INNER JOIN [PoEncabezado] AS [poEnc] WITH (NOLOCK) ON OL.[id] = [poEnc].[idOrdenLocal]
			INNER JOIN #ClientesShipping CLI WITH (NOLOCK) ON CLI.idClienteB = [poEnc].idCliente
			LEFT JOIN Puertos puerto ON puerto.id = [poEnc].idPuertoOrigen
			LEFT JOIN Puertos puerto2 ON puerto2.id = [poEnc].idPuertoDestino
		WHERE OL.idCatalogoStatus = @IdCatRequerida 
			AND OL.fechaEntrega >= @RangoFecha 
			AND NOT EXISTS (SELECT g.nroGuia FROM GuiasHouse g WHERE g.nroGuia = OL.nroOrden)
		UNION
		SELECT DISTINCT
			OL.nroOrden AS nroGuia,
			OL.id AS idGuia,
			poEnc.id,
			OL.idCliente AS idClienteConsolidador,
			OL.fechaEntrega AS OriginDate, 
			OL.fechaEntrega AS DestinyDate,
			[poEnc].idEmpresa AS idEmpresa,
			puerto.idCiudad AS origin,
			puerto2.idCiudad AS destiny,
			[poEnc].idCliente AS idClienteFinal, 
			@local AS tipoRecalculo,
			'' AS tipoGuia,
			OL.fechaEntrega,
			puerto.codigo AS codigoOrigen,
			puerto2.codigo AS codigoDestino
		FROM OrdenesLocales OL
			INNER JOIN #ClientesShipping CLI WITH (NOLOCK) ON CLI.idClienteB = OL.idCliente
			INNER JOIN [PoEncabezado] AS [poEnc] WITH (NOLOCK) ON OL.[id] = [poEnc].[idOrdenLocal]
			LEFT JOIN Puertos puerto ON puerto.id = [poEnc].idPuertoOrigen
			LEFT JOIN Puertos puerto2 ON puerto2.id = [poEnc].idPuertoDestino
		WHERE OL.idCatalogoStatus = @IdCatRequerida 
			AND OL.fechaEntrega >= @RangoFecha
			AND NOT EXISTS (SELECT g.nroGuia FROM GuiasHouse g WHERE g.nroGuia = OL.nroOrden)	
	
		/* DESTINO */
		SELECT TOP 1 @Consolidador = 'CONSOLIDADOR'
		FROM GuiasHouse GH WITH (NOLOCK)
		INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = GH.idCliente
		WHERE GH.house IS NULL 
		AND GH.fechaOrigen >= @RangoFecha

		SELECT TOP 1 @Consignee ='CONSIGNEE'
		FROM GuiasHouse GH WITH (NOLOCK)
		INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = GH.idCliente
		WHERE GH.house IS NOT NULL 
		AND GH.fechaOrigen >= @RangoFecha
	
		SELECT DISTINCT GHD.idGuiaHouse
		INTO #TMP_GH
		FROM #ClientesShipping CLI
		INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON CLI.idClienteB = GHD.idClienteFinal
						
		SELECT TOP 1 @Final = 'FINAL'
		FROM GuiasHouse GH WITH (NOLOCK)	
		INNER JOIN #TMP_GH T ON GH.id = T.idGuiaHouse
		WHERE GH.fechaOrigen >= @RangoFecha
	
		IF @Final IS NOT NULL
		BEGIN
			INSERT INTO #origenesUnificados 
			(nroGuia,idGuia,idClienteConsolidador,OriginDate,DestinyDate,idEmpresa, idTraficoEncabezado, idTraficoEmbarque, totalPiezasHouse, [manual], idTransporteOrigen, idModoTransporte, idCiudadOrigen, idCiudadDestino, tipoRecalculo, tipoGuia, FechaEmbarque)
			SELECT DISTINCT
				guiaHouse1.nroGuia,
				guiaHouse1.idGuia,
				guiaHouse1.idCliente AS idClienteConsolidador, 
				guiaHouse1.fechaOrigen AS originDate,
				guiaHouse1.fechaDestino AS destinyDate,
				guiaHouse1.idEmpresa,
				guiaHouse1.idTraficoEncabezado,
				guiaHouse1.idTraficoEmbarque,
				0 AS totalPiezasHouse,
				guiaHouse1.[manual],
				guiaHouse1.idTransporteOrigen,
				guiaHouse1.idModoTransporte,
				CASE 
				WHEN guiaHouse1.idCiudadPuertoOrigen  LIKE 'PUE%'
				THEN 'CIU0194156'
				ELSE  guiaHouse1.idCiudadPuertoOrigen END AS origin,
				CASE 
				WHEN guiaHouse1.idCiudadPuertoDestino  LIKE 'PUE%'
				THEN 'CIU0194156'
				ELSE  guiaHouse1.idCiudadPuertoDestino END AS destiny, 
				@destino AS tipoRecalculo,  
				'' AS tipoGuia,
				ISNULL( g.fechaEmbarque, guiaHouse1.fechaOrigen) AS fechaEmbarque
			FROM GuiasHouse GH WITH (NOLOCK)
				INNER JOIN GuiasHouse guiaHouse1 WITH (NOLOCK) ON guiaHouse1.idGuia =  GH.idGuia AND guiaHouse1.house IS NULL
				INNER JOIN GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK) ON guiaHouseDetalle.idGuiaHouse =  GH.id
				INNER JOIN #ClientesShipping CLI WITH (NOLOCK) ON CLI.idClienteB = guiaHouseDetalle.idClienteFinal
				LEFT JOIN OrdenesLocales OL WITH (NOLOCK)  ON ol.nroOrden = guiaHouse1.nroGuia AND OL.idCatalogoStatus = @IdCatCancelado
				LEFT JOIN Guias g ON g.id = GH.idGuia
			WHERE guiaHouse1.fechaOrigen >= @RangoFecha
				AND OL.id IS NULL
		END

		IF @Consignee IS NOT NULL
		BEGIN 
			INSERT INTO #origenesUnificados 
			(nroGuia,idGuia,idClienteConsolidador,OriginDate,DestinyDate,idEmpresa, idTraficoEncabezado, idTraficoEmbarque, totalPiezasHouse, [manual], idTransporteOrigen, idModoTransporte, idCiudadOrigen, idCiudadDestino,tipoRecalculo, tipoGuia, FechaEmbarque)
			SELECT DISTINCT 
				GH1.nroGuia,
				GH1.idGuia,
				GH1.idCliente AS idClienteConsolidador, 
				GH1.fechaOrigen AS originDate,
				GH1.fechaDestino AS destinyDate,
				GH1.idEmpresa,
				GH1.idTraficoEncabezado,
				GH1.idTraficoEmbarque ,
				0 AS totalPiezasHouse,
				GH1.[manual],
				GH1.idTransporteOrigen,
				GH1.idModoTransporte,
				CASE 
				WHEN GH1.idCiudadPuertoOrigen  LIKE 'PUE%'
				THEN 'CIU0194156'
				ELSE  GH1.idCiudadPuertoOrigen END AS origin,
				CASE 
				WHEN GH1.idCiudadPuertoDestino  LIKE 'PUE%'
				THEN 'CIU0194156'
				ELSE  GH1.idCiudadPuertoDestino END AS destiny, 
				@destino AS tipoRecalculo,  
				'' AS tipoGuia,
				ISNULL( g.fechaEmbarque, GH1.fechaOrigen) AS fechaEmbarque
			FROM GuiasHouse GH WITH (NOLOCK)
				INNER JOIN #ClientesShipping CLI WITH (NOLOCK) ON CLI.idClienteB = GH.idCliente
				LEFT JOIN GuiasHouse GH1 WITH (NOLOCK) ON GH1.idGuia =  GH.idGuia AND GH1.house IS NULL -- AND GH.house  IS NOT  NULL
				LEFT JOIN OrdenesLocales OL WITH (NOLOCK) ON ol.nroOrden = GH.nroGuia AND OL.idCatalogoStatus = @IdCatCancelado
				LEFT JOIN Guias g ON g.id = GH.idGuia
			WHERE GH.fechaOrigen >= @RangoFecha
				AND gh1.nroGuia  IS NOT  NULL
				AND OL.id IS NULL
		END

		IF @Consolidador IS NOT NULL
		BEGIN 
			INSERT INTO #origenesUnificados 
			(nroGuia,idGuia,idClienteConsolidador,OriginDate,DestinyDate,idEmpresa, idTraficoEncabezado, idTraficoEmbarque, totalPiezasHouse, [manual], idTransporteOrigen, idModoTransporte, idCiudadOrigen, idCiudadDestino, tipoRecalculo, tipoGuia, FechaEmbarque)
			SELECT DISTINCT 
				GH1.nroGuia,
				GH1.idGuia,
				GH1.idCliente AS idClienteConsolidador, 
				GH1.fechaOrigen AS originDate,
				GH1.fechaDestino AS destinyDate,
				GH1.idEmpresa,
				GH1.idTraficoEncabezado,
				GH1.idTraficoEmbarque ,
				0 AS totalPiezasHouse,
				GH1.[manual],
				GH1.idTransporteOrigen,
				GH1.idModoTransporte,
				CASE 
				WHEN GH1.idCiudadPuertoOrigen  LIKE 'PUE%'
				THEN 'CIU0194156'
				ELSE  GH1.idCiudadPuertoOrigen END AS origin,
				CASE 
				WHEN GH1.idCiudadPuertoDestino  LIKE 'PUE%'
				THEN 'CIU0194156'
				ELSE  GH1.idCiudadPuertoDestino END AS destiny, 
				@destino AS tipoRecalculo,  
				'' AS tipoGuia,
				ISNULL( g.fechaEmbarque, GH1.fechaOrigen) AS fechaEmbarque
			FROM GuiasHouse GH1 WITH (NOLOCK)
				INNER JOIN #ClientesShipping CLI WITH (NOLOCK) ON CLI.idClienteB = GH1.idCliente
				LEFT JOIN OrdenesLocales OL WITH (NOLOCK) ON ol.nroOrden = GH1.nroGuia AND OL.idCatalogoStatus = @IdCatCancelado
				LEFT JOIN Guias g ON g.id = GH1.idGuia
			WHERE GH1.fechaOrigen >= @RangoFecha
				AND GH1.HOUSE IS NULL
				AND OL.id IS NULL
		END

		/* ORIGEN */
		INSERT INTO #origenesUnificados 
		(nroGuia,idGuia,idGuiaDistribuida,idGuiaConsolidada,idClienteConsolidador,idClienteFinal, idTraficoEncabezado, idEmpresa,[status],[esTransmitida],  idCiudadOrigen, idCiudadDestino, idTransporte, OriginDate, tipoRecalculo, tipoGuia, tipoGuiaHija, totalPiezasCoordinacion, totalPiezasRecepcion, FechaEmbarque, idReserva,  codigoOrigen, codigoDestino)
		SELECT DISTINCT
			dataGuia.nroGuia, 
			dataGuia.id  AS idGuiaMaster, 
			g.id AS idGuiaDistribuida,
			g.idGuiaConsolidada,
			dataGuia.idCliente AS idClienteMaster,  
			g.idCliente AS idClienteFinal,  
			dataGuia.idTraficoEncabezado, 
			dataGuia.idEmpresa,
			dataGuia.[status],
			dataGuia.[esTransmitida],
			puerto.idCiudad AS origin,
			puerto2.idCiudad AS destiny,
			dataGuia.idTransporte,
			CASE 
			WHEN TD.fechaSalida IS NULL
			THEN dataGuia.fechaEmbarque
			ELSE (
				CONVERT(DATETIME, CONCAT(TD.fechaSalida, 
										' ',
										CASE 
											WHEN TD.horaSalida ='' THEN '00:00'
											ELSE TD.horaSalida 
										END ,':00.000'), 120))END AS DateOrigin,
			@origen AS tipoRecalculo,  
			dataGuia.tipoGuia,
			g.tipoGuia AS tipoGuiaHija,
			dataGuia.totalPiezasCoordinacion,
			dataGuia.totalPiezasRecepcion,
			dataGuia.fechaEmbarque,
			dataGuia.idReserva,
			puerto.codigo AS codigoOrigen,
			puerto2.codigo AS codigoDestino
		FROM Guias g WITH (NOLOCK)		
			INNER JOIN Guias dataGuia WITH (NOLOCK) ON dataGuia.id = g.idGuiaConsolidada
			INNER JOIN Puertos puerto WITH (NOLOCK) ON puerto.id = dataGuia.idPuertoOrigen
			INNER JOIN Puertos puerto2 WITH (NOLOCK) ON puerto2.id = dataGuia.idPuertoDestino	
			INNER JOIN #ClientesShipping CLI WITH (NOLOCK) ON CLI.idClienteB = g.idCliente
			INNER JOIN TraficosEncabezados [TE] ON [TE].id = dataGuia.idTraficoEncabezado
			LEFT JOIN  TraficosDetalles TD ON [TE].id = TD.idTraficoEncabezado AND TD.orden = 1
		WHERE g.fechaEmbarque >= @RangoFecha 
			AND g.[status] <> 'RESERVADO'
			AND g.tipoGuia = 'DISTRIBUCION' 
			AND  g.totalPiezasCoordinacion > 0
			AND g.esTransmitida = 0				
		UNION 
		SELECT DISTINCT
			g.nroGuia, 
			g.id  AS idGuiaMaster, 
			guiaHija.id AS idGuiaDistribuida,
			g.idGuiaConsolidada,
			g.idCliente AS idClienteMaster,  
			guiaHija.idCliente AS idClienteFinal,  
			g.idTraficoEncabezado, 
			g.idEmpresa,
			g.[status],
			g.[esTransmitida],
			puerto.idCiudad AS origin,
			puerto2.idCiudad AS destiny,
			g.idTransporte,
			CASE 
				WHEN TD.fechaSalida IS NULL THEN g.fechaEmbarque
				ELSE (CONVERT(DATETIME, CONCAT(TD.fechaSalida, ' ',
												CASE 
													WHEN TD.horaSalida ='' THEN '00:00'
													ELSE TD.horaSalida 
												END ,':00.000'), 120))
			END AS DateOrigin,
			@origen AS tipoRecalculo,  
			g.tipoGuia,
			guiaHija.tipoGuia AS tipoGuiaHija,
			g.totalPiezasCoordinacion,
			g.totalPiezasRecepcion,
			g.fechaEmbarque,
			g.idReserva,
			puerto.codigo AS codigoOrigen,
			puerto2.codigo AS codigoDestino
		FROM  Guias g WITH (NOLOCK)
			INNER JOIN #ClientesShipping cs WITH (NOLOCK) ON cs.idClienteB = g.idCliente
			INNER JOIN Puertos puerto WITH (NOLOCK) ON puerto.id = g.idPuertoOrigen
			INNER JOIN Puertos puerto2 WITH (NOLOCK) ON puerto2.id = g.idPuertoDestino	
			INNER JOIN TraficosEncabezados [TE] ON [TE].id = g.idTraficoEncabezado
			LEFT JOIN Guias guiaHija WITH (NOLOCK) ON guiaHija.idGuiaConsolidada = g.id
			LEFT JOIN  TraficosDetalles TD ON [TE].id = TD.idTraficoEncabezado AND TD.orden = 1
		WHERE g.fechaEmbarque >= @RangoFecha 
			AND g.[status] <> 'RESERVADO'
			AND g.tipoGuia <> 'DISTRIBUCION' 
			AND  g.totalPiezasCoordinacion > 0
			AND g.esTransmitida = 0
	END

	/* CREACION INDICE  */
	CREATE INDEX idx_Destino ON #origenesUnificados 
	(idGuia,idGuiaDistribuida, nroGuia, idClienteConsolidador, idClienteFinal)

	/* OBTENER INFORMACION EN BASE A CRITERIO DE FILTRADO  */
	IF @filtro = 1
		BEGIN
			/* Guias a renderizar  */
			INSERT INTO #nroGuias
			SELECT 
				NGO.nroGuia, 
				NGO.idClienteConsolidador,
				NGO.tipoRecalculo, 
				NGO.tipoGuia,
				NGO.fechaEmbarque
			FROM 
				(SELECT DISTINCT
					nroGuia,
					idClienteConsolidador, 
					tipoRecalculo, 
					tipoGuia,
					idCiudadOrigen,
					idCiudadDestino,
					OriginDate, 
					fechaEmbarque
				FROM #origenesUnificados og) NGO
			ORDER BY NGO.fechaEmbarque DESC, NGO.nroGuia
			OFFSET @index ROWS
			FETCH NEXT @COUNT ROWS ONLY
		END
	ELSE IF @filtro = 5
		BEGIN			
			/* Guias a renderizar  */
			INSERT INTO #nroGuias
			SELECT 
				NGO.nroGuia, 
				NGO.idClienteConsolidador,
				NGO.tipoRecalculo, 
				NGO.tipoGuia,
				NGO.fechaEmbarque
			FROM 
				(SELECT DISTINCT
					nroGuia,
					idClienteConsolidador, 
					tipoRecalculo, 
					tipoGuia,
					idCiudadOrigen,
					idCiudadDestino,
					OriginDate, 
					fechaEmbarque
				FROM #origenesUnificados og) NGO
			ORDER BY NGO.nroGuia DESC
			OFFSET @index ROWS
			FETCH NEXT @COUNT ROWS ONLY
		END
	ELSE IF @filtro = 6
		BEGIN			
			/* Guias a renderizar  */
			INSERT INTO #nroGuias
			SELECT 
				NGO.nroGuia, 
				NGO.idClienteConsolidador,
				NGO.tipoRecalculo, 
				NGO.tipoGuia,
				NGO.fechaEmbarque
			FROM 
				(SELECT DISTINCT
					nroGuia,
					idClienteConsolidador, 
					tipoRecalculo, 
					tipoGuia,
					idCiudadOrigen,
					idCiudadDestino,
					OriginDate, 
					fechaEmbarque
				FROM #origenesUnificados og) NGO
				LEFT JOIN Ciudades ciudad WITH (NOLOCK) ON ciudad.id = NGO.idCiudadOrigen
			ORDER BY ciudad.nombre, NGO.nroGuia
			OFFSET @index ROWS
			FETCH NEXT @COUNT ROWS ONLY
		END
	ELSE IF @filtro = 7
		BEGIN 			
			/* Guias a renderizar  */
			INSERT INTO #nroGuias
			SELECT 
				NGO.nroGuia, 
				NGO.idClienteConsolidador,
				NGO.tipoRecalculo, 
				NGO.tipoGuia,
				NGO.fechaEmbarque
			FROM 
				(SELECT DISTINCT
					nroGuia,
					idClienteConsolidador, 
					tipoRecalculo, 
					tipoGuia,
					idCiudadOrigen,
					idCiudadDestino,
					OriginDate, 
					fechaEmbarque
				FROM #origenesUnificados og) NGO
				INNER JOIN Ciudades ciudad WITH (NOLOCK) ON ciudad.id = NGO.idCiudadDestino
				ORDER BY ciudad.nombre, NGO.nroGuia
			OFFSET @index ROWS
			FETCH NEXT @COUNT ROWS ONLY
		END 
	ELSE IF @filtro = 9
		BEGIN 			
			/* Guias a renderizar  */
			INSERT INTO #nroGuias
			SELECT 
				NGO.nroGuia, 
				NGO.idClienteConsolidador,
				NGO.tipoRecalculo, 
				NGO.tipoGuia,
				NGO.fechaEmbarque
			FROM 
				(SELECT DISTINCT
					nroGuia,
					idClienteConsolidador, 
					tipoRecalculo, 
					tipoGuia,
					idCiudadOrigen,
					idCiudadDestino,
					OriginDate, 
					fechaEmbarque
				FROM #origenesUnificados og) NGO
			ORDER BY NGO.fechaEmbarque DESC, NGO.nroGuia
			OFFSET @index ROWS
			FETCH NEXT @COUNT ROWS ONLY
		END 
	ELSE
		BEGIN			
			INSERT INTO #nroGuias
			SELECT 
				NGO.nroGuia, 
				NGO.idClienteConsolidador,
				NGO.tipoRecalculo, 
				NGO.tipoGuia,
				ngo.fechaEmbarque
			FROM				
				(SELECT DISTINCT
					nroGuia,
					idClienteConsolidador, 
					tipoRecalculo, 
					tipoGuia,
					idCiudadOrigen,
					idCiudadDestino,
					OriginDate, 
					fechaEmbarque
				FROM #origenesUnificados og) NGO
			ORDER BY  NGO.OriginDate DESC, NGO.nroGuia
			OFFSET @index ROWS
			FETCH NEXT @COUNT ROWS ONLY
		END
	
	SELECT @totalguias =  COUNT(DISTINCT nroGuia)
	FROM #origenesUnificados	

	IF EXISTS (SELECT 1 FROM #nroGuias WHERE tipoRecalculo='LOCAL' )
		BEGIN
			INSERT INTO #GuiasShipping
			SELECT DISTINCT
				 localTemp.idEmpresa AS idEmpresa,
				 localTemp.nroGuia AS nroGuia,
				 localTemp.idGuia AS idGuia,
				 localTemp.idClienteConsolidador,
				 ISNULL(CL.nombreClienteFinal, Cl.nombre) AS nombre,
				 0,
				 CASE
				 WHEN EXISTS(
						SELECT 1
						FROM 
							#ClientesShipping CLI 
						WHERE CLI.idClienteB = localTemp.idClienteConsolidador )
				 THEN(
					 
					  SELECT   
						COUNT(1) AS  pieces,
						'PENDING' AS estadoPieza,
						0 AS totalPiezasPod,
						SUM(tdp.equivalencia) AS fullBox,
						8 AS orden
					FROM #origenesUnificados AS [w]
						INNER JOIN [PoDetalles] AS [poDet] ON [w].[idPo] = [poDet].[idPo]
						INNER JOIN TiposDePieza tdp ON tdp.id = poDet.idTipoPieza
					WHERE W.nroGuia = localTemp.nroGuia AND W.tipoRecalculo = @local
					GROUP BY W.nroGuia
					FOR JSON AUTO
					)
				 ELSE
				 (
					SELECT   
						COUNT(1) AS  pieces,
						'PENDING' AS estadoPieza,
						0 AS totalPiezasPod,
						SUM(tdp.equivalencia) AS fullBox,
						8 AS orden
					FROM #origenesUnificados W
						INNER JOIN #ClientesShipping CLI WITH (NOLOCK) ON CLI.idClienteB = W.idClienteFinal
						INNER JOIN [PoDetalles] AS [poDet] ON [w].[idPo] = [poDet].[idPo]
						INNER JOIN TiposDePieza tdp ON tdp.id = poDet.idTipoPieza
					WHERE W.nroGuia = NGO.nroGuia  AND W.tipoRecalculo = @local
					GROUP BY W.nroGuia
					FOR JSON AUTO
				 ) END AS detailPieces,
				 0 AS [status],
				 0 AS [manual],
				 'TERRESTRE' AS typeCarrier, 
				ISNULL(ciudad.id, '') AS IdOriginPlace, 
				ISNULL(ciudad.nombre, '') AS origin, 
				ISNULL(ciudad2.id, '') AS IdDestinyPlace, 
				ISNULL(ciudad2.nombre, '') AS destiny, 
				localTemp.OriginDate AS OriginDate, 
				localTemp.DestinyDate AS DestinyDate, 
				@destino AS tipoRecalculo, 
				ngo.tipoRecalculo AS tipoGuia,
				'' AS estadoReserva, 
				0 AS pcsCoordinadas, 
				0 AS pcsRecibidas,            
				'' AS estadoGuia,
				'' AS ciudadActual ,
				'LOCAL' AS tipoCliente,
				'' AS traficosListado,
				'' AS nombreTransporte,
				@totalguias AS totalGuias,
				NGO.fechaEmbarque,
				'EMB' AS [type],
				'' AS color,
				''  AS detalleRecalculado,
				0 AS cupo,
				ISNULL(ciudad.codigoIATA, localTemp.codigoOrigen) AS  codigoIataOrigen,
				ISNULL(ciudad2.codigoIATA, localTemp.codigoDestino) AS  codigoIataDestino,
				0 AS validarCupo
			FROM #nroGuias NGO
			INNER JOIN (
					SELECT DISTINCT 
						idEmpresa,
						idGuia,
						nroGuia,
						idClienteConsolidador,
						OriginDate, 
						DestinyDate,
						idPo,
						idCiudadOrigen,
						idCiudadDestino,
						codigoOrigen,
						codigoDestino
					FROM #origenesUnificados
					WHERE tipoRecalculo = @local
				) localTemp ON localTemp.nroGuia =  NGO.nroGuia
				INNER JOIN Clientes CL ON CL.ID = localTemp.idClienteConsolidador
				INNER JOIN PoDetalles AS [poDet] ON localTemp.idPo = [poDet].idPo 
				LEFT JOIN Ciudades ciudad ON ciudad.id = localTemp.idCiudadOrigen
				LEFT JOIN Ciudades ciudad2 ON ciudad2.id = localTemp.idCiudadDestino
			WHERE NGO.tipoRecalculo = @local			
		END
	
	IF EXISTS (SELECT 1 FROM #nroGuias WHERE tipoRecalculo=@destino)
		BEGIN
			INSERT INTO #piezasAgrupadasPorEstado
			(nroGuia, idClienteConsolidado, idClienteConsigne, idClienteFinal, estadoPieza, totalPiezas, totalPiezasPod, fullbox, fullboxPod, tipoRecalculo)
			SELECT 
				GH.nroGuia, 
				NG.idCliente,
				GH.idCliente, 
				guiaHouseDetalle.idClienteFinal,
				guiaHouseDetalle.estadoPieza, 
				COUNT(1) AS totalPiezas,
				SUM(IIF(guiaHouseDetalle.esPOD =1,1,0)) AS totalPiezasPod,
				SUM(tdp.equivalencia) AS fullbox,
				SUM(IIF(guiaHouseDetalle.esPOD =1,tdp.equivalencia,0)) AS fullBoxPod,
				@destino
			FROM #nroGuias NG  
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON NG.nroGuia = GH.nroGuia
				INNER JOIN GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK) ON guiaHouseDetalle.idGuiaHouse =  GH.id
				INNER JOIN #ClientesShipping CL ON CL.idClienteB = guiaHouseDetalle.idClienteFinal
				INNER JOIN TiposDePieza tdp ON tdp.id = guiaHouseDetalle.idTipoDePieza
			WHERE NG.tipoRecalculo=@destino 
			GROUP BY GH.nroGuia, NG.idCliente, GH.idCliente, guiaHouseDetalle.idClienteFinal, guiaHouseDetalle.estadoPieza
			UNION 
			SELECT 
				GH.nroGuia,
				NG.idCliente, 
				GH.idCliente, 
				guiaHouseDetalle.idClienteFinal,
				guiaHouseDetalle.estadoPieza, 
				COUNT(guiaHouseDetalle.id) AS totalPiezas,
				SUM(IIF(guiaHouseDetalle.esPOD =1,1,0)) AS totalPiezasPod,
				SUM(tdp.equivalencia) AS fullbox,
				SUM(IIF(guiaHouseDetalle.esPOD =1,tdp.equivalencia,0)) AS fullBoxPod,
				@destino
			FROM #nroGuias NG 
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON NG.nroGuia = GH.nroGuia
				INNER JOIN #ClientesShipping CL ON CL.idClienteB = GH.idCliente
				INNER JOIN GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK) ON guiaHouseDetalle.idGuiaHouse =  GH.id
				INNER JOIN TiposDePieza tdp ON tdp.id = guiaHouseDetalle.idTipoDePieza
			WHERE NG.tipoRecalculo=@destino 
			GROUP BY GH.nroGuia, 
				NG.idCliente,
				GH.idCliente, 
				guiaHouseDetalle.idClienteFinal,
				guiaHouseDetalle.estadoPieza
			UNION
			SELECT 
				GH.nroGuia, 
				NG.idCliente,
				GH.idCliente, 
				guiaHouseDetalle.idClienteFinal,
				guiaHouseDetalle.estadoPieza, 
				COUNT(1) AS totalPiezas,
				SUM(IIF(guiaHouseDetalle.esPOD =1,1,0)) AS totalPiezasPod,
				SUM(tdp.equivalencia) AS fullbox,
				SUM(IIF(guiaHouseDetalle.esPOD =1,tdp.equivalencia,0)) AS fullBoxPod,
				@destino
			FROM #nroGuias NG  
				INNER JOIN #ClientesShipping CL ON CL.idClienteB = NG.idCliente
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON NG.nroGuia = GH.nroGuia
				INNER JOIN GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK) ON guiaHouseDetalle.idGuiaHouse =  GH.id
				INNER JOIN TiposDePieza tdp ON tdp.id = guiaHouseDetalle.idTipoDePieza
			WHERE NG.tipoRecalculo=@destino 
			GROUP BY GH.nroGuia, NG.idCliente, GH.idCliente,  guiaHouseDetalle.idClienteFinal, guiaHouseDetalle.estadoPieza

			INSERT INTO @informacionPiezas(orden, nombre)
			VALUES  (2, 'DISPATCHED WH'),
					(3, 'LOST'),
					(4, 'RECEIVED WH'),
					(5, 'SHORT'),
					(6, 'STANDBY'),
					(7, 'HOLD'),
					(8, 'PENDING')

			INSERT INTO @resumenDestino(nroGuia,idClienteConsolidado,pending, receibed, dispatched, delivered, lost,hold, short, [standBy])
			SELECT DISTINCT
				NG.nroGuia,
				detallePiezas.idClienteConsolidado,
				SUM(detallePiezas.pending) AS pending,
				SUM(detallePiezas.receibed) AS receibed,
				SUM(detallePiezas.dispatched) AS dispatched,
				SUM(detallePiezas.delivered) AS delivered,
				SUM(detallePiezas.lost) AS lost,
				SUM(detallePiezas.hold) AS hold,
				SUM(detallePiezas.short) AS short,
				SUM(detallePiezas.[standBy]) AS [standBy]
			FROM
				(SELECT
					GS.nroGuia,
					GS.idClienteConsolidado,
					IIF(GS.estadoPieza = 'PENDING', SUM(GS.totalPiezas),0) AS pending, 
					IIF(GS.estadoPieza = 'RECEIVED WH', SUM(GS.totalPiezas),0) AS receibed, 
					IIF(GS.estadoPieza = 'DISPATCHED WH', SUM(GS.totalPiezas),0) AS dispatched, 
					IIF(GS.estadoPieza = 'LOST', SUM(GS.totalPiezas),0) AS lost, 
					IIF(GS.estadoPieza = 'STANDBY', SUM(GS.totalPiezas),0) AS [standBy],
					IIF(GS.estadoPieza = 'HOLD', SUM(GS.totalPiezas),0) AS hold,
					IIF(GS.estadoPieza = 'SHORT', SUM(GS.totalPiezas),0) AS short,
					IIF(GS.estadoPieza = 'DISPATCHED WH' AND SUM(GS.totalPiezasPod) > 0 , SUM(GS.totalPiezas),0) AS delivered
				FROM #piezasAgrupadasPorEstado GS
				WHERE GS.tipoRecalculo = @destino
				GROUP BY GS.nroGuia,
					GS.idClienteConsolidado,
					GS.estadoPieza
				) detallePiezas
				INNER JOIN #nroGuias NG ON NG.nroGuia = detallePiezas.nroGuia
			WHERE  NG.tipoRecalculo = @destino
			GROUP BY NG.nroGuia, detallePiezas.idClienteConsolidado
	
			INSERT INTO #GuiasShipping
			SELECT DISTINCT
				GH.idEmpresa, 
				GH.nroGuia, 
				GH.idGuia, 
				GH.idClienteConsolidador, 
				ISNULL(
					CASE						
						WHEN EXISTS (SELECT 1 FROM #ClientesShipping WHERE idClienteB = GH.idClienteConsolidador) 
						THEN  cliente.nombre
						WHEN EXISTS( 
							SELECT COUNT (DISTINCT shipHijo.idClienteFinal)
							FROM #piezasAgrupadasPorEstado shipHijo
							INNER JOIN #ClientesShipping cli ON cli.idClienteB =  shipHijo.idClienteFinal
							WHERE shipHijo.nroGuia = GH.nroGuia 
								AND shipHijo.tipoRecalculo = @destino
							HAVING COUNT (DISTINCT shipHijo.idClienteFinal) = 1
									) 
						THEN ( 
								SELECT TOP 1 ISNULL(CL.nombreClienteFinal,CL.nombre)
								FROM  #piezasAgrupadasPorEstado shipHijo
									INNER JOIN #ClientesShipping cli ON cli.idClienteB =  shipHijo.idClienteFinal
									INNER JOIN Clientes cl ON cl.id = shipHijo.idClienteFinal 
								WHERE shipHijo.nroGuia = GH.nroGuia 
									AND shipHijo.tipoRecalculo = @destino
							)
						WHEN EXISTS( 
							SELECT COUNT (DISTINCT shipHijo.idClienteFinal)
							FROM #piezasAgrupadasPorEstado shipHijo
							WHERE shipHijo.nroGuia = GH.nroGuia
							HAVING COUNT (DISTINCT shipHijo.idClienteFinal) = 1
									) 
						THEN ( 
								SELECT TOP 1 ISNULL(CL.nombreClienteFinal,CL.nombre)
								FROM #piezasAgrupadasPorEstado shipHijo
								INNER JOIN Clientes cl ON cl.id = shipHijo.idClienteFinal
								WHERE shipHijo.nroGuia = GH.nroGuia 
									AND shipHijo.tipoRecalculo = @destino
							)
						WHEN EXISTS( 
									SELECT COUNT (DISTINCT shipHijo.idClienteFinal)
									FROM #piezasAgrupadasPorEstado shipHijo
									WHERE shipHijo.nroGuia = GH.nroGuia 
										AND shipHijo.tipoRecalculo = @destino
									HAVING COUNT (DISTINCT shipHijo.idClienteFinal) > 1
									) 
						THEN @nombreGrupo 
						ELSE cliente.nombre END,
					cliente.nombre
				) AS consigneName,
				GH.totalPiezasHouse,
				CASE 
					WHEN NOT EXISTS(
						SELECT TOP 1 nroGuia 
						FROM #piezasAgrupadasPorEstado GS 
						WHERE GS.nroGuia = GH.nroGuia 
							AND GS.tipoRecalculo = @destino)
					THEN ''
					WHEN EXISTS(
								SELECT idClienteB 
								FROM #piezasAgrupadasPorEstado GS
								INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = GS.idClienteConsolidado
								WHERE GS.nroGuia = GH.nroGuia AND GS.tipoRecalculo = @destino
							)
						THEN (SELECT  
								SUM(GAPS.totalPiezas) AS  pieces,  
								GAPS.estadoPieza,
								SUM(GAPS.totalPiezasPod) AS totalPiezasPod,
								SUM(GAPS.fullbox)  AS fullBox,
								SUM(GAPS.fullboxPod)  AS fullBoxPod,
								informacion.orden
							FROM  #piezasAgrupadasPorEstado GAPS
								INNER JOIN @informacionPiezas informacion ON informacion.nombre = GAPS.estadoPieza
								INNER JOIN  #ClientesShipping CLI  ON CLI.idClienteB = GAPS.idClienteConsolidado 
							WHERE GAPS.nroGuia = GH.nroGuia AND GAPS.tipoRecalculo = @destino
							GROUP BY GAPS.estadoPieza,informacion.orden
							FOR JSON AUTO
							)
					WHEN  EXISTS (
							SELECT idClienteB 
							FROM #piezasAgrupadasPorEstado GS
							INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = GS.idClienteConsigne
							WHERE GS.nroGuia = GH.nroGuia AND GS.tipoRecalculo = @destino
							)
						THEN ( SELECT  
								SUM(GAPS.totalPiezas) AS  pieces,  
								GAPS.estadoPieza,
								SUM(GAPS.totalPiezasPod) AS totalPiezasPod,
								SUM(GAPS.fullbox)  AS fullBox,
								SUM(GAPS.fullboxPod)  AS fullBoxPod,
								informacion.orden
							FROM  #piezasAgrupadasPorEstado GAPS
							INNER JOIN @informacionPiezas informacion ON informacion.nombre = GAPS.estadoPieza
							INNER JOIN  #ClientesShipping CLI  ON CLI.idClienteB = GAPS.idClienteConsigne
							WHERE GAPS.nroGuia = GH.nroGuia AND GAPS.tipoRecalculo = @destino
							GROUP BY  GAPS.estadoPieza, informacion.orden
							FOR JSON AUTO
							) 	
					ELSE (
						SELECT  
							SUM(GAPS.totalPiezas) AS  pieces,  
							GAPS.estadoPieza ,
							SUM(GAPS.totalPiezasPod) AS totalPiezasPod,
							SUM(GAPS.fullbox)  AS fullBox,
							SUM(GAPS.fullboxPod)  AS fullBoxPod,
							informacion.orden
						FROM  #piezasAgrupadasPorEstado GAPS
						INNER JOIN @informacionPiezas informacion ON informacion.nombre = GAPS.estadoPieza
						INNER JOIN  #ClientesShipping CLI  ON CLI.idClienteB = GAPS.idClienteFinal
						WHERE GAPS.nroGuia = GH.nroGuia AND GAPS.tipoRecalculo = @destino
						GROUP BY GAPS.estadoPieza, informacion.orden
					FOR JSON AUTO
							) 
				END AS detailPieces,
				CASE 
					WHEN GH.[manual] = 1
						AND NOT EXISTS(
						SELECT TOP 1 nroGuia 
						FROM #piezasAgrupadasPorEstado GS 
						WHERE GS.nroGuia = GH.nroGuia AND GS.tipoRecalculo = @destino)
					THEN 17
					WHEN resumen.delivered > 0
					THEN 16
					WHEN resumen.dispatched > 0
					THEN 15
					WHEN resumen.receibed > 0
					THEN 14
					WHEN NOT EXISTS (
										SELECT TOP 1 OL.nroOrden
										FROM  OrdenesLocales OL
										WHERE  OL.nroOrden = GH.nroGuia
									) 
							AND  GH.idTraficoEmbarque  IS NOT  NULL
					THEN (SELECT c.orden FROM Catalogos c WHERE c.id = GH.idTraficoEmbarque )
					WHEN GH.[manual] = 1 AND resumen.pending > 0
					THEN 0
					WHEN resumen.pending > 0 AND EXISTS (
															SELECT TOP 1 OL.nroOrden
															FROM  OrdenesLocales OL WITH (NOLOCK)
															WHERE OL.nroOrden = GH.nroGuia
															)
					THEN 0
					WHEN GH.[manual] = 0 
						AND GH.idTraficoEmbarque IS NULL
						AND NOT EXISTS (
								SELECT TOP 1 OL.nroOrden
								FROM OrdenesLocales OL
								WHERE OL.nroOrden = GH.nroGuia
								)
						AND resumen.delivered=0 
						AND resumen.dispatched = 0
						AND resumen.receibed = 0
					THEN 4
					ELSE 404 END AS [status], 
				GH.[manual],
				IIF(GH.idTransporteOrigen is NULL
					,IIF(EXISTS(SELECT identificador 
								FROM Catalogos c1 WITH (NOLOCK) 
								WHERE c1.id = GH.idModoTransporte)
						,(SELECT identificador 
							FROM Catalogos c1 WITH (NOLOCK) 
							WHERE c1.id = GH.idModoTransporte)
						,'TERRESTRE')
					, catalogo.identificador) AS typeCarrier,
				ISNULL(ciudad.id, 'CIU0194156') AS IdOriginPlace, 
				ISNULL(ciudad.nombre, 'MIAMI') AS origin,
				ISNULL(ciudad2.id, 'CIU0194156') AS IdDestinyPlace,
				ISNULL(ciudad2.nombre, 'MIAMI') AS destiny,			
				GH.OriginDate AS OriginDate,				
				GH.DestinyDate AS DestinyDate,
				nGuia.tipoRecalculo, 
				CASE 
					WHEN EXISTS (
							SELECT TOP 1 OL.nroOrden
							FROM OrdenesLocales OL WITH (NOLOCK)
							WHERE OL.nroOrden = GH.nroGuia
							) 
						THEN 'LOCAL'
				ELSE ''END,
				'',
				0,
				CASE
				WHEN  EXISTS (
						SELECT TOP 1 OL.nroOrden
						FROM  OrdenesLocales OL WITH (NOLOCK)
						WHERE  OL.nroOrden = GH.nroGuia
						)
					THEN (
						SELECT
							COUNT(CASE  
									WHEN ([cat].id  = @IdCatConfirmada AND [guiHouDet].id  IS NOT  NULL) 
										AND  ([guiHouDet].estadoPieza = 'PENDING') 
									THEN 1 END) PA
						FROM [OrdenesLocales] AS [w] WITH (NOLOCK)
							INNER JOIN [Catalogos] AS [catalogo] WITH (NOLOCK) ON [w].[idCatalogoStatus] = [catalogo].[id]
							LEFT JOIN [PoEncabezado] AS [poEnc] WITH (NOLOCK) ON [w].[id] = [poEnc].[idOrdenLocal]
							LEFT JOIN [PoDetalles] AS [poDet] WITH (NOLOCK) ON [poEnc].[id] = [poDet].[idPo]
							LEFT JOIN [Catalogos] AS [cat] WITH (NOLOCK) ON [poDet].[idCatalogoStatus] = [cat].[id]
							LEFT JOIN [GuiasHouseDetalles]  AS [guiHouDet] WITH (NOLOCK) ON [poDet].[id] = [guiHouDet].[idPoDetalle]
							LEFT JOIN [GuiasHouse] AS [guiasHouse] WITH (NOLOCK) ON ([guiHouDet].[idGuiaHouse] = [guiasHouse].[id])
							AND ('LOCAL' = [guiasHouse].[house])
						WHERE [w].nroOrden = GH.nroGuia
						GROUP BY [w].[nroOrden]
					)
					ELSE 0 END,
				'',
				ISNULL((SELECT TOP 1 CI.nombre
					FROM TraficosDetalles TD WITH (NOLOCK)
						LEFT JOIN Puertos PT ON TD.idPuertoDestino = PT.id
						LEFT JOIN Ciudades CI ON CI.id = PT.idCiudad
					WHERE TD.idTraficoEncabezado = GH.idTraficoEncabezado  
						AND TD.statusLlegada = 'ARRIVED'
					ORDER BY TD.orden DESC),'') AS CiudadActual,
				CASE 
					WHEN EXISTS(
								SELECT idClienteB 
								FROM #piezasAgrupadasPorEstado GS
									INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = GS.idClienteConsolidado
								WHERE GS.nroGuia = GH.nroGuia AND GS.tipoRecalculo = @destino
							)
						THEN 'CONSOLIDADO' 
					WHEN  EXISTS (
							SELECT idClienteB 
							FROM #piezasAgrupadasPorEstado GS
								INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = GS.idClienteConsigne
							WHERE GS.nroGuia = GH.nroGuia AND GS.tipoRecalculo = @destino
							)
						THEN 'CONSIGNEE' 
					ELSE
						 'FINAL' 
				END,
				ISNULL(
				(CASE 
					WHEN 
					NOT EXISTS (
							SELECT TOP 1 OL.nroOrden
							FROM OrdenesLocales OL WITH (NOLOCK)
							WHERE OL.nroOrden = GH.nroGuia
							)

					THEN
					(
						SELECT TOP 3
							ROW_NUMBER() OVER(ORDER BY DE.orden DESC) AS [row],
							DE.statusLlegada, DE.orden
						FROM(
							SELECT  TOP (ISNULL((
											SELECT TOP 1 TDH1.orden
											FROM TraficosEncabezadosHistorico TEH1 WITH (NOLOCK)
											LEFT JOIN TraficosDetallesHistorico TDH1 WITH (NOLOCK) ON TDH1.idTraficoEncabezadoHistorico = TEH1.id
											WHERE TEH1.idTraficoEncabezado = GH.idTraficoEncabezado
											ORDER BY TDH1.fechaCambio DESC,tdh1.orden DESC
										),0)+ 1)
									TDH.statusLlegada, TDH.orden
							FROM TraficosEncabezadosHistorico TEH WITH (NOLOCK)
							LEFT JOIN TraficosDetallesHistorico TDH WITH (NOLOCK) ON TDH.idTraficoEncabezadoHistorico = TEH.id
							WHERE TEH.idTraficoEncabezado = GH.idTraficoEncabezado
							ORDER BY TDH.fechaCambio DESC,tdh.orden DESC
						)DE
						FOR JSON AUTO
				)ELSE '' END),'') AS traficoDetalle,
				IIF(transporte.nombre IS NULL, '',transporte.nombre ) AS nombreTransporte,
				@totalguias AS totalGuias,
				nGuia.fechaEmbarque,
				'EMB' AS [type],
				'' AS color,
				''  AS detalleRecalculado,
				0 AS cupo,
				ISNULL(ciudad.codigoIATA, p.codigo) AS  codigoIataOrigen,
				ISNULL(ciudad2.codigoIATA, p2.codigo) AS  codigoIataDestino,
				0 AS validarCupo
			FROM #nroGuias nGuia 
				INNER JOIN (
					SELECT DISTINCT
						nroGuia, 
						idGuia, 
						idGuiaConsolidada,
						idClienteConsolidador,   
						idTraficoEncabezado, 
						idEmpresa,
						[status],
						[esTransmitida],
						idTransporte,
						tipoGuia,
						totalPiezasCoordinacion,
						totalPiezasRecepcion,
						fechaEmbarque,
						idReserva,
						idCiudadOrigen,
						idCiudadDestino,
						idTransporteOrigen,
						[manual],
						idTraficoEmbarque,
						totalPiezasHouse,
						idModoTRansporte,
						OriginDate,
						DestinyDate
					FROM #origenesUnificados G
					WHERE G.tipoRecalculo = 'DESTINO'
				)  GH ON GH.nroGuia= nGuia.nroGuia 
				INNER JOIN Clientes cliente WITH (NOLOCK) ON  cliente.id = GH.idClienteConsolidador
				LEFT JOIN @resumenDestino resumen ON resumen.nroGuia = nGuia.nroGuia
				LEFT JOIN Ciudades ciudad  ON ciudad.id =  GH.idCiudadOrigen
				LEFT JOIN Ciudades ciudad2  ON ciudad2.id =  GH.idCiudadDestino
				LEFT JOIN Puertos p ON ciudad.id = p.idCiudad
				LEFT JOIN Puertos p2 ON ciudad2.id = p2.idCiudad
				LEFT JOIN Transportes transporte WITH (NOLOCK) ON transporte.id = GH.idTransporteOrigen
				LEFT JOIN Catalogos catalogo WITH (NOLOCK) ON catalogo.id = transporte.idTipoTransporte
				LEFT JOIN TraficosEncabezados [TE] WITH (NOLOCK) ON [TE].id = GH.idTraficoEncabezado
			WHERE nGuia.tipoRecalculo = @destino
				--AND GH.idClienteConsolidador = GH.idClienteConsignatario			
		END
	
	IF EXISTS (SELECT  1 FROM #nroGuias WHERE tipoRecalculo=@origen )
		BEGIN			
			INSERT INTO #CoordinacionesTemp
			SELECT DISTINCT
				C.id, 
				C.idExportador, 
				C.idGuia, 
				C.totalPiezasCoordinacion,
				c.totalCajasCoordinacion,
				C.totalPiezasRecepcion,
				C.totalCajasRecepcion,
				C.abierto
			FROM #nroGuias NG
				INNER JOIN #origenesUnificados G WITH (NOLOCK) ON G.nroGuia = NG.nroGuia AND G.tipoRecalculo = @origen
				--INNER JOIN #origenTemp G WITH (NOLOCK) ON G.idGuiaConsolidada = gMaster.id 
				INNER JOIN Coordinaciones C WITH (NOLOCK) ON C.idGuia = G.idGuiaDistribuida
			WHERE NG.tipoRecalculo = @origen				
			UNION
			SELECT DISTINCT
				C.id, 
				C.idExportador, 
				C.idGuia, 
				C.totalPiezasCoordinacion,
				C.totalCajasCoordinacion,
				C.totalPiezasRecepcion,
				C.totalCajasRecepcion,
				C.abierto
			FROM #nroGuias NG
			INNER JOIN #origenesUnificados G WITH (NOLOCK) ON G.nroGuia = NG.nroGuia  AND G.tipoRecalculo = @origen
			--INNER JOIN Guias G WITH (NOLOCK) ON G.nroGuia = NG.nroGuia 
			INNER JOIN Coordinaciones C  WITH (NOLOCK) ON C.idGuia = G.idGuia
			WHERE NG.tipoRecalculo = @origen

			INSERT INTO #CodigoDeBarraTemp
			SELECT 
				cb.id, 
				C.idGuia,
				cb.idCoordinacion,
				cb.pesoNeto, 
				cb.equivalenciaFull,
				cb.checkOut, 
				cb.checkIn,
				cb.[status], 
				cb.codigoBarra
			FROM #CoordinacionesTemp C
			INNER JOIN CodigosDeBarra cb ON cb.idCoordinacion =  c.id

			INSERT INTO #piezasAgrupadasPorEstado
			(idGuia, idClienteConsolidado, idClienteFinal,estadoPieza,orden, totalPiezas, fullbox, tipoRecalculo)
			SELECT 
				g.idGuia AS idGuia,
				G.idClienteConsolidador, 
				g.idClienteFinal AS idClienteFinal, 
				'RESERVADO'  AS estadoPieza, 
				1 AS orden,
				IIF(c.totalPiezasCoordinacion IS NULL, COUNT(1),  COUNT(1)- c.totalPiezasCoordinacion ) AS totalPiezas,
				CASE 
				WHEN PD.idCoordinacion IS NULL
				THEN SUM(tdp.equivalencia)
				ELSE (SUM( tdp.equivalencia)-C.totalCajasCoordinacion) 
				END  AS fullBox,
				@origen
			FROM #nroGuias NG
				INNER JOIN (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque
					FROM #origenesUnificados OU
					WHERE OU.tipoRecalculo = @origen
				) G ON G.nroGuia = NG.nroGuia
				INNER JOIN PoGuiasAsignadas POA WITH (NOLOCK) ON  POA.idGuia = G.idGuiaDistribuida
				INNER JOIN PoDetalles PD WITH (NOLOCK) ON PD.idPoGuiasAsignadas =  POA.id
				LEFT JOIN  #CoordinacionesTemp C WITH (NOLOCK) ON C.id = PD.idCoordinacion
				LEFT JOIN TiposDePieza tdp ON tdp.id = PD.idTipoPieza
			WHERE g.fechaEmbarque >= @RangoFecha --AND g.tipoGuia = 'DISTRIBUCION'
			AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia,
				G.idClienteConsolidador, 
				g.idClienteFinal,
				POA.idGuia, 
				c.totalPiezasCoordinacion,PD.idCoordinacion,C.totalCajasCoordinacion
			HAVING IIF(c.totalPiezasCoordinacion IS NULL, COUNT(1),  COUNT(1)- c.totalPiezasCoordinacion ) > 0
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador,
				g.idClienteFinal AS idClienteFinal, 
				cb.[status] AS estadoPieza,
				5 AS orden,
				COUNT(cb.id) AS totalPiezas,
				SUM(CB.equivalenciaFull) AS fullBox,
				@origen
			FROM #nroGuias NG
				OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
			INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuiaDistribuida
			WHERE g.fechaEmbarque >= @RangoFecha --AND g.tipoGuia = 'DISTRIBUCION'
			AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia,g.idClienteConsolidador,g.idClienteFinal, cb.[status]
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador,
				g.idClienteFinal AS idClienteFinal,
				'DESPACHADO' AS estadoPieza,
				8 AS orden,
				SUM(IIF(cb.checkOut=1,1,0)) AS totalPiezas,
				SUM(IIF(cb.checkOut=1,CB.equivalenciaFull,0)) AS fullBox,
				@origen
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuiaDistribuida
			WHERE g.fechaEmbarque >= @RangoFecha --AND g.tipoGuia = 'DISTRIBUCION'
			AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia,g.idClienteConsolidador,g.idClienteFinal, cb.[status]
			HAVING SUM(IIF(cb.checkOut=1,1,0)) > 0
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador,
				g.idClienteFinal AS idClienteFinal, 
				'ENTREGADO' AS estadoPieza,
				10 AS orden,
				SUM(IIF(cb.pesoNeto>0,1,0)) AS totalPiezas,
				SUM(IIF(cb.pesoNeto>0,CB.equivalenciaFull,0)) AS fullBox,
				@origen
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
			INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuiaDistribuida
			WHERE g.fechaEmbarque >= @RangoFecha --AND g.tipoGuia = 'DISTRIBUCION'
			AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia,g.idClienteConsolidador,g.idClienteFinal, cb.[status]
			HAVING SUM(IIF(cb.pesoNeto>0,1,0)) > 0
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador,
				g.idClienteFinal AS idClienteFinal,
				'ENTREGADO P' AS estadoPieza,
				10 AS orden,
				COUNT(IIF(cbp.id  IS NOT  NULL, 1, 0)) AS totalPiezas,
				SUM(IIF(cb.pesoNeto>0,CB.equivalenciaFull,0)) AS fullBox,
				@origen
			FROM #nroGuias NG
				OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuiaDistribuida
				INNER JOIN CodigosDeBarraPaletizadoras cbp ON cbp.codigoBarra = cb.codigoBarra
			WHERE g.fechaEmbarque >= @RangoFecha
				AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia, g.idClienteConsolidador, g.idClienteFinal 
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador, 
				g.idClienteFinal AS idClienteFinal, 
				'COORDINADO' AS estadoPieza,
				3 AS orden,
				SUM(c.totalPiezasCoordinacion) AS totalPiezas,
				SUM(
					CASE 
					WHEN c.abierto = 1 AND c.totalPiezasRecepcion >= c.totalPiezasCoordinacion
					THEN c.totalCajasRecepcion
					WHEN c.abierto = 1 AND c.totalPiezasRecepcion < c.totalPiezasCoordinacion
					THEN C.totalCajasCoordinacion
					WHEN c.abierto = 0 AND c.totalPiezasRecepcion < c.totalPiezasCoordinacion
					THEN C.totalCajasCoordinacion
					ELSE C.totalCajasRecepcion
					END
				) AS fullBox,
				@origen
				--SUM(C.totalCajasCoordinacion) AS fullBox
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
			INNER JOIN #CoordinacionesTemp  c WITH (NOLOCK) ON c.idGuia = g.idGuiaDistribuida
			WHERE g.fechaEmbarque >= @RangoFecha --AND g.tipoGuia = 'DISTRIBUCION'
			AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia, g.idClienteConsolidador, g.idClienteFinal
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador,  
				g.idClienteFinal AS idClienteFinal, 
				'RESERVADO'  AS estadoPieza, 
				1 AS orden,
				IIF(c.totalPiezasCoordinacion IS NULL, COUNT(1),  COUNT(1)- c.totalPiezasCoordinacion ) AS totalPiezas,
				--SUM(IIF(c.totalPiezasCoordinacion IS NULL,tdp.equivalencia ,c.totalCajasCoordinacion)) AS fullBox
				CASE 
					WHEN PD.idCoordinacion IS NULL
					THEN SUM(tdp.equivalencia)
					ELSE (SUM( tdp.equivalencia)-C.totalCajasCoordinacion) 
					END AS fullBox,
				@origen
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque,
						idGuiaConsolidada,
						tipoGuia
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN PoGuiasAsignadas POA WITH (NOLOCK) ON  POA.idGuia = G.idGuia
				INNER JOIN PoDetalles PD WITH (NOLOCK) ON PD.idPoGuiasAsignadas =  POA.id
				LEFT JOIN  #CoordinacionesTemp C WITH (NOLOCK) ON C.id = PD.idCoordinacion
				LEFT JOIN TiposDePieza tdp ON tdp.id = PD.idTipoPieza
			WHERE g.idGuiaConsolidada IS  NULL 
				AND g.tipoGuia ='DIRECTA'
				AND g.fechaEmbarque >= @RangoFecha
				AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia,
				g.idClienteConsolidador, g.idClienteFinal,
				POA.idGuia, 
				c.totalPiezasCoordinacion,
				PD.idCoordinacion,C.totalCajasCoordinacion
			HAVING IIF(c.totalPiezasCoordinacion IS NULL, COUNT(1),  COUNT(1)- c.totalPiezasCoordinacion ) > 0
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador, 
				g.idClienteFinal AS idClienteFinal,
				cb.[status] AS estadoPieza, 
				5 AS orden,
				COUNT(cb.id) AS totalPiezas,
				SUM(CB.equivalenciaFull) AS fullBox,
				@origen
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque,
						idGuiaConsolidada,
						tipoGuia
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuia
			WHERE g.idGuiaConsolidada IS  NULL 
				AND g.tipoGuia ='DIRECTA'
				AND g.fechaEmbarque >= @RangoFecha 
				AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia, g.idClienteConsolidador, g.idClienteFinal,cb.[status]
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador, 
				g.idClienteFinal AS idClienteFinal, 
				'DESPACHADO' AS estadoPieza,
				8 AS orden,
				SUM(IIF(cb.checkOut=1,1,0)) AS totalPiezas,
				SUM(IIF(cb.checkOut=1,CB.equivalenciaFull,0)) AS fullBox,
				@origen
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque,
						idGuiaConsolidada,
						tipoGuia
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuia
			WHERE g.idGuiaConsolidada IS  NULL 
				AND g.tipoGuia ='DIRECTA'
				AND g.fechaEmbarque >= @RangoFecha
				AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia, g.idClienteConsolidador,g.idClienteFinal,  cb.[status]
			HAVING SUM(IIF(cb.checkOut=1,1,0)) > 0
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador, 
				g.idClienteFinal AS idClienteFinal, 
				'ENTREGADO' AS estadoPieza,
				10 AS orden,
				SUM(IIF(cb.pesoNeto>0,1,0)) AS totalPiezas,
				SUM(IIF(cb.pesoNeto>0,CB.equivalenciaFull,0)) AS fullBox,
				@origen
			FROM #nroGuias NG
				OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque,
						idGuiaConsolidada,
						tipoGuia
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuia
			WHERE 
				g.idGuiaConsolidada IS  NULL 
				AND g.tipoGuia ='DIRECTA'
				AND g.fechaEmbarque >= @RangoFecha
				AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia,g.idClienteConsolidador,g.idClienteFinal, cb.[status]
			HAVING SUM(IIF(cb.pesoNeto>0,1,0)) > 0
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador, 
				g.idClienteFinal AS idClienteFinal,
				'ENTREGADO P' AS estadoPieza,
				10 AS orden,
				SUM(IIF(cbp.pesoNeto>0,1,0)) AS totalPiezas,
				SUM(IIF(cbp.pesoNeto>0,CB.equivalenciaFull,0)) AS fullBox,
				@origen
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque,
						idGuiaConsolidada,
						tipoGuia
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN #CodigoDeBarraTemp cb ON cb.idGuia = g.idGuia
				INNER JOIN CodigosDeBarraPaletizadoras cbp ON cbp.codigoBarra = cb.codigoBarra
			WHERE g.idGuiaConsolidada IS  NULL 
				AND g.tipoGuia ='DIRECTA'
				AND g.fechaEmbarque >= @RangoFecha
				AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia, g.idClienteConsolidador,g.idClienteFinal
			UNION ALL
			SELECT 
				g.idGuia AS idGuia,
				g.idClienteConsolidador, 
				g.idClienteFinal AS idClienteFinal, 
				'COORDINADO' AS estadoPieza, 
				3 AS orden,
				SUM(c.totalPiezasCoordinacion) AS totalPiezas,
				SUM(
					CASE 
					WHEN c.abierto = 1 AND c.totalPiezasRecepcion >= c.totalPiezasCoordinacion
					THEN c.totalCajasRecepcion
					WHEN c.abierto = 1 AND c.totalPiezasRecepcion < c.totalPiezasCoordinacion
					THEN C.totalCajasCoordinacion
					WHEN c.abierto = 0 AND c.totalPiezasRecepcion < c.totalPiezasCoordinacion
					THEN C.totalCajasCoordinacion
					ELSE C.totalCajasRecepcion
					END
				) AS fullBox,
				@origen
				--SUM(c.totalCajasCoordinacion) AS fullBox
			FROM #nroGuias NG
			OUTER APPLY (
					SELECT DISTINCT
						nroGuia,
						idGuia,
						idGuiaDistribuida,
						idClienteConsolidador,
						idClienteFinal, 
						fechaEmbarque,
						idGuiaConsolidada,
						tipoGuia
					FROM #origenesUnificados OU
					WHERE OU.nroGuia = NG.nroGuia
						AND OU.tipoRecalculo = @origen
				) G
				INNER JOIN #CoordinacionesTemp c WITH (NOLOCK) ON c.idGuia = g.idGuia
			WHERE g.idGuiaConsolidada IS  NULL 
				AND g.tipoGuia ='DIRECTA'
				AND g.fechaEmbarque >= @RangoFecha
				AND NG.tipoRecalculo = @origen
			GROUP BY g.idGuia, g.idClienteConsolidador,g.idClienteFinal
			
			INSERT INTO @resumenOrigen
			SELECT DISTINCT
				detallePiezas.idGuia,
				detallePiezas.idClienteConsolidado,
				SUM(detallePiezas.reservado) AS reservado,
				SUM(detallePiezas.coordinado) AS coordinado,
				SUM(detallePiezas.recibido) AS recibido,
				SUM(detallePiezas.despachado) AS despachado,
				SUM(detallePiezas.entregado) AS entregado,
				SUM(detallePiezas.entregadoP) AS entregadoP
			FROM(
					SELECT
						GS.idGuia,
						GS.idClienteConsolidado,
						IIF(GS.estadoPieza = 'RESERVADO', SUM(GS.totalPiezas),0) AS reservado, 
						IIF(GS.estadoPieza = 'COORDINADO', SUM(GS.totalPiezas),0) AS coordinado, 
						IIF(GS.estadoPieza = 'RECIBIDO', SUM(GS.totalPiezas),0) AS recibido, 
						IIF(GS.estadoPieza = 'DESPACHADO', SUM(GS.totalPiezas),0) AS despachado, 
						IIF(GS.estadoPieza = 'ENTREGADO', SUM(GS.totalPiezas),0) AS entregado,
						IIF(GS.estadoPieza = 'ENTREGADO P', SUM(GS.totalPiezas),0) AS entregadoP
					FROM #piezasAgrupadasPorEstado GS
					INNER JOIN #ClientesShipping cs ON cs.idClienteB = gs.idClienteConsolidado
					WHERE GS.tipoRecalculo = @origen
					GROUP BY GS.idGuia,	GS.idClienteConsolidado, GS.estadoPieza
					UNION 
					SELECT
						GS.idGuia,
						GS.idClienteConsolidado,
						IIF(GS.estadoPieza = 'RESERVADO', SUM(GS.totalPiezas),0) AS reservado, 
						IIF(GS.estadoPieza = 'COORDINADO', SUM(GS.totalPiezas),0) AS coordinado, 
						IIF(GS.estadoPieza = 'RECIBIDO', SUM(GS.totalPiezas),0) AS recibido, 
						IIF(GS.estadoPieza = 'DESPACHADO', SUM(GS.totalPiezas),0) AS despachado, 
						IIF(GS.estadoPieza = 'ENTREGADO', SUM(GS.totalPiezas),0) AS entregado,
						IIF(GS.estadoPieza = 'ENTREGADO P', SUM(GS.totalPiezas),0) AS entregadoP
					FROM #piezasAgrupadasPorEstado GS
					INNER JOIN #ClientesShipping cs ON cs.idClienteB = gs.idClienteFinal
					WHERE GS.tipoRecalculo = @origen
					GROUP BY GS.idGuia, GS.idClienteConsolidado, GS.estadoPieza
				) detallePiezas				
			GROUP BY 
				detallePiezas.idGuia,detallePiezas.idClienteConsolidado
			
			/* proceso de trafico origen*/
			BEGIN
				INSERT INTO #traficosDetalleCompletoTemp
				SELECT DISTINCT
					TDH.id, 
					g.idGuia,
					TDH.idTraficoEncabezado,
					TDH.idPuertoOrigen, 
					TDH.idPuertoDestino, 
					TDH.cantidadParciales, 
					TDH.orden,
					TDH.fechaSalida,
					TDH.horaSalida,
					TDH.statusSalida,
					TDH.fechaLlegada,
					TDH.horaLlegada,
					TDH.statusLlegada,
					TDH.fechaCambio
				FROM #nroGuias NG
					INNER JOIN #origenesUnificados G ON NG.nroGuia = G.nroGuia AND G.tipoRecalculo = @origen
					INNER JOIN TraficosDetalles TDH ON TDH.idTraficoEncabezado = g.idTraficoEncabezado
				WHERE NG.tipoRecalculo =@origen	--AND G.idGuiaConsolidada IS NULL 
				AND G.totalPiezasRecepcion <> 0 
				AND G.[status] <> 'RESERVADO' 
				ORDER BY TDH.fechaCambio DESC

				INSERT INTO #totalTemporal
				SELECT DISTINCT
					temp.idTraficoEncabezado,
					totalTrafico.orden,
					guiaTemp.idGuia
				FROM (
						SELECT DISTINCT	
							T.idGuia,
							T.idTraficoEncabezado
						FROM #traficosDetalleCompletoTemp T					
					) guiaTemp
					LEFT JOIN #traficosDetalleCompletoTemp  temp ON TEMP.idTraficoEncabezado = guiaTemp.idTraficoEncabezado
					OUTER APPLY (SELECT TOP 1 orden 
								FROM #traficosDetalleCompletoTemp
								WHERE idTraficoEncabezado = TEMP.idTraficoEncabezado
								ORDER BY orden DESC) totalTrafico
		
				INSERT INTO #TraficosTotalEstados	
				SELECT 
					TR.idTraficoEncabezado,
					TR.idPuertoDestino,
					SUM(IIF(TR.statusSalida ='DEPARTED',1,0)) AS departed,
					SUM(IIF(TR.statusSalida ='DEPARTED PARCIAL',1,0)) AS departedParcial,
					SUM(IIF(TR.statusSalida IN ('PENDING','ESTIMATED') ,1,0)) AS pendingOrigin,
					SUM(IIF(TR.statusLlegada IN ('PENDING','ESTIMATED') ,1,0)) AS pendingDestino,
					SUM(IIF(TR.statusLlegada ='ARRIVED',1,0)) AS arrived,
					SUM(IIF(TR.statusSalida IN('DELAYED','DELAYED UPDATE', 'DELAYED HOLD'),1 ,0 )) AS delayed,
					SUM(IIF(TR.statusLlegada ='MISSING',1,0)) AS missing,
					SUM(IIF(TR.statusLlegada ='READY PICK UP',1,0)) AS readyPickUp,
					SUM(IIF(TR.statusLlegada ='RELEASED PPQ',1,0)) AS ReleasedPpq,
					SUM(IIF(TR.statusLlegada ='ARRIVED',IIF(TR.cantidadParciales IS NULL,0,TR.cantidadParciales),0)) AS totaLPiezasTrafico		
				FROM #traficosDetalleCompletoTemp TR
				GROUP BY TR.idTraficoEncabezado, TR.idPuertoDestino
		
				INSERT INTO #traficoRecalculado
				SELECT 
					total.idTraficoEncabezado,
					total.totalTraficos,
					0,
					destino.idPuertoDestino AS puertoFinal,
					inicio.idPuertoDestino AS puertoInicial,
					CASE 
						WHEN destinoActual.idPuertoDestino <> destino.idPuertoDestino
						THEN destinoActualAlterno.idPuertoDestino
						WHEN destinoActual.idPuertoDestino IS NULL
						THEN inicio.idPuertoDestino
						ELSE destinoActual.idPuertoDestino 
					END AS destinoActual,
					CASE
						WHEN destino.idPuertoDestino = (
													CASE 
														WHEN destinoActual.idPuertoDestino <> destino.idPuertoDestino
														THEN destinoActualAlterno.idPuertoDestino
														WHEN destinoActual.idPuertoDestino IS NULL
														THEN inicio.idPuertoDestino
														ELSE destinoActual.idPuertoDestino 
													END)
						THEN ''
						WHEN destinoActualEspecial.idPuertoDestino IS NULL 
							AND destinoActualEspecialAlterno.idPuertoDestino IS  NULL
						THEN ''
						WHEN destinoActualEspecial.idPuertoDestino IS NULL 
							AND destinoActualEspecialAlterno.idPuertoDestino  IS NOT  NULL
						THEN destinoActualEspecialAlterno.idPuertoDestino
						ELSE destinoActualEspecial.idPuertoDestino 
					END AS destinoActualEspecial,
					total.idGuia
				FROM 
					#totalTemporal total
					OUTER APPLY (
								SELECT TOP 1 tdh.idPuertoDestino
								FROM  #traficosDetalleCompletoTemp TDH
								WHERE TDH.idTraficoEncabezado = total.idTraficoEncabezado
								ORDER BY  tdh.orden DESC
								) destino
					OUTER APPLY (
								SELECT TOP 1 tdh.idPuertoDestino
								FROM  #traficosDetalleCompletoTemp TDH
								WHERE TDH.idTraficoEncabezado = total.idTraficoEncabezado
								ORDER BY TDH.orden ASC
								)inicio
					OUTER APPLY (
								SELECT TOP 1 DE.idPuertoDestino
								FROM  #traficosDetalleCompletoTemp DE 
								WHERE DE.idTraficoEncabezado = total.idTraficoEncabezado
									AND DE.statusLlegada ='ARRIVED'
								ORDER BY DE.fechaCambio DESC
								)destinoActual
					OUTER APPLY (
								SELECT TOP 1 DE.idPuertoDestino
								FROM  #traficosDetalleCompletoTemp DE 
								WHERE DE.idTraficoEncabezado = total.idTraficoEncabezado
								AND DE.statusSalida  NOT IN ( 'PENDING', 'ESTIMATED')
								ORDER BY DE.fechaCambio DESC
								)destinoActualAlterno
					OUTER APPLY (
								SELECT TOP 1 idPuertoDestino
								FROM #traficosDetalleCompletoTemp DE
								WHERE DE.idTraficoEncabezado = total.idTraficoEncabezado
									AND DE.statusLlegada = 'ARRIVED'
									AND DE.statusSalida IN ('DELAYED','DELAYED UPDATE', 'DELAYED HOLD') 
									AND DE.idPuertoDestino = (	SELECT TOP 1 t.idPuertoDestino
																FROM #traficosDetalleCompletoTemp  t
																WHERE t.idTraficoEncabezado = total.idTraficoEncabezado
																AND t.statusLlegada = 'ARRIVED'
																ORDER BY t.fechaCambio DESC)
								) destinoActualEspecial
					OUTER APPLY (
								SELECT TOP 1 idPuertoDestino
								FROM  #traficosDetalleCompletoTemp DE
								WHERE DE.idTraficoEncabezado = total.idTraficoEncabezado
									AND DE.statusLlegada = 'ARRIVED'
									AND DE.statusSalida IN ('ESTIMATED', 'PENDING') 
									AND DE.idPuertoDestino = (	SELECT TOP 1 t.idPuertoDestino
																FROM #traficosDetalleCompletoTemp t
																WHERE t.idTraficoEncabezado = total.idTraficoEncabezado
																AND t.statusLlegada = 'ARRIVED'
																ORDER BY t.fechaCambio DESC
															)
								) destinoActualEspecialAlterno
			
				INSERT INTO #traficoActualizar
				SELECT DISTINCT
					TR.idTraficoEncabezado,
					TR.idPuertoDestino,
					tr.idPuertoDestinoActual,
					TR.idPuertoDestinoActualEspecial,
					TR.idPuertoDestinoInicial,
					IIF(TR.idPuertoDestinoActualEspecial = '', 'normal', 'especial') AS tipoflujo,
					(destinActual.departedParcial + destinActual.departed + destinActual.pendingOrigin) AS totalTraficoOrigen,
					CASE 
						WHEN 
							TR.idPuertoDestinoActualEspecial = ''
						THEN (
							CASE
								WHEN destinoInicial.idPuertoDestino = TR.idPuertoDestinoInicial
									AND destinoInicial.arrived = 0
									AND destinoInicial.pendingDestino > 0
									AND destinoInicial.pendingOrigin > 0
									AND destinoInicial.departed = 0
									AND destinoInicial.departedParcial = 0
								THEN  4 /*@salidaEstimada*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino = 0
									AND destinActual.pendingOrigin = 0
									AND destinActual.departed > 0
									AND destinActual.missing = 0
									AND destinActual.delayed = 0
									AND destinActual.arrived > 0
									AND destinActual.arrived  = destinActual.departed
								THEN 10 /*@despachoAduanas*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino = 0
									AND destinActual.departed > 0
									AND destinActual.missing = 0
									AND destinActual.delayed = 0
									AND destinActual.arrived > 0
									AND destinActual.arrived  = (destinActual.departedParcial + destinActual.departed + destinActual.pendingOrigin)
								THEN 10/*@despachoAduanas*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino = 0
									AND destinActual.pendingOrigin = 0
									AND destinActual.departedParcial > 0
									AND destinActual.missing = 0
									AND destinActual.arrived > 0
									AND destinActual.delayed = 0
									AND destinActual.totaLPiezasTrafico < TR.totalPiezasGuia
									AND destinActual.arrived = (destinActual.departedParcial + destinActual.departed)
								THEN 9 /* @llegadaParcial caso nuevo*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino = 0
									AND destinActual.departedParcial > 0
									AND destinActual.missing = 0
									AND destinActual.delayed = 0
									AND destinActual.arrived > 0
									AND destinActual.arrived  = (destinActual.departedParcial + destinActual.departed + destinActual.pendingOrigin)
								THEN 
									10/*@despachoAduanas NUEVO CASO*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino > 0
									AND destinActual.pendingOrigin > 0
									AND destinActual.missing = 0
									AND destinActual.arrived > 0
									AND destinActual.delayed = 0
									AND destinActual.arrived  < (destinActual.departedParcial + destinActual.departed + destinActual.pendingOrigin)
								THEN 9/*@llegadaParcial*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino > 0
									AND destinActual.pendingOrigin = 0
									AND destinActual.missing = 0
									AND destinActual.arrived > 0
									AND destinActual.delayed = 0
									AND destinActual.arrived  < (destinActual.departedParcial + destinActual.departed + destinActual.pendingOrigin)
								THEN 9/*@llegadaParcial caso nuevo */ 
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino > 0
									AND destinActual.pendingOrigin > 0
									AND destinActual.missing > 0
									AND destinActual.arrived > 0
									AND destinActual.delayed = 0
									AND destinActual.arrived  < (destinActual.departedParcial + destinActual.departed + destinActual.pendingOrigin)
								THEN 9/*@llegadaParcial*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.pendingDestino = 0
									AND destinActual.pendingOrigin = 0
									AND destinActual.missing > 0
									AND destinActual.arrived > 0
									AND destinActual.delayed = 0
									AND destinActual.arrived  < (destinActual.departedParcial + destinActual.departed )
								THEN 9/*@llegadaParcial*/
								WHEN 
									destinActual.idPuertoDestino <> TR.idPuertoDestino
									AND destinActual.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActual.pendingDestino = 0
									AND destinActual.arrived > 0
									AND destinActual.delayed = 0
									AND destinActual.arrived  = (destinActual.departedParcial + destinActual.departed + destinActual.pendingOrigin)
								THEN 8/*@enTransito*/
								WHEN 
									destinActual.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActual.pendingDestino > 0
									AND destinActual.arrived = 0
									AND destinActual.pendingOrigin = 0
									AND destinActual.delayed = 0
									AND destinActual.pendingDestino = (destinActual.departedParcial + destinActual.departed)
								THEN 7/*@salida*/
								WHEN 
									destinActual.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActual.delayed = 0
									AND destinActual.pendingDestino > 0
									AND destinActual.pendingOrigin > 0
									AND destinActual.arrived > 0
									AND destinActual.pendingDestino < (destinActual.departedParcial + destinActual.departed +destinActual.pendingOrigin)
								THEN 6/*@salidaParcial*/
								WHEN 
									destinActual.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActual.delayed = 0
									AND destinActual.missing > 0
									AND destinActual.pendingDestino >= 0
									AND destinActual.pendingOrigin >= 0
									AND destinActual.arrived > 0
									AND destinActual.pendingDestino < (destinActual.departedParcial + destinActual.departed +destinActual.pendingOrigin)
								THEN 6/*@salidaParcial*/
								WHEN 
									-- destinActual.idPuertoDestino <> TR.idPuertoDestino AND
									destinActual.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActual.delayed = 0
									AND destinActual.pendingDestino > 0
									AND destinActual.pendingOrigin > 0
									--AND destinActual.arrived > 0
									AND destinActual.pendingDestino <= (destinActual.departedParcial + destinActual.departed +destinActual.pendingOrigin)
								THEN 6/*@salidaParcial*/
								WHEN 
									-- destinActual.idPuertoDestino <> TR.idPuertoDestino AND
									destinActual.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActual.delayed = 0
									AND destinActual.pendingDestino > 0
									AND destinActual.pendingOrigin = 0
									--AND destinActual.arrived > 0
									AND destinActual.pendingDestino <= (destinActual.departedParcial + destinActual.departed)
								THEN 6/*@salidaParcial*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestino
									AND destinActual.delayed > 0
								THEN  5/*@retraso*/
								WHEN destinActual.idPuertoDestino = TR.idPuertoDestinoActual AND destinActual.delayed > 0
								THEN 5/*@retraso*/
								ELSE 404/*@errorTrafico*/ END 
							) 
						ELSE(
						
							CASE
								WHEN destinoInicial.idPuertoDestino = TR.idPuertoDestinoInicial
									AND destinoInicial.arrived = 0
									AND destinoInicial.pendingDestino > 0
									AND destinoInicial.pendingOrigin > 0
									AND destinoInicial.departed = 0
									AND destinoInicial.departedParcial = 0
								THEN 4/*@salidaEstimada*/
					
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestino
									AND destinActualEspecial.pendingDestino = 0
									AND destinActualEspecial.pendingOrigin = 0
									AND destinActualEspecial.departed > 0
									AND destinActualEspecial.missing = 0
									AND destinActualEspecial.delayed > 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.arrived  = (destinActualEspecial.departed + destinActualEspecial.delayed)
								THEN 10/*@despachoAduanas*/
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestino
									AND destinActualEspecial.pendingDestino = 0
									AND destinActualEspecial.departed > 0
									AND destinActualEspecial.missing = 0
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.arrived  = (destinActualEspecial.departedParcial + 
																		 destinActualEspecial.departed + 
																		 destinActualEspecial.pendingOrigin + 
																		 destinActual.delayed)
								THEN 10/*@despachoAduanas*/
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestino
									AND destinActualEspecial.pendingDestino > 0
									AND destinActualEspecial.pendingOrigin > 0
									AND destinActualEspecial.missing = 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.arrived  < (destinActualEspecial.departedParcial + destinActualEspecial.departed + destinActualEspecial.pendingOrigin)
								THEN 9/*@llegadaParcial*/
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestino
									AND destinActualEspecial.pendingDestino > 0
									AND destinActualEspecial.pendingOrigin > 0
									AND destinActualEspecial.missing = 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.delayed > 0
									AND destinActualEspecial.arrived  < (destinActualEspecial.departedParcial + 
																		destinActualEspecial.departed + 
																		destinActualEspecial.pendingOrigin +
																		destinActualEspecial.delayed)
								THEN 9/*@llegadaParcial*/
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestino
									AND destinActualEspecial.pendingDestino > 0
									AND destinActualEspecial.pendingOrigin > 0
									AND destinActualEspecial.missing > 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.arrived  < (destinActualEspecial.departedParcial + destinActualEspecial.departed + destinActualEspecial.pendingOrigin)
								THEN 9/*@llegadaParcial*/
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestino
									AND destinActualEspecial.pendingDestino = 0
									AND destinActualEspecial.pendingOrigin = 0
									AND destinActualEspecial.missing > 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.arrived  < (destinActual.departedParcial + 
																		destinActual.departed +
																		destinActualEspecial.delayed)
								THEN 9/*@llegadaParcial*/
								WHEN 
									destinActualEspecial.idPuertoDestino <> TR.idPuertoDestino
									AND destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActualEspecial.pendingDestino = 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.arrived  = (destinActualEspecial.departedParcial + destinActualEspecial.departed + destinActualEspecial.pendingOrigin)
								THEN 8/*@enTransito*/
								WHEN 
									destinActualEspecial.idPuertoDestino <> TR.idPuertoDestino
									AND destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActualEspecial.pendingDestino = 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.delayed > 0
									AND destinActualEspecial.arrived  = (destinActualEspecial.departedParcial + 
																		destinActualEspecial.departed + 
																		destinActualEspecial.pendingOrigin +
																		 destinActualEspecial.delayed)
								THEN 8/*@enTransito*/
								WHEN 
									--destinActualEspecial.idPuertoDestino <> TR.idPuertoDestino AND
									destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActualEspecial.pendingDestino > 0
									AND destinActualEspecial.arrived = 0
									AND destinActualEspecial.pendingOrigin = 0
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.pendingDestino = (destinActualEspecial.departedParcial + destinActualEspecial.departed)
								THEN 7/*@salida*/
								WHEN 
									-- destinActualEspecial.idPuertoDestino <> TR.idPuertoDestino AND
									destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.pendingDestino > 0
									AND destinActualEspecial.pendingOrigin > 0
									AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.pendingDestino < (destinActualEspecial.departedParcial + destinActualEspecial.departed +destinActualEspecial.pendingOrigin)
								THEN 6/*@salidaParcial*/
								WHEN 
									-- destinActualEspecial.idPuertoDestino <> TR.idPuertoDestino AND
									destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.pendingDestino > 0
									AND destinActualEspecial.pendingOrigin > 0
									--AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.pendingDestino <= (destinActualEspecial.departedParcial + destinActualEspecial.departed +destinActualEspecial.pendingOrigin)
								THEN 6/*@salidaParcial*/
								WHEN 
									-- destinActualEspecial.idPuertoDestino <> TR.idPuertoDestino AND
									destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActualEspecial.delayed = 0
									AND destinActualEspecial.pendingDestino > 0
									AND destinActualEspecial.pendingOrigin = 0
									--AND destinActualEspecial.arrived > 0
									AND destinActualEspecial.pendingDestino <= (destinActualEspecial.departedParcial + destinActualEspecial.departed)
								THEN 6/*@salidaParcial*/
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestino
									AND destinActualEspecial.delayed > 0
								THEN 5/*@retraso*/
								WHEN destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActual
									AND destinActualEspecial.delayed > 0
								THEN 5/*@retraso*/
								ELSE 404 /*@errorTrafico*/ END 
							) END AS [status],
							TR.idGuia
				FROM #traficoRecalculado  TR
				LEFT JOIN #TraficosTotalEstados trafico ON trafico.idTraficoEncabezado = TR.idTraficoEncabezado
				LEFT JOIN #TraficosTotalEstados destinoInicial ON destinoInicial.idTraficoEncabezado = TR.idTraficoEncabezado AND destinoInicial.idPuertoDestino = TR.idPuertoDestinoInicial
				LEFT JOIN #TraficosTotalEstados destinoFinal ON destinoFinal.idTraficoEncabezado = TR.idTraficoEncabezado AND destinoFinal.idPuertoDestino = TR.IdPuertoDestino
				LEFT JOIN #TraficosTotalEstados destinActual ON destinActual.idTraficoEncabezado = TR.idTraficoEncabezado AND destinActual.idPuertoDestino = TR.idPuertoDestinoActual
				LEFT JOIN #TraficosTotalEstados destinActualEspecial ON destinActualEspecial.idTraficoEncabezado = TR.idTraficoEncabezado AND destinActualEspecial.idPuertoDestino = TR.idPuertoDestinoActualEspecial			
			END
											
			INSERT INTO #GuiasShipping
			SELECT DISTINCT
				G.idEmpresa, 
				G.nroGuia, 
				G.idGuia, 
				G.idClienteConsolidador,
				ISNULL(
					CASE
						WHEN EXISTS (SELECT 1 FROM #ClientesShipping WHERE idClienteB = G.idClienteConsolidador) 
						THEN cliente.nombre						
						WHEN EXISTS( 
							SELECT COUNT (DISTINCT shipHijo.idClienteFinal)
							FROM #piezasAgrupadasPorEstado shipHijo
							INNER JOIN #ClientesShipping cli ON cli.idClienteB =  shipHijo.idClienteFinal
							WHERE shipHijo.idGuia = G.idGuia 
							AND shipHijo.tipoRecalculo = @origen
							HAVING COUNT (DISTINCT shipHijo.idClienteFinal) = 1
							) 
						THEN ( 
								SELECT TOP 1 ISNULL(CL.nombreClienteFinal,CL.nombre)
								FROM #piezasAgrupadasPorEstado shipHijo
									INNER JOIN #ClientesShipping cli ON cli.idClienteB =  shipHijo.idClienteFinal
									INNER JOIN Clientes cl ON cl.id = shipHijo.idClienteFinal
								WHERE shipHijo.idGuia = G.idGuia 
									AND shipHijo.tipoRecalculo = @origen
							)
						--WHEN EXISTS( 
						--	SELECT COUNT (DISTINCT shipHijo.idClienteFinal)
						--	FROM #piezasAgrupadasPorEstado shipHijo
						--	INNER JOIN #ClientesShipping cli ON cli.idClienteB =  shipHijo.idClienteFinal
						--	WHERE 
						--		shipHijo.idGuia = G.idGuia 
						--		AND shipHijo.tipoRecalculo = @origen
						--	HAVING COUNT (DISTINCT shipHijo.idClienteFinal) > 1
						--			) 
						--THEN @nombreGrupo  
						WHEN EXISTS( 
							SELECT COUNT (DISTINCT shipHijo.idClienteFinal)
							FROM #piezasAgrupadasPorEstado shipHijo
							WHERE shipHijo.idGuia = G.idGuia 
							AND shipHijo.tipoRecalculo = @origen
							HAVING COUNT (DISTINCT shipHijo.idClienteFinal) > 1
									) 
						THEN @nombreGrupo 
						ELSE cliente.nombre END,
					cliente.nombre
				) AS consigneName,
				
				0 AS totalPiezasRecepcion,
				CASE 
					WHEN resumen.idGuia IS NULL
					THEN ''
					WHEN EXISTS(
							SELECT idClienteB 
							FROM #ClientesShipping 
							WHERE idClienteB = G.idClienteConsolidador
						) 
						THEN 
						(
							CASE
							WHEN G.[status] <> 'RESERVADO'
							THEN (
									SELECT 
										SUM(vpo.totalPiezas) AS pieces, 
										vpo.estadoPieza,
										SUM(vpo.fullbox)  AS fullBox,
										vpo.orden
									FROM #piezasAgrupadasPorEstado vpo
										INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = vpo.idClienteConsolidado
									WHERE vpo.idGuia = G.idGuia 
										AND vpo.estadoPieza <> 'ENTREGADO P' 
										AND vpo.tipoRecalculo = @origen
									GROUP BY vpo.estadoPieza,vpo.orden
									ORDER BY vpo.orden DESC
									FOR JSON AUTO
								)
							WHEN parametroGuia.idEmpresa  IS NOT  NULL AND catalogo.identificador ='AEREO'
									THEN(
										SELECT 
											SUM(vpo.totalPiezas) AS pieces, 
											vpo.estadoPieza,
											SUM(vpo.fullbox)  AS fullBox,
											vpo.orden
										FROM #piezasAgrupadasPorEstado vpo
											INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = vpo.idClienteConsolidado
										WHERE vpo.idGuia = G.idGuia 
											AND vpo.estadoPieza <> 'ENTREGADO'
											AND vpo.tipoRecalculo = @origen
										GROUP BY vpo.estadoPieza,vpo.orden
										ORDER BY vpo.orden DESC
										FOR JSON AUTO
									)
								ELSE(
									SELECT 
										SUM(vpo.totalPiezas) AS pieces,
										vpo.estadoPieza,
										SUM(vpo.fullbox)  AS fullBox,
										vpo.orden
									FROM #piezasAgrupadasPorEstado vpo
									INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = vpo.idClienteConsolidado
									WHERE vpo.idGuia = G.idGuia
										AND vpo.tipoRecalculo = @origen
									GROUP BY vpo.estadoPieza,vpo.orden
									ORDER BY vpo.orden DESC
									FOR JSON AUTO
										
								)END
						)
				ELSE ( 
					CASE
						WHEN G.[status] <> 'RESERVADO'
						THEN (
								SELECT 
									SUM(vpo.totalPiezas) AS pieces, 
									vpo.estadoPieza,
									SUM(vpo.fullbox)  AS fullBox,
									vpo.orden
								FROM #piezasAgrupadasPorEstado vpo
								INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = vpo.idClienteFinal
								WHERE vpo.idGuia = G.idGuia 
									AND vpo.estadoPieza <> 'ENTREGADO P'
									AND vpo.tipoRecalculo = @origen
								GROUP BY vpo.estadoPieza,vpo.orden
								ORDER BY vpo.orden DESC
								FOR JSON AUTO
							)
						WHEN 
							parametroGuia.idEmpresa  IS NOT  NULL AND catalogo.identificador ='AEREO'
								THEN(						
									SELECT 
										SUM(vpo.totalPiezas) AS pieces,  
										vpo.estadoPieza,
										SUM(vpo.fullbox)  AS fullBox,
										vpo.orden
									FROM #piezasAgrupadasPorEstado vpo
									INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = vpo.idClienteFinal
									WHERE vpo.idGuia = G.idGuia 
									AND vpo.estadoPieza <> 'ENTREGADO'
									AND vpo.tipoRecalculo = @origen
									GROUP BY vpo.idClienteConsolidado,vpo.estadoPieza,vpo.orden
									ORDER BY vpo.orden DESC
									FOR JSON AUTO
								)
							ELSE(
								SELECT 
									SUM(vpo.totalPiezas) AS pieces, 
									vpo.estadoPieza,
									SUM(vpo.fullbox)  AS fullBox,
									vpo.orden
								FROM #piezasAgrupadasPorEstado vpo
								INNER JOIN #ClientesShipping CLI ON CLI.idClienteB = vpo.idClienteFinal
								WHERE vpo.idGuia = G.idGuia
								AND vpo.tipoRecalculo = @origen
								GROUP BY vpo.estadoPieza,vpo.orden
								ORDER BY vpo.orden DESC
								FOR JSON AUTO) END
						) 
				END AS detailPieces,
				CASE 
					WHEN resumen.idGuia IS NULL
					THEN  404
					WHEN  EXISTS(
						SELECT 
							idClienteB 
						FROM 
							#ClientesShipping 
						WHERE 
							idClienteB = G.idClienteConsolidador
						) 
						THEN
							(CASE
								WHEN G.[status]  <> 'RESERVADO' 
									THEN (SELECT TOP 1 tro.[status] FROM #traficoActualizar TRO WHERE TRO.idGuia = G.idGuia)
								WHEN parametroGuia.idEmpresa  IS NOT  NULL 
									AND catalogo.identificador ='AEREO'
									AND resumen.entregadoP > 0
								THEN 3
								WHEN 
									parametroGuia.idEmpresa  IS NOT  NULL
									AND catalogo.identificador <> 'AEREO'
									 AND resumen.entregado > 0 THEN 3
								WHEN  parametroGuia.idEmpresa IS NULL 
									AND resumen.entregado > 0 
								THEN 3
								WHEN resumen.despachado > 0 
								THEN 2
								WHEN resumen.recibido > 0 
								THEN 1
								WHEN resumen.coordinado > 0 
								THEN 0
							END) 
					ELSE (CASE
							
							WHEN G.[status] <> 'RESERVADO' 
									THEN (SELECT TOP 1 tro.[status] FROM #traficoActualizar TRO WHERE TRO.idGuia = G.idGuia)
							WHEN parametroGuia.idEmpresa  IS NOT  NULL 
								 AND catalogo.identificador ='AEREO'
								AND resumen.entregadoP > 0 
							THEN 3
							WHEN  parametroGuia.idEmpresa  IS NOT  NULL 
								AND catalogo.identificador <>'AEREO'
								AND resumen.entregado > 0 
							THEN 3
							WHEN
								parametroGuia.idEmpresa is NULL  AND resumen.entregado > 0 
							THEN 3
							WHEN  resumen.despachado > 0  
							THEN 2
							WHEN resumen.recibido > 0 
							THEN 1
							WHEN resumen.coordinado > 0 
							THEN 0
						END) 
				END AS [status], 
				CONVERT(BIT,0) AS manual,
				catalogo.identificador AS typeCarrier,
				ciudad.id AS IdOriginPlace, 
				ciudad.nombre AS origin,
				ciudad2.id AS IdDestinyPlace, 
				ciudad2.nombre AS destiny,
				CASE 
				WHEN TD.fechaSalida IS NULL
				THEN G.fechaEmbarque
				ELSE (
					CONVERT(DATETIME, CONCAT(TD.fechaSalida, ' ',CASE 
																	WHEN TD.horaSalida =''
																	THEN '00:00'
																	ELSE TD.horaSalida END ,':00.000'), 120))END  AS OriginDate,
				CASE 
				WHEN TD.fechaSalida IS NULL
				THEN G.fechaEmbarque
				ELSE(SELECT TOP 1 
					CONVERT(DATETIME, CONCAT(fechaLlegada, ' ',horaLlegada,':00.000'), 120) AS fecha 
				FROM TraficosDetalles td1
				WHERE td1.idTraficoEncabezado = [TE].id 
				ORDER BY orden DESC) END AS DestinyDate,
				nGuia.tipoRecalculo, 
				G.tipoGuia, 
				r.[status], 
				G.totalPiezasCoordinacion, 
				ISNULL(CASE 
					WHEN EXISTS(
						SELECT idClienteB 
						FROM #ClientesShipping 
						WHERE idClienteB = G.idClienteConsolidador
						) AND G.tipoGuia <> 'DIRECTA'
						THEN resumen.recibido 
				ELSE
					IIF(
						G.tipoGuia = 'DIRECTA', 
						G.totalPiezasRecepcion, 
						resumen.recibido
							) END, 0) AS totalPiezasRecibidas,
				G.[status],
						
				ISNULL((
					SELECT TOP 1 CI.nombre
					FROM TraficosDetalles TD
						LEFT JOIN Puertos PT ON TD.idPuertoDestino = PT.id
						LEFT JOIN Ciudades CI ON CI.id = PT.idCiudad
					WHERE TD.idTraficoEncabezado = G.idTraficoEncabezado  
						AND TD.statusLlegada = 'ARRIVED'
					ORDER BY TD.orden DESC), '') AS CiudadActual,
					'CLORIGEN' AS tipoCliente,
				'',
				IIF(transporte.nombre IS NULL, '',transporte.nombre ) AS nombreTransporte,
				@totalguias AS totalGuias,
				nGuia.fechaEmbarque,
				'EMB' AS [type],
				'' AS color,
				''  AS detalleRecalculado,
				0 AS cupo,
				ISNULL(ciudad.codigoIATA, G.codigoOrigen) AS  codigoIataOrigen,
				ISNULL(ciudad2.codigoIATA, G.codigoDestino) AS  codigoIataDestino,
				0 AS validarCupo
			FROM #nroGuias nGuia
			INNER JOIN (
				SELECT DISTINCT
						nroGuia, 
						idGuia, 
						idGuiaConsolidada,
						idClienteConsolidador,   
						idTraficoEncabezado, 
						idEmpresa,
						[status],
						[esTransmitida],
						idTransporte,
						tipoGuia,
						totalPiezasCoordinacion,
						totalPiezasRecepcion,
						fechaEmbarque,
						idReserva,
						idCiudadOrigen,
						idCiudadDestino,
						codigoOrigen,
						codigoDestino
					FROM #origenesUnificados G
					WHERE G.tipoRecalculo = @origen
				)G ON nGuia.nroGuia = G.nroGuia
				INNER JOIN Reservas r WITH (NOLOCK) ON r.id = G.idReserva
				INNER JOIN Clientes cliente WITH (NOLOCK) ON  cliente.id = G.idClienteConsolidador
				INNER JOIN Ciudades ciudad WITH (NOLOCK) ON ciudad.id = G.idCiudadOrigen
				INNER JOIN Ciudades ciudad2 WITH (NOLOCK) ON ciudad2.id = G.idCiudadDestino
				INNER JOIN Transportes transporte WITH (NOLOCK)  ON transporte.id = G.idTransporte
				INNER JOIN Catalogos catalogo WITH (NOLOCK)  ON catalogo.id = transporte.idTipoTransporte
				LEFT JOIN TraficosEncabezados [TE] WITH (NOLOCK) ON [TE].id = G.idTraficoEncabezado
				LEFT JOIN @resumenOrigen resumen ON resumen.idGuia = G.idGuia
				LEFT JOIN  TraficosDetalles TD WITH (NOLOCK) ON [TE].id = TD.idTraficoEncabezado AND TD.orden = 1
				OUTER APPLY (SELECT TOP 1 plist.idEmpresa
							FROM  ParametrosLista pList 
							LEFT JOIN ParametrosCatalogos pCat ON pCat.idParametroLista = pList.id
							WHERE pList.idEmpresa = G.idEmpresa
								AND pList.codigo = 'LaBodegaRecibeLaCarga' 
								AND pCat.valor='SI') parametroGuia

			WHERE --G.idGuiaConsolidada IS NULL AND 
				nGuia.tipoRecalculo = @origen 
		END	
	
	IF @filtro = 1
		BEGIN 
			SELECT 
				idEmpresa, 
				nroGuia, 
				idGuia, 
				idCliente, 
				nombre, 
				totalPieces, 
				detailPieces, 
				[status], 
				[manual], 
				typeCarrier, 
				IdOriginPlace, 
				origin, 
				IdDestinyPlace, 
				destiny, 
				OriginDate, 
				DestinyDate, 
				tipoRecalculo, 
				tipoGuia,
				estadoReserva, 
				pcsCoordinadas, 
				pcsRecibidas, 
				estadoGuia,
				tipoCliente,
				ciudadActual,
				traficosListado,
				nombreTransporte,
				totalGuias,
				fechaEmbarque,
				[type], 
				color,
				detalleRecalculado, 
				cupo,
				codigoIataOrigen,
				codigoIataDestino,
				validarCupo
			FROM #GuiasShipping 
			ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, fechaEmbarque)) DESC, [status] ASC
		END
	ELSE IF @filtro = 2
		BEGIN 
			SELECT 
				idEmpresa, 
				nroGuia, 
				idGuia, 
				idCliente, 
				nombre, 
				totalPieces, 
				detailPieces, 
				[status], 
				[manual], 
				typeCarrier, 
				IdOriginPlace, 
				origin, 
				IdDestinyPlace, 
				destiny, 
				OriginDate, 
				DestinyDate, 
				tipoRecalculo, 
				tipoGuia,
				estadoReserva, 
				pcsCoordinadas, 
				pcsRecibidas, 
				estadoGuia,
				tipoCliente,
				ciudadActual,
				traficosListado,
				nombreTransporte,
				totalGuias,
				fechaEmbarque,
				[type], 
				color,
				detalleRecalculado, 
				cupo,
				codigoIataOrigen,
				codigoIataDestino,
				validarCupo
			FROM #GuiasShipping 
			ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, OriginDate)) DESC, [status] ASC
		END
	ELSE
		BEGIN
			SELECT @OrderBy = codigoRelacion 
			FROM Catalogos 
			WHERE codigo ='EstadosFiltrosShipping' AND orden = @filtro AND [status] ='Activo'

			SELECT @Selectcmd = ('SELECT idEmpresa, nroGuia, idGuia, idCliente, nombre, totalPieces, detailPieces, status, manual, typeCarrier, IdOriginPlace, origin, IdDestinyPlace, destiny, OriginDate, DestinyDate,  tipoRecalculo, tipoGuia,estadoReserva, 
								pcsCoordinadas, pcsRecibidas,estadoGuia,tipoCliente,ciudadActual,traficosListado,nombreTransporte,totalGuias, fechaEmbarque, [type], color,detalleRecalculado,cupo,codigoIataOrigen,codigoIataDestino, validarCupo
								FROM #GuiasShipping 
								ORDER BY '+ @OrderBy)
			EXEC (@Selectcmd)
		END

	DROP TABLE #ClientesShipping
	DROP TABLE #origenesUnificados	
	DROP TABLE #piezasAgrupadasPorEstado
	DROP TABLE #nroGuias
	DROP TABLE #GuiasShipping
	DROP TABLE #CoordinacionesTemp
	DROP TABLE #CodigoDeBarraTemp
	DROP TABLE #traficosDetalleCompletoTemp
	DROP TABLE #TraficosTotalEstados
	DROP TABLE #traficoRecalculado	
	DROP TABLE #traficoActualizar
	DROP TABLE #totalTemporal
	DROP TABLE #TMP_GH
END
/*
exec sp_executesql N'pro_ObtenerDatosEmbarquesPorCliente @VIdCliente, @Fillter, @Index  ',N'@VIdCliente NVARCHAR(9),@Index INT,@Fillter INT',@VIdCliente=N'CLI017181',@Index=1,@Fillter=1
exec pro_ObtenerDatosEmbarquesPorCliente 'CLI0416174',1,1
exec [pro_ObtenerDatosEmbarquesPorCliente] 'CLI013680', 1, 1
exec [pro_ObtenerDatosEmbarquesPorCliente] 'CLI012336', 1, 1
exec [pro_ObtenerDatosEmbarquesPorCliente] 'CLI014327', 1, 1
*/