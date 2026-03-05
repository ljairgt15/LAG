USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_ListarDespachoPorClientexCliente]    Script Date: 04/03/2026 06:40:12 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
VERSION			AUTOR					FECHA			HU			    CAMBIO
1				Edwin Casa   		    14-09-2023		C360 30972  	Codigo Inicial 
2				Fernando Ordoñez		10-09-2024		41334			Quitar Headerlabel
3				Edwin Casa				29-11-2024		Bug-46125		Se corrige la logica para las piezas que son de inventario
4				Jose Ganchozo			09-01-2025		CC: 47597		Ajustes de formato y revision de traces antes y despues
5				Joel Cedeno				23-01-2024		CC: 45093		Filtro para obtener pendientes y completados correctos
*/
ALTER   PROCEDURE [dbo].[pro_ListarDespachoPorClientexCliente]
(
	@fechaDesde				DATE,
	@fechaHasta				DATE,
	@idCliente				VARCHAR(16),
	@isPending				BIT,
	@nombreClienteFinal		VARCHAR(256) = NULL,
	@nombreClienteConsignee	VARCHAR(512) = NULL,
	@nombreExportador		VARCHAR(256) = NULL,
	@idBodega				VARCHAR(16) = NULL,
	@PO						VARCHAR(64) = NULL,
	@nroGuia				VARCHAR(32) = NULL,
	@truckId				VARCHAR(16) = NULL
)
AS
BEGIN	
	DECLARE @tipoCliente			VARCHAR(32),
			@idSistema				INT, 
			@idDocumentoManifiesto	VARCHAR(16),
			@isPendigB				BIT,
			@fechaDestinoComodin	DATETIME,
			@final					VARCHAR(16) = NULL,
			@consignee				VARCHAR(16) = NULL,
			@consolidador			VARCHAR(16) = NULL,
			@pendiente				BIT = 0,
			@completado				BIT = 1,
			@mailEnviado			BIT = 0,
			@esPod					BIT = 1
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
		AltoIn					DECIMAL (18, 2),
		LargoIn					DECIMAL (18, 2),
		AnchoIn					DECIMAL (18, 2),
		IdClienteFinal			VARCHAR (16),
		TruckId					VARCHAR (16),
		IdBodega				VARCHAR (16) NULL,
		idProgramacionCarrier	UNIQUEIDENTIFIER,
		IdCarrier				VARCHAR (16) NULL,
		FechaDespacho			DATETIME
	)
	
	SELECT TOP 1 @idSistema = Id 
	FROM SistemasEntidades WITH(NOLOCK) 
	WHERE Codigo = 'UNIFICADO'

	SELECT TOP 1 @idDocumentoManifiesto = Id 
	FROM Documentos WITH(NOLOCK) 
	WHERE Codigo = 'MANIFEST'

	SELECT @tipoCliente = C.identificador 
	FROM Clientes CL
	INNER JOIN DetalleEntidades DE ON DE.idEntidad = CL.id
	INNER JOIN Catalogos C ON C.id = DE.idCatalogo
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
			FROM GrupoClientes 
			WHERE idGrupoCliente = @idCliente
		END

	/* validacion  tipo de clientes*/
	SELECT TOP 1 @consolidador = 'CONSOLIDADOR'
	FROM GuiasHouse GH WITH(NOLOCK)
	INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH.idCliente
	WHERE fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta AND GH.house IS NULL 

	SELECT TOP 1 @consignee ='CONSIGNEE'
	FROM GuiasHouse GH WITH(NOLOCK)
	INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH.idCliente
	WHERE fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta AND GH.house IS NOT NULL 

	SELECT TOP 1 @final = 'FINAL'
	FROM GuiasHouseDetalles GHD WITH(NOLOCK)
	INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GHD.idClienteFinal
	WHERE fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta

	IF @isPendigB=0
	BEGIN
		SELECT @fechaDestinoComodin = DATEADD(DAY,-30,@fechaHasta) 
	END
	
	/* validacion  tipo de clientes*/
	IF @nombreClienteFinal IS  NULL 
		AND @nombreClienteConsignee IS NULL 
		AND @nombreExportador IS NULL 
		AND @PO IS NULL 
		AND @nroGuia IS NULL 
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
				GHD.TruckId,
				GH.idBodega,
				t.id as idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho
			FROM ProgramacionCarrier AS t WITH(NOLOCK)
			INNER JOIN GuiasHouseDetalles AS GHD WITH(NOLOCK) ON GHD.id = T.idGuiaHouseDetalle AND GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
			INNER JOIN #ClientesRelacionados CL ON CL.idCliente = GHD.idClienteFinal
			INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.id =  GHD.idGuiaHouse
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
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho
			FROM GuiasHouse GH WITH(NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH(NOLOCK) ON CLI.idCliente = GH.idCliente
				INNER JOIN GuiasHouseDetalles AS GHD WITH(NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier AS t  WITH(NOLOCK) ON T.idGuiaHouseDetalle = GHD.id AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
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
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho
			FROM GuiasHouse GH1 WITH(NOLOCK)
				INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH1.idCliente
				INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.idGuia = gh1.idGuia
				INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON T.idGuiaHouseDetalle = GHD.id AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
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
			SELECT @nombreClienteConsignee = UPPER(@nombreClienteConsignee)

			INSERT INTO #ClientesConsignee
			SELECT id
			FROM Clientes
			WHERE nombre LIKE '%'+@nombreClienteConsignee+'%'
		END

		IF @nombreExportador IS NOT NULL
		BEGIN 
			SELECT  @nombreExportador = UPPER(@nombreExportador)

			INSERT INTO #exportadores
			SELECT id
			FROM Exportadores
			WHERE nombreComercial LIKE '%'+@nombreExportador+'%' OR nombre LIKE '%'+@nombreExportador+'%' 
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
				t.fechaDespacho
			FROM GuiasHouseDetalles GHD WITH(NOLOCK)
				INNER JOIN #ClientesRelacionados CL WITH(NOLOCK) ON CL.idCliente = GHD.idClienteFinal
				INNER JOIN ProgramacionCarrier t WITH(NOLOCK) ON GHD.id = T.idGuiaHouseDetalle AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.id =  GHD.idGuiaHouse
			WHERE GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaHasta
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
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho
			FROM GuiasHouse GH WITH(NOLOCK)
				INNER JOIN #ClientesRelacionados CLI WITH(NOLOCK) ON CLI.idCliente = GH.idCliente
				INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier t WITH(NOLOCK) ON GHD.id = T.idGuiaHouseDetalle AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta 
			WHERE GH.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta AND GH.house IS NOT NULL 
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
				GHD.TruckId,
				GH.idBodega,
				t.id idProgramacionCarrier,
				t.idCarrier,
				t.fechaDespacho
			FROM GuiasHouse GH1 WITH(NOLOCK)
				INNER JOIN #ClientesRelacionados CLI ON CLI.idCliente = GH1.idCliente
				INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.idGuia = gh1.idGuia
				INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON ghd.idGuiaHouse = gh.id
				INNER JOIN ProgramacionCarrier t WITH(NOLOCK) ON GHD.id = T.idGuiaHouseDetalle AND T.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
			WHERE GH1.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaHasta
				AND GH1.house IS NULL 
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
		MAN.NroManifiesto,
		SUM(GHD.AltoIn * GHD.LargoIn * GHD.AnchoIn) CapacidadCarga,
		COUNT(1) TotalPiezas,
		GHD.IdClienteFinal,
		GHD.TruckId,
		ISNULL(ub.idBodega,GHD.IdBodega) idBodega,
		GHD.IdCarrier,
		PTE.IdTe,
		MAN.Id IdManifiesto,
		CAST (CASE 
			WHEN SV.tipoVenta = 5 AND SVD.tipoPieza = 1 THEN 1
			WHEN SV.tipoVenta < 4 THEN 1
			ELSE 0 
		END AS BIT)  esInventario,
		DDO.NombreDocumentoDespacho,
		DDO.IdDocumentosDespacho,
		DDO.MailEnviado,
		GHD.EsPod
	INTO #tmpDetalle
	FROM
		(
			SELECT DISTINCT
				GHD.ID,
				GHD.EstadoPieza,
				GHD.FechaDespacho,
				ghd.idProgramacionCarrier,
				GHD.AltoIn,
				GHD.LargoIn,
				GHD.AnchoIn,
				GHD.IdClienteFinal,
				GHD.TruckId,
				GHD.IdBodega,
				GHD.IdCarrier,
				GHD.EsPod
			FROM #TmpGuiasHouseDetalles ghd
		) ghd
		LEFT JOIN ProgramacionTe PTE WITH (NOLOCK) ON PTE.IdProgramacionCarrier = ghd.idProgramacionCarrier
		LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PM.IdProgramacionCarrier = ghd.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MAN WITH (NOLOCK) ON MAN.Id = PM.IdManifiestoDespacho
		OUTER APPLY (
        	SELECT TOP 1 
				DD.EsPod, 
				DD.mailEnviado, 
				DD.NombreArchivo AS NombreDocumentoDespacho, 
				DD.Id AS IdDocumentosDespacho
        	FROM DocumentosDespacho DD WITH(NOLOCK)
        	WHERE DD.idManifiesto = MAN.Id
        	AND DD.idDocumento = @idDocumentoManifiesto
        	ORDER BY EsPod DESC
      ) DDO
		LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
		LEFT JOIN Ubicaciones u WITH (NOLOCK) ON up.idUbicacion = u.id 
		LEFT JOIN UbicacionesBodega ub WITH (NOLOCK) ON u.idUbicacionBodega = ub.id 
		LEFT JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON SVD.idGuiaHouseDetalle = ghd.id
		LEFT JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud
	WHERE
		CASE 
			WHEN @isPendigB = 1 AND (GHD.EsPod = @isPendigB OR DDO.MailEnviado= @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = @isPendigB OR ISNULL(DDO.MailEnviado,@isPendigB)  = @isPendigB) THEN 1 
			WHEN @isPendigB = 0 AND (GHD.EsPod = 1 OR ISNULL(DDO.MailEnviado,@isPendigB) = 0 )THEN 1 
			ELSE 0
		END = 1

	GROUP BY GHD.EstadoPieza,
		GHD.FechaDespacho,
		MAN.NroManifiesto,
		GHD.IdClienteFinal,
		GHD.TruckId,
		GHD.IdBodega,
		ub.idBodega,
		GHD.IdCarrier,
		PTE.IdTe,
		MAN.Id,
		CASE 
			WHEN SV.tipoVenta = 5 AND SVD.tipoPieza = 1 THEN 1
			WHEN SV.tipoVenta < 4 THEN 1 
			ELSE 0 
		END,
		DDO.NombreDocumentoDespacho,
		DDO.IdDocumentosDespacho,
		DDO.MailEnviado,
		GHD.EsPod

	SELECT
		ROW_NUMBER() OVER (ORDER BY TMP.FechaDespacho) Id,
		TMP.EstadoPieza,
		TMP.FechaDespacho,
		TMP.NroManifiesto,
		TMP.CapacidadCarga,
		TMP.TotalPiezas,
		ISNULL(CLI.NombreClienteFinal,CLI.Nombre ) NombreClienteFinal,
		PA.Nombre NombrePais,
		PA.CodigoIso CodigoIsoPais,
		EST.CodigoIso CodigoIsoEstado,
		TRA.Nombre NombreCarrier,
		CR.Codigo CodigoCarrier,
		PUE.CodigoAduana,
		BOD.Nombre NombreBodega,
		TMP.NombreDocumentoDespacho,
		TMP.MailEnviado,
		TMP.IdClienteFinal,
		TMP.TruckId,
		TMP.IdBodega,
		TMP.IdCarrier,
		TMP.IdManifiesto,
		PA.Id IdPais,
		EST.Id IdEstado,
		TMP.IdDocumentosDespacho,
		TMP.EsInventario ,
		tmp.EsPod
	FROM #tmpDetalle TMP
	INNER JOIN Bodegas BOD WITH(NOLOCK) ON TMP.IdBodega = BOD.Id
	INNER JOIN Transportes TRA WITH(NOLOCK) ON TMP.IdCarrier = TRA.Id
	INNER JOIN Clientes CLI WITH(NOLOCK) ON TMP.IdClienteFinal = CLI.Id
	INNER JOIN Paises PA WITH(NOLOCK) ON CLI.IdPais = PA.Id
	INNER JOIN Estados EST WITH(NOLOCK) ON CLI.IdEstado = EST.Id
	LEFT JOIN CodigosRelacionSistemas CR WITH(NOLOCK) ON TMP.IdCarrier = CR.IdEntidad AND CR.TipoEntidad = 'CARRIER' AND CR.IdSistemaEntidad = @idSistema
	LEFT JOIN TransportacionExportacion TE WITH(NOLOCK) ON TMP.IdTe = TE.Id
	LEFT JOIN Puertos PUE WITH(NOLOCK) ON TE.IdPuerto = PUE.Id
	WHERE TMP.idBodega = ISNULL(@idBodega, TMP.idBodega ) 

	DROP TABLE #ClientesRelacionados
	DROP TABLE #TmpGuiasHouseDetalles
END

/*
exec sp_executesql N'pro_ListarDespachoPorClientexCliente @fechaDesde, @fechaHasta, @idCliente, @isPending, @nombreClienteFinal, @nombreClienteConsignee, @nombreExportador, @idBodega, @PO, @nroGuia, @truckId
',N'@fechaDesde datetime,@fechaHasta datetime,@idCliente nvarchar(9),@isPending bit,@nombreClienteConsignee nvarchar(4000),@nombreClienteFinal nvarchar(4000),@nombreExportador nvarchar(4000),@nroGuia nvarchar(4000),@PO nvarchar(4000),@truckId nvarchar(4000),@idBodega nvarchar(4000)',
@fechaDesde='20250114',@fechaHasta='20250114',
@idCliente='CLI013588',@isPending=0,@nombreClienteConsignee=NULL,
@nombreClienteFinal=NULL,@nombreExportador=NULL,@nroGuia=NULL,@PO=NULL,@truckId=NULL,@idBodega=NULL

exec sp_executesql N'pro_ListarDespachoPorClientexCliente @fechaDesde, @fechaHasta, @idCliente, @isPending, @nombreClienteFinal, @nombreClienteConsignee, @nombreExportador, @idBodega, @PO, @nroGuia, @truckId
',N'@fechaDesde datetime,@fechaHasta datetime,@idCliente nvarchar(9),@isPending bit,@nombreClienteConsignee nvarchar(4000),@nombreClienteFinal nvarchar(4000),@nombreExportador nvarchar(4000),@nroGuia nvarchar(4000),@PO nvarchar(4000),@truckId nvarchar(4000),@idBodega nvarchar(4000)',
@fechaDesde='20241219',@fechaHasta='20241219',
@idCliente='CLI013588',@isPending=1,@nombreClienteConsignee=NULL,
@nombreClienteFinal=NULL,@nombreExportador=NULL,@nroGuia=NULL,@PO=NULL,@truckId=NULL,@idBodega=NULL

exec sp_executesql N'pro_ListarDespachoPorClientexCliente @fechaDesde, @fechaHasta, @idCliente, @isPending, @nombreClienteFinal, @nombreClienteConsignee, @nombreExportador, @idBodega, @PO, @nroGuia, @truckId
',N'@fechaDesde datetime,@fechaHasta datetime,@idCliente nvarchar(9),@isPending bit,@nombreClienteConsignee nvarchar(4000),@nombreClienteFinal nvarchar(4000),@nombreExportador nvarchar(4000),@nroGuia nvarchar(4000),@PO nvarchar(4000),@truckId nvarchar(4000),@idBodega nvarchar(4000)',
@fechaDesde='20241210',@fechaHasta='20241214',
@idCliente='CLI013588',@isPending=0,@nombreClienteConsignee=NULL,
@nombreClienteFinal=NULL,@nombreExportador=NULL,@nroGuia=NULL,@PO=NULL,@truckId=NULL,@idBodega=NULL

exec sp_executesql N'pro_ListarDespachoPorClientexCliente @fechaDesde, @fechaHasta, @idCliente, @isPending, @nombreClienteFinal, @nombreClienteConsignee, @nombreExportador, @idBodega, @PO, @nroGuia, @truckId
',N'@fechaDesde datetime,@fechaHasta datetime,@idCliente nvarchar(9),@isPending bit,@nombreClienteConsignee nvarchar(4000),@nombreClienteFinal nvarchar(4000),@nombreExportador nvarchar(4000),@nroGuia nvarchar(4000),@PO nvarchar(4000),@truckId nvarchar(4000),@idBodega nvarchar(4000)',
@fechaDesde='20241210',@fechaHasta='20241214',
@idCliente='CLI013588',@isPending=1,@nombreClienteConsignee=NULL,
@nombreClienteFinal=NULL,@nombreExportador=NULL,@nroGuia=NULL,@PO=NULL,@truckId=NULL,@idBodega=NULL

exec sp_executesql N'pro_ListarDespachoPorClientexCliente @fechaDesde, @fechaHasta, @idCliente, @isPending, @nombreClienteFinal, @nombreClienteConsignee, @nombreExportador, @idBodega, @PO, @nroGuia, @truckId
',N'@fechaDesde datetime,@fechaHasta datetime,@idCliente nvarchar(9),@isPending bit,@nombreClienteConsignee nvarchar(4000),@nombreClienteFinal nvarchar(4000),@nombreExportador nvarchar(4000),@nroGuia nvarchar(4000),@PO nvarchar(4000),@truckId nvarchar(4000),@idBodega nvarchar(4000)',
@fechaDesde='20241219',@fechaHasta='20241219',
@idCliente='CLI013588',@isPending=1,@nombreClienteConsignee=NULL,
@nombreClienteFinal='WF CITYSIDE FLOWERS',@nombreExportador=NULL,@nroGuia=NULL,@PO=NULL,@truckId=NULL,@idBodega=NULL
*/