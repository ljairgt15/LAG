ALTER     PROCEDURE [dbo].[pro_ListarDespachoPorClientexDetallada]
(
	@fechaDesde				DATE,
	@fechaHasta				DATE,
	@idCliente				VARCHAR(16),
	@idClienteFinal			VARCHAR(16) = NULL,
	@isPending				BIT,
	@nombreClienteFinal		VARCHAR (256) = NULL,
	@nombreClienteConsignee	VARCHAR (512) = NULL,
	@nombreExportador		VARCHAR (256) = NULL,
	@idBodega				VARCHAR (16) = NULL,
	@PO						VARCHAR (64) = NULL,
	@nroGuia				VARCHAR (32) = NULL,
	@truckId				VARCHAR (16) = NULL,
	@esInventario			BIT = NULL
)
AS
BEGIN	
	DECLARE @tipoCliente			VARCHAR(32),
			@idSistema				INT, 
			@idDocumentoManifiesto	VARCHAR ( 16 ),
			@isPendigB				BIT,
			@fechaDestinoComodin	DATETIME,
			@final					VARCHAR (16) = NULL,
			@consignee				VARCHAR (16) = NULL,
			@consolidador			VARCHAR (16) = NULL,
			@mailEnviado			BIT = 0

	/*
		@isPendigB validacion
		cuando viene pendiente = 0 debe mostrar espod 1 mail enviado 1 no nulo
		cuando viene pendiente = 1 debe mostrar espod 1 mail enviado 0 o null 
		cuando viene pendiente = 1 debe mostrar espod 0 mail enviado 0 o null 
	*/
	SELECT 
		@isPendigB = IIF(@isPending = 0, 1,0),
		@fechaDestinoComodin = DATEADD(DAY,-90,@fechaHasta) 

	CREATE TABLE #ClientesRelacionados(
		[idCliente] [VARCHAR](16)
	)
	CREATE TABLE #ClientesFinales(
		[idCliente] [VARCHAR](16)
	)
	CREATE TABLE #ClientesConsignee(
		[idCliente] [VARCHAR](16)
	)
	CREATE TABLE #exportadores(
		[id] [VARCHAR](16)
	)
	CREATE TABLE #TmpGuiasHouseDetalles
	(
		id						UNIQUEIDENTIFIER,
		idGuiaHouse				UNIQUEIDENTIFIER,
		EstadoPieza				VARCHAR (64),
		EsPod					BIT,
		AltoIn					DECIMAL ( 18, 2 ),
		LargoIn					DECIMAL ( 18, 2 ),
		AnchoIn					DECIMAL ( 18, 2 ),
		IdClienteFinal			VARCHAR (16),
		TruckId					VARCHAR ( 16 ),
		IdBodega				VARCHAR ( 16 ) NULL,
		idProgramacionCarrier	UNIQUEIDENTIFIER,
		IdCarrier				VARCHAR ( 16 ) NULL,
		FechaDespacho			DATETIME,
		NroGuia					VARCHAR ( 32 ),
		IdClienteConsignee		VARCHAR (16),
		po						VARCHAR (64),
		House					VARCHAR ( 32 ),
		IdGuia					VARCHAR ( 64 ),
		IdExportador			VARCHAR ( 16 ),
	)
	
	SELECT TOP 1  @idSistema = Id 
	FROM SistemasEntidades WITH (NOLOCK) 
	WHERE Codigo = 'UNIFICADO'

	SELECT TOP 1  @idDocumentoManifiesto = Id 
	FROM Documentos WITH (NOLOCK) 
	WHERE Codigo = 'MANIFEST'

	SELECT  @tipoCliente = cat.identificador 
	FROM  Clientes CL
		INNER JOIN DetalleEntidades DetI ON DetI.idEntidad = CL.id
		INNER JOIN Catalogos cat ON cat.id = DetI.idCatalogo
	WHERE  CL.id = @idCliente

	IF @tipoCliente = 'CLIENTE'
		BEGIN 
			INSERT INTO #ClientesRelacionados (idCliente) 
			VALUES(@idCliente)
		END
	ELSE
		BEGIN 
			INSERT INTO #ClientesRelacionados (idCliente) 
			SELECT  idCliente 
			FROM  dbo.GrupoClientes 
			WHERE  idGrupoCliente = @idCliente
		END

	/* validacion  tipo de clientes*/
	SELECT TOP 1  @consolidador = 'CONSOLIDADOR'
	FROM  GuiasHouse GH
		INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH.idCliente
	WHERE GH.house IS NULL AND fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta

	SELECT TOP 1  @consignee ='CONSIGNEE'
	FROM  GuiasHouse GH
		INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH.idCliente
	WHERE GH.house IS NOT NULL AND fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta

	SELECT TOP 1  @final = 'FINAL'
	FROM  GuiasHouseDetalles GHD
		INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GHD.idClienteFinal
	WHERE fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta

	IF @isPendigB=0
	BEGIN
		SELECT @fechaDestinoComodin = DATEADD(DAY,-30,@fechaHasta) 
	END
	
	IF @nombreClienteFinal IS  NULL AND @nombreClienteConsignee IS NULL AND @nombreExportador IS NULL AND @PO IS NULL AND @nroGuia IS NULL AND @truckId IS NULL AND @idBodega IS NULL AND @idClienteFinal IS NULL
	BEGIN
		/* CLIENTES FINALES */
		IF @final IS NOT NULL 
		BEGIN
			INSERT INTO  #TmpGuiasHouseDetalles
			SELECT DISTINCT
				GHD.id,
				GHD.idGuiaHouse,
				GHD.estadoPieza,
				GHD.esPOD,
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador
			FROM ProgramacionCarrier t  WITH (NOLOCK)
				INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON 
													GHD.id = T.idGuiaHouseDetalle 
													AND GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
				INNER JOIN #ClientesRelacionados CL ON CL.idCliente = GHD.idClienteFinal
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
			WHERE  T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				
		END
		 /* CLIENTES CONSIGNEE */
		IF @consignee IS NOT NULL
		BEGIN
			
			INSERT INTO  #TmpGuiasHouseDetalles
			SELECT DISTINCT
				GHD.id,
				GHD.idGuiaHouse,
				GHD.estadoPieza,
				GHD.esPOD,
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador
			FROM dbo.GuiasHouse GH WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH.idCliente
				INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier t  WITH (NOLOCK) ON 
									T.idGuiaHouseDetalle = GHD.id 
									AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE  GH.house IS NOT NULL 
				AND GH.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
		END
		/* CLIENTES CONSOLIDADORES */
		IF @consolidador IS NOT NULL
		BEGIN
			INSERT INTO #TmpGuiasHouseDetalles
			SELECT DISTINCT
				GHD.id,
				GHD.idGuiaHouse,
				GHD.estadoPieza,
				GHD.esPOD,
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador
			FROM GuiasHouse GH1 WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH1.idCliente
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
				INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier AS T WITH (NOLOCK) ON 
								T.idGuiaHouseDetalle = GHD.id
								AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE GH1.house IS NULL 
				AND GH1.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
		END 
	END
	ELSE
	BEGIN 
		IF @nombreClienteFinal IS NOT NULL
		BEGIN 
			SELECT  @nombreClienteFinal = UPPER(@nombreClienteFinal)

			INSERT INTO #ClientesFinales
			SELECT id
			FROM Clientes
			WHERE nombreClienteFinal LIKE '%'+@nombreClienteFinal+'%' OR nombre LIKE '%'+@nombreClienteFinal+'%' 
			
		END
		IF @nombreClienteConsignee IS NOT NULL
		BEGIN 
			SELECT  @nombreClienteConsignee = UPPER(@nombreClienteConsignee)

			INSERT INTO #ClientesConsignee
			SELECT id
			FROM Clientes
			WHERE  nombre LIKE '%'+@nombreClienteConsignee+'%' 
		END

		IF @nombreExportador IS NOT NULL
		BEGIN 
			SELECT  @nombreExportador = UPPER(@nombreExportador)

			INSERT INTO #exportadores
			SELECT id
			FROM Exportadores
			WHERE nombreComercial LIKE '%'+@nombreExportador+'%' 
		END

		IF @final IS NOT NULL 
		BEGIN
			INSERT INTO  #TmpGuiasHouseDetalles
			SELECT DISTINCT
				GHD.id,
				GHD.idGuiaHouse,
				GHD.estadoPieza,
				GHD.esPOD,
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador
			FROM GuiasHouseDetalles GHD WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CL WITH (NOLOCK) ON CL.idCliente = GHD.idClienteFinal
				INNER JOIN ProgramacionCarrier t WITH (NOLOCK) ON 
												GHD.id = T.idGuiaHouseDetalle
												AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
			WHERE  GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
				AND ( GHD.idClienteFinal = ISNULL(@idClienteFinal, GHD.idClienteFinal ))
				AND (
					@nombreClienteFinal IS NULL 
					OR GHD.idClienteFinal IN (SELECT idCliente FROM #ClientesFinales) 
				)
				AND (
						@nombreExportador IS NULL
						OR gh.idExportador IN (SELECT id FROM #exportadores)
					)
				AND (@truckId IS NULL OR GHD.truckId LIKE '%' + @truckId + '%')
				AND (@PO IS NULL OR GHD.po LIKE '%' + @PO + '%')
				AND (
						@nombreClienteConsignee IS NULL 
						OR GH.idCliente IN (SELECT idCliente FROM #ClientesConsignee) 
					)
				AND (@nroGuia IS NULL OR GH.nroGuia LIKE '%' + @nroGuia + '%')
					
		END
		 /* CLIENTES CONSIGNEE */
		IF @consignee IS NOT NULL
		BEGIN
			
			INSERT INTO  #TmpGuiasHouseDetalles
			SELECT DISTINCT
				GHD.id,
				GHD.idGuiaHouse,
				GHD.estadoPieza,
				GHD.esPOD,
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador
			FROM GuiasHouse GH WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH.idCliente
				INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier AS t WITH (NOLOCK) ON 
												GHD.id = T.idGuiaHouseDetalle
												AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta 
				LEFT JOIN #TmpGuiasHouseDetalles  temp WITH (NOLOCK) ON temp.idGuiaHouse = GH.id
			WHERE  GH.house IS NOT NULL 
				AND GH.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
				AND TEMP.ID IS NULL
				AND (@nroGuia IS NULL OR GH.nroGuia LIKE '%' + @nroGuia + '%')
				AND (
						@nombreExportador IS NULL
						OR gh.idExportador IN (SELECT id FROM #exportadores)
					)
				AND (
						@nombreClienteConsignee IS NULL 
						OR GH.idCliente IN (SELECT idCliente FROM #ClientesConsignee) 
					)
				
				AND ( GHD.idClienteFinal =ISNULL(@idClienteFinal, GHD.idClienteFinal ))
				AND (
						@nombreClienteFinal IS NULL 
						OR GHD.idClienteFinal IN (SELECT idCliente FROM #ClientesFinales) 
					)
				AND (@truckId IS NULL OR GHD.truckId LIKE '%' + @truckId + '%')
				AND (@PO IS NULL OR GHD.po LIKE '%' + @PO + '%')
		END
		/* CLIENTES CONSOLIDADORES */
		IF @consolidador IS NOT NULL
		BEGIN 
			INSERT INTO #TmpGuiasHouseDetalles
			SELECT DISTINCT
				GHD.id,
				GHD.idGuiaHouse,
				GHD.estadoPieza,
				GHD.esPOD,
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador
			FROM GuiasHouse GH1
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH1.idCliente
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
				INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier t ON 
												GHD.id = T.idGuiaHouseDetalle
												AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				LEFT JOIN #TmpGuiasHouseDetalles GHTEMP ON GHTEMP.id = GHD.id
			WHERE  GH1.house IS NULL 
				AND GH1.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
				AND GHTEMP.ID IS NULL
				AND (@nroGuia IS NULL OR GH.nroGuia LIKE '%' + @nroGuia + '%')
				AND (
						@nombreExportador IS NULL
						OR gh.idExportador IN (SELECT id FROM #exportadores)
					)
				AND (
						@nombreClienteConsignee IS NULL 
						OR GH.idCliente IN (SELECT idCliente FROM #ClientesConsignee) 
					)
				
				AND ( GHD.idClienteFinal = ISNULL(@idClienteFinal, GHD.idClienteFinal ))
				AND (
						@nombreClienteFinal IS NULL 
						OR GHD.idClienteFinal IN (SELECT idCliente FROM #ClientesFinales) 
					)
				AND (@truckId IS NULL OR GHD.truckId LIKE '%' + @truckId + '%')
				AND (@PO IS NULL OR GHD.po LIKE '%' + @PO + '%')
		END 
	END
	
	SELECT DISTINCT
		ghd.id,
		GHD.EstadoPieza,
		GHD.FechaDespacho,
		MAN.NroManifiesto,
		GHD.AltoIn,
		GHD.LargoIn,
		GHD.AnchoIn,
		GHD.IdClienteFinal,
		GHD.TruckId,
		ISNULL(ub.idBodega, GHD.IdBodega) idBodega,
		GHD.IdCarrier,
		PT.IdTe,
		MAN.Id IdManifiesto ,
		GHD.nroGuia,
		GHD.IdClienteConsignee,
		GHD.po,
		GHD.house,
		GHD.idGuia,
		ghd.IdExportador,
		ghd.idGuiaHouse,
		CAST(CASE 
			WHEN SV.tipoVenta = 5 AND SVD.tipoPieza = 1 THEN 1
			WHEN SV.tipoVenta < 4 THEN 1
			ELSE 0 
			END AS BIT) esInventario,
		DDO.IdDocumentosDespacho, 
		CASE
			WHEN DDO.mailEnviado IS NULL OR DDO.mailEnviado = ''
			THEN CAST(0 AS BIT) ELSE DDO.mailEnviado
		END AS EmailEnviado, 
		DDO.NombreDocumentoDespacho
	INTO #tmpDetalle
	FROM #TmpGuiasHouseDetalles ghd
		LEFT JOIN ProgramacionTe PT WITH (NOLOCK) ON PT.IdProgramacionCarrier = ghd.idProgramacionCarrier
		LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PM.IdProgramacionCarrier = ghd.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MAN WITH (NOLOCK) ON MAN.Id = PM.IdManifiestoDespacho
		OUTER APPLY (
        	SELECT TOP 1 
					DD.EsPod, 
					DD.mailEnviado, 
					DD.id IdDocumentosDespacho, 
					DD.nombreArchivo NombreDocumentoDespacho
        	FROM DocumentosDespacho DD WITH(NOLOCK)
        	WHERE DD.idManifiesto = MAN.Id
        	AND DD.idDocumento = @idDocumentoManifiesto
        	ORDER BY EsPod DESC
      ) DDO
		LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
		LEFT JOIN Ubicaciones u WITH (NOLOCK) ON up.idUbicacion = u.id 
		LEFT JOIN UbicacionesBodega ub WITH (NOLOCK) ON u.idUbicacionBodega = ub.id 
		LEFT JOIN SolicitudDeVentaDetalles svd WITH (NOLOCK) ON SVD.idGuiaHouseDetalle = ghd.id
		LEFT JOIN SolicitudDeVenta sv WITH (NOLOCK) ON SV.id = SVD.idSolicitud
	WHERE 
		CASE 
			WHEN @isPendigB = 1 AND (GHD.EsPod = @isPendigB OR DDO.MailEnviado= @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = @isPendigB OR ISNULL(DDO.MailEnviado,@isPendigB)  = @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = 1 OR ISNULL(DDO.MailEnviado,@isPendigB) = 0 )THEN 1 
			ELSE 0
		END = 1
		AND CASE 
				WHEN @esInventario IS NULL THEN 1
				WHEN @esInventario = 0 AND SV.id IS NULL  THEN 1
				WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SVD.tipoPieza = 2 THEN 1
				WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
				WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SVD.tipoPieza = 1 THEN 1
				WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
				ELSE 0 
			END  = 1

	SELECT
		NEWID()  id,
		tmp.IdGuiaHouse, 
		tmp.idGuia, 
		tmp.id IdGuiaHouseDetalle,
		tmp.fechaDespacho, 
		tmp.idBodega, 
		BOD.nombre NombreBodega, 
		TRA.id IdCarrier, 
		TRA.nombre NombreCarrier, 
		'' CodigoCarrier,
		tmp.IdClienteConsignee, 
		clientesCons.nombre NombreClienteConsignee, 
		'' IdPaisConsignee,
		'' NombrePaisConsignee,
		CLI_FIN.nombre NombreClienteFinalAlt,
		'' NombreClienteFinalClienteFinalAlt,
		'' IdEstadoConsignee,
		''  CodigoIsoEstadoConsignee,
		paisClientes.id IdPaisAlt, 
		paisClientes.nombre NombrePaisAlt, 
		paisClientes.codigoISO CodigoIsoPaisAlt, 
		estadoClientes.id IdEstadoAlt, 
		estadoClientes.codigoISO CodigoIsoEstadoAlt, 
		CLI_FIN.id IdClienteFinal, 
		CLI_FIN.nombreClienteFinal, 
		paisClientesFinal.id IdPais, 
		paisClientesFinal.nombre NombrePais, 
		paisClientesFinal.codigoISO CodigoIsoPais, 
		estadoClientesFinal.id IdEstado, 
		estadoClientesFinal.codigoISO CodigoIsoEstado,
		tmp.IdManifiesto, 
		TMP.nroManifiesto, 
		'' ColorEstadoManifiesto,
		'' ColorEnvioTE,
		PUE.codigoAduana DescripcionPuertoFronterizo,
		0 PcsPending,
        0 PcsReceivedDr,
        0 PcsReceivedWh,
        0 PcsHold,
        0 PcsLost,
        0 PcsDispatchedWh,
        0 PcsStandby,
        0 TotalPcs,
		tmp.estadoPieza [Status], 
		CAST(0 AS BIT) AS CargaTransito,
		CAST(0 AS BIT) AS CargaTransitoNull,
		'' AS TipoNubeDocs,
		TMP.IdDocumentosDespacho, 
		TMP.EmailEnviado, 
		CASE
			WHEN TRA_EXP.[id] IS NOT NULL
			THEN CASE
					WHEN TRA_EXP.[enviado] = 1
					THEN CAST(1 AS BIT) 
					ELSE CAST(0 AS BIT)
					END 
			ELSE CAST(0 AS BIT)
		END AS [TransportExportEnviado], 
		'' AS IdDocumentosDespachoString,
		CASE
		 WHEN [empleado].[id] IS NOT NULL
			THEN ([empleado].[nombres] + ' ') + [empleado].[apellidos] 
			ELSE CASE
				WHEN [usuariocliente].[id] IS NOT NULL
				THEN [usuariocliente].[nombre] ELSE CASE
					WHEN [usuariocliente].[id] IS NOT NULL
					THEN [usuariocliente].[nombre] ELSE ''
				END
			END
		END AS UsuarioEnvioTE,
        '' AS FechaEnvioTE,
        '' AS TextoTooltipTE,
		'' AS IdBroker,
		tmp.[nroGuia], 
		'' AS NroOrdenLocal,
        '' AS NroDocumento,
		tmp.[truckId],
		'' AS TruckIdText,
		0.00 AS CapacidadCarga,
		tmp.[po], 
		'' AS CuttOfTime,
		[carrierSubCarrier].[codigoIcao] AS [CodigoSubCarrier], 
		[carrierSubCarrier].[nombre] AS [NombreSubCarrier],
		'' IdExportador,
        '' NombreExportador,
		'' Estatus,
		0 AS OrdenEstatus,
		'' ClaseCssEstado,
		'' TipoDocumentoDespacho,
		TMP.NombreDocumentoDespacho, 
		0 CantidadPODEnviados,
		0.00 piesCubicosShipper,
		0.00 piesCubicosTruckId,
		tmp.[largoIn], 
		tmp.[altoIn], 
		tmp.[anchoIn], 
		0.00 multiplicacionDimensiones,
		tmp.[house], 
		CAST(0 AS BIT) Modificado,
		'' Pallet,
		NULL IdOrdenVenta,
		'' Puerta,
        '' Placa,
        '' NroDespacho,
		NULL FechaOrdenVenta, 
		TMP.esInventario 
	FROM #tmpDetalle TMP
	INNER JOIN Bodegas BOD WITH (NOLOCK) ON TMP.IdBodega = BOD.Id
	INNER JOIN Transportes TRA WITH (NOLOCK) ON TMP.IdCarrier = TRA.Id
	INNER JOIN Clientes CLI_FIN WITH (NOLOCK) ON TMP.IdClienteFinal = CLI_FIN.Id
	INNER JOIN [Clientes] [clientesCons] ON TMP.IdClienteConsignee = [clientesCons].[id]
	INNER JOIN [Exportadores] [exportador] ON TMP.idExportador = [exportador].[id]
	INNER JOIN Paises PAI_CLI WITH (NOLOCK) ON CLI_FIN.IdPais = PAI_CLI.Id
	INNER JOIN Estados EST_CLI WITH (NOLOCK) ON CLI_FIN.IdEstado = EST_CLI.Id
	LEFT JOIN CodigosRelacionSistemas COD_REL WITH (NOLOCK) ON TMP.IdCarrier = COD_REL.IdEntidad AND COD_REL.TipoEntidad = 'CARRIER' AND COD_REL.IdSistemaEntidad = @idSistema 
	LEFT JOIN TransportacionExportacion TRA_EXP WITH (NOLOCK) ON TMP.IdTe = TRA_EXP.Id
	LEFT JOIN Puertos PUE WITH (NOLOCK) ON TRA_EXP.IdPuerto = PUE.Id
	LEFT JOIN [Transportes] [carrierSubCarrier] ON TMP.[idCarrier] = [carrierSubCarrier].[id]
	LEFT JOIN [InformacionClienteFinal] [infoClientesFinal] ON CLI_FIN.[id] = [infoClientesFinal].[id]
	LEFT JOIN [Paises] [paisClientesFinal] ON [infoClientesFinal].[idPais] = [paisClientesFinal].[id]
	LEFT JOIN [Estados] [estadoClientesFinal] ON [infoClientesFinal].[idEstado] = [estadoClientesFinal].[id]
	LEFT JOIN [Paises] [paisClientes] ON CLI_FIN.[idPais] = [paisClientes].[id]
	LEFT JOIN [Estados] [estadoClientes] ON CLI_FIN.[idEstado] = [estadoClientes].[id]
	LEFT JOIN [Usuarios] [usuario] ON TRA_EXP.[idUsuarioEnvio] = [usuario].[id]
	LEFT JOIN [Empleados] [empleado] ON [usuario].[idEntidad] = [empleado].[id]
	LEFT JOIN [Clientes] [usuariocliente] ON [usuario].[idEntidad] = [usuariocliente].[id]
	WHERE  TMP.idBodega = ISNULL(@idBodega, TMP.idBodega )

	DROP TABLE #ClientesRelacionados
	DROP TABLE #TmpGuiasHouseDetalles
END
