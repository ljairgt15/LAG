/* VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
   1		    Jair Gomez			2026-03-03	   58765		Initial Code - Based on pro_ListarDespachoPorCarrierxDetallada. 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByCarrier360Detailed]
(
	@fechaDesde				DATE,
	@fechaHasta				DATE,
	@idCliente				VARCHAR(16),
	@isPending				BIT,
	@nombreClienteFinal		VARCHAR ( 256 ) = NULL,
	@nombreClienteConsignee	VARCHAR ( 512 ) = NULL,
	@nombreExportador		VARCHAR ( 256 ) = NULL,
	@idBodega				VARCHAR ( 16 ) = NULL,
	@PO						VARCHAR ( 64 ) = NULL,
	@nroGuia				VARCHAR ( 32 ) = NULL,
	@truckId				VARCHAR ( 16 ) = NULL,
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
	SELECT @isPendigB = IIF(@isPending = 0, 1,0),
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
		id [UNIQUEIDENTIFIER],
		idGuiaHouse [UNIQUEIDENTIFIER],
		EstadoPieza [VARCHAR] (64),
		EsPod [BIT],
		AltoIn [DECIMAL] ( 18, 2 ),
		LargoIn [DECIMAL] ( 18, 2 ),
		AnchoIn [DECIMAL] ( 18, 2 ),
		IdClienteFinal [VARCHAR] (16),
		IdHeaderLabel [UNIQUEIDENTIFIER],
		TruckId [VARCHAR] ( 16 ),
		IdBodega [VARCHAR] ( 16 ) NULL,
		idProgramacionCarrier [UNIQUEIDENTIFIER],
		IdCarrier [VARCHAR] ( 16 ) NULL,
		FechaDespacho [DATETIME],
		NroGuia [VARCHAR] ( 32 ),
		IdClienteConsignee [VARCHAR] (16),
		po [VARCHAR] (64),
		House [VARCHAR] ( 32 ),
		IdGuia [VARCHAR] ( 64 ),
		IdExportador [VARCHAR] ( 16 ),
		[idBroker] [VARCHAR] ( 16 )
	)

	SELECT TOP 1 @idSistema = Id 
	FROM SistemasEntidades WITH (NOLOCK) 
	WHERE Codigo = 'UNIFICADO'

	SELECT TOP 1 @idDocumentoManifiesto = Id 
	FROM Documentos WITH (NOLOCK) 
	WHERE Codigo = 'MANIFEST'

	SELECT @tipoCliente = cat.identificador 
	FROM Clientes CL
	INNER JOIN dbo.DetalleEntidades DetI ON DetI.idEntidad = CL.id
	INNER JOIN dbo.Catalogos cat ON cat.id = DetI.idCatalogo
	WHERE CL.id = @idCliente

	IF @tipoCliente = 'CLIENTE'
		BEGIN 
			INSERT INTO #ClientesRelacionados (idCliente) 
			VALUES(@idCliente)

		END
	ELSE
		BEGIN 
			INSERT INTO #ClientesRelacionados (idCliente) 
			SELECT idCliente 
			FROM dbo.GrupoClientes 
			WHERE idGrupoCliente = @idCliente
		END

	/* validacion  tipo de clientes*/
	SELECT TOP 1 @consolidador = 'CONSOLIDADOR'
	FROM GuiasHouse GH
	INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH.idCliente
	WHERE GH.house IS NULL AND fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta

	SELECT TOP 1 @consignee ='CONSIGNEE'
	FROM GuiasHouse GH
	INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH.idCliente
	WHERE GH.house IS NOT NULL AND fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta

	SELECT TOP 1 @final = 'FINAL'
	FROM GuiasHouseDetalles GHD
	INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GHD.idClienteFinal
	WHERE fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta

	IF @isPendigB=0
	BEGIN
		SELECT @fechaDestinoComodin = DATEADD(DAY, -30, @fechaHasta) 
	END

	IF @nombreClienteFinal IS  NULL 
	   AND @nombreClienteConsignee IS NULL 
	   AND @nombreExportador IS NULL 
	   AND @PO IS NULL AND @nroGuia IS NULL 
	   AND @truckId IS NULL 
	   AND @idBodega IS NULL 
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
				GHD.IdHeaderLabel,
				GHD.TruckId,
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador,
				GH.idBroker
			FROM ProgramacionCarrier t  WITH (NOLOCK)
			INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GHD.id = T.idGuiaHouseDetalle 
															AND GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
			INNER JOIN #ClientesRelacionados CL ON CL.idCliente = GHD.idClienteFinal
			INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id = GHD.idGuiaHouse
			WHERE T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				
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
				GHD.IdHeaderLabel,
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
				gh.idExportador,
				GH.idBroker
			FROM dbo.GuiasHouse GH WITH (NOLOCK)
			INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH.idCliente
			INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
			INNER JOIN ProgramacionCarrier AS t  WITH (NOLOCK) ON T.idGuiaHouseDetalle = GHD.id AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE GH.house IS NOT NULL AND GH.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
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
				GHD.IdHeaderLabel,
				GHD.TruckId,
				GH.idBodega,
				t.id AS idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador,
				GH.idBroker
			FROM dbo.GuiasHouse GH1 WITH (NOLOCK)
			INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH1.idCliente
			INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
			INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
			INNER JOIN ProgramacionCarrier AS T WITH (NOLOCK) ON T.idGuiaHouseDetalle = GHD.id AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE GH1.house IS NULL AND GH1.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
		END 
	END
	ELSE
	BEGIN 
		IF @nombreClienteFinal IS NOT NULL
		BEGIN 
			SELECT @nombreClienteFinal = UPPER(@nombreClienteFinal)

			INSERT INTO #ClientesFinales
			SELECT id
			FROM Clientes
			WHERE nombreClienteFinal LIKE '%'+@nombreClienteFinal+'%' OR nombre LIKE '%'+@nombreClienteFinal+'%' 
			
		END
		IF @nombreClienteConsignee IS NOT NULL
		BEGIN 
			SELECT @nombreExportador = UPPER(@nombreExportador)

			INSERT INTO #ClientesConsignee
			SELECT id
			FROM Clientes
			WHERE nombre LIKE '%'+@nombreClienteConsignee+'%' 
		END

		IF @nombreExportador IS NOT NULL
		BEGIN 
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
				GHD.IdHeaderLabel,
				GHD.TruckId,
				GH.idBodega,
				t.id AS idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.nroGuia,
				GH.idCliente,
				GHD.po,
				GH.house,
				GH.idGuia,
				gh.idExportador,
				GH.idBroker
			FROM GuiasHouseDetalles AS GHD WITH (NOLOCK)
			INNER JOIN #ClientesRelacionados CL WITH (NOLOCK) ON CL.idCliente = GHD.idClienteFinal
			INNER JOIN ProgramacionCarrier AS t WITH (NOLOCK) ON GHD.id = T.idGuiaHouseDetalle
															 AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
			WHERE GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
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
				GHD.IdHeaderLabel,
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
				gh.idExportador,
				GH.idBroker
			FROM dbo.GuiasHouse GH WITH (NOLOCK)
			INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH.idCliente
			INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
			INNER JOIN ProgramacionCarrier t WITH (NOLOCK) ON GHD.id = T.idGuiaHouseDetalle
														  AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta 
			WHERE GH.house IS NOT NULL 
				  AND GH.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
				  AND (@nroGuia IS NULL OR GH.nroGuia LIKE '%' + @nroGuia + '%')
				  AND (
				  		@nombreExportador IS NULL
				  		OR gh.idExportador IN (SELECT id FROM #exportadores)
				  	)
				  AND (
				  		@nombreClienteConsignee IS NULL 
				  		OR GH.idCliente IN (SELECT idCliente FROM #ClientesConsignee) 
				  	)
				  
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
				GHD.IdHeaderLabel,
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
				gh.idExportador,
				GH.idBroker
			FROM dbo.GuiasHouse GH1
			INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH1.idCliente
			INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
			INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
			INNER JOIN ProgramacionCarrier t ON GHD.id = T.idGuiaHouseDetalle
											AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE GH1.house IS NULL 
				  AND GH1.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
				  AND (@nroGuia IS NULL OR GH.nroGuia LIKE '%' + @nroGuia + '%')
				  AND (
				  		@nombreExportador IS NULL
				  		OR gh.idExportador IN (SELECT id FROM #exportadores)
				  	)
				  AND (
				  		@nombreClienteConsignee IS NULL 
				  		OR GH.idCliente IN (SELECT idCliente FROM #ClientesConsignee) 
				  	)
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
		GHD.IdHeaderLabel,
		GHD.TruckId,
		ISNULL(ub.idBodega,GHD.IdBodega) idBodega,
		GHD.IdCarrier,
		PRO_TE.IdTe,
		MAN.Id IdManifiesto ,
		GHD.nroGuia,
		GHD.IdClienteConsignee,
		GHD.po,
		GHD.house,
		GHD.idGuia,
		ghd.IdExportador,
		ghd.idGuiaHouse,
		GHD.idBroker,
		CAST(CASE 
				WHEN sv.tipoVenta = 5 AND svd.tipoPieza = 1 THEN 1
				WHEN sv.tipoVenta < 4 THEN 1
				ELSE 0
			END AS BIT) esInventario,
		DOC.[id] [IdDocumentosDespacho], 
		CONVERT(VARCHAR(36),DOC.[id]) [IdDocumentosDespachoString], 
		CASE
			WHEN DOC.[mailEnviado] IS NULL OR DOC.[mailEnviado] = ''
			THEN CAST(0 AS BIT) ELSE DOC.[mailEnviado]
		END [EmailEnviado], 
		DOC.[NombreDocumentoDespacho]
	INTO #tmpDetalle
	FROM #TmpGuiasHouseDetalles ghd
	LEFT JOIN ProgramacionTe PRO_TE WITH (NOLOCK) ON PRO_TE.IdProgramacionCarrier = ghd.idProgramacionCarrier
	LEFT JOIN ProgramacionManifiesto PRO_MAN WITH (NOLOCK) ON PRO_MAN.IdProgramacionCarrier = ghd.idProgramacionCarrier
	LEFT JOIN ManifiestosDespacho MAN WITH (NOLOCK) ON MAN.Id = PRO_MAN.IdManifiestoDespacho
	OUTER APPLY (
        	SELECT TOP 1 
				DD.EsPod, 
				DD.mailEnviado, 
				DD.id,
				DD.nombreArchivo NombreDocumentoDespacho
        	FROM DocumentosDespacho DD WITH(NOLOCK)
        	WHERE DD.idManifiesto = MAN.Id
        	AND DD.idDocumento = @idDocumentoManifiesto
        	ORDER BY EsPod DESC
      ) DOC
	LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
	LEFT JOIN Ubicaciones u WITH (NOLOCK) ON up.idUbicacion = u.id 
	LEFT JOIN UbicacionesBodega ub WITH (NOLOCK) ON u.idUbicacionBodega = ub.id 
	LEFT JOIN SolicitudDeVentaDetalles svd WITH (NOLOCK) ON svd.idGuiaHouseDetalle = ghd.id
	LEFT JOIN SolicitudDeVenta sv WITH (NOLOCK) ON sv.id = svd.idSolicitud
	WHERE 
		CASE 
			WHEN @isPendigB = 1 AND (GHD.EsPod = @isPendigB OR DOC.MailEnviado= @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = @isPendigB OR ISNULL(DOC.MailEnviado,@isPendigB)  = @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = 1 OR ISNULL(DOC.MailEnviado,@isPendigB) = 0 )THEN 1 
			ELSE 0
		END = 1
		AND CASE
		  	WHEN @esInventario IS NULL THEN 1
		  	WHEN @esInventario = 0 AND sv.id IS NULL  THEN 1
		  	WHEN @esInventario = 0 AND sv.tipoVenta = 5 AND svd.tipoPieza = 2 THEN 1
		  	WHEN @esInventario = 0 AND sv.tipoVenta = 4  THEN 1
		  	WHEN @esInventario = 1 AND sv.tipoVenta = 5 AND svd.tipoPieza = 1 THEN 1
		  	WHEN @esInventario = 1 AND sv.tipoVenta < 4 THEN 1 
		  	ELSE 0 
		  	END = 1

	SELECT DISTINCT
		NEWID() id,
		tmp.[IdGuiaHouse], 
		'' [idGuia], 
		tmp.[id] [IdGuiaHouseDetalle],
		tmp.[fechaDespacho], 
		tmp.[idBodega], 
		BOD.[nombre] [NombreBodega], 
		TRA.[id] [IdCarrier], 
		TRA.[nombre] [NombreCarrier], 
		COR.codigo CodigoCarrier, 
		 '' [IdClienteConsignee], 
		CLC.[nombre] [NombreClienteConsignee],  
		'' IdPaisConsignee,
		'' NombrePaisConsignee,
		CLI.[nombre] [NombreClienteFinalAlt], 
		'' NombreClienteFinalClienteFinalAlt,
		'' IdEstadoConsignee,
		'' CodigoIsoEstadoConsignee,
		PC.[id] [IdPaisAlt], 
		PC.[nombre] [NombrePaisAlt], 
		'' [CodigoIsoPaisAlt], 
		EC.[id] [IdEstadoAlt], 
		EC.[codigoISO] [CodigoIsoEstadoAlt], 
		CLI.[id] [IdClienteFinal], 
		CLI.[nombreClienteFinal], 
		PCF.[id] [IdPais], 
		PCF.[nombre] [NombrePais],  
		'' [CodigoIsoPais], 
		ES.[id] [IdEstado], 
		ES.[codigoISO] [CodigoIsoEstado], 
		tmp.[IdManifiesto], 
		TMP.[nroManifiesto], 
		'' ColorEstadoManifiesto,
		'' ColorEnvioTE,
		PUE.[codigoAduana] [DescripcionPuertoFronterizo], 
		0 PcsPending,
        0 PcsReceivedDr,
        0 PcsReceivedWh,
        0 PcsHold,
        0 PcsLost,
        0 PcsDispatchedWh,
        0 PcsStandby,
        0 TotalPcs,
		tmp.[estadoPieza] [Status], 
		CAST(0 AS BIT) CargaTransito,
		CAST(0 AS BIT) CargaTransitoNull,
		'' TipoNubeDocs,
		TMP.IdDocumentosDespacho,
		TMP.IdDocumentosDespachoString, 
		TMP.EmailEnviado, 
		CAST(0 AS BIT) [TransportExportEnviado], 
		'' UsuarioEnvioTE,
        '' FechaEnvioTE,
        '' TextoTooltipTE,
		'' [nroGuia], 
		'' NroOrdenLocal,
        '' NroDocumento,
		tmp.[truckId], 
		'' TruckIdText,
		0.00 CapacidadCarga,
		tmp.[po], 
		'' CuttOfTime,
		'' [CodigoSubCarrier], 
		'' [NombreSubCarrier], 
		HEA.headerLabel, 
		NULL [IdHeaderLabel],
		'' IdExportador,
		'' Estatus,
		0 OrdenEstatus,
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
		'' [house], 
		CAST(0 AS BIT) Modificado,
		'' Pallet,
		NULL IdOrdenVenta,
		'' Puerta,
        '' Placa,
        '' NroDespacho,
		NULL FechaOrdenVenta,
		TMP.idBroker, 
		E.[nombreComercial] NombreExportador,
		TMP.EsInventario
	FROM #tmpDetalle TMP WITH (NOLOCK)
	INNER JOIN Bodegas BOD WITH (NOLOCK) ON TMP.IdBodega = BOD.Id
	INNER JOIN Transportes TRA WITH (NOLOCK) ON TMP.IdCarrier = TRA.Id
	INNER JOIN Clientes CLI WITH (NOLOCK) ON TMP.IdClienteFinal = CLI.Id
	INNER JOIN Clientes CLC WITH (NOLOCK) ON TMP.IdClienteConsignee = CLC.[id]
	INNER JOIN Exportadores E WITH (NOLOCK) ON TMP.idExportador = E.[id]
	INNER JOIN Paises P WITH (NOLOCK) ON CLI.IdPais = P.Id
	INNER JOIN Estados EST_CLI WITH (NOLOCK) ON CLI.IdEstado = EST_CLI.Id
	LEFT JOIN HeaderLabels HEA WITH (NOLOCK) ON TMP.IdHeaderLabel = HEA.Id
	LEFT JOIN CodigosRelacionSistemas COR WITH (NOLOCK) ON TMP.IdCarrier = COR.IdEntidad AND COR.TipoEntidad = 'CARRIER' AND COR.IdSistemaEntidad = @idSistema 
	LEFT JOIN TransportacionExportacion TEX WITH (NOLOCK) ON TMP.IdTe = TEX.Id
	LEFT JOIN Puertos PUE WITH (NOLOCK) ON TEX.IdPuerto = PUE.Id
	LEFT JOIN Transportes CSC WITH (NOLOCK) ON TMP.[idCarrier] = CSC.[id]
	LEFT JOIN InformacionClienteFinal AS ICF WITH (NOLOCK) ON CLI.[id] = ICF.[id]
	LEFT JOIN Paises PCF WITH (NOLOCK) ON ICF.[idPais] = PCF.[id]
	LEFT JOIN Estados ES WITH (NOLOCK) ON ICF.[idEstado] = ES.[id]
	LEFT JOIN Paises PC WITH (NOLOCK) ON CLI.[idPais] = PC.[id]
	LEFT JOIN Estados EC WITH (NOLOCK) ON CLI.[idEstado] = EC.[id]
	LEFT JOIN Usuarios U WITH (NOLOCK) ON TEX.[idUsuarioEnvio] = U.[id]
	LEFT JOIN Empleados EMP WITH (NOLOCK) ON U.[idEntidad] = EMP.[id]
	LEFT JOIN Clientes UC WITH (NOLOCK) ON U.[idEntidad] = UC.[id]
	WHERE TMP.idBodega = ISNULL(@idBodega, TMP.idBodega )

	DROP TABLE #ClientesRelacionados
	DROP TABLE #TmpGuiasHouseDetalles
END


/*
EXEC [dbo].[AC_pro_GetDispatchByCarrier360Detailed]
    @FechaDesde = '2026-02-24',
    @FechaHasta = '2026-03-05',
    @IdCliente = 'CLI0120247',
    @IsPending = 1,
    @NombreClienteFinal = NULL,
    @NombreClienteConsignee = NULL,
    @NombreExportador = NULL,
    @IdBodega = NULL,
    @Po = NULL,
    @NroGuia = NULL,
    @TruckId = NULL,
    @EsInventario = NULL;
*/