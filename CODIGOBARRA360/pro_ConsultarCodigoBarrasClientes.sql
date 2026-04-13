/*
VERSION		AUTOR				FECHA		HU			CAMBIO
1			Edwin Casa			14-08-2023  WMS 30232	Codigo inicial SP PARA LISTAR CODIGOS DE BARRAS CON FILTROS ENVIADOS POR APLICACIÓN ORIENTADO A CLIENTES
2			Edwin Casa			14-08-2023  WMS 30972	AGREGAR PARAMETROS (@idCarrier,@idBodega,@fechaDespacho, @truckId)
3			Edwin Casa			17-10-2023  WMS 31256	AGREGAR PARAMETROS esVendida
4			Edwin Casa			08-11-2023  WMS 32794	[BUG] Se agrega un flujo para consultas que inician por fechaDespacho y Carrier
5			Edwin Casa			09-11-2023  WMS 33184	[BUG] Correccion de piezas totales por link de cliente360
6			Edwin Casa			11-11-2023  WMS 33426	[BUG] Correccion de piezas totales por link de modulo PODS se agrega el parametro @idManifiesto, @idGuiaHouse
7			Edwin Casa			23-11-2023  WMS 33889	[BUG] se detecta un escenario donde es importante incluir la fechaDespacho y idCarrier desde las migas de pan de cliente Final desde cliente360
8			Edwin Casa			23-11-2023  WMS 33898	[BUG] se retira los conver de los campos fechaOrigenFecha
9			Edwin Casa			27-11-2023  WMS 33898	[BUG] AGREGAR PARAMETROS @isDispatchCarrier para controlar regla de sinManifiesto
10			Edwin Casa			28-11-2023  WMS 33898	[BUG] Se agrega un control para cuando vengan nulos los parametros @idCarrier  AND @fechaDespacho AND @idManifiesto
11			Edwin Casa			28-11-2023  CC 	34094	Se agrega else en el case de asignacion de valor a la variable @sinManifiesto 
12			Edwin Casa			14-12-2023  CC 	34220	Se agrega parametro @idNotificacion y dos flujos nuevos para este nuevo parametro
13			Edwin Casa			26-12-2023  CC 	35030	Se reemplaza inner join por left join a programacion carrier en el llenado de #TempPiezasPorCarrier caso cliente consolidador sin filtros de despacho
14			Edwin Casa			26-03-2024  CC 	36501	Se retira del where la condición para validar por fechaDestino para los casos de links de codigos de barra que vienen desde las piezas de cliente360
15			Fernando Ordoñez	16-10-2024	HU	41334	Quitar headerLabel	
*/
ALTER    PROCEDURE [dbo].[pro_ConsultarCodigoBarrasClientes]
(
	@fechaDesde DATETIME,
	@fechaHasta DATETIME,
	@IdCliente VARCHAR(16),
	@nombreExportador VARCHAR(512) = NULL,
	@nombreClienteDistribucion VARCHAR(512) = NULL,
	@nombreClienteFinal VARCHAR(512) = NULL,
	@house VARCHAR(32) = NULL,
	@nroPo VARCHAR(32) = NULL,
	@codBarra VARCHAR(32) = NULL,
	@estado	XML = NULL,
	@orden VARCHAR(16) = NULL, 
	@nroManifiesto VARCHAR(16) = NULL,
	@palletLabel VARCHAR(32) = NULL,
	@idGuia						VARCHAR(64) = NULL,
	@tipoCliente				VARCHAR(64) = NULL,
	@idExportador				VARCHAR(16) = NULL,
	@idClienteFinal				VARCHAR(16) = NULL,
	@esPOD						BIT = NULL,
	@esVendida					BIT = NULL,
	@idCarrier					VARCHAR(16) = NULL,
	@idBodega					VARCHAR(16) = NULL,
	@fechaDespacho				DATETIME = NULL,
	@truckId					VARCHAR(16)= NULL,
	@idManifiesto				UNIQUEIDENTIFIER= NULL,
	@idGuiaHouse				UNIQUEIDENTIFIER= NULL,
	@isDispatchCarrier			BIT = NULL,
	@idNotificacion				UNIQUEIDENTIFIER= NULL,
	@esInventario				BIT = NULL
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @idParametroLista VARCHAR(16),
				@tipoClienteLag VARCHAR(64),
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
			id [UNIQUEIDENTIFIER],
			idGuiaHouse [UNIQUEIDENTIFIER],
			CodigoBarra [VARCHAR](32),
			ProductoDescripcion [VARCHAR](512),
			FechaRecepcion [DATETIME],
			AltoCm [DECIMAL](18,3),
			AnchoCm [DECIMAL](18,3),
			LargoCm [DECIMAL](18,3),
			AltoInch [DECIMAL](18,3),
			AnchoInch [DECIMAL](18,3),
			LargoInch [DECIMAL](18,3),
			Nota [VARCHAR](256),
			EstadoPieza [VARCHAR](64),
			FechaCreacion [DATETIME],
			FechaCambio [DATETIME],
			TotalTallos INT,
			PrecioTallo [DECIMAL](18,3),
			Peso [DECIMAL](18,3),
			Po [VARCHAR](64),
			RecepcionEscaner [BIT],
			TruckId [VARCHAR](16),
			IdAccion [UNIQUEIDENTIFIER],
			NoPermitirVenta BIT,
			NroGuia [VARCHAR](32),
			House [VARCHAR](32),
			FechaOrigen [DATETIME], 
			FechaDestino [DATETIME],
			FechaOrigenFecha [DATE],
			FechaDestinoFecha [DATE],
			IdExportador [VARCHAR](16),
			IdClienteDistribucion [VARCHAR](16),
			idBodega [VARCHAR](16),
			IdProgramacionCarrier [UNIQUEIDENTIFIER],
			FechaDespacho [DATETIME],
			RecibidoOrigen [VARCHAR](16),
			RecibidoDestino [VARCHAR](16),
			DespachadoDestino [VARCHAR](16),
			Chofer [VARCHAR](16),
			IdEmpresa [VARCHAR](16),
			valor [VARCHAR](64),
			nombreComercial [VARCHAR](512),
			nombre [VARCHAR](1024),
			razonSocial [VARCHAR](512),
			idTipoDePieza [VARCHAR](16),
			idClienteFinal [VARCHAR](16),
			idUsuarioLog [VARCHAR](16),
			idPoDetalle [UNIQUEIDENTIFIER],
			idDetalleMercancia [VARCHAR](16),
			idCliente [VARCHAR](16),
			nombreClienteConsignee [VARCHAR](512)
		);

		CREATE TABLE #ClientesRel(
			[id] [VARCHAR](16)
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
	
			SELECT  @tipoClienteLag = cat.identificador 
			FROM  DetalleEntidades DetI 
				INNER JOIN dbo.Catalogos cat ON cat.id = DetI.idCatalogo
			WHERE  DetI.idEntidad = @IdCliente

			IF @tipoClienteLag = 'CLIENTE'
			BEGIN 
				INSERT INTO #ClientesRel (id) 
				VALUES(@IdCliente)
			END
			ELSE
			BEGIN 
				INSERT INTO #ClientesRel (id) 
				SELECT  idCliente 
				FROM  dbo.GrupoClientes 
				WHERE  idGrupoCliente = @IdCliente
			END

		
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
						INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
					WHERE  GH.house IS NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1  @Consignee ='CONSIGNEE'
					FROM  GuiasHouse GH
						INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
					WHERE  GH.house IS NOT NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1  @Final = 'FINAL'
					FROM  GuiasHouseDetalles GHD
						INNER JOIN #ClientesRel CLI ON CLI.id = GHD.idClienteFinal
					WHERE fechaCreacion BETWEEN @fechaDesde AND @FechaHasta
				
					/* CLIENTES FINALES */
					IF @Final IS NOT NULL 
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							'' Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
						FROM ProgramacionCarrier pc  WITH (NOLOCK)
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON 
																GHD.id = pc.idGuiaHouseDetalle 
																AND GHD.fechaCreacion BETWEEN @fechaDesde AND @FechaHasta
							INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteFinal
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE  pc.fechaDespacho = @fechaDespacho
							AND pc.idCarrier = @idCarrier
							AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
							AND (@nombreClienteDistribucion IS NULL 
								OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
							AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
							AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
							AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GH.house LIKE @house+'%')
				
					END

					 /* CLIENTES CONSIGNEE */
					IF @Consignee IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							''  Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
						FROM GuiasHouse GH WITH (NOLOCK)
							INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH.idCliente
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
							INNER JOIN ProgramacionCarrier AS pc  WITH (NOLOCK) ON 
												pc.idGuiaHouseDetalle = GHD.id 
												AND pc.fechaDespacho = @fechaDespacho
												AND pc.idCarrier = @idCarrier
						
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE  GH.house IS NOT NULL 
							AND GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN gh.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
							AND (@nombreClienteDistribucion IS NULL 
								OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
							AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
							AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
							AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GH.house LIKE @house+'%')
					END
				
					/* CLIENTES CONSOLIDADORES */
					IF @Consolidador IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							ghd.idCatalogoAccion AS IdAccion,
							ghd.NoPermitirVenta,
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							'' Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
						FROM GuiasHouse GH1 WITH (NOLOCK)
							INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH1.idCliente
							INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
											pc.idGuiaHouseDetalle = GHD.id
											AND pc.fechaDespacho = @fechaDespacho
											AND  pc.idCarrier = @idCarrier
						
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE  GH1.house IS NULL 
							AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN gh.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
							AND (@nombreClienteDistribucion IS NULL 
								OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
							AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
							AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
							AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GH.house LIKE @house+'%')
					END
				
					SELECT DISTINCT
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
						ghd.AltoCm,
						ghd.AnchoCm,
						ghd.LargoCm,
						ghd.AltoInch,
						ghd.AnchoInch,
						ghd.LargoInch,
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
						ghd.IdAccion,
						ghd.NoPermitirVenta,
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						ghd.NroGuia,
						ghd.House,
						ghd.FechaOrigen,
						ghd.FechaDestino,
						ghd.fechaOrigen FechaOrigenFecha,
						ghd.fechaDestino FechaDestinoFecha,
						GHD.IdExportador,
						GHD.nombreComercial NombreComercialExportador,
						GHD.nombre NombreExportador,
						GHD.razonSocial RazonSocialExportador,
						GHD.idCliente IdClienteDistribucion,
						GHD.nombreClienteConsignee NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,ghd.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						ghd.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						ghd.IdEmpresa,
						pod.farmName FarmName 
					FROM  #TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON ghd.idExportador = ex.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						LEFT JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          					ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON ghd.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE ghd.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) SV
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.IdAccion = cat.Id 
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
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega, GHD.idBodega) = @IdBodega THEN 1
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
							INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
						WHERE  GH.house IS NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1  @Consignee ='CONSIGNEE'
						FROM  GuiasHouse GH
							INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
						WHERE GH.house IS NOT NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1  @Final = 'FINAL'
						FROM  GuiasHouseDetalles GHD
							INNER JOIN #ClientesRel CLI ON CLI.id = GHD.idClienteFinal
						WHERE  fechaCreacion BETWEEN @fechaDesde AND @FechaHasta

						/* CLIENTES FINALES */
						IF @Final IS NOT NULL 
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.productoDescripcion DescripcionProducto,
								ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.idCliente IdClienteDistribucion,
								gh.idBodega,
								pc.id IdProgramacionCarrier,
								pc.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								'' Chofer,
								gh.IdEmpresa,
								pmc.valor,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								gh.idCliente,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
							FROM
								GuiasHouse GH  WITH (NOLOCK)
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GH.id = GHD.idGuiaHouse
								INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteFinal
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON GHD.id = pc.idGuiaHouseDetalle
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												gh.idCliente = pmc.idEntidad 
												AND pmc.idParametroLista = @idParametroLista
							WHERE 
								GH.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
								AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
								AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
				
						END

						 /* CLIENTES CONSIGNEE */
						IF @Consignee IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.productoDescripcion DescripcionProducto,
								ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.idCliente IdClienteDistribucion,
								gh.idBodega,
								pc.id IdProgramacionCarrier,
								pc.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								'' Chofer,
								gh.IdEmpresa,
								pmc.valor,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								gh.idCliente,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
							FROM
								GuiasHouse GH WITH (NOLOCK)
								INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH.idCliente
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								LEFT JOIN ProgramacionCarrier pc  WITH (NOLOCK) ON pc.idGuiaHouseDetalle = GHD.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												gh.idCliente = pmc.idEntidad 
												AND pmc.idParametroLista = @idParametroLista
							WHERE 
								GH.house IS NOT NULL 
								AND GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN gh.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
								AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
								AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
						END
				
						/* CLIENTES CONSOLIDADORES */
						IF @Consolidador IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.productoDescripcion DescripcionProducto,
								ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.idCliente IdClienteDistribucion,
								gh.idBodega,
								pc.id IdProgramacionCarrier,
								pc.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								'' Chofer,
								gh.IdEmpresa,
								pmc.valor,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								gh.idCliente,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH1.idCliente
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON pc.idGuiaHouseDetalle = GHD.id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												gh.idCliente = pmc.idEntidad 
												AND pmc.idParametroLista = @idParametroLista
							WHERE 
								GH1.house IS NULL 
								AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN gh.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
								AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
								AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
						END
					END
					ELSE
					BEGIN
					
						SELECT 
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							'' Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
							GH1.idCliente  idClienteConsolidador,
							gh.idGuia
						INTO  #tempNotificacion
						FROM
							NotificacionPiezasDetalle ntpd WITH (NOLOCK) 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ntpd.idGuiaHouseDetalle = GHD.id
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id = ghd.idGuiaHouse
							INNER JOIN GuiasHouse GH1 WITH (NOLOCK) ON GH.idGuia = gh1.idGuia AND GH1.house IS NULL
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON pc.idGuiaHouseDetalle = GHD.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE 
							ntPD.idNotificacionPiezas = @idNotificacion

						INSERT INTO #TempPiezasPorCarrier
							SELECT 
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.DescripcionProducto,
								ghd.FechaRecepcion,
								ghd.AltoCm,
								ghd.AnchoCm,
								ghd.LargoCm,
								ghd.AltoInch,
								ghd.AnchoInch,
								ghd.LargoInch,
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
								ghd.IdAccion,
								ghd.NoPermitirVenta,
								ghd.NroGuia,
								ghd.House,
								ghd.FechaOrigen,
								ghd.FechaDestino,
								ghd.FechaOrigenFecha,
								ghd.FechaDestinoFecha,
								ghd.IdExportador,
								GHd.IdClienteDistribucion,
								ghd.idBodega,
								ghd.IdProgramacionCarrier,
								ghd.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								ghd.Chofer,
								ghd.IdEmpresa,
								ghd.valor,
								ghd.nombreComercial,
								ghd.nombre,
								ghd.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								ghd.idCliente,
								ghd.nombreClienteConsigne
							FROM
								#tempNotificacion GHD
								INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteFinal
							WHERE 
								CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ghd.nombreClienteConsigne LIKE @nombreClienteDistribucion+'%')
								AND (ghd.idGuia = ISNULL(@idGuia, ghd.idGuia))
								AND(GHd.idExportador = ISNULL(@idExportador, GHd.idExportador))
								AND (@nombreExportador IS NULL OR ghd.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GHd.house LIKE @house+'%')
							UNION
							SELECT 
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.DescripcionProducto,
								ghd.FechaRecepcion,
								ghd.AltoCm,
								ghd.AnchoCm,
								ghd.LargoCm,
								ghd.AltoInch,
								ghd.AnchoInch,
								ghd.LargoInch,
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
								ghd.IdAccion,
								ghd.NoPermitirVenta,
								ghd.NroGuia,
								ghd.House,
								ghd.FechaOrigen,
								ghd.FechaDestino,
								ghd.FechaOrigenFecha,
								ghd.FechaDestinoFecha,
								ghd.IdExportador,
								GHd.IdClienteDistribucion,
								ghd.idBodega,
								ghd.IdProgramacionCarrier,
								ghd.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								ghd.Chofer,
								ghd.IdEmpresa,
								ghd.valor,
								ghd.nombreComercial,
								ghd.nombre,
								ghd.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								ghd.idCliente,
								ghd.nombreClienteConsigne
							FROM
								#tempNotificacion GHD
								INNER JOIN #ClientesRel CL ON CL.id = GHD.idCliente
							WHERE 
								CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ghd.nombreClienteConsigne LIKE @nombreClienteDistribucion+'%')
								AND (ghd.idGuia = ISNULL(@idGuia, ghd.idGuia))
								AND(GHd.idExportador = ISNULL(@idExportador, GHd.idExportador))
								AND (@nombreExportador IS NULL OR ghd.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GHd.house LIKE @house+'%')
							UNION
							SELECT 
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.DescripcionProducto,
								ghd.FechaRecepcion,
								ghd.AltoCm,
								ghd.AnchoCm,
								ghd.LargoCm,
								ghd.AltoInch,
								ghd.AnchoInch,
								ghd.LargoInch,
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
								ghd.IdAccion,
								ghd.NoPermitirVenta,
								ghd.NroGuia,
								ghd.House,
								ghd.FechaOrigen,
								ghd.FechaDestino,
								ghd.FechaOrigenFecha,
								ghd.FechaDestinoFecha,
								ghd.IdExportador,
								GHd.IdClienteDistribucion,
								ghd.idBodega,
								ghd.IdProgramacionCarrier,
								ghd.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								ghd.Chofer,
								ghd.IdEmpresa,
								ghd.valor,
								ghd.nombreComercial,
								ghd.nombre,
								ghd.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								ghd.idCliente,
								ghd.nombreClienteConsigne
							FROM
								#tempNotificacion GHD
								INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteConsolidador
							WHERE 
								CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ghd.nombreClienteConsigne LIKE @nombreClienteDistribucion+'%')
								AND (ghd.idGuia = ISNULL(@idGuia, ghd.idGuia))
								AND(GHd.idExportador = ISNULL(@idExportador, GHd.idExportador))
								AND (@nombreExportador IS NULL OR ghd.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GHd.house LIKE @house+'%')
					
					END

					SELECT DISTINCT
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
						ghd.AltoCm,
						ghd.AnchoCm,
						ghd.LargoCm,
						ghd.AltoInch,
						ghd.AnchoInch,
						ghd.LargoInch,
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
						ghd.IdAccion,
						ghd.NoPermitirVenta,
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						ghd.NroGuia,
						ghd.House,
						ghd.FechaOrigen,
						ghd.FechaDestino,
						ghd.fechaOrigen FechaOrigenFecha,
						ghd.fechaDestino FechaDestinoFecha,
						GHD.IdExportador,
						GHD.nombreComercial NombreComercialExportador,
						GHD.nombre NombreExportador,
						GHD.razonSocial RazonSocialExportador,
						GHD.idCliente IdClienteDistribucion,
						GHD.nombreClienteConsignee NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,ghd.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						ghd.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						ghd.IdEmpresa,
						pod.farmName FarmName 
					FROM 
						#TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON ghd.idExportador = ex.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						LEFT JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          					ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON ghd.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE ghd.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.IdAccion = cat.Id 
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
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega, GHD.idBodega) = @IdBodega THEN 1
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
						INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
					WHERE 
						GH.house IS NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1 
						@Consignee ='CONSIGNEE'
					FROM 
						GuiasHouse GH
						INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
					WHERE 
						GH.house IS NOT NULL 
						AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

					SELECT TOP 1 
						@Final = 'FINAL'
					FROM 
						GuiasHouseDetalles GHD
						INNER JOIN #ClientesRel CLI ON CLI.id = GHD.idClienteFinal
					WHERE 
						fechaCreacion BETWEEN @fechaDesde AND @FechaHasta


					/* CLIENTES FINALES */
					IF @Final IS NOT NULL 
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							'' Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
						FROM
							ProgramacionCarrier pc  WITH (NOLOCK)
							INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON 
																GHD.id = pc.idGuiaHouseDetalle 
																AND GHD.fechaCreacion BETWEEN @fechaDesde AND @FechaHasta
							INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteFinal
							INNER JOIN #idsCatalogos CATEST ON CATEST.id = ghd.estadoPieza
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE 
							pc.fechaDespacho = @fechaDespacho
							AND pc.idCarrier = @idCarrier
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@nombreClienteDistribucion IS NULL 
								OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
							AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
							AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
							AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GH.house LIKE @house+'%')
							AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
				
					END

					 /* CLIENTES CONSIGNEE */
					IF @Consignee IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							'' Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
						FROM
							GuiasHouse GH WITH (NOLOCK)
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH.idCliente
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
							INNER JOIN #idsCatalogos CATEST ON CATEST.id = ghd.estadoPieza
							INNER JOIN ProgramacionCarrier pc  WITH (NOLOCK) ON 
												pc.idGuiaHouseDetalle = GHD.id 
												AND pc.fechaDespacho = @fechaDespacho
												AND pc.idCarrier = @idCarrier
						
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE 
							GH.house IS NOT NULL 
							AND GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN gh.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@nombreClienteDistribucion IS NULL 
								OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
							AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
							AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
							AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GH.house LIKE @house+'%')
							AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
					END
				
					/* CLIENTES CONSOLIDADORES */
					IF @Consolidador IS NOT NULL
					BEGIN
						INSERT INTO #TempPiezasPorCarrier
						SELECT DISTINCT
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							'' Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
						FROM
							GuiasHouse GH1 WITH (NOLOCK)
							INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH1.idCliente
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
							INNER JOIN #idsCatalogos CATEST ON CATEST.id = ghd.estadoPieza
							INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON 
											pc.idGuiaHouseDetalle = GHD.id
											AND pc.fechaDespacho = @fechaDespacho
											AND  pc.idCarrier = @idCarrier
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE 
							GH1.house IS NULL 
							AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN gh.id = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@nombreClienteDistribucion IS NULL 
								OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
							AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
							AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
							AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GH.house LIKE @house+'%')
							AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
					END
				
					SELECT DISTINCT
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
						ghd.AltoCm,
						ghd.AnchoCm,
						ghd.LargoCm,
						ghd.AltoInch,
						ghd.AnchoInch,
						ghd.LargoInch,
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
						ghd.IdAccion,
						ghd.NoPermitirVenta,
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						ghd.NroGuia,
						ghd.House,
						ghd.FechaOrigen,
						ghd.FechaDestino,
						ghd.fechaOrigen FechaOrigenFecha,
						ghd.fechaDestino FechaDestinoFecha,
						GHD.IdExportador,
						GHD.nombreComercial NombreComercialExportador,
						GHD.nombre NombreExportador,
						GHD.razonSocial RazonSocialExportador,
						GHD.idCliente IdClienteDistribucion,
						GHD.nombreClienteConsignee NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,ghd.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						ghd.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						ghd.IdEmpresa,
						pod.farmName FarmName 
					FROM 
						#TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON ghd.idExportador = ex.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						LEFT JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          					ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON ghd.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE ghd.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.IdAccion = cat.Id 
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
							WHEN ISNULL(ubicacionesBodega.idBodega, GHD.idBodega) = @IdBodega THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
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
							INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
						WHERE 
							GH.house IS NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1 
							@Consignee ='CONSIGNEE'
						FROM 
							GuiasHouse GH
							INNER JOIN #ClientesRel CLI ON CLI.id = GH.idCliente
						WHERE 
							GH.house IS NOT NULL 
							AND fechaDestino BETWEEN @fechaDesde AND @FechaHasta

						SELECT TOP 1 
							@Final = 'FINAL'
						FROM 
							GuiasHouseDetalles GHD
							INNER JOIN #ClientesRel CLI ON CLI.id = GHD.idClienteFinal
						WHERE 
							fechaCreacion BETWEEN @fechaDesde AND @FechaHasta

						/* CLIENTES FINALES */
						IF @Final IS NOT NULL 
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.productoDescripcion DescripcionProducto,
								ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.idCliente IdClienteDistribucion,
								gh.idBodega,
								pc.id IdProgramacionCarrier,
								pc.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								'' Chofer,
								gh.IdEmpresa,
								pmc.valor,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								gh.idCliente,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
							FROM
								GuiasHouse GH  WITH (NOLOCK)
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GH.id = GHD.idGuiaHouse
								INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteFinal
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON GHD.id = pc.idGuiaHouseDetalle
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												gh.idCliente = pmc.idEntidad 
												AND pmc.idParametroLista = @idParametroLista
							WHERE 
								GH.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
								AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
								AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
				
						END

						 /* CLIENTES CONSIGNEE */
						IF @Consignee IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.productoDescripcion DescripcionProducto,
								ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.idCliente IdClienteDistribucion,
								gh.idBodega,
								pc.id IdProgramacionCarrier,
								pc.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								'' Chofer,
								gh.IdEmpresa,
								pmc.valor,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								gh.idCliente,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
							FROM
								dbo.GuiasHouse GH WITH (NOLOCK)
								INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH.idCliente
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								LEFT JOIN ProgramacionCarrier pc  WITH (NOLOCK) ON pc.idGuiaHouseDetalle = GHD.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												gh.idCliente = pmc.idEntidad 
												AND pmc.idParametroLista = @idParametroLista
							WHERE 
								GH.house IS NOT NULL 
								AND GH.fechaDestino BETWEEN @FechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN gh.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
								AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
								AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
						END
				
						/* CLIENTES CONSOLIDADORES */
						IF @Consolidador IS NOT NULL
						BEGIN
							INSERT INTO #TempPiezasPorCarrier
							SELECT DISTINCT
								ghd.id,
								ghd.idGuiaHouse, 
								ghd.CodigoBarra,
								ghd.productoDescripcion DescripcionProducto,
								ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								GH.IdExportador,
								GH.idCliente IdClienteDistribucion,
								gh.idBodega,
								pc.id IdProgramacionCarrier,
								pc.FechaDespacho, 
								ghd.RecibidoOrigen,
								ghd.RecibidoDestino,
								ghd.DespachadoDestino,
								'' Chofer,
								gh.IdEmpresa,
								pmc.valor,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial,
								ghd.idTipoDePieza,
								ghd.idClienteFinal,
								ghd.idUsuarioLog,
								ghd.idPoDetalle,
								ghd.idDetalleMercancia,
								gh.idCliente,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne
							FROM
								GuiasHouse GH1 WITH (NOLOCK)
								INNER JOIN #ClientesRel CLI WITH (NOLOCK) ON CLI.id = GH1.idCliente
								INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON pc.idGuiaHouseDetalle = GHD.id
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
												gh.idCliente = pmc.idEntidad 
												AND pmc.idParametroLista = @idParametroLista
							WHERE 
								GH1.house IS NULL 
								AND GH1.fechaDestino BETWEEN @fechaDesde AND @FechaHasta
								AND CASE
									WHEN @idGuiaHouse IS NULL THEN 1
									WHEN gh.id = @idGuiaHouse THEN 1
									ELSE 0 END = 1
								AND (ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
								AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
								AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
								AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
								AND (@nombreClienteDistribucion IS NULL 
									OR ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%')
								AND (gh.idGuia = ISNULL(@idGuia, gh.idGuia))
								AND(GH.idExportador = ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
						END
					END
					ELSE
					BEGIN
						SELECT 
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.productoDescripcion DescripcionProducto,
							ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
							gh.NroGuia,
							gh.House,
							gh.FechaOrigen,
							gh.FechaDestino,
							CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
							CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
							GH.IdExportador,
							GH.idCliente IdClienteDistribucion,
							gh.idBodega,
							pc.id IdProgramacionCarrier,
							pc.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							'' Chofer,
							gh.IdEmpresa,
							pmc.valor,
							ex.nombreComercial,
							ex.nombre,
							ex.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							gh.idCliente,
							ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
							GH1.idCliente  idClienteConsolidador,
							gh.idGuia
						INTO  #tempNotificaciones
						FROM
							NotificacionPiezasDetalle ntpd WITH (NOLOCK) 
							INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ntpd.idGuiaHouseDetalle = GHD.id
							INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id = ghd.idGuiaHouse
							INNER JOIN GuiasHouse GH1 WITH (NOLOCK) ON GH.idGuia = gh1.idGuia AND GH1.house IS NULL
							INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
							INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
							LEFT JOIN ProgramacionCarrier PC WITH (NOLOCK) ON pc.idGuiaHouseDetalle = GHD.id
							LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
											gh.idCliente = pmc.idEntidad 
											AND pmc.idParametroLista = @idParametroLista
						WHERE 
							ntPD.idNotificacionPiezas = @idNotificacion

						INSERT INTO #TempPiezasPorCarrier
						SELECT 
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.DescripcionProducto,
							ghd.FechaRecepcion,
							ghd.AltoCm,
							ghd.AnchoCm,
							ghd.LargoCm,
							ghd.AltoInch,
							ghd.AnchoInch,
							ghd.LargoInch,
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
							ghd.IdAccion,
							ghd.NoPermitirVenta,
							ghd.NroGuia,
							ghd.House,
							ghd.FechaOrigen,
							ghd.FechaDestino,
							ghd.FechaOrigenFecha,
							ghd.FechaDestinoFecha,
							ghd.IdExportador,
							GHd.IdClienteDistribucion,
							ghd.idBodega,
							ghd.IdProgramacionCarrier,
							ghd.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							ghd.Chofer,
							ghd.IdEmpresa,
							ghd.valor,
							ghd.nombreComercial,
							ghd.nombre,
							ghd.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							ghd.idCliente,
							ghd.nombreClienteConsigne
						FROM
							#tempNotificaciones GHD
							INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteFinal
						WHERE 
							(ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
							AND (@nombreClienteDistribucion IS NULL 
								OR ghd.nombreClienteConsigne LIKE @nombreClienteDistribucion+'%')
							AND (ghd.idGuia = ISNULL(@idGuia, ghd.idGuia))
							AND(GHd.idExportador = ISNULL(@idExportador, GHd.idExportador))
							AND (@nombreExportador IS NULL OR ghd.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GHd.house LIKE @house+'%')
						UNION
						SELECT 
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.DescripcionProducto,
							ghd.FechaRecepcion,
							ghd.AltoCm,
							ghd.AnchoCm,
							ghd.LargoCm,
							ghd.AltoInch,
							ghd.AnchoInch,
							ghd.LargoInch,
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
							ghd.IdAccion,
							ghd.NoPermitirVenta,
							ghd.NroGuia,
							ghd.House,
							ghd.FechaOrigen,
							ghd.FechaDestino,
							ghd.FechaOrigenFecha,
							ghd.FechaDestinoFecha,
							ghd.IdExportador,
							GHd.IdClienteDistribucion,
							ghd.idBodega,
							ghd.IdProgramacionCarrier,
							ghd.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							ghd.Chofer,
							ghd.IdEmpresa,
							ghd.valor,
							ghd.nombreComercial,
							ghd.nombre,
							ghd.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							ghd.idCliente,
							ghd.nombreClienteConsigne
						FROM
							#tempNotificaciones GHD
							INNER JOIN #ClientesRel CL ON CL.id = GHD.idCliente
						WHERE 
							(ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
							AND (@nombreClienteDistribucion IS NULL 
								OR ghd.nombreClienteConsigne LIKE @nombreClienteDistribucion+'%')
							AND (ghd.idGuia = ISNULL(@idGuia, ghd.idGuia))
							AND(GHd.idExportador = ISNULL(@idExportador, GHd.idExportador))
							AND (@nombreExportador IS NULL OR ghd.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GHd.house LIKE @house+'%')
						UNION
						SELECT 
							ghd.id,
							ghd.idGuiaHouse, 
							ghd.CodigoBarra,
							ghd.DescripcionProducto,
							ghd.FechaRecepcion,
							ghd.AltoCm,
							ghd.AnchoCm,
							ghd.LargoCm,
							ghd.AltoInch,
							ghd.AnchoInch,
							ghd.LargoInch,
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
							ghd.IdAccion,
							ghd.NoPermitirVenta,
							ghd.NroGuia,
							ghd.House,
							ghd.FechaOrigen,
							ghd.FechaDestino,
							ghd.FechaOrigenFecha,
							ghd.FechaDestinoFecha,
							ghd.IdExportador,
							GHd.IdClienteDistribucion,
							ghd.idBodega,
							ghd.IdProgramacionCarrier,
							ghd.FechaDespacho, 
							ghd.RecibidoOrigen,
							ghd.RecibidoDestino,
							ghd.DespachadoDestino,
							ghd.Chofer,
							ghd.IdEmpresa,
							ghd.valor,
							ghd.nombreComercial,
							ghd.nombre,
							ghd.razonSocial,
							ghd.idTipoDePieza,
							ghd.idClienteFinal,
							ghd.idUsuarioLog,
							ghd.idPoDetalle,
							ghd.idDetalleMercancia,
							ghd.idCliente,
							ghd.nombreClienteConsigne
						FROM
							#tempNotificaciones GHD
							INNER JOIN #ClientesRel CL ON CL.id = GHD.idClienteConsolidador
						WHERE 
							(ghd.idClienteFinal = ISNULL(@idClienteFinal,ghd.idClienteFinal))
							AND CASE
								WHEN @idGuiaHouse IS NULL THEN 1
								WHEN ghd.idGuiaHouse = @idGuiaHouse THEN 1
								ELSE 0 END = 1
							AND (@TruckId IS NULL OR GHD.truckId LIKE '%' + @TruckId + '%')
							AND (@codBarra IS NULL OR ghd.codigoBarra LIKE @codBarra+'%')
							AND (@nroPo IS NULL OR ghd.po LIKE @nroPo+'%')
							AND (@nombreClienteDistribucion IS NULL 
								OR ghd.nombreClienteConsigne LIKE @nombreClienteDistribucion+'%')
							AND (ghd.idGuia = ISNULL(@idGuia, ghd.idGuia))
							AND(GHd.idExportador = ISNULL(@idExportador, GHd.idExportador))
							AND (@nombreExportador IS NULL OR ghd.nombreComercial LIKE @nombreExportador+'%')
							AND (@house IS NULL OR GHd.house LIKE @house+'%')
					END

					SELECT DISTINCT
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
						ghd.AltoCm,
						ghd.AnchoCm,
						ghd.LargoCm,
						ghd.AltoInch,
						ghd.AnchoInch,
						ghd.LargoInch,
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
						ghd.IdAccion,
						ghd.NoPermitirVenta,
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						ghd.NroGuia,
						ghd.House,
						ghd.FechaOrigen,
						ghd.FechaDestino,
						ghd.fechaOrigen FechaOrigenFecha,
						ghd.fechaDestino FechaDestinoFecha,
						GHD.IdExportador,
						GHD.nombreComercial NombreComercialExportador,
						GHD.nombre NombreExportador,
						GHD.razonSocial RazonSocialExportador,
						GHD.idCliente IdClienteDistribucion,
						GHD.nombreClienteConsignee NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,ghd.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						ghd.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						ghd.IdEmpresa,
						pod.farmName FarmName 
					FROM 
						#TempPiezasPorCarrier ghd 
						LEFT JOIN Exportadores ex WITH (NOLOCK) ON ghd.idExportador = ex.id
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						LEFT JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          					SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          					FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          					WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          					ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON ghd.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          					SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          					FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          					WHERE ghd.id = svd.idGuiaHouseDetalle 
          					ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.IdAccion = cat.Id 
					WHERE
						(
							@estado IS NULL 
							OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
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
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
							ELSE 0 END = 1
						AND CASE 
							WHEN @IdBodega IS NULL THEN 1
							WHEN ISNULL(ubicacionesBodega.idBodega, GHD.idBodega) = @IdBodega THEN 1
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
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						gh.NroGuia,
						gh.House,
						gh.FechaOrigen,
						gh.FechaDestino,
						gh.FechaOrigenFecha,
						gh.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.idCliente IdClienteDistribucion,
						GH.nombreClienteConsigne NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,gh.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						gh.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						gh.IdEmpresa,
						pod.farmName FarmName
					FROM 
						(
							SELECT
								gh.id,
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								gh.idBodega,
								gh.IdEmpresa,
								gh.idCliente,
								gh.idGuia,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
								pmc.valor, 
								ex.id IdExportador,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										gh.idCliente = pmc.idEntidad 
										AND pmc.idParametroLista = @idParametroLista
							WHERE
								gh.idGuia = @idGuia
								AND (GH.idExportador =  ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
								AND CASE 
									WHEN @nombreClienteDistribucion IS NULL THEN 1
									WHEN ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%' THEN 1
									ELSE 0 END = 1
						
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id 
						INNER JOIN #ClientesRel CLC ON CLC.id = GHD.idClienteFinal
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						INNER JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						INNER JOIN ProgramacionCarrier pc WITH (NOLOCK) ON
															ghd.id = pc.idGuiaHouseDetalle 
															AND PC.idCarrier = @idCarrier
															AND PC.fechaDespacho = @fechaDespacho
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON gh.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE ghd.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.idCatalogoAccion = cat.Id 
					WHERE
						( ghd.idClienteFinal = ISNULL(@idClienteFinal, ghd.idClienteFinal ))
						AND(
							@estado IS NULL 
							OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR ghd.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR GHD.po LIKE '%' + @nroPo + '%')
				
						AND CASE 
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
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
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						gh.NroGuia,
						gh.House,
						gh.FechaOrigen,
						gh.FechaDestino,
						gh.FechaOrigenFecha,
						gh.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.idCliente IdClienteDistribucion,
						GH.nombreClienteConsigne NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,gh.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						gh.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						gh.IdEmpresa,
						pod.farmName FarmName
					FROM 
						(
							SELECT
								gh.id,
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								gh.idBodega,
								gh.IdEmpresa,
								gh.idCliente,
								gh.idGuia,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
								pmc.valor, 
								ex.id IdExportador,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										gh.idCliente = pmc.idEntidad 
										AND pmc.idParametroLista = @idParametroLista
							WHERE
								gh.idGuia = @idGuia
								AND (GH.idExportador =  ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
								AND CASE 
									WHEN @nombreClienteDistribucion IS NULL THEN 1
									WHEN ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%' THEN 1
									ELSE 0 END = 1
						
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id 
						INNER JOIN #ClientesRel CLC ON CLC.id = GHD.idClienteFinal
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						INNER JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON gh.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
       				  WHERE ghd.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.idCatalogoAccion = cat.Id 
					WHERE
						( ghd.idClienteFinal = ISNULL(@idClienteFinal, ghd.idClienteFinal ))
						AND(
							@estado IS NULL 
							OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR ghd.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR GHD.po LIKE '%' + @nroPo + '%')
						AND CASE 
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
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
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						gh.NroGuia,
						gh.House,
						gh.FechaOrigen,
						gh.FechaDestino,
						gh.FechaOrigenFecha,
						gh.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.idCliente IdClienteDistribucion,
						GH.nombreClienteConsigne NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,gh.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						gh.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						hl.HeaderLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						gh.IdEmpresa,
						pod.farmName FarmName
					FROM 
						(
							SELECT
								gh.id,
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								gh.idBodega,
								gh.IdEmpresa,
								gh.idCliente,
								gh.idGuia,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
								pmc.valor, 
								ex.id IdExportador,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN #ClientesRel CLC ON CLC.id = GH.idCliente
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										gh.idCliente = pmc.idEntidad 
										AND pmc.idParametroLista = @idParametroLista
							WHERE
								gh.idGuia = @idGuia
								AND (GH.idExportador =  ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
								AND CASE 
									WHEN @nombreClienteDistribucion IS NULL THEN 1
									WHEN ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id 
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						INNER JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						INNER JOIN ProgramacionCarrier pc WITH (NOLOCK) ON 
													ghd.id = pc.idGuiaHouseDetalle 
													AND PC.idCarrier = @idCarrier
													AND pc.fechaDespacho = @fechaDespacho 
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON gh.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE ghd.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN HeaderLabels hl WITH (NOLOCK) ON ghd.idHeaderLabel = hl.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.idCatalogoAccion = cat.Id 
					WHERE
						( ghd.idClienteFinal = ISNULL(@idClienteFinal, ghd.idClienteFinal ))
						AND (
							@estado IS NULL 
							OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR GHD.esPOD = @realEsPOD)
					
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR ghd.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR GHD.po LIKE '%' + @nroPo + '%')
				
						AND CASE 
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
							ELSE 0 END = 1
						AND (@nroManifiesto IS NULL OR md.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@palletLabel IS NULL OR p.pallet LIKE '%' + @palletLabel + '%')
						AND (@orden IS NULL OR sv.nroOrden LIKE '%' + @orden + '%')
						AND (@esInventario IS NULL OR ISNULL(ubicacionesBodega.areaInventario, 0) = @esInventario)
				END
				ELSE
				BEGIN
					SELECT
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						gh.NroGuia,
						gh.House,
						gh.FechaOrigen,
						gh.FechaDestino,
						gh.FechaOrigenFecha,
						gh.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.idCliente IdClienteDistribucion,
						GH.nombreClienteConsigne NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,gh.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						gh.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						gh.IdEmpresa,
						pod.farmName FarmName
					FROM 
						(
							SELECT
								gh.id,
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								gh.idBodega,
								gh.IdEmpresa,
								gh.idCliente,
								gh.idGuia,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
								pmc.valor, 
								ex.id IdExportador,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial
							FROM
								GuiasHouse gh WITH (NOLOCK)
								INNER JOIN #ClientesRel CLC ON CLC.id = GH.idCliente
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										gh.idCliente = pmc.idEntidad 
										AND pmc.idParametroLista = @idParametroLista
							WHERE
								--gh.FechaDestino BETWEEN  @fechaDesde AND @fechaHasta  
								--AND 
								gh.idGuia = @idGuia
								AND (GH.idExportador =  ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
								AND CASE 
									WHEN @nombreClienteDistribucion IS NULL THEN 1
									WHEN ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id 
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						INNER JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON gh.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE ghd.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.idCatalogoAccion = cat.Id 
					WHERE
						( ghd.idClienteFinal = ISNULL(@idClienteFinal, ghd.idClienteFinal ))
						AND (
							@estado IS NULL 
							OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR ghd.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR GHD.po LIKE '%' + @nroPo + '%')
				
						AND CASE 
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
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
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						gh.NroGuia,
						gh.House,
						gh.FechaOrigen,
						gh.FechaDestino,
						gh.FechaOrigenFecha,
						gh.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.idCliente IdClienteDistribucion,
						GH.nombreClienteConsigne NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,gh.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						gh.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						gh.IdEmpresa,
						pod.farmName FarmName
					FROM 
						(
							SELECT
								gh.id,
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								gh.idBodega,
								gh.IdEmpresa,
								gh.idCliente,
								gh.idGuia,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
								pmc.valor, 
								ex.id IdExportador,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial
							FROM
								GuiasHouse gh1 WITH (NOLOCK)
								INNER JOIN #ClientesRel CLC ON CLC.id = GH1.idCliente
								INNER JOIN GuiasHouse gh WITH (NOLOCK) ON GH.idGuia = GH1.idGuia
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										gh.idCliente = pmc.idEntidad 
										AND pmc.idParametroLista = @idParametroLista
							WHERE
								GH1.house IS NULL 
								-- AND gh1.FechaDestino BETWEEN @fechaDesde AND @fechaHasta  
								AND gh1.idGuia = @idGuia
								AND (GH.idExportador =  ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
								AND CASE 
									WHEN @nombreClienteDistribucion IS NULL THEN 1
									WHEN ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id 
						INNER JOIN ProgramacionCarrier pc WITH (NOLOCK) ON 
																ghd.id = pc.idGuiaHouseDetalle 
																AND PC.idCarrier = @idCarrier
																AND pc.fechaDespacho = @fechaDespacho
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						INNER JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON gh.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE ghd.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.idCatalogoAccion = cat.Id 
					WHERE
						( ghd.idClienteFinal = ISNULL(@idClienteFinal, ghd.idClienteFinal ))
						AND (
							@estado IS NULL 
							OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR ghd.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR GHD.po LIKE '%' + @nroPo + '%')
						AND CASE 
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
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
						ghd.id,
						ghd.idGuiaHouse, 
						ghd.CodigoBarra,
						ghd.productoDescripcion DescripcionProducto,
						ISNULL(ghd.fechaRecepcion, @fechaSinHora) FechaRecepcion,
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
						tp.id IdTipoPieza,
						tp.TipoPieza,
						CLF.id IdClienteFinal,
						ISNULL(clf.nombreClienteFinal, clf.nombre) NombreClienteFinal,
						u.nombre Nombre,
						gh.NroGuia,
						gh.House,
						gh.FechaOrigen,
						gh.FechaDestino,
						gh.FechaOrigenFecha,
						gh.FechaDestinoFecha,
						GH.IdExportador,
						GH.nombreComercial NombreComercialExportador,
						GH.nombre NombreExportador,
						GH.razonSocial RazonSocialExportador,
						GH.idCliente IdClienteDistribucion,
						GH.nombreClienteConsigne NombreClienteDistribucion,
						ISNULL(ubicacionesBodega.idBodega,gh.idBodega) IdBodega,
						ISNULL(bodegaPieza.nombre,bodegaGuia.nombre) NombreBodega,
						gh.valor CodigoClienteInventario, 
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
						pc.id IdProgramacionCarrier,
						pc.FechaDespacho,
						t.id IdCarrier,
						t.codigoMiami CodigoCarrier,
						t.nombre NombreCarrier,
						md.NroManifiesto,
						sv.nroOrden Orden,
						sv.fechaSolicitud FechaOrden,
						p.pallet PalletLabel,
						'' EstadoCarrier,
						ghd.RecibidoOrigen,
						ghd.RecibidoDestino,
						ghd.DespachadoDestino,
						md.id IdManifiesto,
						'' Chofer,
						cat.Nombre AccionNombre,
						cat.NombreIngles AccionNombreIngles,
						gh.IdEmpresa,
						pod.farmName FarmName
					FROM 
						(
							SELECT
								gh.id,
								gh.NroGuia,
								gh.House,
								gh.FechaOrigen,
								gh.FechaDestino,
								CONVERT(DATE, gh.fechaOrigen) FechaOrigenFecha,
								CONVERT(DATE, gh.fechaDestino) FechaDestinoFecha,
								gh.idBodega,
								gh.IdEmpresa,
								gh.idCliente,
								gh.idGuia,
								ISNULL(cld.nombreClienteFinal, cld.nombre) nombreClienteConsigne,
								pmc.valor, 
								ex.id IdExportador,
								ex.nombreComercial,
								ex.nombre,
								ex.razonSocial
							FROM
								GuiasHouse gh1 WITH (NOLOCK)
								INNER JOIN #ClientesRel CLC ON CLC.id = GH1.idCliente
								INNER JOIN GuiasHouse gh WITH (NOLOCK) ON GH.idGuia = GH1.idGuia
								INNER JOIN Exportadores ex WITH (NOLOCK) ON gh.idExportador = ex.id
								INNER JOIN Clientes cld WITH (NOLOCK) ON gh.idCliente = cld.id 
								LEFT JOIN ParametrosCatalogos pmc WITH (NOLOCK) ON 
										gh.idCliente = pmc.idEntidad 
										AND pmc.idParametroLista = @idParametroLista
							WHERE
								GH1.house IS NULL 
								AND gh1.idGuia = @idGuia
								AND (GH.idExportador =  ISNULL(@idExportador, GH.idExportador))
								AND (@nombreExportador IS NULL OR ex.nombreComercial LIKE @nombreExportador+'%')
								AND (@house IS NULL OR GH.house LIKE @house+'%')
								AND CASE 
									WHEN @nombreClienteDistribucion IS NULL THEN 1
									WHEN ISNULL(cld.nombreClienteFinal, cld.nombre) LIKE @nombreClienteDistribucion+'%' THEN 1
									ELSE 0 END = 1
						) GH 
						INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id 
						INNER JOIN TiposDePieza tp WITH (NOLOCK) ON ghd.idTipoDePieza = tp.id
						INNER JOIN Clientes clf WITH (NOLOCK) ON ghd.idClienteFinal = clf.id
						INNER JOIN Usuarios u WITH (NOLOCK) ON ghd.idUsuarioLog = u.id
						LEFT JOIN PoDetalles pod ON ghd.idPoDetalle = pod.id
						LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON ghd.id = dd.idGuiaHouseDetalle
						LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
						LEFT JOIN DetalleMercancias dm WITH (NOLOCK) ON ghd.idDetalleMercancia = dm.id
						LEFT JOIN UbicacionPiezas up WITH (NOLOCK) ON ghd.id = up.idGuiaHouseDetalle 
						OUTER APPLY (
          				  SELECT TOP 1 pinv.id, checkInv.estado, pinv.fechaCambio, checkInv.numero 
          				  FROM PiezasInventariadas pinv
            				LEFT JOIN ChequeoInventario checkInv ON pinv.IdChequeoInventario = checkInv.id 
          				  WHERE pinv.IdGuiaHouseDetalle=ghd.id 
          				  ORDER BY pinv.fechaCambio DESC
        				) AS chekInventario
						LEFT JOIN Ubicaciones ub WITH (NOLOCK) ON up.idUbicacion = ub.id 
						LEFT JOIN UbicacionesBodega ubicacionesBodega WITH (NOLOCK) ON ub.idUbicacionBodega = ubicacionesBodega.id 
						LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON gh.idBodega = bodegaGuia.id 
						LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 				
						LEFT JOIN ProgramacionCarrier pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle 
						LEFT JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id 
						LEFT JOIN ProgramacionManifiesto pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
						LEFT JOIN ManifiestosDespacho md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id 
						OUTER APPLY (
          				  SELECT TOP 1 
								svc.nroOrden, svc.fechaSolicitud, svc.tipoVenta, svd.tipoPieza
          				  FROM SolicitudDeVentaDetalles svd 
            				LEFT JOIN SolicitudDeVenta svc ON svd.idSolicitud = svc.id 
          				  WHERE ghd.id = svd.idGuiaHouseDetalle 
          				  ORDER BY svc.fechaSolicitud DESC
        				) sv
						LEFT JOIN PalletsDetalles pd WITH (NOLOCK) ON ghd.id = pd.idGuiasHouseDetalle
						LEFT JOIN Pallets p WITH (NOLOCK) ON pd.idPallet = p.id 
						LEFT JOIN Catalogos cat WITH (NOLOCK) ON ghd.idCatalogoAccion = cat.Id 
					WHERE
						( ghd.idClienteFinal = ISNULL(@idClienteFinal, ghd.idClienteFinal ))
						AND (
							@estado IS NULL 
							OR GHD.estadoPieza IN (SELECT id FROM #idsCatalogos) 
						)
						AND (@esPOD IS NULL OR GHD.esPOD = @realEsPOD)
						AND CASE 
							WHEN @esVendida IS NULL OR @realEsVendida = 0  THEN 1
							WHEN sv.fechaSolicitud IS NOT NULL THEN 1
							ELSE 0 END = 1
						AND (@codBarra IS NULL OR ghd.codigoBarra LIKE '%' + @codBarra + '%')
						AND (@nroPo IS NULL OR GHD.po LIKE '%' + @nroPo + '%')
						AND CASE 
							WHEN @nombreClienteFinal IS NULL THEN 1
							WHEN ISNULL(clf.nombreClienteFinal, clf.nombre) LIKE @nombreClienteFinal+'%' THEN 1
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
 exec [pro_ConsultarCodigoBarrasClientes] '20230720', '20230724','CLI013680'
 exec [pro_ConsultarCodigoBarrasClientes] 'EMP014', '20230201', '20230204', 'PONTE'

 exec dbo.pro_ConsultarCodigoBarrasClientes 
	@fechaDesde='20221205',
	@fechaHasta='20231205'
	,@IdCliente=N'CLI013680',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>
	<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<string>PENDING</string>
	</ArrayOfString>',
	@idGuia=N'GUI011367313',
	@tipoCliente=N'CONSOLIDADO'

 exec dbo.pro_ConsultarCodigoBarrasClientes 
 @fechaDesde='20221125',@fechaHasta='20231125',
 @idsClienteConsigne=NULL,
 @idsClienteDistribucion=NULL,
 @tipoCliente='CONSOLIDADO',
 @idCliente='CLI013680',
 @idsClienteFinal=NULL,@nombreExportador=NULL,@nombreClienteDistribucion=NULL,
 @nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=NULL,@orden=NULL,
 @nroManifiesto=NULL,@palletLabel=NULL,@idGuia=N'GUI011359631',@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL

 exec dbo.pro_ConsultarCodigoBarrasClientes 
 @fechaDesde='2023-01-17 00:00:00',
 @fechaHasta='2024-01-17 00:00:00',
 @IdCliente=N'CLI013680',
 @nombreExportador=NULL,
 @nombreClienteDistribucion=NULL,
 @nombreClienteFinal=NULL,
 @house=NULL,@nroPo=NULL,
 @codBarra=NULL,
 @estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>RECEIVED WH</string>
</ArrayOfString>',
@orden=NULL,
@nroManifiesto=NULL,
@palletLabel=NULL,
@idGuia=N'GUI011386792',
@tipoCliente=N'CONSOLIDADO',
@idExportador=NULL,
@idClienteFinal=N'CLI0518638',
@esPOD=0,
@idCarrier=NULL,
@idBodega=NULL,
@fechaDespacho=NULL,@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20231021',
@fechaHasta='20231021',
@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,
@idGuia=N'2310200R0KDWUNGK',
@tipoCliente=N'CONSOLIDADO',
@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=0,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20231020',
@fechaHasta='20231022',
@IdCliente=N'CLI013680'


exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230120'
,@fechaHasta='20240120',
@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>RECEIVED WH</string>
</ArrayOfString>',@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,
@idGuia=N'GUI011386792',
@tipoCliente=N'CONSOLIDADO',
@idExportador=NULL,@idClienteFinal=N'CLI0419130',@esPOD=0,
@esVendida=1,@idCarrier=NULL,@idBodega=NULL,
@fechaDespacho=NULL,@truckId=NULL


exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230120',
@fechaHasta='20240120',
@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,
@house=NULL,@nroPo=NULL,@codBarra=NULL,
@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,
@idGuia=N'GUI011386792',@tipoCliente=N'CONSOLIDADO',
@idExportador=NULL,@idClienteFinal=NULL,@esPOD=0,
@esVendida=0,
@idCarrier=NULL,
@idBodega=NULL,
@fechaDespacho=NULL,@truckId=NULL


exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20231016',
@fechaHasta='20231023',
@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,
@codBarra=NULL,
@estado=NULL,
@orden=NULL,
@nroManifiesto=NULL,@palletLabel=NULL,
@idGuia='GUI071395352',
@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,
@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230123',
@fechaHasta='20240123',
@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>DISPATCHED WH</string>
</ArrayOfString>',
@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,
@idGuia=N'GUI011385040',
@tipoCliente=N'CONSOLIDADO',
@idExportador=NULL,
@idClienteFinal=N'CLI0517203',
@esPOD=0,
@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,@truckId=NULL


exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230123',
@fechaHasta='20240123',
@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>DISPATCHED WH</string>
</ArrayOfString>',@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,
@idGuia=N'GUI011382510',@tipoCliente=N'CONSOLIDADO',
@idExportador=NULL,@idClienteFinal=NULL,@esPOD=0,
@esVendida=0,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230201',@fechaHasta='20240201',@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>PENDING</string>
</ArrayOfString>',
@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'rhYaa8T6',@idBodega=N'LXgyot5M',@fechaDespacho='20231101',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes @fechaDesde='20230201',@fechaHasta='20240201',
@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,
@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'rhYaa8T6',@idBodega=N'LXgyot5M',
@fechaDespacho='20231101',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230202',@fechaHasta='20240202',@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>RECEIVED WH</string>
</ArrayOfString>',@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=N'8MzNjSzrP6sE',@idBodega=N'LXgyot5M',
@fechaDespacho='20231102',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes
@fechaDesde='20230202',@fechaHasta='20240202',@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>RECEIVED WH</string>
</ArrayOfString>',@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=N'8MzNjSzrP6sE',@idBodega=N'LXgyot5M',
@fechaDespacho='20231102',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes @fechaDesde='20230202',@fechaHasta='20240202',@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'Da5hRzHe',@idBodega=N'LXgyot5M',@fechaDespacho='20231102',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes @fechaDesde='20230202',@fechaHasta='20240202',@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'Da5hRzHe',@idBodega=N'LXgyot5M',@fechaDespacho='20231102',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230202',@fechaHasta='20240202',
@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>PENDING</string>
</ArrayOfString>',@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=N'CLI015758',@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'OpxdPHsa',@idBodega=N'LXgyot5M',@fechaDespacho='20231102',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230202',@fechaHasta='20240202',
@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>PENDING</string>
</ArrayOfString>',@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=N'CLI015758',@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'OpxdPHsa',@idBodega=N'LXgyot5M',@fechaDespacho='20231102',@truckId=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230202',@fechaHasta='20240202',
@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,
@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,
@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,
@idClienteFinal=N'CLI015758',@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'OpxdPHsa',@idBodega=N'LXgyot5M',@fechaDespacho='20231102',@truckId=NULL


exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20230211',
@fechaHasta='20240211',
@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NUL
L,
@idClienteFinal=N'CLI0420241',
@esPOD=NULL,@esVendida=NULL,
@idCarrier=N'SK9sUPDYF1E2',
@idBodega=N'QK6s23du',
@fechaDespacho='20230901',
@truckId=NULL,
@idManifiesto='B6CDA485-3F09-4354-8390-5682648894FE'

exec dbo.pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20231105',
@fechaHasta='20231112',
@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>PENDING</string>
  <string>RECEIVED DR</string>
  <string>RECEIVED WH</string>
  <string>STANDBY</string>
</ArrayOfString>',
@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,
@fechaDespacho=NULL,@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL


exec dbo.pro_ConsultarCodigoBarrasClientes @fechaDesde='20231124',@fechaHasta='20231125',@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,@estado=N'<?xml version
="1.0" encoding="utf-16"?>
<ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <string>PENDING</string>
  <string>RECEIVED DR</string>
  <string>RECEIVED WH</string>
  <string>STANDBY</string>
</ArrayOfString>',@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL

exec dbo.pro_ConsultarCodigoBarrasClientes @fechaDesde='20231124',@fechaHasta='20231125',@IdCliente=N'CLI013680',@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL

, @esInventario = 0

exec pro_ConsultarCodigoBarrasClientes @fechaDesde='20231124',@fechaHasta='20231125',@IdCliente=N'CLI0124909',
		@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
		@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,
		@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,
		@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL, @idNotificacion='72d63896-b579-416b-9cec-1bcd00865a2e'	



exec pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20231124',@fechaHasta='20231125',@IdCliente=N'CLI0116742',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,
@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,
@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL, 
@idNotificacion='340DEA7B-F5C8-4FFE-BD07-5B12D38268E0'	

exec pro_ConsultarCodigoBarrasClientes
@fechaDesde='20231124',@fechaHasta='20231125',@IdCliente=N'CLI0116742',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,
@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,
@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL, 
@idNotificacion='DB462A4C-B184-4840-A51C-594F399493CE'	

exec pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20231124',@fechaHasta='20231125',@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,
@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,
@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL, 
@idNotificacion='80B03344-9C8B-4134-9FE3-684CB9EC2940'	

exec pro_ConsultarCodigoBarrasClientes 
@fechaDesde='20231124',@fechaHasta='20231125',@IdCliente=N'CLI013680',
@nombreExportador=NULL,@nombreClienteDistribucion=NULL,@nombreClienteFinal=NULL,@house=NULL,@nroPo=NULL,@codBarra=NULL,
@estado=NULL,@orden=NULL,@nroManifiesto=NULL,@palletLabel=NULL,@idGuia=NULL,@tipoCliente=NULL,@idExportador=NULL,
@idClienteFinal=NULL,@esPOD=NULL,@esVendida=NULL,@idCarrier=NULL,@idBodega=NULL,@fechaDespacho=NULL,
@truckId=NULL,@idManifiesto=NULL,@idGuiaHouse=NULL, 
@idNotificacion='06A03F7D-EE20-4687-AE69-A678E52CBB1D'	
*/