/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Fernando Ordoñez	2026-01-26		  57725			 Initial code base on pro_ConsultarCodigoBarrasLinks
*/

ALTER   PROCEDURE [dbo].[AC_pro_GetBarCodeLinks]
( 
	@idEmpresa					VARCHAR(16),
	@fechaDesde					DATETIME,
	@fechaHasta					DATETIME,
	@idCarrier					VARCHAR(16) = NULL,	
	@sinManifiesto				BIT = NULL,
	@idBodega					VARCHAR(16) = NULL,
	@fechaDespacho				DATETIME = NULL,
	@nroPo						VARCHAR(64) = NULL,
	@idGuiaHouse				UNIQUEIDENTIFIER = NULL,
	@nroGuia					VARCHAR(32) = NULL,
	@idOrdenVenta				UNIQUEIDENTIFIER = NULL,
	@filtroVentas				VARCHAR(32) = NULL,
	@idGuia						VARCHAR(128) = NULL,		
	@station					VARCHAR(16) = NULL,
	@estado						XML = NULL,
	@idManifiesto				UNIQUEIDENTIFIER = NULL,
	@idCatalogo					UNIQUEIDENTIFIER = NULL,
	@idNotificacion				UNIQUEIDENTIFIER = NULL,
	@permitirCarrierNullo		BIT = NULL,
	@numeroChequeoInventario	INT = NULL,
	@tipoInventario				INT = NULL,
	@idCatalogoChequeo			UNIQUEIDENTIFIER = NULL,
	@idGrupoCliente				VARCHAR(16) = NULL,
	@sinTruckId					BIT = NULL,
	@esInventario				BIT = NULL,
	----=========== Filtros de buscador ==============

	@house						VARCHAR(32) = NULL,
	@codBarra					VARCHAR(32) = NULL,
	@orden						VARCHAR(16) = NULL,
	@nroManifiesto				VARCHAR(32) = NULL,
	@palletLabel				VARCHAR(16) = NULL,
	@truckId					VARCHAR(16) = NULL,
	@puerta						VARCHAR(64) = NULL,
	@camion						VARCHAR(32) = NULL,
	@nroDespacho				VARCHAR(32) = NULL,
	----=======Filtros de CycleCount==========
	@countNumber				INT = NULL,
	@isScanned					BIT = NULL,
	@isTheoric					BIT = NULL,
	@idLocationWarehouse		UNIQUEIDENTIFIER = NULL,
	@isLocationWarehouse		BIT = NULL,
	@codeDetail					VARCHAR(64) = NULL,
	@isInventorycycleCount		BIT = NULL,
	----=======Filtros de Entities==========
	@billToId					VARCHAR(16) = NULL,
	@shipToId					VARCHAR(16) = NULL,
	@consigneeId				VARCHAR(16) = NULL,
	@consigneeName				VARCHAR(512) = NULL,
	@shipToName					VARCHAR(256) = NULL,
	@supplierName				VARCHAR(256) = NULL,
	@carrierName				VARCHAR(512) = NULL,
	@billToName					VARCHAR(512) = NULL,
	@supplierId					VARCHAR(16) = NULL
)
AS
BEGIN
	BEGIN TRY
		DECLARE @idParametroLista VARCHAR(16),
				@withoutCode varchar(64) = NULL,
				@sql_script NVARCHAR(MAX),
				@ValorInventario VARCHAR(16) = 'INVENTARIO',
				@CodigoTipoServicio VARCHAR(16) = 'TipoServicio',
				@shipToTable NVARCHAR(128) = 'v_ClientsEntities vst ON ghd.ShipToId = vst.id ',
				@consigneeTable NVARCHAR(32) = ' LEFT JOIN v_ClientsEntities ',
				@esVenta BIT = CASE 
								WHEN @idOrdenVenta IS NULL AND @orden IS NULL THEN 1 
								ELSE 0 END,
				@venta NVARCHAR(3) = CASE 
										WHEN @idOrdenVenta IS NULL AND @orden IS NULL THEN 'sv' 
										ELSE 'svd' 
									 END

		SELECT @idParametroLista = id 
		FROM ParametrosLista pl
		WHERE pl.codigo = 'TipoServicio'
		AND pl.idEmpresa = @idEmpresa

		BEGIN --TABLAS TEMPORALES
			CREATE TABLE #estados (
				estado VARCHAR (64)
			)
			CREATE TABLE #supplier (
				id VARCHAR(16)
			)

			CREATE TABLE #shipTo (
				id VARCHAR(16),
				nombre VARCHAR(216),
			)

			CREATE TABLE #consignee (
				id VARCHAR(16),
				nombre VARCHAR(216)
			)

			CREATE TABLE #carrier (
				id VARCHAR(16)
			)
			CREATE TABLE #idPiezasInventariadas (
				id UNIQUEIDENTIFIER
			)
			CREATE TABLE #idClientes (
				id VARCHAR(16)
			)
			CREATE TABLE #CycleCountTemp (
				id UNIQUEIDENTIFIER,
				idUbicationLast UNIQUEIDENTIFIER
			)
			IF @countNumber IS NOT NULL 
			BEGIN
				SELECT @isLocationWarehouse =ISNULL(@isLocationWarehouse, 1)
				IF @isTheoric = 1
				BEGIN
					INSERT INTO #CycleCountTemp
					SELECT
						CCD.idItem, 
						U.id
					FROM CycleCounts CC
						INNER JOIN CycleCountDetails CCD WITH (NOLOCK) ON CCD.idCycleCount = CC.id
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON CCD.idItem = GHD.id
						INNER JOIN GuiasHouse GH ON GH.id = GHD.idGuiaHouse
						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON CCD.idItem = UP.idGuiaHouseDetalle
						LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
						LEFT JOIN UbicacionesBodega UB ON u.idUbicacionBodega = UB.id
						OUTER APPLY (
							SELECT TOP 1 
								IIF(PC.valor = @ValorInventario, 1, 0) AS InventoryCalculated
							FROM ParametrosCatalogos PC
							LEFT JOIN ParametrosLista PL ON PL.ID = PC.idParametroLista
							WHERE PC.idEntidad = GHD.idClienteFinal
								AND PL.codigo = @CodigoTipoServicio
								AND PL.idEmpresa = @idEmpresa
						) IC
					WHERE CC.cycleCountNumber = @countNumber
						AND ISNULL(CCD.codeDiscrepancy, @withoutCode) = ISNULL(@codeDetail, ISNULL(CCD.codeDiscrepancy, @codeDetail))
						AND GH.ConsigneeId = ISNULL(@consigneeId, CCD.idClient)
						AND ISNULL(IC.InventoryCalculated,0) = ISNULL(@isInventorycycleCount, CCD.IsInventory)
						AND CASE 
							WHEN @idLocationWarehouse IS NULL AND @isLocationWarehouse = 0 AND UB.id IS NULL  THEN 1
							WHEN @idLocationWarehouse IS NULL AND @isLocationWarehouse <> 0  THEN 1
							WHEN UB.id = @idLocationWarehouse THEN 1 
							ELSE 0 END = 1
				END
				ELSE
				BEGIN

					INSERT INTO #CycleCountTemp
					SELECT
						CCD.idItem, 
						U.id
					FROM CycleCounts CC
						INNER JOIN CycleCountDetails CCD WITH (NOLOCK) ON CCD.idCycleCount = CC.id AND CCD.scanned = @isScanned
						INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON CCD.idItem = GHD.id
						INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id = GHD.idGuiaHouse
 						LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON CCD.idItem = UP.idGuiaHouseDetalle
						LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
						LEFT JOIN UbicacionesBodega UB ON u.idUbicacionBodega = UB.id
						OUTER APPLY (
							SELECT TOP 1 
								IIF(PC.valor = @ValorInventario, 1, 0) AS InventoryCalculated
							FROM ParametrosCatalogos PC
							LEFT JOIN ParametrosLista PL ON PL.ID = PC.idParametroLista
							WHERE PC.idEntidad = GHD.idClienteFinal
								AND PL.codigo = @CodigoTipoServicio
								AND PL.idEmpresa = @idEmpresa
						) IC
					WHERE CC.cycleCountNumber = @countNumber
						AND ISNULL(CCD.codeDiscrepancy, @withoutCode) = ISNULL(@codeDetail, ISNULL(CCD.codeDiscrepancy, @codeDetail))
						AND GH.ConsigneeId = ISNULL(@consigneeId, CCD.idClient)
						AND (@isInventorycycleCount IS NULL OR ISNULL(IC.InventoryCalculated, 0) = @isInventorycycleCount)
						AND CASE 
							WHEN @idLocationWarehouse IS NULL AND @isLocationWarehouse = 0 AND UB.id IS NULL THEN 1
							WHEN @idLocationWarehouse IS NULL AND @isLocationWarehouse <> 0 THEN 1
							WHEN UB.id = @idLocationWarehouse THEN 1 
							ELSE 0 END = 1;

				END
			END
			
			IF(@estado IS NOT NULL)
			BEGIN
				INSERT INTO #estados
				SELECT [Value] 
				FROM [dbo].fnObtenerValoresXML(@estado)
			END

			IF(@supplierName IS NOT NULL)
			BEGIN
				INSERT INTO #supplier
				SELECT id 
				FROM Exportadores ex 
				WHERE ex.nombreComercial LIKE '%'+@supplierName+'%'
			END

			IF(@billToName IS NOT NULL OR @billToId IS NOT NULL OR @consigneeName IS NOT NULL OR @consigneeId IS NOT NULL)
			BEGIN

				SELECT @consigneeTable = ' INNER JOIN #consignee '
				IF(@billToId IS NOT NULL)
				BEGIN
					INSERT INTO #consignee
					SELECT id, nombre
					FROM v_ClientsEntities 
					WHERE BillToId = @billToId;
				END
				ELSE IF(@billToName IS NOT NULL)
				BEGIN
					INSERT INTO #consignee
					SELECT v.id, nombre
					FROM f_SearchEntities(@billToName, 'BillTo') f
						INNER JOIN v_ClientsEntities v ON v.id = f.id;
				END

				IF(@consigneeId IS NOT NULL)
				BEGIN
					INSERT INTO #consignee
					SELECT id, nombre
					FROM v_ClientsEntities 
					WHERE ConsigneeId = @consigneeId;
				END
				ELSE IF(@consigneeName IS NOT NULL)
				BEGIN
					INSERT INTO #consignee
					SELECT v.id, nombre
					FROM f_SearchEntities(@consigneeName, 'Consignee') f
						INNER JOIN v_ClientsEntities v ON v.id = f.id;
				END
			END

			IF(@shipToName IS NOT NULL OR @shipToId IS NOT NULL)
			BEGIN
				
				IF(@shipToId IS NOT NULL)
				BEGIN
					SELECT @shipToTable = ' v_ClientsEntities vst ON ghd.ShipToId = vst.id AND vst.id = @shipToId'
				END
				ELSE
				BEGIN
					SELECT @shipToTable = ' #shipTo vst ON ghd.ShipToId = vst.id'

					INSERT INTO #shipTo
					SELECT f.id, v.nombre
					FROM f_SearchEntities(@shipToName, 'ShipTo') f
						INNER JOIN v_ClientsEntities v ON v.id = f.id;
				END
			END


			IF(@carrierName IS NOT NULL AND @idCarrier IS NULL)
			BEGIN
				INSERT INTO #carrier
				SELECT id 
				FROM Transportes t 
				WHERE t.nombre LIKE '%'+@carrierName+'%'
			END

			IF(@idGrupoCliente IS NOT NULL)
			BEGIN
				INSERT INTO #idClientes
				SELECT idCliente 
				FROM GrupoClientes 
				WHERE idGrupoCliente = @idGrupoCliente
			END

			IF(@tipoInventario = 2)
			BEGIN		
				INSERT INTO #idPiezasInventariadas
				SELECT ppi.IdGuiaHouseDetalle
				FROM ChequeoInventario cchi
				INNER JOIN PiezasInventariadas ppi ON cchi.id = ppi.IdChequeoInventario
				INNER JOIN GuiasHouseDetalles ghd ON ppi.IdGuiaHouseDetalle = ghd.id
				WHERE cchi.numero = @numeroChequeoInventario 
				AND cchi.idCatalogos = @idCatalogoChequeo
				AND ghd.estadoPieza IN('RECEIVED WH','STANDBY') 
			END
		END

		SELECT @sql_script = CONCAT(N'
			SELECT ghd.Id,									
					ghd.IdGuiaHouse,
					ghd.CodigoBarra	,
					ghd.productoDescripcion DescripcionProducto,
					ISNULL(ghd.fechaRecepcion, GETDATE()) FechaRecepcion,
					ghd.AltoCm,
					ghd.AnchoCm,
					ghd.LargoCm,
					ghd.AltoIn AltoInch,
					ghd.AnchoIn AnchoInch,
					ghd.LargoIn LargoInch,
					ghd.Nota,
					ghd.EstadoPieza,
					ghd.FechaCreacion,
					ghd.FechaCambio,
					ghd.TotalTallos,
					ghd.PrecioTallo,
					ghd.Peso,
					ghd.Po,
					ghd.RecepcionEscaner,
					ghd.TruckId,
					ghd.idCatalogoAccion IdAccion,
					ghd.NoPermitirVenta,
					ghd.station Station,
					tp.id IdTipoPieza,
					tp.TipoPieza,
					vst.id ShipToId,
					vst.nombre ShipToName,
					us.nombre,
					gh.NroGuia,
					gh.House,
					gh.FechaOrigen,
					gh.FechaDestino,
					gh.fechaOrigen FechaOrigenFecha,
					gh.fechaDestino FechaDestinoFecha,
					ex.id IdExportador,
					ex.nombreComercial NombreComercialExportador,
					ex.nombre NombreExportador,
					ex.razonSocial RazonSocialExportador,
					vcd.id ConsigneeId,
					vcd.nombre ConsigneeName,	
					ISNULL(ub.idBodega, gh.idBodega) IdBodega,
					ISNULL(bodegaPieza.nombre, bodegaGuia.nombre) NombreBodega,
					pmc.valor CodigoClienteInventario,
					ISNULL(ed.Puerta, ghd.Gate) Puerta,
					ve.placa Camion,
					ed.truckId NroDespacho,
					dm.nombre NombreProducto,
					dm.nombreIngles NombreInglesProducto,
					dm.id IdDetalleMercancia,',
					CASE 
						WHEN @idCatalogoChequeo IS NOT NULL THEN 
							'CASE 																		
								WHEN ci.id IS NOT NULL 												
								THEN CAST(1 AS BIT) 													
								ELSE CAST(0 AS BIT) 													
							END Inventario,
							ci.id IdPiezasInventariadas,
							ci.fechaCambio FechaCambioPiezasInven,
							ci.numero NumeroCheckInventario,'				
						ELSE '
							CASE 																		
								WHEN chekInventario.id IS NOT NULL 												
								THEN CAST(1 AS BIT) 													
								ELSE CAST(0 AS BIT) 													
								END Inventario,
							chekInventario.id IdPiezasInventariadas,
							chekInventario.fechaCambio FechaCambioPiezasInven,
							chekInventario.numero NumeroCheckInventario,'
					END, '
					u.id IdUbicacion,
					u.codigo NombreUbicacion,					
					pc.id IdProgramacionCarrier,
					pc.FechaDespacho,
					t.id IdCarrier,
					t.codigoMiami CodigoCarrier,
					t.nombre NombreCarrier,
					md.NroManifiesto,
					sv.nroOrden Orden,
					sv.fechaSolicitud FechaOrden,	
					p.pallet PalletLabel,
					cbc.estadoPieza EstadoCarrier,
					CASE WHEN cbc.estadoPieza IN (''RECEIVED'',''SHUTTLED'',''PUT_AWAY'',''MIS_STAGED'', ''COOLER'',''LOADED'') THEN 1 ELSE 0 END EntregadoCarrier,
					ghd.RecibidoOrigen,
					ghd.RecibidoDestino,
					ghd.DespachadoDestino,
					md.id IdManifiesto,
					e.Nombres + '' '' + e.Apellidos Chofer,
					cat.Nombre AccionNombre,
					cat.NombreIngles AccionNombreIngles,
					gh.IdEmpresa,
					POD.farmName FarmName,
					CASE WHEN ',
					CASE 
						WHEN @esVenta = 1 THEN 
						'(sv' 
						ELSE '(svd' 
					END, '.picking = 0 OR pc.fechaCambioPicking IS NULL) AND ghd.ScanDespacho = 1 AND ghd.despachadoDestino <> ''Web'' THEN ''EscanerFiltroMarcas''
								ELSE CASE 
									WHEN',
									CASE
										WHEN @esVenta = 1 THEN
										' sv.picking <> 1'
										ELSE
										' svd.picking <> 1'
									END,
									' AND ghd.estadoPieza = ''DISPATCHED WH'' AND ghd.despachadoDestino = ''Web''											
									THEN ''WebFiltroMarcas''
									WHEN pc.fechaCambioPicking IS NOT NULL',
									CASE
										WHEN @esVenta = 1 THEN
										' OR sv.picking = 1'
										ELSE
										' OR svd.picking = 1'
									END,'
									THEN ''Picked''																				
							END
						END Picked
				FROM ',
				CASE 
					WHEN @countNumber IS NOT NULL
					THEN '#CycleCountTemp CCT 
						INNER JOIN GuiasHouseDetalles ghd WITH(NOLOCK) ON CCT.id = ghd.id 
						INNER JOIN GuiasHouse gh WITH(NOLOCK) ON ghd.idGuiaHouse = gh.id' 
					WHEN @idCatalogoChequeo IS NULL AND @codBarra IS NULL AND @truckId IS NULL AND @estado IS NULL AND 
							@station IS NULL AND @idNotificacion IS NULL AND @station IS NULL AND @idCatalogo IS NULL THEN 
						'GuiasHouse gh WITH(NOLOCK) 
						INNER JOIN GuiasHouseDetalles ghd WITH(NOLOCK) ON gh.id = ghd.idGuiaHouse'
					ELSE 
						'GuiasHouseDetalles ghd WITH(NOLOCK) 
						INNER JOIN GuiasHouse gh WITH(NOLOCK) ON ghd.idGuiaHouse = gh.id' 
				END ,
				'
				INNER JOIN ', @shipToTable, '
				INNER JOIN TiposDePieza tp WITH(NOLOCK) ON ghd.idTipoDePieza = tp.id
				INNER JOIN Usuarios us WITH(NOLOCK) ON ghd.idUsuarioLog = us.id
				INNER JOIN Exportadores ex WITH(NOLOCK) ON gh.idExportador = ex.id',					
				CASE 
					WHEN @idNotificacion IS NOT NULL THEN 
						' INNER JOIN NotificacionPiezasDetalle ntPD  WITH(NOLOCK) ON ghd.id = ntPD.idGuiaHouseDetalle 
						INNER JOIN NotificacionPiezas ntP  WITH(NOLOCK) ON ntPD.idNotificacionPiezas = ntP.id' 
				END,  
				CASE 
					WHEN @idManifiesto IS NULL AND @fechaDespacho IS NULL AND @idCarrier IS NULL AND @carrierName IS NULL THEN 
						' LEFT' 
					ELSE 
						' INNER' 
				END, 
				' JOIN ProgramacionCarrier pc (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle', 
				CASE 
					WHEN @idManifiesto IS NULL AND @nroManifiesto IS NULL THEN 
						' LEFT' 
					ELSE 
						' INNER' 
				END, 
				' JOIN ProgramacionManifiesto pm WITH(NOLOCK) ON pc.id = pm.idProgramacionCarrier',
				CASE 
					WHEN @idManifiesto IS NULL AND @nroManifiesto IS NULL THEN 
						' LEFT' 
					ELSE 
						' INNER' 
				END, 
				' JOIN ManifiestosDespacho md WITH(NOLOCK) ON pm.idManifiestoDespacho = md.id',
				CASE 
					WHEN @esVenta = 1 THEN 
						' 
						OUTER APPLY (
							SELECT TOP 1 svc.nroOrden, svc.fechaSolicitud, svd.Picking, svc.tipoVenta, svd.tipoPieza
							FROM SolicitudDeVentaDetalles svd 
								LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
							WHERE ghd.id = svd.idGuiaHouseDetalle 
							ORDER BY svc.fechaSolicitud DESC
						) sv
						'
					ELSE 
						' 
						INNER JOIN SolicitudDeVentaDetalles svd WITH(NOLOCK) ON ghd.id = svd.idGuiaHouseDetalle
						INNER JOIN SolicitudDeVenta sv WITH(NOLOCK) ON svd.idSolicitud = sv.id
						'
				END,				
				CASE 
					WHEN @idCatalogo IS NOT NULL THEN 
						' 
						INNER JOIN NotificacionesGenerales ng ON ng.idCatalogo = @idCatalogo AND ng.idEmpresa = @idEmpresa AND  ghd.id = ng.idCorrelacion    
						INNER JOIN Catalogos catNot ON ng.idCatalogo = catNot.id ' 
				END,
				@consigneeTable,' vcd ON ISNULL(gh.BilltoConsigneeId, gh.ConsigneeId) = vcd.id 
				LEFT JOIN ParametrosCatalogos pmc WITH(NOLOCK) ON gh.ConsigneeId = pmc.idEntidad AND pmc.idParametroLista = @idParametroLista', 
				CONVERT(VARCHAR(MAX), 
				CASE 
					WHEN @camion IS NULL AND @nroDespacho IS NULL THEN 
						' LEFT' 
					ELSE 
						' INNER' 
				END), 
				' JOIN DetalleDespacho dd WITH(NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle',
				CONVERT(VARCHAR(MAX), 
				CASE 
					WHEN @camion IS NULL AND @nroDespacho IS NULL THEN 
						' LEFT' 
					ELSE 
						' INNER' 
				END), 
				' JOIN EncabezadoDespacho ed WITH(NOLOCK) ON dd.idEncabezadoDespacho = ed.id',
				CONVERT(VARCHAR(MAX), 
					CASE 
						WHEN @camion IS NULL THEN 
							' LEFT' 
						ELSE 
							' INNER' 
					END), 
				' JOIN VehiculosExportadores ve WITH(NOLOCK) ON ed.idVehiculo = ve.id
				LEFT JOIN DetalleMercancias dm WITH(NOLOCK) ON ghd.idDetalleMercancia = dm.id',
				CONVERT(VARCHAR(MAX), 
					CASE 
						WHEN @idCatalogoChequeo IS NULL THEN 
							' LEFT' 
						ELSE 
							' INNER' 
					END), 
				' JOIN UbicacionPiezas up WITH(NOLOCK) ON ghd.id = up.idGuiaHouseDetalle',
				CASE 
					WHEN @idCatalogoChequeo IS NULL THEN 
					' 
					OUTER APPLY (
						SELECT TOP 1 pinv.id, 
									checkInv.estado, 
									pinv.fechaCambio, 
									checkInv.numero 
						FROM PiezasInventariadas pinv
						LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
						WHERE pinv.IdGuiaHouseDetalle = ghd.id
						ORDER BY pinv.fechaCambio DESC
					) AS chekInventario'				
					ELSE				
						CASE @tipoInventario WHEN 1 THEN 
							' INNER JOIN PiezasInventariadas pinv ON ghd.id  = pinv.IdGuiaHouseDetalle 
							INNER JOIN ChequeoInventario ci ON pinv.IdChequeoInventario = ci.id
							' 
						ELSE 
							' LEFT JOIN ChequeoInventario ci ON ci.idCatalogos = @idCatalogoChequeo AND ci.numero = @numeroChequeoInventario
							LEFT JOIN PiezasInventariadas pinv ON pinv.IdChequeoInventario = ci.id AND ghd.id  = pinv.IdGuiaHouseDetalle'
						END
				END,'
				LEFT JOIN Ubicaciones u WITH(NOLOCK) ON up.idUbicacion = u.id
				LEFT JOIN UbicacionesBodega ub WITH(NOLOCK) ON u.idUbicacionBodega = ub.id 
				LEFT JOIN Bodegas bodegaGuia WITH(NOLOCK) ON gh.idBodega = bodegaGuia.id 
				LEFT JOIN Catalogos cat WITH(NOLOCK) ON ghd.idCatalogoAccion = cat.Id
				LEFT JOIN Bodegas bodegaPieza WITH(NOLOCK) ON ub.idBodega = bodegaPieza.id
				LEFT JOIN PoDetalles POD WITH(NOLOCK) ON ghd.idPoDetalle = POD.id',
				CONVERT(VARCHAR(MAX),
					CASE 
						WHEN @idCarrier IS NULL AND @carrierName IS NULL THEN 
							' LEFT' 
						ELSE ' INNER' 
					END), 
				' JOIN Transportes t WITH(NOLOCK) ON pc.idCarrier = t.id',
				CONVERT(VARCHAR(MAX),
					CASE 
						WHEN @palletLabel IS NULL THEN 
							' LEFT' 
						ELSE 
							' INNER' 
					END),
				' JOIN PalletsDetalles pd WITH(NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle',
				CONVERT(VARCHAR(MAX),
					CASE 
						WHEN @palletLabel IS NULL THEN 
							' LEFT' 
						ELSE 
							' INNER' 
					END), 
				' JOIN Pallets p WITH(NOLOCK) ON pd.idPallet = p.id
				OUTER APPLY (
					SELECT TOP 1 cbcc.estadoPieza 
					FROM CodigosDeBarraCarrier cbcc
					WHERE cbcc.codigoBarras =  ghd.codigoBarra
					ORDER BY cbcc.fechaCambio DESC
				) AS cbc
				LEFT JOIN Empleados e WITH(NOLOCK) ON ed.IdEmpleado = e.Id				
				WHERE gh.FechaDestino BETWEEN  @fechaDesde AND @fechaHasta AND gh.idEmpresa = @idEmpresa',	
				CASE WHEN @idGuia IS NOT NULL THEN ' AND gh.IdGuia = @idGuia' END,
				CASE WHEN @idGuiaHouse IS NOT  NULL THEN ' AND gh.Id = @idGuiaHouse' END, 				
				CASE WHEN @idManifiesto IS NOT NULL THEN ' AND md.id = @idManifiesto' END,			
				CASE WHEN @fechaDespacho IS NOT  NULL THEN ' AND pc.FechaDespacho = @fechaDespacho' END,
				CASE WHEN @idCarrier IS NOT NULL THEN ' AND t.id = @idCarrier' END,
				CASE WHEN @permitirCarrierNullo = 1 THEN ' AND pc.idCarrier IS NULL' END,
				CASE WHEN @nroPo IS NOT NULL THEN ' AND ghd.po LIKE ''%''+@nroPo+''%''' END,
				CASE WHEN @codBarra IS NOT NULL THEN ' AND ghd.CodigoBarra LIKE @codBarra+''%''' END,
				CASE WHEN @truckId IS NOT NULL  THEN ' AND ghd.truckId LIKE ''%''+@truckId+''%''' END,
				CASE WHEN @sinTruckId IS NOT NULL AND @sinTruckId = 1 THEN ' AND ghd.truckId IS NULL' END,
				CASE WHEN @estado IS NOT NULL THEN ' AND ghd.estadoPieza IN (SELECT estado FROM #estados)' END,
				CASE 
					WHEN @station IS NOT NULL AND @station = '0' THEN 
						' AND (ghd.estadoPieza = ''RECEIVED WH'' 
								AND ghd.station IS NULL 
								OR (SELECT station FROM machine..Input mest WHERE mest.BarCode = ghd.codigoBarra AND mest.IdAWB = gh.idGuia) IS NULL
							 )' 
				END,
				CASE 
					WHEN @station IS NOT NULL AND @station <> '0' THEN 
						' AND @station = CASE ghd.estadoPieza WHEN ''RECEIVED WH'' THEN 
											ghd.station 
											ELSE (SELECT station 
													FROM machine..Input mest 
													WHERE mest.BarCode = ghd.codigoBarra 
													AND mest.IdAWB = gh.idGuia) 
										 END' 
				END,			
				CASE WHEN @idOrdenVenta IS NOT  NULL THEN ' AND sv.id = @idOrdenVenta' END,				
				CASE WHEN @idBodega IS NOT  NULL THEN ' AND ISNULL(ub.idBodega, gh.idBodega)  = @idBodega' END,
				CASE WHEN @supplierId IS NOT  NULL THEN ' AND ex.id = @supplierId' END,
				CASE WHEN @sinManifiesto IS NOT  NULL AND  @sinManifiesto = 1 THEN ' AND md.id IS NULL' END,
				CASE WHEN @filtroVentas IS NOT  NULL AND @filtroVentas = 'NoDispatch' THEN ' AND ghd.estadoPieza <> ''DISPATCHED WH''' END,
				CASE WHEN @filtroVentas IS NOT  NULL AND @filtroVentas = 'NoPicking' THEN ' AND svd.picking = 0' END,			
				CASE WHEN @supplierName IS NOT NULL AND @supplierId IS NULL THEN ' AND ex.id IN (SELECT id FROM #supplier)' END,				
				CASE WHEN @puerta IS NOT NULL THEN ' AND ISNULL(ed.Puerta, ghd.Gate) = @puerta' END,
				CASE WHEN @camion IS NOT  NULL THEN ' AND ve.placa = @camion' END,
				CASE WHEN @idNotificacion IS NOT  NULL THEN ' AND ntP.id = @idNotificacion' END,	
				CASE WHEN @idGrupoCliente IS NOT NULL THEN ' AND vst.id IN (SELECT id FROM #idClientes)' END,
				CASE WHEN @tipoInventario = 1 THEN 
					' AND ci.idEmpresa = @idEmpresa 
					 AND ci.numero = @numeroChequeoInventario 
					 AND ci.idCatalogos = @idCatalogoChequeo' END,
				CASE WHEN @tipoInventario = 2 THEN ' AND ghd.id NOT IN (
							SELECT id FROM #idPiezasInventariadas
					)
				' END,
				CASE WHEN @idCatalogoChequeo IS NOT NULL THEN ' AND ghd.estadoPieza IN(''RECEIVED WH'',''STANDBY'')' END,
				CASE 
					WHEN @esInventario = 1 THEN 
					' AND (sv.tipoVenta < 4 OR (sv.tipoVenta = 5 AND ' + @venta + '.tipoPieza = 1))' 
					ELSE '' 
				END,
				CASE WHEN @nroGuia IS NOT  NULL THEN ' AND gh.nroGuia LIKE ''%''+@nroGuia+''%''' END,
				CASE WHEN @house IS NOT  NULL THEN ' AND gh.house LIKE ''%''+@house+''%''' END,
				CASE WHEN @orden IS NOT  NULL THEN ' AND sv.nroOrden LIKE ''%''+@orden+''%''' END,
				CASE WHEN @nroManifiesto IS NOT  NULL THEN ' AND md.nroManifiesto LIKE ''%''+@nroManifiesto+''%''' END,
				CASE WHEN @palletLabel IS NOT  NULL THEN ' AND p.pallet LIKE ''%''+@palletLabel+''%''' END,			
				CASE WHEN @nroDespacho IS NOT  NULL THEN ' AND ed.truckId LIKE ''%''+@nroDespacho+''%''' END,
				CASE WHEN @carrierName IS NOT NULL AND @idCarrier IS NULL THEN ' AND t.id IN (SELECT id FROM #carrier)' END	
			)
			
		EXEC SP_EXECUTESQL @sql_script, N'@fechaDesde DATETIME, @fechaHasta DATETIME, @idEmpresa VARCHAR(16), @idManifiesto UNIQUEIDENTIFIER, @idGuia VARCHAR(128), 
										@fechaDespacho DATETIME, @idCarrier VARCHAR(16), @nroPo VARCHAR(64), @idGuiaHouse UNIQUEIDENTIFIER, 
										@nroGuia VARCHAR(32), @idOrdenVenta UNIQUEIDENTIFIER, @idBodega VARCHAR(16), @consigneeId VARCHAR(16), @station VARCHAR(16), 
										@idParametroLista VARCHAR(16), @idCatalogo UNIQUEIDENTIFIER,
										@house VARCHAR(32), @codBarra VARCHAR(32), @orden VARCHAR(16), @nroManifiesto VARCHAR(32),
										@palletLabel VARCHAR(16), @truckId VARCHAR(16),	@puerta VARCHAR(64), @camion VARCHAR(32), @nroDespacho VARCHAR(32),
										@numeroChequeoInventario INT, @idCatalogoChequeo UNIQUEIDENTIFIER, @idNotificacion UNIQUEIDENTIFIER, @esInventario BIT,
										@supplierId VARCHAR(16), @shipToId VARCHAR(16)',
							@fechaDesde = @fechaDesde, @fechaHasta = @fechaHasta, @idEmpresa = @idEmpresa, @idManifiesto = @idManifiesto,
							@idGuia = @idGuia, @fechaDespacho = @fechaDespacho, @idCarrier = @idCarrier, 
							@nroPo = @nroPo, @idGuiaHouse = @idGuiaHouse, @nroGuia = @nroGuia, @idOrdenVenta = @idOrdenVenta, @idBodega = @idBodega, 
							@consigneeId = @consigneeId, @station = @station, @idParametroLista = @idParametroLista, @idCatalogo = @idCatalogo,
							@house = @house, @codBarra = @codBarra, @orden = @orden, @nroManifiesto	= @nroManifiesto, @palletLabel = @palletLabel, @truckId = @truckId,
							@puerta	= @puerta, @camion = @camion, @nroDespacho = @nroDespacho, @numeroChequeoInventario = @numeroChequeoInventario,
							@idCatalogoChequeo = @idCatalogoChequeo, @idNotificacion = @idNotificacion, @esInventario = @esInventario, 
							@supplierId = @supplierId, @shipToId = @shipToId
	END TRY
	BEGIN CATCH			
		EXEC [dbo].[pro_LogError] 
	END CATCH;
END
/*

exec dbo.AC_pro_GetBarCodeLinks @idEmpresa=N'EMP014',@fechaDesde='20250503',@fechaHasta='20260503'
,@billToId='ETY071'
,@idCarrier='rhYaa8T6'
,@consigneeId='ETY073'
,@shipToId='ETY00057706'

exec dbo.AC_pro_GetBarCodeLinks @idEmpresa=N'EMP014',@fechaDesde='20250503',@fechaHasta='20260503'
,@billToName='naranjo farms'
,@consigneeName='in and out'
,@shipToName='CANDELARI'
,@supplierName='ANGY ROS'


exec dbo.AC_pro_GetBarCodeLinks @idEmpresa=N'EMP014',@fechaDesde='20250503',@fechaHasta='20260503'
,@billToId='ETY071'
,@idCarrier='rhYaa8T6'
,@consigneeId='ETY073'
,@shipToId='ETY00057706'
,@palletLabel='H4P1209250504'

*/

