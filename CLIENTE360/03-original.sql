ALTER   PROCEDURE [dbo].[pro_ListarDespachoPorCarrierXCarrier]
(
	@fechaDesde DATE,
	@fechaHasta DATE,
	@idCliente VARCHAR(16),
	@isPending BIT,
	@nombreClienteFinal VARCHAR ( 256 ) = NULL,
	@nombreClienteConsignee VARCHAR ( 512 ) = NULL,
	@nombreExportador VARCHAR ( 256 ) = NULL,
	@idBodega VARCHAR ( 16 ) = NULL,
	@PO VARCHAR ( 64 ) = NULL,
	@nroGuia VARCHAR ( 32 ) = NULL,
	@truckId VARCHAR ( 16 ) = NULL
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
		id [UNIQUEIDENTIFIER],
		idGuiaHouse [UNIQUEIDENTIFIER],
		EstadoPieza [VARCHAR] (64),
		EsPod [BIT],
		IdBodega [VARCHAR] ( 16 ) NULL,
		idProgramacionCarrier [UNIQUEIDENTIFIER],
		IdCarrier [VARCHAR] ( 16 ) NULL,
		FechaDespacho [DATETIME],
		IdBroker [VARCHAR] (16)
	)

	SELECT TOP 1  @idSistema = Id 
	FROM SistemasEntidades WITH (NOLOCK) 
	WHERE Codigo = 'UNIFICADO'

	SELECT TOP 1  @idDocumentoManifiesto = Id 
	FROM Documentos WITH (NOLOCK) 
	WHERE Codigo = 'MANIFEST'

	SELECT  @tipoCliente = cat.identificador 
	FROM  Clientes CL
		INNER JOIN dbo.DetalleEntidades DetI ON DetI.idEntidad = CL.id
		INNER JOIN dbo.Catalogos cat ON cat.id = DetI.idCatalogo
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
			WHERE idGrupoCliente = @idCliente
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

	SELECT TOP 1 @final = 'FINAL'
	FROM GuiasHouseDetalles GHD
		INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GHD.idClienteFinal
	WHERE fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta

	IF @isPendigB=0
	BEGIN
		SELECT @fechaDestinoComodin = DATEADD(DAY,-30,@fechaHasta) 
	END
	/* validacion  tipo de clientes*/
	

	IF @nombreClienteFinal IS  NULL AND @nombreClienteConsignee IS NULL AND @nombreExportador IS NULL AND @PO IS NULL AND @nroGuia IS NULL AND @truckId IS NULL AND @idBodega IS NULL 
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
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.idBroker
			FROM ProgramacionCarrier AS t  WITH (NOLOCK)
				INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON 
													GHD.id = T.idGuiaHouseDetalle 
													AND GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
				INNER JOIN #ClientesRelacionados CL ON CL.idCliente = GHD.idClienteFinal
				INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
			WHERE 
				T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				
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
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.idBroker
			FROM GuiasHouse GH WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH.idCliente
				INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier AS t  WITH (NOLOCK) ON 
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
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.idBroker
			FROM GuiasHouse GH1 WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH1.idCliente
				INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
				INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier AS T WITH (NOLOCK) ON 
								T.idGuiaHouseDetalle = GHD.id
								AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE  GH1.house IS NULL 
				AND GH1.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
		END 
	END
	ELSE
	BEGIN 
		IF @nombreClienteFinal IS NOT NULL
		BEGIN 
			SELECT 
				@nombreClienteFinal = UPPER(@nombreClienteFinal)

			INSERT INTO #ClientesFinales
			SELECT id
			FROM Clientes
			WHERE nombreClienteFinal LIKE '%'+@nombreClienteFinal+'%' OR nombre LIKE '%'+@nombreClienteFinal+'%' 
			
		END
		IF @nombreClienteConsignee IS NOT NULL
		BEGIN 
			SELECT @nombreClienteConsignee = UPPER(@nombreClienteConsignee)

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
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.idBroker
			FROM GuiasHouseDetalles AS GHD WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CL WITH (NOLOCK) ON CL.idCliente = GHD.idClienteFinal
				INNER JOIN ProgramacionCarrier AS t WITH (NOLOCK) ON 
												GHD.id = T.idGuiaHouseDetalle
												AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
			WHERE  GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
				AND (
						@nombreExportador IS NULL
						OR gh.idExportador IN (SELECT id FROM #exportadores)
					)
				AND (
					@nombreClienteFinal IS NULL 
					OR GHD.idClienteFinal IN (SELECT idCliente FROM #ClientesFinales) 
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
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.idBroker
			FROM GuiasHouse GH WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH.idCliente
				INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier AS t WITH (NOLOCK) ON 
												GHD.id = T.idGuiaHouseDetalle
												AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta 
			WHERE  GH.house IS NOT NULL 
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
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho,
				GH.idBroker
			FROM GuiasHouse GH1 WITH (NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idCliente = GH1.idCliente
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
				INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier AS t WITH (NOLOCK) ON 
												GHD.id = T.idGuiaHouseDetalle
												AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE  GH1.house IS NULL 
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
	
	SELECT
		GHD.EstadoPieza,
		GHD.FechaDespacho,
		SUM(IIF(DOC.esPOD = 1 AND DOC.mailEnviado = 1, 1, 0)) ConPodEnviado,
		SUM(IIF(MAN.id IS NOT NULL, 1, 0)) PiezasManifiesto,
		COUNT(1) AS TotalPiezas,
		ghd.EsPod,
		ISNULL(ub.idBodega,GHD.IdBodega) idBodega,
		GHD.IdCarrier,
		GHD.IdBroker,
		CAST(CASE 
			WHEN SV.tipoVenta = 5 AND SVD.tipoPieza = 1 THEN 1
			WHEN SV.tipoVenta < 4 THEN 1
			ELSE 0 
			END AS BIT) esInventario
	INTO #tmpDetalle
	FROM (	
			SELECT DISTINCT
				ghd.id,
				ghd.idProgramacionCarrier,
				GHD.EstadoPieza,
				GHD.FechaDespacho,
				ghd.EsPod,
				GHD.IdBodega,
				GHD.IdCarrier,
				GHD.IdBroker
			FROM #TmpGuiasHouseDetalles ghd
		)AS GHD
		LEFT JOIN ProgramacionTe PRO_TE WITH (NOLOCK) ON PRO_TE.IdProgramacionCarrier = ghd.idProgramacionCarrier
		LEFT JOIN ProgramacionManifiesto PRO_MAN WITH (NOLOCK) ON PRO_MAN.IdProgramacionCarrier = ghd.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MAN WITH (NOLOCK) ON MAN.Id = PRO_MAN.IdManifiestoDespacho
		OUTER APPLY (
        	SELECT TOP 1 DD.EsPod, DD.mailEnviado
        	FROM DocumentosDespacho DD WITH(NOLOCK)
        	WHERE DD.idManifiesto = MAN.Id
        	AND DD.idDocumento = @idDocumentoManifiesto
        	ORDER BY EsPod DESC
      ) DOC
		LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
		LEFT JOIN Ubicaciones u WITH (NOLOCK) ON up.idUbicacion = u.id 
		LEFT JOIN UbicacionesBodega ub WITH (NOLOCK) ON u.idUbicacionBodega = ub.id 
		LEFT JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON SVD.idGuiaHouseDetalle = ghd.id
		LEFT JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud
	WHERE 
		CASE 
			WHEN @isPendigB = 1 AND (GHD.EsPod = @isPendigB OR DOC.MailEnviado= @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = @isPendigB OR ISNULL(DOC.MailEnviado,@isPendigB)  = @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = 1 OR ISNULL(DOC.MailEnviado,@isPendigB) = 0 )THEN 1 
			ELSE 0
		END = 1

	GROUP BY GHD.EstadoPieza,
		GHD.FechaDespacho,
		ghd.EsPod,
		GHD.IdBodega,
		ub.idBodega,
		GHD.IdCarrier,
		GHD.IdBroker,
		CASE 
			WHEN SV.tipoVenta = 5 AND SVD.tipoPieza = 1 THEN 1
			WHEN SV.tipoVenta < 4 THEN 1 
			ELSE 0 
			END

	SELECT
		ROW_NUMBER() OVER (ORDER BY TMP.FechaDespacho) Id,
		TMP.EstadoPieza,
		TMP.FechaDespacho,
		TMP.ConPodEnviado,
		TMP.PiezasManifiesto,
		TMP.TotalPiezas,
		TRA.Nombre NombreCarrier,
		BOD.Nombre NombreBodega,
		TMP.IdBodega,
		TMP.IdCarrier,
		TMP.IdBroker,
		TMP.EsInventario
	FROM #tmpDetalle TMP
	INNER JOIN Bodegas BOD WITH (NOLOCK) ON TMP.IdBodega = BOD.Id
	INNER JOIN Transportes TRA WITH (NOLOCK) ON TMP.IdCarrier = TRA.Id
	WHERE  TMP.idBodega = ISNULL(@idBodega, TMP.idBodega )

	DROP TABLE #ClientesRelacionados
	DROP TABLE #TmpGuiasHouseDetalles
END
