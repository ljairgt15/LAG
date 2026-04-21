/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-04-18		  58763			 Based on pro_ConsultarCodigoBarrasClientes
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetBarCodeExternal]
(
	@FechaDesde			DATETIME,
	@FechaHasta			DATETIME,
	@House				VARCHAR(32) = NULL,
	@NroPo				VARCHAR(32) = NULL,
	@CodBarra			VARCHAR(32) = NULL,
	@Estado				XML = NULL,
	@Orden				VARCHAR(16) = NULL, 
	@NroManifiesto		VARCHAR(16) = NULL,
	@PalletLabel		VARCHAR(32) = NULL,
	@IdGuia				VARCHAR(64) = NULL,
	@TipoCliente		VARCHAR(64) = NULL,	
	@EsPOD				BIT = NULL,
	@EsVendida			BIT = NULL,
	@IdCarrier			VARCHAR(16) = NULL,
	@IdBodega			VARCHAR(16) = NULL,
	@FechaDespacho		DATETIME = NULL,
	@TruckId			VARCHAR(16)= NULL,
	@IdManifiesto		UNIQUEIDENTIFIER= NULL,
	@IdGuiaHouse		UNIQUEIDENTIFIER= NULL,
	@IsDispatchCarrier	BIT = NULL,
	@IdNotificacion		UNIQUEIDENTIFIER= NULL,
	@EsInventario		BIT = NULL,
	@EntityId			VARCHAR(16), 
	@SupplierName		VARCHAR(512) = NULL,
	@SupplierId			VARCHAR(16) = NULL,
	@ConsigneeName		VARCHAR(512) = NULL, 
	@ConsigneeId		VARCHAR(16) = NULL, 
	@ShipToName			VARCHAR(512) = NULL,
	@ShipToId			VARCHAR(16) = NULL,
	@BillToName			VARCHAR(512) = NULL, 
	@BillToId			VARCHAR(16) = NULL,
	@UserType           VARCHAR(32) = NULL
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @IdParametroLista VARCHAR(16),
				@IdEmpresa VARCHAR(16) = NULL,
				@RealEsPOD BIT,
				@RealEsVendida BIT,
				@Final VARCHAR (16) = NULL,
				@Consignee VARCHAR (16) = NULL,
				@Consolidador VARCHAR (16) = NULL,
				@FechaSinHora DATE,
				@SinManifiesto BIT = 0

		
		SELECT @RealEsPOD = CAST(ISNULL(@EsPOD,0) AS BIT),
				@RealEsVendida = CAST(ISNULL(@EsVendida,0)AS BIT),
				@FechaSinHora = CONVERT(DATE, GETDATE())
			
		IF (@IsDispatchCarrier IS  NULL OR @IsDispatchCarrier = 0 ) AND @IdManifiesto IS NULL
		BEGIN 
			SELECT  @SinManifiesto = 1
		END

		IF @IdCarrier IS NULL AND @FechaDespacho IS NULL AND @IdManifiesto IS NULL
		BEGIN
			SELECT @SinManifiesto = 0
		END

		CREATE TABLE #TempPiezasPorCarrier (
			id UNIQUEIDENTIFIER,
			idGuiaHouse UNIQUEIDENTIFIER,
			CodigoBarra VARCHAR(32),
			ProductoDescripcion VARCHAR(512),
			FechaRecepcion DATETIME,
			AltoCm DECIMAL(18,3),
			AnchoCm DECIMAL(18,3),
			LargoCm DECIMAL(18,3),
			AltoInch DECIMAL(18,3),
			AnchoInch DECIMAL(18,3),
			LargoInch DECIMAL(18,3),
			Nota VARCHAR(256),
			EstadoPieza VARCHAR(64),
			FechaCreacion DATETIME,
			FechaCambio DATETIME,
			TotalTallos INT,
			PrecioTallo DECIMAL(18,3),
			Peso DECIMAL(18,3),
			Po VARCHAR(64),
			RecepcionEscaner BIT,
			TruckId VARCHAR(16),
			IdAccion UNIQUEIDENTIFIER,
			NoPermitirVenta BIT,
			NroGuia VARCHAR(32),
			House VARCHAR(32),
			FechaOrigen DATETIME, 
			FechaDestino DATETIME,
			FechaOrigenFecha DATE,
			FechaDestinoFecha DATE,
			IdExportador VARCHAR(16),
			ConsigneeId VARCHAR(16),
			idBodega VARCHAR(16),
			IdProgramacionCarrier UNIQUEIDENTIFIER,
			FechaDespacho DATETIME,
			RecibidoOrigen VARCHAR(16),
			RecibidoDestino VARCHAR(16),
			DespachadoDestino VARCHAR(16),
			Chofer VARCHAR(16),
			IdEmpresa VARCHAR(16),
			valor VARCHAR(64),
			nombreComercial VARCHAR(512),
			nombre VARCHAR(1024),
			razonSocial VARCHAR(512),
			idTipoDePieza VARCHAR(16),
			ShipToId VARCHAR(16),
			idUsuarioLog VARCHAR(16),
			idPoDetalle UNIQUEIDENTIFIER,
			idDetalleMercancia VARCHAR(16),
			ConsigneeName VARCHAR(512)
		);

		CREATE TABLE #TMP_RelatedClients (
            [Id]                VARCHAR(16),
            [IdCliente]         VARCHAR(16),
            [BillToConsigneeId] VARCHAR(16),
            [BillToId]          VARCHAR(16),
            [ConsigneeId]       VARCHAR(16),
            [BillToName]        VARCHAR(256),
            [Name]              VARCHAR(256),
            [JoinKey]           VARCHAR(16)
        )

		CREATE TABLE #idsCatalogos (
			id [VARCHAR](64)
		)

		SELECT  @IdParametroLista = id 
		FROM ParametrosLista PL
		WHERE PL.codigo = 'TipoServicio'
			AND (@IdEmpresa IS NULL OR PL.idEmpresa = @IdEmpresa);

		IF(@Estado IS NOT NULL)
		BEGIN
			INSERT INTO #idsCatalogos
			SELECT [Value] 
			FROM [dbo].fnObtenerValoresXML(@Estado)
		END

        INSERT INTO #TMP_RelatedClients (Id,IdCliente, BillToConsigneeId,BilltoId,ConsigneeId, BillToName, [Name], JoinKey)
        EXEC [dbo].[AC_pro_GetClientsEntities]
             @EntityId = @EntityId,
             @UserType = @UserType 
        
        IF @BillToId IS NOT NULL
        BEGIN
            DELETE FROM #TMP_RelatedClients 
            WHERE BilltoId <> @BillToId OR BilltoId IS NULL;
        END
        ELSE IF @BillToName IS NOT NULL
        BEGIN
			DELETE FROM #TMP_RelatedClients 
            WHERE BillToName NOT LIKE @BillToName + '%' OR BillToName IS NULL;
        END
		
		IF @TipoCliente IS NULL
		BEGIN
			IF @FechaDespacho IS NOT NULL 
			BEGIN 
				SELECT 
					@FechaDesde =  DATEADD(DAY,-90,@FechaDespacho),
					@FechaHasta = @FechaDespacho
			END
			/* validacion  tipo de clientes*/
			SELECT TOP 1 @Consolidador = 'CONSOLIDADOR'
			FROM GuiasHouse GH WITH (NOLOCK)
			INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId = GH.ConsigneeId
			WHERE GH.house IS NULL
			AND GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta

			SELECT TOP 1 @Consignee = 'CONSIGNEE'
			FROM GuiasHouse GH WITH (NOLOCK)
			INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId = GH.ConsigneeId
			WHERE GH.house IS NOT NULL
			AND GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta

			SELECT TOP 1 @Final = 'FINAL'
			FROM GuiasHouseDetalles GHD WITH (NOLOCK)
			INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId = GHD.ShipToId
			WHERE GHD.fechaCreacion BETWEEN @FechaDesde AND @FechaHasta

			IF @Estado IS NULL
			BEGIN
				IF @FechaDespacho IS NOT NULL AND @IdCarrier IS NOT NULL
				BEGIN
					/* CLIENTES FINALES */
					IF @Final IS NOT NULL 
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							'' Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							VCC.nombre ConsigneeName
						FROM ProgramacionCarrier PC  WITH (NOLOCK)
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON 
																 GHD.id = PC.idGuiaHouseDetalle 
																AND  GHD.fechaCreacion BETWEEN @FechaDesde AND @FechaHasta
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =   GHD.idGuiaHouse
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE  PC.fechaDespacho = @FechaDespacho
							AND PC.idCarrier = @IdCarrier
							AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
							AND (@ConsigneeName IS NULL 
								OR VCC.nombre LIKE @ConsigneeName+'%')
														AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
							AND( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
							AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GH.house LIKE @House+'%')
					END

					 /* CLIENTES CONSIGNEE */
					IF @Consignee IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							''  Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							VCC.Nombre ConsigneeName
						FROM GuiasHouse GH WITH (NOLOCK)
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
												PC.idGuiaHouseDetalle =  GHD.id 
												AND PC.fechaDespacho = @FechaDespacho
												AND PC.idCarrier = @IdCarrier
						
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE   GH.house IS NOT NULL 
							AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
							AND (@ConsigneeName IS NULL 
								OR VCC.Nombre LIKE @ConsigneeName+'%')
							AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
							AND( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
							AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GH.house LIKE @House+'%')
					END
				
					/* CLIENTES CONSOLIDADORES */
					IF @Consolidador IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion AS IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							'' Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							VCC.Nombre ConsigneeName
						FROM GuiasHouse GH1 WITH (NOLOCK)
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
											PC.idGuiaHouseDetalle =  GHD.id
											AND PC.fechaDespacho = @FechaDespacho
											AND  PC.idCarrier = @IdCarrier
						
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE  GH1.house IS NULL 
							AND GH1.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
							AND (@ConsigneeName IS NULL 
								OR VCC.Nombre LIKE @ConsigneeName+'%')
							AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
							AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GH.house LIKE @House+'%')
					END
			
				END
				ELSE
				BEGIN
					IF @IdNotificacion IS NULL
					BEGIN
						/* CLIENTES FINALES */
						IF @Final IS NOT NULL 
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoIn AltoInch,
								GHD.AnchoIn AnchoInch,
								GHD.LargoIn LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.idCatalogoAccion IdAccion,
								GHD.NoPermitirVenta,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.ConsigneeId ,
								GH.idBodega,
								PC.id IdProgramacionCarrier,
								PC.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								'' Chofer,
								GH.IdEmpresa,
								PMC.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH  WITH (NOLOCK)
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
								INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @IdParametroLista
							WHERE 
								 GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
								AND CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR VCC.nombre LIKE @ConsigneeName+'%')
								AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
						END

						 /* CLIENTES CONSIGNEE */
						IF @Consignee IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoIn AltoInch,
								GHD.AnchoIn AnchoInch,
								GHD.LargoIn LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.idCatalogoAccion IdAccion,
								GHD.NoPermitirVenta,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.ConsigneeId,
								GH.idBodega,
								PC.id IdProgramacionCarrier,
								PC.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								'' Chofer,
								GH.IdEmpresa,
								PMC.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
								INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC  WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id 
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @IdParametroLista
							WHERE 
								 GH.house IS NOT NULL 
								AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR VCC.nombre LIKE @ConsigneeName+'%')
								AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
						END
				
						/* CLIENTES CONSOLIDADORES */
						IF @Consolidador IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoIn AltoInch,
								GHD.AnchoIn AnchoInch,
								GHD.LargoIn LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.idCatalogoAccion IdAccion,
								GHD.NoPermitirVenta,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.ConsigneeId,
								GH.idBodega,
								PC.id IdProgramacionCarrier,
								PC.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								'' Chofer,
								GH.IdEmpresa,
								PMC.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
								INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @IdParametroLista
							WHERE 
								GH1.house IS NULL 
								AND GH1.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR VCC.nombre LIKE @ConsigneeName+'%')
								AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
						END
					END
					ELSE
					BEGIN
					
						SELECT 
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							'' Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							VCC.nombre ConsigneeName,
							GH1.ConsigneeId idClienteConsolidador,
							GH.idGuia
						INTO  #tempNotificacion
						FROM
							NotificacionPiezasDetalle NTP WITH (NOLOCK) 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON NTP.idGuiaHouseDetalle =  GHD.id
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
							INNER JOIN GuiasHouse GH1 WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia AND GH1.house IS NULL
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE 
							NTP.idNotificacionPiezas = @IdNotificacion

						INSERT INTO #TempPiezasPorCarrier
							SELECT 
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.DescripcionProducto,
								GHD.FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoInch,
								GHD.AnchoInch,
								GHD.LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.IdAccion,
								GHD.NoPermitirVenta,
								GHD.NroGuia,
								GHD.House,
								GHD.FechaOrigen,
								GHD.FechaDestino,
								GHD.FechaOrigenFecha,
								GHD.FechaDestinoFecha,
								GHD.IdExportador,
								GHD.ConsigneeId,
								GHD.idBodega,
								GHD.IdProgramacionCarrier,
								GHD.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								GHD.Chofer,
								GHD.IdEmpresa,
								GHD.valor,
								GHD.nombreComercial,
								GHD.nombre,
								GHD.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GHD.ConsigneeName
							FROM
								#tempNotificacion GHD
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
							WHERE 
								CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR  GHD.ConsigneeName LIKE @ConsigneeName+'%')
								AND ( GHD.idGuia = ISNULL(@IdGuia,  GHD.idGuia))
								AND( GHD.idExportador = ISNULL(@SupplierId,  GHD.idExportador))
								AND (@SupplierName IS NULL OR  GHD.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GHD.house LIKE @House+'%')
							UNION
							SELECT 
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.DescripcionProducto,
								GHD.FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoInch,
								GHD.AnchoInch,
								GHD.LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.IdAccion,
								GHD.NoPermitirVenta,
								GHD.NroGuia,
								GHD.House,
								GHD.FechaOrigen,
								GHD.FechaDestino,
								GHD.FechaOrigenFecha,
								GHD.FechaDestinoFecha,
								GHD.IdExportador,
								GHD.ConsigneeId,
								GHD.idBodega,
								GHD.IdProgramacionCarrier,
								GHD.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								GHD.Chofer,
								GHD.IdEmpresa,
								GHD.valor,
								GHD.nombreComercial,
								GHD.nombre,
								GHD.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GHD.ConsigneeName
							FROM
								#tempNotificacion GHD
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ConsigneeId
							WHERE 
								CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR  GHD.ConsigneeName LIKE @ConsigneeName+'%')
								AND ( GHD.idGuia = ISNULL(@IdGuia,  GHD.idGuia))
								AND( GHD.idExportador = ISNULL(@SupplierId,  GHD.idExportador))
								AND (@SupplierName IS NULL OR  GHD.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GHD.house LIKE @House+'%')
							UNION
							SELECT 
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.DescripcionProducto,
								GHD.FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoInch,
								GHD.AnchoInch,
								GHD.LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.IdAccion,
								GHD.NoPermitirVenta,
								GHD.NroGuia,
								GHD.House,
								GHD.FechaOrigen,
								GHD.FechaDestino,
								GHD.FechaOrigenFecha,
								GHD.FechaDestinoFecha,
								GHD.IdExportador,
								GHD.ConsigneeId,
								GHD.idBodega,
								GHD.IdProgramacionCarrier,
								GHD.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								GHD.Chofer,
								GHD.IdEmpresa,
								GHD.valor,
								GHD.nombreComercial,
								GHD.nombre,
								GHD.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GHD.ConsigneeName
							FROM
								#tempNotificacion GHD
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.idClienteConsolidador
							WHERE 
								CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR  GHD.ConsigneeName LIKE @ConsigneeName+'%')
								AND ( GHD.idGuia = ISNULL(@IdGuia,  GHD.idGuia))
								AND( GHD.idExportador = ISNULL(@SupplierId,  GHD.idExportador))
								AND (@SupplierName IS NULL OR  GHD.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GHD.house LIKE @House+'%')
					END
				END
			END
			ELSE
			BEGIN 
				IF @FechaDespacho IS NOT NULL AND @IdCarrier IS NOT NULL
				BEGIN
					/* CLIENTES FINALES */
					IF @Final IS NOT NULL 
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							'' Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							VCC.Nombre ConsigneeName
						FROM
							ProgramacionCarrier PC  WITH (NOLOCK)
							INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON 
																 GHD.id = PC.idGuiaHouseDetalle 
																AND  GHD.fechaCreacion BETWEEN @FechaDesde AND @FechaHasta
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
							INNER JOIN #idsCatalogos CATEST ON CATEST.id =  GHD.estadoPieza
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =   GHD.idGuiaHouse
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE 
							PC.fechaDespacho = @FechaDespacho
							AND PC.idCarrier = @IdCarrier
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@ConsigneeName IS NULL 
								OR VCC.Nombre LIKE @ConsigneeName+'%')
							AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
							AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GH.house LIKE @House+'%')
							AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
					END

					 /* CLIENTES CONSIGNEE */
					IF @Consignee IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							'' Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							VCC.Nombre ConsigneeName
						FROM
							GuiasHouse GH WITH (NOLOCK)
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN #idsCatalogos CATEST ON CATEST.id =  GHD.estadoPieza
							INNER JOIN ProgramacionCarrier PC  WITH (NOLOCK) ON 
												PC.idGuiaHouseDetalle =  GHD.id 
												AND PC.fechaDespacho = @FechaDespacho
												AND PC.idCarrier = @IdCarrier
						
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE 
							 GH.house IS NOT NULL 
							AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@ConsigneeName IS NULL 
								OR VCC.Nombre LIKE @ConsigneeName+'%')							
							AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
							AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GH.house LIKE @House+'%')
							AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
					END
				
					/* CLIENTES CONSOLIDADORES */
					IF @Consolidador IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							'' Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							VCC.Nombre ConsigneeName
						FROM
							GuiasHouse GH1 WITH (NOLOCK)
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN #idsCatalogos CATEST ON CATEST.id =  GHD.estadoPieza
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
											PC.idGuiaHouseDetalle =  GHD.id
											AND PC.fechaDespacho = @FechaDespacho
											AND  PC.idCarrier = @IdCarrier
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE 
							GH1.house IS NULL 
							AND GH1.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@ConsigneeName IS NULL 
								OR VCC.Nombre LIKE @ConsigneeName+'%')
							AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
							AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GH.house LIKE @House+'%')
							AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
					END
				END
				ELSE

				BEGIN
					IF @IdNotificacion IS NULL
					BEGIN
						/* CLIENTES FINALES */
						IF @Final IS NOT NULL 
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoIn AltoInch,
								GHD.AnchoIn AnchoInch,
								GHD.LargoIn LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.idCatalogoAccion IdAccion,
								GHD.NoPermitirVenta,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.ConsigneeId,
								GH.idBodega,
								PC.id IdProgramacionCarrier,
								PC.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								'' Chofer,
								GH.IdEmpresa,
								PMC.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
                                VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH  WITH (NOLOCK)
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @IdParametroLista
							WHERE 
								 GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
								AND CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR VCC.Nombre LIKE @ConsigneeName+'%')
								AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
								AND( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
						END

						 /* CLIENTES CONSIGNEE */
						IF @Consignee IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoIn AltoInch,
								GHD.AnchoIn AnchoInch,
								GHD.LargoIn LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.idCatalogoAccion IdAccion,
								GHD.NoPermitirVenta,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.ConsigneeId,
								GH.idBodega,
								PC.id IdProgramacionCarrier,
								PC.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								'' Chofer,
								GH.IdEmpresa,
								PMC.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
                                VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC  WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id 
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @IdParametroLista
							WHERE 
								 GH.house IS NOT NULL 
								AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR VCC.Nombre LIKE @ConsigneeName+'%')
								AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
						END
				
						/* CLIENTES CONSOLIDADORES */
						IF @Consolidador IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
								GHD.AltoCm,
								GHD.AnchoCm,
								GHD.LargoCm,
								GHD.AltoIn AltoInch,
								GHD.AnchoIn AnchoInch,
								GHD.LargoIn LargoInch,
								GHD.Nota,
								GHD.EstadoPieza,
								GHD.FechaCreacion,
								GHD.FechaCambio,
								GHD.TotalTallos,
								GHD.PrecioTallo,
								GHD.Peso,
								GHD.Po,
								GHD.RecepcionEscaner,
								GHD.TruckId,
								GHD.idCatalogoAccion IdAccion,
								GHD.NoPermitirVenta,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.ConsigneeId,
								GH.idBodega,
								PC.id IdProgramacionCarrier,
								PC.FechaDespacho, 
								GHD.RecibidoOrigen,
								GHD.RecibidoDestino,
								GHD.DespachadoDestino,
								'' Chofer,
								GH.IdEmpresa,
								PMC.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @IdParametroLista
							WHERE 
								GH1.house IS NULL 
								AND GH1.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @IdGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @IdGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
								AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
								AND (@ConsigneeName IS NULL 
									OR VCC.Nombre LIKE @ConsigneeName+'%')
								AND ( GH.idGuia = ISNULL(@IdGuia,  GH.idGuia))
								AND( GH.idExportador = ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
						END
					END
					ELSE
					BEGIN
						SELECT 
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoIn AltoInch,
							GHD.AnchoIn AnchoInch,
							GHD.LargoIn LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.idCatalogoAccion IdAccion,
							GHD.NoPermitirVenta,
							GH.NroGuia,
							GH.House,
							GH.FechaOrigen,
							GH.FechaDestino,
							CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.ConsigneeId,
							GH.idBodega,
							PC.id IdProgramacionCarrier,
							PC.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							'' Chofer,
							GH.IdEmpresa,
							PMC.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
                            VCC.Nombre ConsigneeName,
							GH1.ConsigneeId  idClienteConsolidador,
							GH.idGuia
						INTO  #tempNotificaciones
						FROM
							NotificacionPiezasDetalle NTP WITH (NOLOCK) 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON NTP.idGuiaHouseDetalle =  GHD.id
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
							INNER JOIN GuiasHouse GH1 WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia AND GH1.house IS NULL
                            INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
							INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
							LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @IdParametroLista
						WHERE 
							NTP.idNotificacionPiezas = @IdNotificacion

						INSERT INTO #TempPiezasPorCarrier
						SELECT 
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.DescripcionProducto,
							GHD.FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoInch,
							GHD.AnchoInch,
							GHD.LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.IdAccion,
							GHD.NoPermitirVenta,
							GHD.NroGuia,
							GHD.House,
							GHD.FechaOrigen,
							GHD.FechaDestino,
							GHD.FechaOrigenFecha,
							GHD.FechaDestinoFecha,
							GHD.IdExportador,
							GHD.ConsigneeId,
							GHD.idBodega,
							GHD.IdProgramacionCarrier,
							GHD.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							GHD.Chofer,
							GHD.IdEmpresa,
							GHD.valor,
							GHD.nombreComercial,
							GHD.nombre,
							GHD.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GHD.ConsigneeName
						FROM
							#tempNotificaciones GHD
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
						WHERE 
							( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
							AND (@ConsigneeName IS NULL 
								OR  GHD.ConsigneeName LIKE @ConsigneeName+'%')
							AND ( GHD.idGuia = ISNULL(@IdGuia,  GHD.idGuia))
							AND ( GHD.idExportador = ISNULL(@SupplierId,  GHD.idExportador))
							AND (@SupplierName IS NULL OR  GHD.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GHD.house LIKE @House+'%')
						UNION
						SELECT 
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.DescripcionProducto,
							GHD.FechaRecepcion,
							GHD.AltoCm,
							GHD.AnchoCm,
							GHD.LargoCm,
							GHD.AltoInch,
							GHD.AnchoInch,
							GHD.LargoInch,
							GHD.Nota,
							GHD.EstadoPieza,
							GHD.FechaCreacion,
							GHD.FechaCambio,
							GHD.TotalTallos,
							GHD.PrecioTallo,
							GHD.Peso,
							GHD.Po,
							GHD.RecepcionEscaner,
							GHD.TruckId,
							GHD.IdAccion,
							GHD.NoPermitirVenta,
							GHD.NroGuia,
							GHD.House,
							GHD.FechaOrigen,
							GHD.FechaDestino,
							GHD.FechaOrigenFecha,
							GHD.FechaDestinoFecha,
							GHD.IdExportador,
							GHD.ConsigneeId,
							GHD.idBodega,
							GHD.IdProgramacionCarrier,
							GHD.FechaDespacho, 
							GHD.RecibidoOrigen,
							GHD.RecibidoDestino,
							GHD.DespachadoDestino,
							GHD.Chofer,
							GHD.IdEmpresa,
							GHD.valor,
							GHD.nombreComercial,
							GHD.nombre,
							GHD.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GHD.ConsigneeName
						FROM
							#tempNotificaciones GHD
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ConsigneeId
						WHERE 
							( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
							AND (@ConsigneeName IS NULL 
								OR  GHD.ConsigneeName LIKE @ConsigneeName+'%')
							AND ( GHD.idGuia = ISNULL(@IdGuia,  GHD.idGuia))
							AND ( GHD.idExportador = ISNULL(@SupplierId,  GHD.idExportador))
							AND (@SupplierName IS NULL OR  GHD.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GHD.house LIKE @House+'%')
						UNION
						SELECT 
							 GHD.id,
							 GHD.idGuiaHouse, 
							 GHD.CodigoBarra,
							 GHD.DescripcionProducto,
							 GHD.FechaRecepcion,
							 GHD.AltoCm,
							 GHD.AnchoCm,
							 GHD.LargoCm,
							 GHD.AltoInch,
							 GHD.AnchoInch,
							 GHD.LargoInch,
							 GHD.Nota,
							 GHD.EstadoPieza,
							 GHD.FechaCreacion,
							 GHD.FechaCambio,
							 GHD.TotalTallos,
							 GHD.PrecioTallo,
							 GHD.Peso,
							 GHD.Po,
							 GHD.RecepcionEscaner,
							 GHD.TruckId,
							 GHD.IdAccion,
							 GHD.NoPermitirVenta,
							 GHD.NroGuia,
							 GHD.House,
							 GHD.FechaOrigen,
							 GHD.FechaDestino,
							 GHD.FechaOrigenFecha,
							 GHD.FechaDestinoFecha,
							 GHD.IdExportador,
							 GHD.ConsigneeId,
							 GHD.idBodega,
							 GHD.IdProgramacionCarrier,
							 GHD.FechaDespacho, 
							 GHD.RecibidoOrigen,
							 GHD.RecibidoDestino,
							 GHD.DespachadoDestino,
							 GHD.Chofer,
							 GHD.IdEmpresa,
							 GHD.valor,
							 GHD.nombreComercial,
							 GHD.nombre,
							 GHD.razonSocial,
							 GHD.idTipoDePieza,
							 GHD.ShipToId,
							 GHD.idUsuarioLog,
							 GHD.idPoDetalle,
							 GHD.idDetalleMercancia,
							 GHD.ConsigneeName
						FROM
							#tempNotificaciones GHD
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.idClienteConsolidador
						WHERE 
							( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
							AND CASE
								WHEN @IdGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @IdGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE @CodBarra+'%')
							AND (@NroPo IS NULL OR  GHD.po LIKE @NroPo+'%')
							AND (@ConsigneeName IS NULL 
								OR  GHD.ConsigneeName LIKE @ConsigneeName+'%')
							AND ( GHD.idGuia = ISNULL(@IdGuia,  GHD.idGuia))
							AND( GHD.idExportador = ISNULL(@SupplierId,  GHD.idExportador))
							AND (@SupplierName IS NULL OR  GHD.nombreComercial LIKE @SupplierName+'%')
							AND (@House IS NULL OR  GHD.house LIKE @House+'%')
					END
					SELECT DISTINCT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoInch,
						GHD.AnchoInch,
						GHD.LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
                        VCS.Id ShipToId,
                        VCS.Nombre ShipToName,
						U.nombre Nombre,
						GHD.NroGuia,
						GHD.House,
						GHD.FechaOrigen,
						GHD.FechaDestino,
						GHD.fechaOrigen FechaOrigenFecha,
						GHD.fechaDestino FechaDestinoFecha,
						GHD.IdExportador,
						GHD.nombreComercial NombreComercialExportador,
						GHD.nombre NombreExportador,
						GHD.razonSocial RazonSocialExportador,
						GHD.ConsigneeId,
						GHD.ConsigneeName,
						ISNULL(ubicacionesBodega.idBodega, GHD.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GHD.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						GHD.IdEmpresa,
						POD.farmName FarmName 
					FROM 
						#TempPiezasPorCarrier GHD 
						LEFT JOIN Exportadores EX WITH (NOLOCK) ON  GHD.idExportador = EX.id
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
                        INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						LEFT JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
						LEFT JOIN PoDetalles POD ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas PIN
            				LEFT JOIN ChequeoInventario checkInv ON PIN.IdChequeoInventario = checkInv.id 
          					WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          					ORDER BY PIN.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GHD.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id 
						OUTER APPLY (
          					SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud, SVC.tipoVenta, SVD.tipoPieza
          					FROM SolicitudDeVentaDetalles SVD 
            				LEFT JOIN SolicitudDeVenta SVC ON SVD.idSolicitud = SVC.id 
          					WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          					ORDER BY SVC.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.IdAccion = CAT.Id 
					WHERE
						(
							@Estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE @NroManifiesto+'%')
						AND CASE
							WHEN @SinManifiesto = 0 THEN 1
							WHEN @SinManifiesto = 1 AND MD.ID IS NULL THEN 1
							ELSE 0 END = 1
						AND CASE
							WHEN @IdManifiesto IS NULL THEN 1
							WHEN MD.id = @IdManifiesto THEN 1
							ELSE 0 END = 1
						AND (@PalletLabel IS NULL OR P.pallet LIKE @PalletLabel+'%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE @Orden+'%')
						AND CASE 
							WHEN @ShipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega,  GHD.idBodega) = @IdBodega THEN 1
							ELSE 0 END = 1
						AND CASE 
								WHEN @EsInventario IS NULL THEN 1
								WHEN @EsInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1
				END
			END
--aqui				
					SELECT DISTINCT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoInch,
						GHD.AnchoInch,
						GHD.LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
						VCS.Id ShipToId,
						VCS.Nombre ShipToName,
						U.nombre Nombre,
						GHD.NroGuia,
						GHD.House,
						GHD.FechaOrigen,
						GHD.FechaDestino,
						GHD.fechaOrigen FechaOrigenFecha,
						GHD.fechaDestino FechaDestinoFecha,
						GHD.IdExportador,
						GHD.nombreComercial NombreComercialExportador,
						GHD.nombre NombreExportador,
						GHD.razonSocial RazonSocialExportador,
						GHD.ConsigneeId,
						GHD.ConsigneeName,
						ISNULL(ubicacionesBodega.idBodega, GHD.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GHD.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						GHD.IdEmpresa,
						POD.farmName FarmName 
			FROM  #TempPiezasPorCarrier GHD 
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
						INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						LEFT JOIN Exportadores EX WITH (NOLOCK) ON  GHD.idExportador = EX.id
						LEFT JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
				LEFT JOIN PoDetalles POD WITH (NOLOCK) ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas PIN WITH (NOLOCK)
            				LEFT JOIN ChequeoInventario checkInv WITH (NOLOCK) ON PIN.IdChequeoInventario = checkInv.id 
          					WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          					ORDER BY PIN.fechaCambio DESC
				) AS chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GHD.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id 
						OUTER APPLY (
          					SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud, SVC.tipoVenta, SVD.tipoPieza
          					FROM SolicitudDeVentaDetalles SVD WITH (NOLOCK) 
            				LEFT JOIN SolicitudDeVenta SVC WITH (NOLOCK) ON SVD.idSolicitud = SVC.id 
          					WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          					ORDER BY SVC.fechaSolicitud DESC
				) AS SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.IdAccion = CAT.Id 
					WHERE
				(@Estado IS NULL OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos))
				AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE @NroManifiesto+'%')
						AND CASE
							WHEN @SinManifiesto = 0 THEN 1
							WHEN @SinManifiesto = 1 AND MD.ID IS NULL THEN 1
							ELSE 0 END = 1
						AND CASE
							WHEN @IdManifiesto IS NULL THEN 1
							WHEN MD.id = @IdManifiesto THEN 1
							ELSE 0 END = 1
						AND (@PalletLabel IS NULL OR P.pallet LIKE @PalletLabel+'%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE @Orden+'%')
						AND CASE 
					WHEN @ShipToName IS NULL THEN 1
					WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
					WHEN @IdBodega IS NULL THEN 1
					WHEN ISNULL(ubicacionesBodega.idBodega, GHD.idBodega) = @IdBodega THEN 1
							ELSE 0 END = 1
						AND CASE 
								WHEN @EsInventario IS NULL THEN 1
								WHEN @EsInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1
		END
		ELSE 
		BEGIN
		
			IF  @TipoCliente ='FINAL'
			BEGIN
				IF @IdCarrier IS NOT NULL
				BEGIN 
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoIn AltoInch,
						GHD.AnchoIn AnchoInch,
						GHD.LargoIn LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.idCatalogoAccion IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
                        VCS.Id ShipToId,
                        VCS.Nombre ShipToName,
						U.nombre Nombre,
						GH.NroGuia,
						GH.House,
						GH.FechaOrigen,
						GH.FechaDestino,
						GH.FechaOrigenFecha,
						GH.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.ConsigneeId ,
						GH.ConsigneeName ,
						ISNULL(ubicacionesBodega.idBodega, GH.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GH.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						POD.farmName FarmName
					FROM 
						(
							SELECT
								GH.id,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.idBodega,
								GH.IdEmpresa,
								GH.ConsigneeId,
								GH.idGuia,
                                VCC.Nombre ConsigneeName,
								PMC.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @IdParametroLista
							WHERE
								 GH.idGuia = @IdGuia
								AND ( GH.idExportador =  ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
								AND CASE 
									WHEN @ConsigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @ConsigneeName+'%' THEN 1
									ELSE 0 END = 1
						
						) GH 
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GHD.ShipToId
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
                        INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
						INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON
															 GHD.id = PC.idGuiaHouseDetalle 
															AND PC.idCarrier = @IdCarrier
															AND PC.fechaDespacho = @FechaDespacho
						LEFT JOIN PoDetalles POD ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas PIN
            				LEFT JOIN ChequeoInventario checkInv ON PIN.IdChequeoInventario = checkInv.id 
          				  WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY PIN.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
						OUTER APPLY (
          				  SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud, SVC.tipoVenta, SVD.tipoPieza
          				  FROM SolicitudDeVentaDetalles SVD 
            				LEFT JOIN SolicitudDeVenta SVC ON SVD.idSolicitud = SVC.id 
          				  WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          				  ORDER BY SVC.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.idCatalogoAccion = CAT.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
						AND(
							@Estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@EsPOD IS NULL OR  GHD.esPOD = @RealEsPOD)
						AND CASE 
							WHEN @EsVendida IS NULL OR @RealEsVendida = 0  THEN 1
							WHEN SV.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @CodBarra + '%')
						AND (@NroPo IS NULL OR  GHD.po LIKE '%' + @NroPo + '%')
				
						AND CASE 
							WHEN @ShipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @NroManifiesto + '%')
						AND (@PalletLabel IS NULL OR P.pallet LIKE '%' + @PalletLabel + '%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE '%' + @Orden + '%')
						AND CASE 
								WHEN @EsInventario IS NULL THEN 1
								WHEN @EsInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1
				END
				ELSE
				BEGIN
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoIn AltoInch,
						GHD.AnchoIn AnchoInch,
						GHD.LargoIn LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.idCatalogoAccion IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
                        VCS.Id ShipToId,
                        VCS.Nombre ShipToName,
						U.nombre Nombre,
						GH.NroGuia,
						GH.House,
						GH.FechaOrigen,
						GH.FechaDestino,
						GH.FechaOrigenFecha,
						GH.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.ConsigneeId ,
						GH.ConsigneeName ,
						ISNULL(ubicacionesBodega.idBodega, GH.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GH.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						POD.farmName FarmName
					FROM 
						(
							SELECT
								GH.id,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.idBodega,
								GH.IdEmpresa,
								GH.ConsigneeId,
								GH.idGuia,
                                VCC.Nombre ConsigneeName,
								PMC.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @IdParametroLista
							WHERE
								 GH.idGuia = @IdGuia
								AND ( GH.idExportador =  ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
								AND CASE  
									WHEN @ConsigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @ConsigneeName+'%' THEN 1
									ELSE 0 END = 1
						
						) GH 
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GHD.ShipToId
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
                        INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
						LEFT JOIN PoDetalles POD ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas PIN
            				LEFT JOIN ChequeoInventario checkInv ON PIN.IdChequeoInventario = checkInv.id 
          				  WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY PIN.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
						OUTER APPLY (
          				  SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles SVD 
            				LEFT JOIN SolicitudDeVenta SVC ON SVD.idSolicitud = SVC.id 
       				  WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          				  ORDER BY SVC.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.idCatalogoAccion = CAT.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
						AND(
							@Estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@EsPOD IS NULL OR  GHD.esPOD = @RealEsPOD)
						AND CASE 
							WHEN @EsVendida IS NULL OR @RealEsVendida = 0  THEN 1
							WHEN SV.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @CodBarra + '%')
						AND (@NroPo IS NULL OR  GHD.po LIKE '%' + @NroPo + '%')
						AND CASE 
							WHEN @ShipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @NroManifiesto + '%')
						AND (@PalletLabel IS NULL OR P.pallet LIKE '%' + @PalletLabel + '%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE '%' + @Orden + '%')
						AND (@EsInventario IS NULL OR ISNULL(ubicacionesBodega.areaInventario, 0) =  @EsInventario)
				END

			END
			ELSE IF  @TipoCliente ='CONSIGNEE'
			BEGIN
				IF @IdCarrier IS NOT NULL
				BEGIN
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoIn AltoInch,
						GHD.AnchoIn AnchoInch,
						GHD.LargoIn LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.idCatalogoAccion IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
                        VCS.Id ShipToId,
                        VCS.Nombre ShipToName,
						U.nombre Nombre,
						GH.NroGuia,
						GH.House,
						GH.FechaOrigen,
						GH.FechaDestino,
						GH.FechaOrigenFecha,
						GH.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.ConsigneeId ,
						GH.ConsigneeName ,
						ISNULL(ubicacionesBodega.idBodega, GH.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GH.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						HL.HeaderLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						POD.farmName FarmName
					FROM 
						(
							SELECT
								GH.id,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.idBodega,
								GH.IdEmpresa,
								GH.ConsigneeId,
								GH.idGuia,
                                VCC.Nombre ConsigneeName,
								PMC.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GH.ConsigneeId
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @IdParametroLista
							WHERE
								 GH.idGuia = @IdGuia
								AND ( GH.idExportador =  ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
								AND CASE 
									WHEN @ConsigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @ConsigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
                        INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
						INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
													 GHD.id = PC.idGuiaHouseDetalle 
													AND PC.idCarrier = @IdCarrier
													AND PC.fechaDespacho = @FechaDespacho 
						LEFT JOIN PoDetalles POD ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas PIN
            				LEFT JOIN ChequeoInventario checkInv ON PIN.IdChequeoInventario = checkInv.id 
          				  WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY PIN.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles SVD 
            				LEFT JOIN SolicitudDeVenta SVC ON SVD.idSolicitud = SVC.id 
          				  WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          				  ORDER BY SVC.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id 
						LEFT JOIN HeaderLabels HL WITH (NOLOCK) ON  GHD.idHeaderLabel = HL.id 
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.idCatalogoAccion = CAT.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId ))
						AND (
							@Estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@EsPOD IS NULL OR  GHD.esPOD = @RealEsPOD)
					
						AND CASE 
							WHEN @EsVendida IS NULL OR @RealEsVendida = 0  THEN 1
							WHEN SV.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @CodBarra + '%')
						AND (@NroPo IS NULL OR  GHD.po LIKE '%' + @NroPo + '%')
				
						AND CASE 
							WHEN @ShipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @NroManifiesto + '%')
						AND (@PalletLabel IS NULL OR P.pallet LIKE '%' + @PalletLabel + '%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE '%' + @Orden + '%')
						AND (@EsInventario IS NULL OR ISNULL(ubicacionesBodega.areaInventario, 0) = @EsInventario)
				END
				ELSE
				BEGIN
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoIn AltoInch,
						GHD.AnchoIn AnchoInch,
						GHD.LargoIn LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.idCatalogoAccion IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
                        VCS.Id ShipToId,
                        VCS.Nombre ShipToName,
						U.nombre Nombre,
						GH.NroGuia,
						GH.House,
						GH.FechaOrigen,
						GH.FechaDestino,
						GH.FechaOrigenFecha,
						GH.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.ConsigneeId ,
						GH.ConsigneeName ,
						ISNULL(ubicacionesBodega.idBodega, GH.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GH.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						POD.farmName FarmName
					FROM 
						(
							SELECT
								GH.id,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.idBodega,
								GH.IdEmpresa,
								GH.ConsigneeId,
								GH.idGuia,
                                VCC.Nombre ConsigneeName,
								PMC.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GH.ConsigneeId
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @IdParametroLista
							WHERE
								-- GH.FechaDestino BETWEEN  @FechaDesde AND @FechaHasta  
								--AND 
								 GH.idGuia = @IdGuia
								AND ( GH.idExportador =  ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
								AND CASE 
									WHEN @ConsigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @ConsigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
                        INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
						LEFT JOIN PoDetalles POD ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas PIN
            				LEFT JOIN ChequeoInventario checkInv ON PIN.IdChequeoInventario = checkInv.id 
          				  WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY PIN.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles SVD 
            				LEFT JOIN SolicitudDeVenta SVC ON SVD.idSolicitud = SVC.id 
          				  WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          				  ORDER BY SVC.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.idCatalogoAccion = CAT.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
						AND (
							@Estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@EsPOD IS NULL OR  GHD.esPOD = @RealEsPOD)
						AND CASE 
							WHEN @EsVendida IS NULL OR @RealEsVendida = 0  THEN 1
							WHEN SV.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @CodBarra + '%')
						AND (@NroPo IS NULL OR  GHD.po LIKE '%' + @NroPo + '%')
				
						AND CASE 
							WHEN @ShipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @NroManifiesto + '%')
						AND (@PalletLabel IS NULL OR P.pallet LIKE '%' + @PalletLabel + '%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE '%' + @Orden + '%')
						AND (@EsInventario IS NULL OR ISNULL(ubicacionesBodega.areaInventario, 0) = @EsInventario)
				END
			
			END
			ELSE IF  @TipoCliente ='CONSOLIDADO'
			BEGIN
				IF @IdCarrier IS NOT NULL 
				BEGIN 
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoIn AltoInch,
						GHD.AnchoIn AnchoInch,
						GHD.LargoIn LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.idCatalogoAccion IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
                        VCS.Id ShipToId,
                        VCS.Nombre ShipToName,
						U.nombre Nombre,
						GH.NroGuia,
						GH.House,
						GH.FechaOrigen,
						GH.FechaDestino,
						GH.FechaOrigenFecha,
						GH.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.ConsigneeId ,
						GH.ConsigneeName ,
						ISNULL(ubicacionesBodega.idBodega, GH.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GH.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						POD.farmName FarmName
					FROM 
						(
							SELECT
								GH.id,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.idBodega,
								GH.IdEmpresa,
								GH.ConsigneeId,
								GH.idGuia,
                                VCC.Nombre ConsigneeName,
								PMC.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @IdParametroLista
							WHERE
								GH1.house IS NULL 
								-- AND GH1.FechaDestino BETWEEN @FechaDesde AND @FechaHasta  
								AND GH1.idGuia = @IdGuia
								AND ( GH.idExportador =  ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
								AND CASE 
									WHEN @ConsigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @ConsigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
																 GHD.id = PC.idGuiaHouseDetalle 
																AND PC.idCarrier = @IdCarrier
																AND PC.fechaDespacho = @FechaDespacho
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
                        INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
						LEFT JOIN PoDetalles POD ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas PIN
            				LEFT JOIN ChequeoInventario checkInv ON PIN.IdChequeoInventario = checkInv.id 
          				  WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY PIN.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud, SVC.tipoVenta, SVD.tipoPieza
          				  FROM SolicitudDeVentaDetalles SVD 
            				LEFT JOIN SolicitudDeVenta SVC ON SVD.idSolicitud = SVC.id 
          				  WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          				  ORDER BY SVC.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id 
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.idCatalogoAccion = CAT.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
						AND (
							@Estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@EsPOD IS NULL OR  GHD.esPOD = @RealEsPOD)
						AND CASE 
							WHEN @EsVendida IS NULL OR @RealEsVendida = 0  THEN 1
							WHEN SV.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @CodBarra + '%')
						AND (@NroPo IS NULL OR  GHD.po LIKE '%' + @NroPo + '%')
						AND CASE 
							WHEN @ShipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @NroManifiesto + '%')
						AND (@PalletLabel IS NULL OR P.pallet LIKE '%' + @PalletLabel + '%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE '%' + @Orden + '%')
						AND CASE 
								WHEN @EsInventario IS NULL THEN 1
								WHEN @EsInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1
				
				END
				ELSE
				BEGIN 
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @FechaSinHora) FechaRecepcion,
						GHD.AltoCm,
						GHD.AnchoCm,
						GHD.LargoCm,
						GHD.AltoIn AltoInch,
						GHD.AnchoIn AnchoInch,
						GHD.LargoIn LargoInch,
						GHD.Nota,
						GHD.EstadoPieza,
						GHD.FechaCreacion,
						GHD.FechaCambio,
						GHD.TotalTallos,
						GHD.PrecioTallo,
						GHD.Peso,
						GHD.Po,
						GHD.RecepcionEscaner,
						GHD.TruckId,
						GHD.idCatalogoAccion IdAccion,
						GHD.NoPermitirVenta,
						TP.id IdTipoPieza,
						TP.TipoPieza,
                        VCS.Id ShipToId,
                        VCS.Nombre ShipToName,
						U.nombre Nombre,
						GH.NroGuia,
						GH.House,
						GH.FechaOrigen,
						GH.FechaDestino,
						GH.FechaOrigenFecha,
						GH.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.ConsigneeId ,
						GH.ConsigneeName,
						ISNULL(ubicacionesBodega.idBodega, GH.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						GH.valor CodigoClienteInventario, 
						ED.Puerta, 
						'' Camion,
						ED.truckId NroDespacho,
						DM.nombre NombreProducto,
						DM.nombreIngles NombreInglesProducto,
						DM.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						UB.id IdUbicacion,
						UB.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						T.id IdCarrier,
						T.codigoMiami CodigoCarrier,
						T.nombre NombreCarrier,
						MD.NroManifiesto,
						SV.nroOrden Orden,
						SV.fechaSolicitud FechaOrden,
						P.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						MD.id IdManifiesto,
						'' Chofer,
						CAT.Nombre AccionNombre,
						CAT.NombreIngles AccionNombreIngles,
						 GH.IdEmpresa,
						POD.farmName FarmName
					FROM 
						(
							SELECT
								GH.id,
								GH.NroGuia,
								GH.House,
								GH.FechaOrigen,
								GH.FechaDestino,
								CONVERT(DATE,  GH.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE,  GH.fechaDestino) FechaDestinoFecha,
								GH.idBodega,
								GH.IdEmpresa,
								GH.ConsigneeId,
								GH.idGuia,
                                VCC.Nombre ConsigneeName,
								PMC.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
								INNER JOIN Exportadores EX WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos PMC WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @IdParametroLista
							WHERE
								GH1.house IS NULL 
								AND GH1.idGuia = @IdGuia
								AND ( GH.idExportador =  ISNULL(@SupplierId,  GH.idExportador))
								AND (@SupplierName IS NULL OR EX.nombreComercial LIKE @SupplierName+'%')
								AND (@House IS NULL OR  GH.house LIKE @House+'%')
								AND CASE 
									WHEN @ConsigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @ConsigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN TiposDePieza TP WITH (NOLOCK) ON  GHD.idTipoDePieza = TP.id
                        INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios U WITH (NOLOCK) ON  GHD.idUsuarioLog = U.id
						LEFT JOIN PoDetalles POD ON  GHD.idPoDetalle = POD.id
						LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON  GHD.id = DD.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
						LEFT JOIN DetalleMercancias DM WITH (NOLOCK) ON  GHD.idDetalleMercancia = DM.id
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON  GHD.id = UP.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 PIN.id, checkInv.estado, PIN.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas PIN
            				LEFT JOIN ChequeoInventario checkInv ON PIN.IdChequeoInventario = checkInv.id 
          				  WHERE PIN.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY PIN.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones UB WITH (NOLOCK) ON UP.idUbicacion = UB.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON UB.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id 
						LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PC.id = PM.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								SVC.nroOrden, SVC.fechaSolicitud, SVC.tipoVenta, SVD.tipoPieza
          				  FROM SolicitudDeVentaDetalles SVD 
            				LEFT JOIN SolicitudDeVenta SVC ON SVD.idSolicitud = SVC.id 
          				  WHERE  GHD.id = SVD.idGuiaHouseDetalle 
          				  ORDER BY SVC.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles PD WITH (NOLOCK) ON  GHD.id = PD.idGuiasHouseDetalle
						LEFT JOIN Pallets P WITH (NOLOCK) ON PD.idPallet = P.id 
						LEFT JOIN Catalogos CAT WITH (NOLOCK) ON  GHD.idCatalogoAccion = CAT.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@ShipToId,  GHD.ShipToId))
						AND (
							@Estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@EsPOD IS NULL OR  GHD.esPOD = @RealEsPOD)
						AND CASE 
							WHEN @EsVendida IS NULL OR @RealEsVendida = 0  THEN 1
							WHEN SV.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@CodBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @CodBarra + '%')
						AND (@NroPo IS NULL OR  GHD.po LIKE '%' + @NroPo + '%')
						AND CASE 
							WHEN @ShipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @ShipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@NroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @NroManifiesto + '%')
						AND (@PalletLabel IS NULL OR P.pallet LIKE '%' + @PalletLabel + '%')
						AND (@Orden IS NULL OR SV.nroOrden LIKE '%' + @Orden + '%')
						AND CASE 
								WHEN @EsInventario IS NULL THEN 1
								WHEN @EsInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @EsInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @EsInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1
				END

			END
	
		END
	END TRY
	BEGIN CATCH			
		EXEC [dbo].[pro_LogError] 
	END CATCH;	
END
/*

exec dbo.AC_pro_GetBarCodeExternal 
	@fechaDesde='20210713',
	@fechaHasta='20260714',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>  <ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">    <string>PENDING</string>  </ArrayOfString>',
	@idCarrier=N'9Nlyxt0q6dGE',
	@idBodega=N'LXgyot5M',
	@fechaDespacho='20260413',
	@isDispatchCarrier=0,
	@esInventario=0,
	@EntityId=N'CLI013680',
	@shipToId=N'ETY011729',
	@UserType=N'GRUPOCLIENTE'

exec dbo.AC_pro_GetBarCodeExternal 
	@fechaDesde='20220101',
	@fechaHasta='20260423',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>  <ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">    <string>PENDING</string>   <string>RECEIVED WH</string> </ArrayOfString>',
	@isDispatchCarrier=0,
	@EntityId=N'CLI013680',
	@consigneeName=N'BOTANICA WHOLESALE HOUSTON',
	@consigneeId=N'ETY011765',
	@UserType=N'GRUPOCLIENTE'

*/