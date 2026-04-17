/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Fernando Ordoñez	2026-04-09		  57725			 Initial code based on pro_ConsultarCodigoBarrasClientes
*/
ALTER   PROCEDURE [dbo].[AC_pro_GetBarCodeExternal]
(
	@fechaDesde			DATETIME,
	@fechaHasta			DATETIME,
	@house				VARCHAR(32) = NULL,
	@nroPo				VARCHAR(32) = NULL,
	@codBarra			VARCHAR(32) = NULL,
	@estado				XML = NULL,
	@orden				VARCHAR(16) = NULL, 
	@nroManifiesto		VARCHAR(16) = NULL,
	@palletLabel		VARCHAR(32) = NULL,
	@idGuia				VARCHAR(64) = NULL,
	@tipoCliente		VARCHAR(64) = NULL,	
	@esPOD				BIT = NULL,
	@esVendida			BIT = NULL,
	@idCarrier			VARCHAR(16) = NULL,
	@idBodega			VARCHAR(16) = NULL,
	@fechaDespacho		DATETIME = NULL,
	@truckId			VARCHAR(16)= NULL,
	@idManifiesto		UNIQUEIDENTIFIER= NULL,
	@idGuiaHouse		UNIQUEIDENTIFIER= NULL,
	@isDispatchCarrier	BIT = NULL,
	@idNotificacion		UNIQUEIDENTIFIER= NULL,
	@esInventario		BIT = NULL,
	--nombre cliente distribuion ya no se usa
	----=======Filtros de Entities==========
	@EntityId			VARCHAR(16), -- idcliente
	@supplierName		VARCHAR(512) = NULL,
	@supplierId			VARCHAR(16) = NULL,
	@consigneeName		VARCHAR(512) = NULL, --nuevo
	@consigneeId		VARCHAR(16) = NULL, --nuevo
	@shipToName			VARCHAR(512) = NULL,
	@shipToId			VARCHAR(16) = NULL,
	@billToName			VARCHAR(512) = NULL, --nuevo
	@billToId			VARCHAR(16) = NULL, --nuevo
	@UserType           VARCHAR(32) = NULL
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @idParametroLista VARCHAR(16),
				@idEmpresa VARCHAR(16) = NULL,
				@realEsPOD BIT,
				@realEsVendida BIT,
				@Final VARCHAR (16) = NULL,
				@Consignee VARCHAR (16) = NULL,
				@Consolidador VARCHAR (16) = NULL,
				@fechaSinHora DATE,
				@sinManifiesto BIT = 0

		
		SELECT @realEsPOD = CAST(ISNULL(@esPOD,0) AS BIT),
				@realEsVendida = CAST(ISNULL(@esVendida,0)AS BIT),
				@fechaSinHora = CONVERT(DATE, GETDATE())
			
		IF (@isDispatchCarrier IS  NULL OR @isDispatchCarrier = 0 ) AND @idManifiesto IS NULL
		BEGIN 
			SELECT  @sinManifiesto = 1
		END

		IF @idCarrier IS NULL AND @fechaDespacho IS NULL AND @idManifiesto IS NULL
		BEGIN
			SELECT @sinManifiesto = 0
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
			ConsigneeId VARCHAR(16),
			ConsigneeName VARCHAR(512)
		);

		CREATE TABLE #TMP_RelatedClients (
        [Id]      VARCHAR(16),
        [IdCliente]     VARCHAR(16),
        [BillToConsigneeId] VARCHAR(16),
        [BilltoId]     VARCHAR(16),
        [ConsigneeId]     VARCHAR(16)
        )

		CREATE TABLE #idsCatalogos (
			id [VARCHAR](64)
		)

		SELECT  @idParametroLista = id 
		FROM ParametrosLista pl
		WHERE pl.codigo = 'TipoServicio'
			AND (@idEmpresa IS NULL OR pl.idEmpresa = @idEmpresa);

		IF(@estado IS NOT NULL)
		BEGIN
			INSERT INTO #idsCatalogos
			SELECT [Value] 
			FROM [dbo].fnObtenerValoresXML(@estado)
		END

		INSERT INTO #TMP_RelatedClients (Id,IdCliente, BillToConsigneeId,BilltoId,ConsigneeId)
        EXEC [dbo].[AC_pro_GetClientsEntities]
             @EntityId = @EntityId,
             @UserType = @UserType 
		
		IF @tipoCliente IS NULL
		BEGIN
			IF @fechaDespacho IS NOT NULL 
			BEGIN 
				SELECT 
					@fechaDesde =  DATEADD(DAY,-90,@fechaDespacho),
					@fechaHasta = @fechaDespacho
			END
			IF @estado IS NULL
			BEGIN
				IF @fechaDespacho IS NOT NULL AND @idCarrier IS NOT NULL
				BEGIN
					/* validacion  tipo de clientes*/
					SELECT TOP 1  @Consolidador = 'CONSOLIDADOR'
					FROM  GuiasHouse GH
						INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
					WHERE   GH.house IS NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1  @Consignee ='CONSIGNEE'
					FROM  GuiasHouse GH
						INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
					WHERE   GH.house IS NOT NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1  @Final = 'FINAL'
					FROM  GuiasHouseDetalles GHD
						INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GHD.ShipToId
					WHERE fechaCreacion BETWEEN @fechaDesde AND @FechaHasta
				
					/* CLIENTES FINALES */
					IF @Final IS NOT NULL 
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
							VCC.nombre ConsigneeName
						FROM ProgramacionCarrier pc  WITH (NOLOCK)
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON 
																 GHD.id = PC.idGuiaHouseDetalle 
																AND  GHD.fechaCreacion BETWEEN @fechaDesde AND @FechaHasta
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =   GHD.idGuiaHouse
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE  PC.fechaDespacho = @fechaDespacho
							AND PC.idCarrier = @idCarrier
							AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
							AND (@consigneeName IS NULL 
								OR VCC.nombre LIKE @consigneeName+'%')
							AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
							AND( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
							AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GH.house LIKE @house+'%')
				
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
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
							VCC.Nombre ConsigneeName
						FROM GuiasHouse GH WITH (NOLOCK)
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
												PC.idGuiaHouseDetalle =  GHD.id 
												AND PC.fechaDespacho = @fechaDespacho
												AND PC.idCarrier = @idCarrier
						
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE   GH.house IS NOT NULL 
							AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
							AND (@consigneeName IS NULL 
								OR VCC.Nombre LIKE @consigneeName+'%')
							AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
							AND( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
							AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GH.house LIKE @house+'%')
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
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
							VCC.Nombre ConsigneeName
						FROM GuiasHouse GH1 WITH (NOLOCK)
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
							INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = gh1.idGuia
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
											PC.idGuiaHouseDetalle =  GHD.id
											AND PC.fechaDespacho = @fechaDespacho
											AND  PC.idCarrier = @idCarrier
						
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE  GH1.house IS NULL 
							AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
							AND (@consigneeName IS NULL 
								OR VCC.Nombre LIKE @consigneeName+'%')
							AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
							AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GH.house LIKE @house+'%')
					END
				
					SELECT DISTINCT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						VCS.id ShipToId,
						VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GHD.IdEmpresa,
						pod.farmName FarmName 
					FROM  #TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON  GHD.idExportador = EX.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
						INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						LEFT JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          					ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GHD.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE  GHD.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.IdAccion = cat.Id 
					WHERE (@nroManifiesto IS NULL OR md.nroManifiesto LIKE @nroManifiesto+'%')
						AND CASE
							WHEN @sinManifiesto = 0 THEN 1
							WHEN @sinManifiesto = 1 AND MD.ID IS NULL THEN 1
							ELSE 0 END = 1
						AND CASE
							WHEN @idManifiesto IS NULL THEN 1
							WHEN MD.id = @idManifiesto THEN 1
							ELSE 0 END = 1
						AND (@palletLabel IS NULL OR p.pallet LIKE @palletLabel+'%')
						AND (@orden IS NULL OR sv.nroOrden LIKE @orden+'%')
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega,  GHD.idBodega) = @IdBodega THEN 1
							ELSE 0 END = 1
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN @esInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1				
				END
				ELSE
				BEGIN
					IF @idNotificacion IS NULL
					BEGIN
						/* validacion  tipo de clientes*/
						SELECT TOP 1  @Consolidador = 'CONSOLIDADOR'
						FROM  GuiasHouse GH
							INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
						WHERE   GH.house IS NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1  @Consignee ='CONSIGNEE'
						FROM  GuiasHouse GH
							INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
						WHERE  GH.house IS NOT NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1  @Final = 'FINAL'
						FROM  GuiasHouseDetalles GHD
							INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GHD.ShipToId
						WHERE  fechaCreacion BETWEEN @fechaDesde AND @FechaHasta

						/* CLIENTES FINALES */
						IF @Final IS NOT NULL 
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								pmc.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GH.ConsigneeId,
								VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH  WITH (NOLOCK)
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
								INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @idParametroLista
							WHERE 
								 GH.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR VCC.nombre LIKE @consigneeName+'%')
								AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
				
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
								ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								pmc.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GH.ConsigneeId,
								VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
								INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier pc  WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @idParametroLista
							WHERE 
								 GH.house IS NOT NULL 
								AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR VCC.nombre LIKE @consigneeName+'%')
								AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
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
								ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								pmc.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GH.ConsigneeId,
								VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = gh1.idGuia
								INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @idParametroLista
							WHERE 
								GH1.house IS NULL 
								AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR VCC.nombre LIKE @consigneeName+'%')
								AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
						END
					END
					ELSE
					BEGIN
					
						SELECT 
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
							VCC.nombre ConsigneeName
							-- ver que hace - OCUPA EN EL UNION
							GH1.ConsigneeId idClienteConsolidador,
							GH.idGuia
						INTO  #tempNotificacion
						FROM
							NotificacionPiezasDetalle ntpd WITH (NOLOCK) 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ntpd.idGuiaHouseDetalle =  GHD.id
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
							INNER JOIN GuiasHouse GH1 WITH (NOLOCK) ON  GH.idGuia = gh1.idGuia AND GH1.house IS NULL
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE 
							ntPD.idNotificacionPiezas = @idNotificacion

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
								GHD.ConsigneeId,
								GHD.ConsigneeName
							FROM
								#tempNotificacion GHD
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
							WHERE 
								CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR  GHD.ConsigneeName LIKE @consigneeName+'%')
								AND ( GHD.idGuia = ISNULL(@idGuia,  GHD.idGuia))
								AND( GHD.idExportador = ISNULL(@supplierId,  GHD.idExportador))
								AND (@supplierName IS NULL OR  GHD.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GHD.house LIKE @house+'%')
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
								GHD.ConsigneeId,
								GHD.ConsigneeName
							FROM
								#tempNotificacion GHD
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ConsigneeId
							WHERE 
								CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR  GHD.ConsigneeName LIKE @consigneeName+'%')
								AND ( GHD.idGuia = ISNULL(@idGuia,  GHD.idGuia))
								AND( GHD.idExportador = ISNULL(@supplierId,  GHD.idExportador))
								AND (@supplierName IS NULL OR  GHD.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GHD.house LIKE @house+'%')
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
								GHD.ConsigneeId,
								GHD.ConsigneeName
							FROM
								#tempNotificacion GHD
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.idClienteConsolidador
							WHERE 
								CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR  GHD.ConsigneeName LIKE @consigneeName+'%')
								AND ( GHD.idGuia = ISNULL(@idGuia,  GHD.idGuia))
								AND( GHD.idExportador = ISNULL(@supplierId,  GHD.idExportador))
								AND (@supplierName IS NULL OR  GHD.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GHD.house LIKE @house+'%')
					
					END

					SELECT DISTINCT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						VCS.Id ShipToId,
						VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GHD.IdEmpresa,
						pod.farmName FarmName 
					FROM 
						#TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON  GHD.idExportador = EX.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
						INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id 
						LEFT JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          					ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GHD.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE  GHD.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.IdAccion = cat.Id 
					WHERE
						(@nroManifiesto IS NULL OR md.nroManifiesto LIKE @nroManifiesto+'%')
						AND CASE
							WHEN @sinManifiesto = 0 THEN 1
							WHEN @sinManifiesto = 1 AND MD.ID IS NULL THEN 1
							ELSE 0 END = 1
						AND CASE
							WHEN @idManifiesto IS NULL THEN 1
							WHEN MD.id = @idManifiesto THEN 1
							ELSE 0 END = 1
						AND (@palletLabel IS NULL OR p.pallet LIKE @palletLabel+'%')
						AND (@orden IS NULL OR sv.nroOrden LIKE @orden+'%')
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega,  GHD.idBodega) = @IdBodega THEN 1
							ELSE 0 END = 1
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN @esInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1


				END

			
			END
			ELSE
			BEGIN 
				IF @fechaDespacho IS NOT NULL AND @idCarrier IS NOT NULL
				BEGIN
					/* validacion  tipo de clientes*/
					SELECT TOP 1 
						@Consolidador = 'CONSOLIDADOR'
					FROM 
						GuiasHouse GH
						INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
					WHERE 
						 GH.house IS NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1 
						@Consignee ='CONSIGNEE'
					FROM 
						GuiasHouse GH
						INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
					WHERE 
						 GH.house IS NOT NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1 
						@Final = 'FINAL'
					FROM 
						GuiasHouseDetalles GHD
						INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GHD.ShipToId
					WHERE 
						fechaCreacion BETWEEN @fechaDesde AND @FechaHasta


					/* CLIENTES FINALES */
					IF @Final IS NOT NULL 
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
							VCC.Nombre ConsigneeName
						FROM
							ProgramacionCarrier pc  WITH (NOLOCK)
							INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON 
																 GHD.id = PC.idGuiaHouseDetalle 
																AND  GHD.fechaCreacion BETWEEN @fechaDesde AND @FechaHasta
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
							INNER JOIN #idsCatalogos CATEST ON CATEST.id =  GHD.estadoPieza
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =   GHD.idGuiaHouse
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE 
							PC.fechaDespacho = @fechaDespacho
							AND PC.idCarrier = @idCarrier
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@consigneeName IS NULL 
								OR VCC.Nombre LIKE @consigneeName+'%')
							AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
							AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GH.house LIKE @house+'%')
							AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
				
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
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
							VCC.Nombre ConsigneeName
						FROM
							GuiasHouse GH WITH (NOLOCK)
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN #idsCatalogos CATEST ON CATEST.id =  GHD.estadoPieza
							INNER JOIN ProgramacionCarrier pc  WITH (NOLOCK) ON 
												PC.idGuiaHouseDetalle =  GHD.id 
												AND PC.fechaDespacho = @fechaDespacho
												AND PC.idCarrier = @idCarrier
						
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE 
							 GH.house IS NOT NULL 
							AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@consigneeName IS NULL 
								OR VCC.Nombre LIKE @consigneeName+'%')
							AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
							AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GH.house LIKE @house+'%')
							AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
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
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
							VCC.Nombre ConsigneeName
						FROM
							GuiasHouse GH1 WITH (NOLOCK)
							INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = gh1.idGuia
							INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
							INNER JOIN #idsCatalogos CATEST ON CATEST.id =  GHD.estadoPieza
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
											PC.idGuiaHouseDetalle =  GHD.id
											AND PC.fechaDespacho = @fechaDespacho
											AND  PC.idCarrier = @idCarrier
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE 
							GH1.house IS NULL 
							AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GH.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@consigneeName IS NULL 
								OR VCC.Nombre LIKE @consigneeName+'%')
							AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
							AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
							AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GH.house LIKE @house+'%')
							AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
					END
					--me quede aqui
				
					SELECT DISTINCT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						VCS.id ShipToId,
						VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GHD.IdEmpresa,
						pod.farmName FarmName 
					FROM 
						#TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON  GHD.idExportador = EX.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
						INNER JOIN v_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						LEFT JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          					ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GHD.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE  GHD.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.IdAccion = cat.Id 
					WHERE
						(@nroManifiesto IS NULL OR md.nroManifiesto LIKE @nroManifiesto+'%')
						AND CASE
							WHEN @sinManifiesto = 0 THEN 1
							WHEN @sinManifiesto = 1 AND MD.ID IS NULL THEN 1
							ELSE 0 END = 1
						AND CASE
							WHEN @idManifiesto IS NULL THEN 1
							WHEN MD.id = @idManifiesto THEN 1
							ELSE 0 END = 1
						AND (@palletLabel IS NULL OR p.pallet LIKE @palletLabel+'%')
						AND (@orden IS NULL OR sv.nroOrden LIKE @orden+'%')
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega,  GHD.idBodega) = @IdBodega THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN vcs.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN @esInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1
				
				END
				ELSE

				BEGIN
					IF @idNotificacion IS NULL
					BEGIN
						/* validacion  tipo de clientes*/
						SELECT TOP 1 
							@Consolidador = 'CONSOLIDADOR'
						FROM 
							GuiasHouse GH
							INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
						WHERE 
							 GH.house IS NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1 
							@Consignee ='CONSIGNEE'
						FROM 
							GuiasHouse GH
							INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GH.ConsigneeId
						WHERE 
							 GH.house IS NOT NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1 
							@Final = 'FINAL'
						FROM 
							GuiasHouseDetalles GHD
							INNER JOIN #TMP_RelatedClients CLI ON CLI.ConsigneeId =  GHD.ShipToId
						WHERE 
							fechaCreacion BETWEEN @fechaDesde AND @FechaHasta

						/* CLIENTES FINALES */
						IF @Final IS NOT NULL 
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								GHD.id,
								GHD.idGuiaHouse, 
								GHD.CodigoBarra,
								GHD.productoDescripcion DescripcionProducto,
								ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								pmc.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ShipToId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GH.ConsigneeId,
                                VCC.Nombre ConsigneeName
							FROM
								GuiasHouse GH  WITH (NOLOCK)
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
								INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @idParametroLista
							WHERE 
								 GH.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR VCC.Nombre LIKE @consigneeName+'%')
								AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
								AND( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
				
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
								ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								pmc.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.ConsigneeId,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GH.ConsigneeId,
                                VCC.Nombre ConsigneeName
							FROM
								dbo.GuiasHouse GH WITH (NOLOCK)
								INNER JOIN#TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId =  GH.ConsigneeId
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier pc  WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @idParametroLista
							WHERE 
								 GH.house IS NOT NULL 
								AND  GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR VCC.Nombre LIKE @consigneeName+'%')
								AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
								AND ( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
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
								ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								pmc.valor,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial,
								GHD.idTipoDePieza,
								GHD.idClienteFinal,
								GHD.idUsuarioLog,
								GHD.idPoDetalle,
								GHD.idDetalleMercancia,
								GH.ConsigneeId,
								VCC.Nombre nombreClienteConsigne
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLI WITH (NOLOCK) ON CLI.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.idGuia = gh1.idGuia
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												 GH.ConsigneeId = PMC.idEntidad 
												AND PMC.idParametroLista = @idParametroLista
							WHERE 
								GH1.house IS NULL 
								AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN  GH.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND ( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
								AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
								AND (@consigneeName IS NULL 
									OR VCC.Nombre LIKE @consigneeName+'%')
								AND ( GH.idGuia = ISNULL(@idGuia,  GH.idGuia))
								AND( GH.idExportador = ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
						END
					END
					ELSE
					BEGIN
						SELECT 
							GHD.id,
							GHD.idGuiaHouse, 
							GHD.CodigoBarra,
							GHD.productoDescripcion DescripcionProducto,
							ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							pmc.valor,
							EX.nombreComercial,
							EX.nombre,
							EX.razonSocial,
							GHD.idTipoDePieza,
							GHD.ShipToId,
							GHD.idUsuarioLog,
							GHD.idPoDetalle,
							GHD.idDetalleMercancia,
							GH.ConsigneeId,
                            vcc.Nombre ConsigneeName,
							GH1.idCliente  idClienteConsolidador,
							GH.idGuia
						INTO  #tempNotificaciones
						FROM
							NotificacionPiezasDetalle ntpd WITH (NOLOCK) 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ntpd.idGuiaHouseDetalle =  GHD.id
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id =  GHD.idGuiaHouse
							INNER JOIN GuiasHouse GH1 WITH (NOLOCK) ON  GH.idGuia = gh1.idGuia AND GH1.house IS NULL
                            INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
							INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
							LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PC.idGuiaHouseDetalle =  GHD.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											 GH.ConsigneeId = PMC.idEntidad 
											AND PMC.idParametroLista = @idParametroLista
						WHERE 
							ntPD.idNotificacionPiezas = @idNotificacion

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
							GHD.ConsigneeId,
							GHD.ConsigneeName
						FROM
							#tempNotificaciones GHD
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ShipToId
						WHERE 
							( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
							AND (@consigneeName IS NULL 
								OR  GHD.ConsigneeName LIKE @consigneeName+'%')
							AND ( GHD.idGuia = ISNULL(@idGuia,  GHD.idGuia))
							AND ( GHD.idExportador = ISNULL(@supplierId,  GHD.idExportador))
							AND (@supplierName IS NULL OR  GHD.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GHD.house LIKE @house+'%')
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
							GHD.ConsigneeId,
							GHD.ConsigneeName
						FROM
							#tempNotificaciones GHD
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.ConsigneeId
						WHERE 
							( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
							AND (@consigneeName IS NULL 
								OR  GHD.ConsigneeName LIKE @consigneeName+'%')
							AND ( GHD.idGuia = ISNULL(@idGuia,  GHD.idGuia))
							AND ( GHD.idExportador = ISNULL(@supplierId,  GHD.idExportador))
							AND (@supplierName IS NULL OR  GHD.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GHD.house LIKE @house+'%')
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
							 GHD.ConsigneeId,
							 GHD.ConsigneeName
						FROM
							#tempNotificaciones GHD
							INNER JOIN #TMP_RelatedClients CL ON CL.ConsigneeId =  GHD.idClienteConsolidador
						WHERE 
							( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN  GHD.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR  GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR  GHD.po LIKE @nroPo+'%')
							AND (@consigneeName IS NULL 
								OR  GHD.ConsigneeName LIKE @consigneeName+'%')
							AND ( GHD.idGuia = ISNULL(@idGuia,  GHD.idGuia))
							AND( GHD.idExportador = ISNULL(@supplierId,  GHD.idExportador))
							AND (@supplierName IS NULL OR  GHD.nombreComercial LIKE @supplierName+'%')
							AND (@house IS NULL OR  GHD.house LIKE @house+'%')
					END

					SELECT DISTINCT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
                        VCS.ID ShipToId,
                        VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GHD.IdEmpresa,
						pod.farmName FarmName 
					FROM 
						#TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON  GHD.idExportador = EX.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
                        INNER JOIN V_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						LEFT JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          					ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GHD.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE  GHD.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.IdAccion = cat.Id 
					WHERE
						(
							@estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE @nroManifiesto+'%')
						AND CASE
							WHEN @sinManifiesto = 0 THEN 1
							WHEN @sinManifiesto = 1 AND MD.ID IS NULL THEN 1
							ELSE 0 END = 1
						AND CASE
							WHEN @idManifiesto IS NULL THEN 1
							WHEN MD.id = @idManifiesto THEN 1
							ELSE 0 END = 1
						AND (@palletLabel IS NULL OR p.pallet LIKE @palletLabel+'%')
						AND (@orden IS NULL OR sv.nroOrden LIKE @orden+'%')
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega,  GHD.idBodega) = @IdBodega THEN 1
							ELSE 0 END = 1
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN @esInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
								ELSE 0 
							END  = 1

				END
			END
		END
		ELSE 
		BEGIN
		
			IF  @tipoCliente ='FINAL'
			BEGIN
				IF @idCarrier IS NOT NULL
				BEGIN 
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
                        VCS.ID ShipToId,
                        VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						pod.farmName FarmName
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
								pmc.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @idParametroLista
							WHERE
								 GH.idGuia = @idGuia
								AND ( GH.idExportador =  ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
								AND CASE 
									WHEN @consigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @consigneeName+'%' THEN 1
									ELSE 0 END = 1
						
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GHD.ShipToId
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
                        INNER JOIN V_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						INNER JOIN ProgramacionCarrier pc WITH (NOLOCK) ON
															 GHD.id = PC.idGuiaHouseDetalle 
															AND PC.idCarrier = @idCarrier
															AND PC.fechaDespacho = @fechaDespacho
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE  GHD.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.idCatalogoAccion = cat.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
						AND(
							@estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR  GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR  GHD.po LIKE '%' + @nroPo + '%')
				
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@palletLabel IS NULL OR p.pallet LIKE '%' + @palletLabel + '%')
						AND (@orden IS NULL OR sv.nroOrden LIKE '%' + @orden + '%')
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN @esInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
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
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
                        VCS.ID ShipToId,
                        VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						pod.farmName FarmName
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
								GH.idCliente,
								GH.idGuia,
                                VCC.Nombre ConsigneeName,
								pmc.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @idParametroLista
							WHERE
								 GH.idGuia = @idGuia
								AND ( GH.idExportador =  ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
								AND CASE  
									WHEN @consigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @consigneeName+'%' THEN 1
									ELSE 0 END = 1
						
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GHD.ShipToId
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
                        INNER JOIN V_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
       				  WHERE  GHD.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.idCatalogoAccion = cat.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
						AND(
							@estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR  GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR  GHD.po LIKE '%' + @nroPo + '%')
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@palletLabel IS NULL OR p.pallet LIKE '%' + @palletLabel + '%')
						AND (@orden IS NULL OR sv.nroOrden LIKE '%' + @orden + '%')
						AND (@esInventario IS NULL OR ISNULL(ubicacionesBodega.areaInventario, 0) =  @esInventario)
				END

			END
			ELSE IF  @tipoCliente ='CONSIGNEE'
			BEGIN
				IF @idCarrier IS NOT NULL
				BEGIN
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
                        VCS.ID ShipToId,
                        VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						hl.HeaderLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						pod.farmName FarmName
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
								pmc.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GH.ConsigneeId
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @idParametroLista
							WHERE
								 GH.idGuia = @idGuia
								AND ( GH.idExportador =  ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
								AND CASE 
									WHEN @consigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @consigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
                        INNER JOIN V_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						INNER JOIN ProgramacionCarrier pc WITH (NOLOCK) ON 
													 GHD.id = PC.idGuiaHouseDetalle 
													AND PC.idCarrier = @idCarrier
													AND PC.fechaDespacho = @fechaDespacho 
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE  GHD.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN HeaderLabels hl WITH (NOLOCK) ON  GHD.idHeaderLabel = hl.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.idCatalogoAccion = cat.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId ))
						AND (
							@estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR  GHD.esPOD = @realEsPOD)
					
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR  GHD.po LIKE '%' + @nroPo + '%')
				
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@palletLabel IS NULL OR p.pallet LIKE '%' + @palletLabel + '%')
						AND (@orden IS NULL OR sv.nroOrden LIKE '%' + @orden + '%')
						AND (@esInventario IS NULL OR ISNULL(ubicacionesBodega.areaInventario, 0) = @esInventario)
				END
				ELSE
				BEGIN
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
                        VCS.ID ShipToId,
                        VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						pod.farmName FarmName
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
								pmc.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId =  GH.ConsigneeId
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @idParametroLista
							WHERE
								-- GH.FechaDestino BETWEEN  @fechaDesde AND @fechaHasta  
								--AND 
								 GH.idGuia = @idGuia
								AND ( GH.idExportador =  ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
								AND CASE 
									WHEN @consigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @consigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
                        INNER JOIN V_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE  GHD.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.idCatalogoAccion = cat.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
						AND (
							@estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR  GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR  GHD.po LIKE '%' + @nroPo + '%')
				
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@palletLabel IS NULL OR p.pallet LIKE '%' + @palletLabel + '%')
						AND (@orden IS NULL OR sv.nroOrden LIKE '%' + @orden + '%')
						AND (@esInventario IS NULL OR ISNULL(ubicacionesBodega.areaInventario, 0) = @esInventario)
				END
			
			END
			ELSE IF  @tipoCliente ='CONSOLIDADO'
			BEGIN
				IF @idCarrier IS NOT NULL 
				BEGIN 
					SELECT
						GHD.id,
						GHD.idGuiaHouse, 
						GHD.CodigoBarra,
						GHD.productoDescripcion DescripcionProducto,
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
                        VCS.ID ShipToId,
                        VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						GH.IdEmpresa,
						pod.farmName FarmName
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
								pmc.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse gh1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse gh WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @idParametroLista
							WHERE
								GH1.house IS NULL 
								-- AND gh1.FechaDestino BETWEEN @fechaDesde AND @fechaHasta  
								AND gh1.idGuia = @idGuia
								AND ( GH.idExportador =  ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
								AND CASE 
									WHEN @consigneeName IS NULL THEN 1
									WHEN VCC.Nombre LIKE @consigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN ProgramacionCarrier pc WITH (NOLOCK) ON 
																 GHD.id = PC.idGuiaHouseDetalle 
																AND PC.idCarrier = @idCarrier
																AND PC.fechaDespacho = @fechaDespacho
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON  GHD.idClienteFinal = clf.id
						INNER JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE  GHD.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.idCatalogoAccion = cat.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
						AND (
							@estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR  GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR  GHD.po LIKE '%' + @nroPo + '%')
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@palletLabel IS NULL OR p.pallet LIKE '%' + @palletLabel + '%')
						AND (@orden IS NULL OR sv.nroOrden LIKE '%' + @orden + '%')
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN @esInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
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
						ISNULL( GHD.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
                        VCS.ID ShipToId,
                        VCS.Nombre ShipToName,
						u.nombre Nombre,
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
						ed.Puerta, 
						'' Camion,
						ed.truckId NroDespacho,
						dm.nombre NombreProducto,
						dm.nombreIngles NombreInglesProducto,
						dm.id IdDetalleMercancia,
						CASE 
							WHEN  chekInventario.id IS NOT NULL 
							THEN CAST(1 AS BIT) 
							ELSE CAST(0 AS BIT) 
						END Inventario, 
						chekInventario.id IdPiezasInventariadas,
						chekInventario.fechaCambio FechaCambioPiezasInven,
						ub.id IdUbicacion,
						ub.codigo NombreUbicacion,
						chekInventario.numero NumeroCheckInventario,
						PC.id IdProgramacionCarrier,
						PC.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						GHD.RecibidoOrigen,
						GHD.RecibidoDestino,
						GHD.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						 GH.IdEmpresa,
						pod.farmName FarmName
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
								pmc.valor, 
								EX.id IdExportador,
								EX.nombreComercial,
								EX.nombre,
								EX.razonSocial
							FROM
								GuiasHouse gh1 WITH (NOLOCK)
								INNER JOIN #TMP_RelatedClients CLC ON CLC.ConsigneeId = GH1.ConsigneeId
								INNER JOIN GuiasHouse gh WITH (NOLOCK) ON  GH.idGuia = GH1.idGuia
								INNER JOIN Exportadores ex WITH (NOLOCK) ON  GH.idExportador = EX.id
                                INNER JOIN v_ClientsEntities VCC WITH (NOLOCK) ON  GH.ConsigneeId = VCC.Id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										 GH.ConsigneeId = PMC.idEntidad 
										AND PMC.idParametroLista = @idParametroLista
							WHERE
								GH1.house IS NULL 
								AND gh1.idGuia = @idGuia
								AND ( GH.idExportador =  ISNULL(@supplierId,  GH.idExportador))
								AND (@supplierName IS NULL OR EX.nombreComercial LIKE @supplierName+'%')
								AND (@house IS NULL OR  GH.house LIKE @house+'%')
								AND CASE 
									WHEN @consigneeName IS NULL THEN 1
									WHEN ISNULL VCC.Nombre LIKE @consigneeName+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON  GHD.idGuiaHouse =  GH.id 
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON  GHD.idTipoDePieza = tp.id
                        INNER JOIN V_ClientsEntities VCS WITH (NOLOCK) ON  GHD.ShipToId = VCS.Id
						INNER JOIN Usuarios u WITH (NOLOCK) ON  GHD.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON  GHD.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON  GHD.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON  GHD.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON  GHD.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle= GHD.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON  GH.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON  GHD.id = PC.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON PC.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON PC.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE  GHD.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON  GHD.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON  GHD.idCatalogoAccion = cat.Id 
					WHERE
						( GHD.ShipToId = ISNULL(@shipToId,  GHD.ShipToId))
						AND (
							@estado IS NULL 
							OR  GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR  GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR  GHD.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR  GHD.po LIKE '%' + @nroPo + '%')
						AND CASE 
							WHEN @shipToName IS NULL THEN 1
							WHEN VCS.Nombre LIKE @shipToName+'%' THEN 1
							ELSE 0 END = 1
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@palletLabel IS NULL OR p.pallet LIKE '%' + @palletLabel + '%')
						AND (@orden IS NULL OR sv.nroOrden LIKE '%' + @orden + '%')
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN @esInventario = 0 AND SV.nroOrden IS NULL  THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 5 AND SV.tipoPieza = 2 THEN 1
								WHEN @esInventario = 0 AND SV.tipoVenta = 4  THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta = 5 AND SV.tipoPieza = 1 THEN 1
								WHEN @esInventario = 1 AND SV.tipoVenta < 4 THEN 1 
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

AC_pro_GetBarCodeExternal @consigneeId='ETY0000000018053',
@fechaDespacho= '20260109', @idBodega='LXgyot5M', @idCarrier= 'ybOy4oex7F5E',
@sinManifiesto=1, @esInventario=0, @fechaDesde='20210409', @fechaHasta= '20260409',
@EntityId='CLI0127475'

*/