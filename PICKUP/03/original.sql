USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_modulo_DespachoPickup]    Script Date: 27/03/2026 09:23:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
VERSION		AUTOR				FECHA			HU			CAMBIO
1			Jesús Yandún		11/01/2021					Extrae información para modulo de pickup
2			Jonathan Merino		09/04/2021					se modifica listado para devolver TipoManifiesto en base al parametro del cliente Consignee
3			Jonathan Merino		10/06/2021					se retorna documentoDes.modificado para validar manifiesto modificado y pintar de color rojo la nube
4			Luchin				05/08/2021					No agrupar por totales, house, idGuiaHouse - No hacer join con DocumentoDespacho - No hacer join con Usuarios - Remover campos no usados
5			Jonathan Merino		25/08/2021			  		modificacion del listado para mostrar en pendientes piezas que no tengan manifiesto o cuyo manifiesto no se EPOD
6			Jonathan Merino		01/10/2021			  		modificacion para filtrar informacion por pallet
7			Jonathan Merino		04/11/2021			  		modificacion para agrupar por orden de venta y total de picking para estado sold
8			Saul Mendez			27/12/2021	  				se agrega los campos de carrier
9			Saul Mendez			30/12/2021		  			Mostrar Bodega de acuerdo con la ubicación de la pieza
10			Luchin				15/04/2022		  			Mostrar Bodega de acuerdo con la ubicación de la pieza
11			Luchin / Paty		27/12/2022		15337		Mejoras SP
12			Jose Ganchozo		30/05/2023		25674		Agregar columnas despachadoDestino y totalPickingLoading
13          Jean Martillo		24/11/2023      29121		Agregar a la suma de piezas cuando es lost y short
14			Jose Ganchozo		27/11/2023		33811		Cambiar el filtro a la primera consulta tabla #TMP_PROGRAM de numero po
15			Oscar Yunda			19/12/2023		CC33054		Se modifica el listado para obtener el idTE de ProgramacionTE y el IdPais de Cliente y IdPais Cliente Final
16			Fernando Ordoñez	13/09/2024		HU 41334	Agregar inventario
17			Jose Ganchozo		29-11-2024		Bug-46654	Se corrige la logica para las piezas que son de inventario
18			Ismael Flores		06-12-2024		HU 41334	Se aplica OUTER APPLY para la consulta de idDocumento = 'DOC052395'
*/
ALTER   PROCEDURE [dbo].[pro_modulo_DespachoPickup]
(
    @nroDocument VARCHAR(32) = NULL,
    @po VARCHAR(64) = NULL,
    @Consignee NVARCHAR(512) = NULL,
    @status VARCHAR(32) = NULL,
    @nroManifiesto VARCHAR(32) = NULL,
    @barcode VARCHAR(32) = NULL,
    @supplier NVARCHAR(512) = NULL,
    @idEmpresa VARCHAR(16),
    @consulta INT,
	@fechaDesde INT,
	@palletLabel VARCHAR(16) = NULL
)
AS
BEGIN
	BEGIN TRY
		DECLARE @fechaDespaho DATETIME = DATEADD(MM, -@fechaDesde, GETDATE()),
				@idParametroDelivery VARCHAR(16),
				@idParametroTipo VARCHAR(16)

		CREATE TABLE #TablaAgrupacionGuiasPickUp
		(
			idManifiesto		UNIQUEIDENTIFIER,
			nroManifiesto		VARCHAR(32),	
			idClienteFinal		VARCHAR(32),
			nombreClienteFinal	NVARCHAR(512),		
			idBodega			VARCHAR(32),
			nombreBodega		NVARCHAR(512),		
			idCarrier			VARCHAR(32),				
			truckId				VARCHAR(16),
			fechaDespacho		DATETIME,
			valor				VARCHAR(1024),
			totalPiezas			INT,
			totalDespachado		INT,
			totalStandBy		INT,
			totalHold			INT,
			totalPending		INT,
			totalRecibido		INT,
			totalShort			INT,
			EsPod				BIT NOT NULL DEFAULT 0,
			ordenVenta			VARCHAR(16) NULL,
			totalPicking		INT,
			idOrdenVenta		UNIQUEIDENTIFIER,
			nombreCarrier		NVARCHAR(512),
			codigoCarrier		VARCHAR(32),
			totalPickingLoading INT,
			idPaisCliente		VARCHAR(16),
			idPaisAlt			VARCHAR(16),
			idTEGuid			UNIQUEIDENTIFIER NULL,
			esInventario		BIT
		);  

		SELECT @idParametroDelivery = id 
		FROM ParametrosLista parametroLista WITH (NOLOCK) 
		WHERE parametroLista.codigo = 'EsDelivery'
			AND parametroLista.idEmpresa = @idEmpresa;

		SELECT @idParametroTipo = id 
		FROM ParametrosLista parametroLista WITH (NOLOCK) 
		WHERE parametroLista.codigo = 'TipoManifiestoDespacho'
			AND parametroLista.idEmpresa = @idEmpresa;

		SELECT C.idEntidad, C.codigo
		INTO #TMP_CodigosRelacionSistemas
		FROM CodigosRelacionSistemas C WITH (NOLOCK) 
		WHERE C.tipoEntidad = 'CARRIER' 
			AND C.idSistemaEntidad = 100;

		SELECT pc.id,
		t.id idCarrier,
		pc.fechaDespacho,
		t.nombre nombreTransporte,
		ghd.id idGuiaHouseDetalle,
		ghd.idGuiaHouse,
		ghd.idPoDetalle,
		ghd.codigoBarra,
		ghd.estadoPieza,
		ghd.idClienteFinal,
		ghd.truckId,
		ghd.despachadoDestino,
		pc.idUsuarioLogPicking,
		te.idTE
		INTO #TMP_PROGRAM
		FROM ProgramacionCarrier pc WITH (NOLOCK) 		
			INNER JOIN Transportes t WITH (NOLOCK) ON pc.idCarrier = t.id
			INNER JOIN ParametrosCatalogos parametro WITH (NOLOCK) ON t.idTransportePrincipal = parametro.idEntidad AND parametro.idParametroLista = @idParametroDelivery AND parametro.valor = 'NO'
			INNER JOIN GuiasHouseDetalles ghd WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle
			LEFT JOIN ProgramacionTe te WITH (NOLOCK) ON pc.id = te.idProgramacionCarrier  
		WHERE pc.fechaDespacho > @fechaDespaho
			AND (@po IS NULL OR ghd.po LIKE @po + '%')
	
		IF(@nroDocument IS NULL AND @po IS NULL AND @Consignee IS NULL AND @nroManifiesto IS NULL AND @supplier IS NULL AND @barcode IS NULL AND @PalletLabel IS NULL)
		BEGIN

			INSERT INTO #TablaAgrupacionGuiasPickUp 
			SELECT 
			manifiesto.id, 
			manifiesto.nroManifiesto,
			progra.idClienteFinal, 
			ISNULL (cl.nombreClienteFinal, cl.nombre) NombreClienteFinal,
			ISNULL(ub.idBodega, house.idBodega) idBodega, 
			ISNULL(bodegaPieza.nombre, bodegaGuia.nombre) nombreBodega,
			progra.idCarrier, 		
			progra.truckId, 
			progra.fechaDespacho ,
			parametroCat.valor, 
			COUNT(progra.estadoPieza),
			SUM(IIF(progra.estadoPieza = 'DISPATCHED WH', 1, 0)),
			SUM(IIF(progra.estadoPieza = 'STANDBY', 1, 0)),
			SUM(IIF(progra.estadoPieza = 'HOLD', 1, 0)),
			SUM(IIF(progra.estadoPieza = 'PENDING', 1, 0)),
			SUM(IIF(progra.estadoPieza = 'RECEIVED WH', 1, 0)),
			SUM(IIF(progra.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),
			ISNULL(dcd.esPOD,0),
			svc.nroOrden,
			SUM(IIF(svc.picking = 1, 1, 0)),
			svc.id,
			progra.nombreTransporte,
			T1.codigo,
			SUM(IIF(progra.idUsuarioLogPicking IS NOT NULL, 1, 0)) totalPickingLoading,
			paisClInfoFinal.id idPaisCliente,
			paCl.id idPaisAlt,
			progra.idTE idTEGuid,
			CASE 
				WHEN svc.tipoVenta < 4 THEN 1 
				WHEN svc.tipoVenta = 5 AND svc.tipoPieza = 1  THEN 1 
				ELSE 0
			END esInventario
			FROM #TMP_PROGRAM progra		
				INNER JOIN #TMP_CodigosRelacionSistemas T1  ON progra.idCarrier = T1.idEntidad
				INNER JOIN GuiasHouse gh WITH (NOLOCK) ON progra.idGuiaHouse = gh.id
				INNER JOIN Clientes cl WITH (NOLOCK) ON progra.idClienteFinal = cl.id
				INNER JOIN dbo.Paises paCl ON cl.idPais = paCl.id  
				CROSS APPLY 
				(   
					SELECT G.idCliente, idBodega
					FROM GuiasHouse G WITH (NOLOCK)
					WHERE progra.idGuiaHouse  = G.id 
				) house  
				LEFT JOIN ParametrosCatalogos parametroCat WITH (NOLOCK) ON parametroCat.idEntidad = house.idCliente AND parametroCat.idParametroLista = @idParametroTipo
				LEFT JOIN ProgramacionManifiesto progMani WITH (NOLOCK) ON progra.id = progMani.idProgramacionCarrier
				LEFT JOIN ManifiestosDespacho manifiesto WITH (NOLOCK) ON progMani.idManifiestoDespacho = manifiesto.id
				--LEFT JOIN DocumentosDespacho dcd WITH (NOLOCK) ON manifiesto.id = dcd.idManifiesto AND dcd.idDocumento = 'DOC052395'
				OUTER APPLY (
					SELECT TOP 1 DD.EsPod
					FROM DocumentosDespacho DD WITH (NOLOCK)
					WHERE DD.idManifiesto = manifiesto.id 
					AND DD.idDocumento = 'DOC052395'
					ORDER BY EsPod DESC
				) dcd
				LEFT JOIN UbicacionPiezas ubicacionPiezas WITH (NOLOCK) ON progra.idGuiaHouseDetalle = ubicacionPiezas.idGuiaHouseDetalle
				LEFT JOIN Ubicaciones ubicaciones WITH (NOLOCK) ON ubicacionPiezas.idUbicacion = ubicaciones.id
				LEFT JOIN UbicacionesBodega ub WITH (NOLOCK) ON ubicaciones.idUbicacionBodega = ub.id
				LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON house.idBodega = bodegaGuia.id
				LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ub.idBodega = bodegaPieza.id
				LEFT JOIN 
				(		
					SELECT progra.idGuiaHouseDetalle,
					solicitud.id, solicitud.nroOrden, 
					svd.picking,
					solicitud.fechaSolicitud ,
					ROW_NUMBER() OVER (PARTITION BY progra.idGuiaHouseDetalle ORDER BY solicitud.fechaSolicitud DESC) rown,
					solicitud.tipoVenta,
					svd.tipoPieza
					FROM #TMP_PROGRAM progra 
					INNER JOIN SolicitudDeVentaDetalles svd WITH (NOLOCK) ON progra.idGuiaHouseDetalle = svd.idGuiaHouseDetalle
					INNER JOIN SolicitudDeVenta solicitud WITH (NOLOCK) ON solicitud.id = svd.idSolicitud 
				) svc ON progra.idGuiaHouseDetalle = svc.idGuiaHouseDetalle AND svc.rown = 1
				LEFT JOIN InformacionClienteFinal infoClFinal ON cl.id = infoClFinal.id       
				LEFT JOIN Paises paisClInfoFinal ON infoClFinal.idPais = paisClInfoFinal.id
			WHERE @idEmpresa IS NULL OR gh.idEmpresa = @idEmpresa
			GROUP BY 
				manifiesto.id, 
				manifiesto.nroManifiesto, 
				progra.idClienteFinal, 
				ISNULL (cl.nombreClienteFinal,cl.nombre) ,
				ISNULL(ub.idBodega, house.idBodega) , 
				ISNULL(bodegaPieza.nombre, bodegaGuia.nombre) ,
				progra.idCarrier, 
				progra.truckId, 
				progra.fechaDespacho, 
				parametroCat.valor,
				dcd.esPOD,
				svc.nroOrden,
				svc.id,
				PROGRA.nombreTransporte,
				T1.codigo,
				progra.despachadoDestino,
				progra.idUsuarioLogPicking,
				paisClInfoFinal.id,
				paCl.id,
				progra.idTE,
				CASE 
					WHEN svc.tipoVenta < 4 THEN 1 
					WHEN svc.tipoVenta = 5 AND svc.tipoPieza = 1  THEN 1 
					ELSE 0 
				END;
		END
		ELSE
		BEGIN
			INSERT INTO #TablaAgrupacionGuiasPickUp 
			SELECT 
				manifiesto.id, 
				manifiesto.nroManifiesto,
				progra.idClienteFinal, 
				ISNULL (cl.nombreClienteFinal, cl.nombre) NombreClienteFinal,
				ISNULL(ub.idBodega, house.idBodega) idBodega, 
				ISNULL(bodegaPieza.nombre, bodegaGuia.nombre) nombreBodega,
				progra.idCarrier, 		
				progra.truckId, 
				progra.fechaDespacho ,
				parametroCat.valor, 
				COUNT(progra.estadoPieza),
				SUM(IIF(progra.estadoPieza = 'DISPATCHED WH', 1, 0)),
				SUM(IIF(progra.estadoPieza = 'STANDBY', 1, 0)),
				SUM(IIF(progra.estadoPieza = 'HOLD', 1, 0)),
				SUM(IIF(progra.estadoPieza = 'PENDING', 1, 0)),
				SUM(IIF(progra.estadoPieza = 'RECEIVED WH', 1, 0)),
				SUM(IIF(progra.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),		
				ISNULL(dcd.esPOD,0),
				svc.nroOrden,
				SUM(IIF(svc.picking = 1, 1, 0)),
				svc.id,
				PROGRA.nombreTransporte,
				T1.codigo, 
				SUM(IIF(progra.idUsuarioLogPicking IS NOT  NULL, 1, 0)) totalPickingLoading,
				paisClInfoFinal.id idPaisCliente,
				paCl.id idPaisAlt,
				progra.idTE idTEGuid,
				CASE 
					WHEN svc.tipoVenta < 4 THEN 1 
					WHEN svc.tipoVenta = 5 AND svc.tipoPieza = 1  THEN 1
					ELSE 0 
				END esInventario
			FROM #TMP_PROGRAM progra		
				INNER JOIN #TMP_CodigosRelacionSistemas T1 ON progra.idCarrier = T1.idEntidad
				INNER JOIN GuiasHouse gh WITH (NOLOCK) ON progra.idGuiaHouse = gh.id
				INNER JOIN Clientes cl WITH (NOLOCK) ON progra.idClienteFinal = cl.id	
				INNER JOIN dbo.Paises paCl ON cl.idPais = paCl.id   
				CROSS APPLY 
				(   
					SELECT G.idCliente, idBodega, idExportador, nroGuia
					FROM GuiasHouse G WITH (NOLOCK)
					WHERE progra.idGuiaHouse  = G.id 
				) house  
				LEFT JOIN dbo.PalletsDetalles pld WITH (NOLOCK) ON progra.idGuiaHouseDetalle = pld.idGuiasHouseDetalle
				LEFT JOIN dbo.Pallets pal WITH (NOLOCK) ON pld.idPallet = pal.id
				LEFT JOIN ParametrosCatalogos parametroCat WITH (NOLOCK) ON parametroCat.idEntidad = house.idCliente AND parametroCat.idParametroLista = @idParametroTipo
				LEFT JOIN ProgramacionManifiesto progMani WITH (NOLOCK) ON progra.id = progMani.idProgramacionCarrier
				LEFT JOIN manifiestosDespacho manifiesto WITH (NOLOCK) ON progMani.idManifiestoDespacho = manifiesto.id
				--LEFT JOIN DocumentosDespacho dcd WITH (NOLOCK) ON manifiesto.id = dcd.idManifiesto AND dcd.idDocumento = 'DOC052395'
				OUTER APPLY (
					SELECT TOP 1 DD.EsPod
					FROM DocumentosDespacho DD WITH (NOLOCK)
					WHERE DD.idManifiesto = manifiesto.id 
					AND DD.idDocumento = 'DOC052395'
					ORDER BY EsPod DESC
				) dcd
				LEFT JOIN UbicacionPiezas ubicacionPiezas WITH (NOLOCK) ON progra.idGuiaHouseDetalle = ubicacionPiezas.idGuiaHouseDetalle
				LEFT JOIN Ubicaciones ubicaciones WITH (NOLOCK) ON ubicacionPiezas.idUbicacion = ubicaciones.id
				LEFT JOIN UbicacionesBodega ub WITH (NOLOCK) ON ubicaciones.idUbicacionBodega = ub.id
				LEFT JOIN Bodegas bodegaGuia WITH (NOLOCK) ON house.idBodega = bodegaGuia.id
				LEFT JOIN Bodegas bodegaPieza WITH (NOLOCK) ON ub.idBodega = bodegaPieza.id
				LEFT JOIN 
				(		
					SELECT progra.idGuiaHouseDetalle,
					solicitud.id, solicitud.nroOrden, 
					solicitudDetalle.picking,
					solicitud.fechaSolicitud ,
					ROW_NUMBER() OVER (PARTITION BY progra.idGuiaHouseDetalle ORDER BY solicitud.fechaSolicitud DESC) AS rown,
					solicitud.tipoVenta,
					tipoPieza
					FROM #TMP_PROGRAM progra 
					INNER JOIN SolicitudDeVentaDetalles solicitudDetalle WITH (NOLOCK) ON progra.idGuiaHouseDetalle = solicitudDetalle.idGuiaHouseDetalle
					INNER JOIN SolicitudDeVenta solicitud WITH (NOLOCK) ON solicitud.id = solicitudDetalle.idSolicitud 
				) svc ON progra.idGuiaHouseDetalle = svc.idGuiaHouseDetalle AND svc.rown = 1
				LEFT JOIN dbo.InformacionClienteFinal infoClFinal ON cl.id = infoClFinal.id    
				LEFT JOIN dbo.Paises paisClInfoFinal ON infoClFinal.idPais = paisClInfoFinal.id
			WHERE (@idEmpresa IS NULL OR gh.idEmpresa = @idEmpresa)
				AND (@barcode IS NULL OR progra.codigoBarra LIKE '%' + @barcode + '%')
				AND (@nroDocument IS NULL OR house.nroGuia LIKE '%' + @nroDocument + '%')
				AND (@Consignee IS NULL OR house.idCliente IN ( SELECT id FROM Clientes WITH (NOLOCK) WHERE nombre LIKE '%' + @Consignee + '%' ))
				AND (@supplier IS NULL OR house.idExportador IN ( SELECT id FROM Exportadores WITH (NOLOCK) WHERE nombre LIKE '%' + @supplier + '%' ))
				AND (@palletLabel IS NULL OR pal.pallet LIKE '%' + @palletLabel + '%')
				AND (@nroManifiesto IS NULL OR manifiesto.nroManifiesto LIKE '%' + @nroManifiesto + '%')
			GROUP BY 
				manifiesto.id, 
				manifiesto.nroManifiesto, 
				progra.idClienteFinal, 
				ISNULL (cl.nombreClienteFinal, cl.nombre),
				ISNULL(ub.idBodega, house.idBodega), 
				ISNULL(bodegaPieza.nombre, bodegaGuia.nombre),
				progra.idCarrier, 
				progra.truckId, 
				progra.fechaDespacho, 
				parametroCat.valor,
				dcd.esPOD,
				svc.nroOrden,
				svc.id,
				PROGRA.nombreTransporte,
				T1.codigo,
				progra.idUsuarioLogPicking,
				paisClInfoFinal.id,
				paCl.id,
				progra.idTE,
				CASE 
					WHEN svc.tipoVenta < 4 THEN 1 
					WHEN svc.tipoVenta = 5 AND svc.tipoPieza = 1  THEN 1 
					ELSE 0 
				END;
		END
			SELECT      
				NEWID() id,
				guiasAgrupado.idManifiesto,
				guiasAgrupado.nroManifiesto,
				guiasAgrupado.idClienteFinal,		
				guiasAgrupado.fechaDespacho,
				guiasAgrupado.idBodega,
				guiasAgrupado.nombreBodega,		
				guiasAgrupado.nombreClienteFinal,
				guiasAgrupado.idCarrier,
				guiasAgrupado.truckId,		
				guiasAgrupado.valor,
				SUM(guiasAgrupado.totalPiezas) TotalPiezas,
				SUM(guiasAgrupado.totalDespachado) TotalDespachado,
				SUM(guiasAgrupado.totalStandBy) TotalStandBy,
				SUM(guiasAgrupado.totalHold) TotalHold,
				SUM(guiasAgrupado.totalPending) TotalPending,
				SUM(guiasAgrupado.totalRecibido) TotalRecibido,
				SUM(guiasAgrupado.totalShort) TotalShort,	
				guiasAgrupado.EsPod,	
				NULL mailEnviado,
				NULL tipoNubeDocs,
				NULL modificado,
				ordenVenta,
				SUM(guiasAgrupado.totalPicking) TotalPicking,
				idOrdenVenta,		
				guiasAgrupado.nombreCarrier,
				guiasAgrupado.codigoCarrier,
				NULL validarDiferenciaPiezas,
				SUM(guiasAgrupado.totalPickingLoading) TotalPickingLoading ,
				guiasAgrupado.idPaisCliente,
				guiasAgrupado.idPaisAlt,
				guiasAgrupado.idTEGuid,
				guiasAgrupado.esInventario
			FROM #TablaAgrupacionGuiasPickUp guiasAgrupado	
			GROUP BY 
				guiasAgrupado.idManifiesto,
				guiasAgrupado.nroManifiesto,
				guiasAgrupado.idClienteFinal,		
				guiasAgrupado.fechaDespacho,
				guiasAgrupado.idBodega,
				guiasAgrupado.nombreBodega,		
				guiasAgrupado.nombreClienteFinal,
				guiasAgrupado.idCarrier,
				guiasAgrupado.truckId,		
				guiasAgrupado.valor,
				guiasAgrupado.ordenVenta,
				guiasAgrupado.idOrdenventa,
				guiasAgrupado.nombreCarrier,
				guiasAgrupado.codigoCarrier,
				guiasAgrupado.EsPod,
				guiasAgrupado.idPaisCliente,
				guiasAgrupado.idPaisAlt,
				guiasAgrupado.idTEGuid,
				guiasAgrupado.esInventario
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError];
	END CATCH;
END
/*
	pro_modulo_DespachoPickup null, null, null, null, null, null, null, 'EMP014', 1, 3, null
	pro_modulo_DespachoPickup null, null, null, null, null, '22333931453', null, 'EMP014', 2, 3, null
	pro_modulo_DespachoPickup null, null, 'ALIS LUXURY BQTS CORP', null, null, null, null, 'EMP014', 1, 3, null
	pro_modulo_DespachoPickup null, null, 'ALIS LUXURY BQTS CORP', null, null, null, 'LOPEZ ANDRADE MARIA ANABEL', 'EMP014', 1, 3, null
	pro_modulo_DespachoPickup '8552', null, null, null, null, null, null, 'EMP014', 1, 3, null
*/