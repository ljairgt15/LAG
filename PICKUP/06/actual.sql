USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[AC_pro_GetCompletedScheduledPickupShipTo]    Script Date: 26/03/2026 09:45:46 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  
VERSION		MODIFIEDBY			MODIFIEDDATE		HU				MODIFICATION  
1			Juan Yanza			29-01-2026			WMS 57731		Based on pro_Despacho_PickUpShipTocompletescheduled  
*/  

ALTER   PROCEDURE [dbo].[AC_pro_GetCompletedScheduledPickupShipTo]   
(  
	@FechaDesde					DATE,  
	@FechaHasta					DATE,  
	@NroDocumento				VARCHAR(32)	 = NULL,  
	@Po							VARCHAR(32)  = NULL,  
	@IdBillTo					VARCHAR(16)  = NULL,
	@NombreBillTo				VARCHAR(512) = NULL,
	@IdConsignee				VARCHAR(16)  = NULL,  
	@NombreClienteConsignee		VARCHAR(512) = NULL,  
	@NroPOD						VARCHAR(16)  = NULL,  
	@CodigoBarras				VARCHAR(32)  = NULL,  
	@NombreComercialExportador	VARCHAR(50)  = NULL,  
	@PalletLabel				VARCHAR(20)  = NULL,  
	@idEmpresa					VARCHAR(16)  
)  
AS  
BEGIN
	BEGIN TRY
		DECLARE @idParametroDelivery VARCHAR(16);
		
		CREATE TABLE #TablaAgrupacionGuiasHouseScheduled (  
			Id						INT IDENTITY(1, 1) NOT NULL,  
			IdClienteFinal			VARCHAR(16),
			IdShipTo				VARCHAR(16),  
			nombreClienteFinal		VARCHAR(1024),    
			FechaPickUpProgramada	DATETIME,  
			FechaPickUpEntrega		DATETIME,  
			TotalPending			INT,  
			TotalHold				INT,  
			TotalShort				INT,  
			TotalReceived			INT,  
			TotalStandBy			INT,  
			TotalDespachado			INT,  
			Total					INT,  
			IdBodega				VARCHAR(16),  
			nombreBodega			VARCHAR(1024),    
			IdManifiesto			UNIQUEIDENTIFIER,  
			IdCarrier				VARCHAR(16),  
			NombreCarrier			VARCHAR(512),  
			EsPod					BIT NOT NULL DEFAULT 0,  
			idOrdenventa			UNIQUEIDENTIFIER,  
			codigoCarrier			NVARCHAR(16)  
		);  
         
		SELECT @idParametroDelivery = id   
		FROM ParametrosLista parametroLista  
		WHERE parametroLista.codigo = 'EsDelivery'  
		AND parametroLista.idEmpresa = @idEmpresa; 
		
		CREATE TABLE #TMP_ConsigneeByName (id VARCHAR(16))
		CREATE TABLE #TMP_BillToById     (id VARCHAR(16))
		CREATE TABLE #TMP_BillToByName   (id VARCHAR(16))

		IF @NombreClienteConsignee IS NOT NULL
			INSERT INTO #TMP_ConsigneeByName SELECT f.id FROM f_SearchEntities(@NombreClienteConsignee, 'Consignee') f

		IF @IdConsignee IS NULL AND @NombreClienteConsignee IS NULL
		BEGIN
			IF @IdBillTo IS NOT NULL
				INSERT INTO #TMP_BillToById SELECT f.id FROM f_SearchEntities(@IdBillTo, 'IdBillTo') f

			IF @NombreBillTo IS NOT NULL
				INSERT INTO #TMP_BillToByName SELECT f.id FROM f_SearchEntities(@NombreBillTo, 'BillTo') f
		END
  
		IF (     
			@NroDocumento				IS NULL AND 
			@Po							IS NULL AND 
			@IdBillTo					IS NULL AND
			@NombreBillTo				IS NULL AND
			@IdConsignee				IS NULL AND
			@NombreClienteConsignee		IS NULL AND
			@NroPOD						IS NULL AND 
			@CodigoBarras				IS NULL AND 
			@NombreComercialExportador	IS NULL AND
			@PalletLabel				IS NULL 
		)  
        BEGIN  
  
		INSERT INTO #TablaAgrupacionGuiasHouseScheduled  
		SELECT        
			VCE.id AS IdClienteFinal,  
			guiaHouseDetalle.ShipToId														AS IdShipTo,
			ISNULL(VCE.nombre, VCE.BillToName)												AS NombreClienteFinal,
			programacionCarrier.fechaDespacho												AS FechaPickUpProgramada,  
			MAX(guiaHouseDetalle.fechaCambio)												AS FechaPickUpEntrega,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'PENDING', 1, 0))						AS TotalPending,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'HOLD', 1, 0))							AS TotalHold,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'SHORT', 1, 0))							AS TotalShort,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'RECEIVED WH', 1, 0))					AS TotalReceived,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'STANDBY', 1, 0))						AS TotalStandBy,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0))					AS TotalDespachado,  
			COUNT(1)																		AS Total,  
			CASE  
			WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
			THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega  
			END																				AS idBodega,   
			CASE  
			WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
			THEN bodegaGuia.nombre ELSE bodegaPieza.nombre  
			END																				AS nombreBodega,   
			manifiestoDespacho.id															AS IdManifiesto,  
			programacionCarrier.idCarrier													AS IdCarrier,  
			subCarrier.nombre																AS NombreCarrier,  
			IIF(dcd.esPOD  IS NULL, CONVERT(BIT,0), dcd.esPOD),  
				svc.id,  
				codigoRelacion.codigo  
  
		FROM dbo.GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK)    
		INNER JOIN dbo.GuiasHouse guiaHouse ON guiaHouseDetalle.idGuiaHouse = guiaHouse.id  
		INNER JOIN dbo.v_ClientsEntities VCE ON guiaHouseDetalle.ShipToId = VCE.Id  
		INNER JOIN dbo.ProgramacionCarrier programacionCarrier WITH (NOLOCK) ON programacionCarrier.idGuiaHouseDetalle = guiaHouseDetalle.id  
		INNER JOIN dbo.Transportes subCarrier ON programacionCarrier.idCarrier = subCarrier.id  
		INNER JOIN dbo.Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id  
		INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad AND parametroCatalogo.idParametroLista = @idParametroDelivery  
		LEFT JOIN dbo.ProgramacionManifiesto programacionManifiesto ON programacionManifiesto.idProgramacionCarrier = programacionCarrier.id                
		LEFT JOIN dbo.ManifiestosDespacho manifiestoDespacho ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho  
		LEFT JOIN DocumentosDespacho dcd ON manifiestoDespacho.id = dcd.idManifiesto AND dcd.idDocumento = 'DOC052395'  
		LEFT JOIN dbo.PalletsDetalles pld ON guiaHouseDetalle.id = pld.idGuiasHouseDetalle  
		LEFT JOIN dbo.Pallets pal ON pld.idPallet = pal.id  
		OUTER APPLY (SELECT TOP (1) solicitud.id,  
									solicitud.nroOrden  
					FROM dbo.SolicitudDeVentaDetalles solicitudDetalle  
					LEFT JOIN dbo.SolicitudDeVenta solicitud  
						ON solicitud.id = solicitudDetalle.idSolicitud  
					WHERE solicitudDetalle.idGuiaHouseDetalle = guiaHouseDetalle.id  
					ORDER BY solicitud.fechaSolicitud DESC) AS svc  
		INNER JOIN dbo.CodigosRelacionSistemas AS codigoRelacion  
		ON programacionCarrier.idCarrier = codigoRelacion.idEntidad AND codigoRelacion.tipoEntidad = 'CARRIER' AND codigoRelacion.idSistemaEntidad = 100  
		LEFT JOIN UbicacionPiezas AS ubicacionPiezas ON guiaHouseDetalle.id = ubicacionPiezas.idGuiaHouseDetalle  
		LEFT JOIN Ubicaciones AS ubicaciones ON ubicacionPiezas.idUbicacion = ubicaciones.id  
		LEFT JOIN UbicacionesBodega AS ubicacionesBodega ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id  
		LEFT JOIN Bodegas AS bodegaGuia ON guiaHouse.idBodega = bodegaGuia.id  
		LEFT JOIN Bodegas AS bodegaPieza ON ubicacionesBodega.idBodega = bodegaPieza.id  
  
		WHERE guiaHouse.idEmpresa = @idEmpresa   
		AND parametroCatalogo.valor = 'NO'  
		AND programacionCarrier.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta  
		AND (@PalletLabel IS NULL OR   pal.pallet LIKE '%' + @PalletLabel + '%')  
     
		GROUP BY   
		VCE.id,
		guiaHouseDetalle.ShipToId,  
		ISNULL(VCE.nombre, VCE.BillToName), 
		CASE  
		WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
		THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega  
		END,   
		CASE  
		WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
		THEN bodegaGuia.nombre ELSE bodegaPieza.nombre  
		END,   
		programacionCarrier.fechaDespacho,  
		manifiestoDespacho.id,  
		programacionCarrier.idCarrier,  
		subCarrier.nombre,  
		dcd.esPOD,  
		svc.nroOrden,  
		svc.id,  
		codigoRelacion.codigo  
		HAVING COUNT(1) = SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0));  
  
        END  
        ELSE  
        BEGIN  
  
        INSERT INTO #TablaAgrupacionGuiasHouseScheduled  
		SELECT        
			VCE.id																			AS IdClienteFinal,
			guiaHouseDetalle.ShipToId														AS IdShipTo,  
			ISNULL(VCE.nombre, VCE.BillToName)												AS NombreClienteFinal,
			programacionCarrier.fechaDespacho												AS FechaPickUpProgramada,  
			MAX(guiaHouseDetalle.fechaCambio)												AS FechaPickUpEntrega,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'PENDING', 1, 0))						AS TotalPending,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'HOLD', 1, 0))							AS TotalHold,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'SHORT', 1, 0))							AS TotalShort,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'RECEIVED WH', 1, 0))					AS TotalReceived,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'STANDBY', 1, 0))						AS TotalStandBy,  
			SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0))					AS TotalDespachado,  
			COUNT(1) AS Total,  
		CASE  
		WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
		THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega  
		END																					AS idBodega,   
		CASE  
		WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
		THEN bodegaGuia.nombre ELSE bodegaPieza.nombre  
		END																					AS nombreBodega,   
		manifiestoDespacho.id																AS IdManifiesto,  
		programacionCarrier.idCarrier														AS IdCarrier,  
		subCarrier.nombre																	AS NombreCarrier,  
		IIF(dcd.esPOD  IS NULL, CONVERT(BIT,0), dcd.esPOD),  
		svc.id,  
		codigoRelacion.codigo  
  
		FROM dbo.GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK)   
		INNER JOIN dbo.GuiasHouse guiaHouse ON guiaHouseDetalle.idGuiaHouse = guiaHouse.id  
		INNER JOIN dbo.v_ClientsEntities VCE ON guiaHouseDetalle.ShipToId = VCE.Id  
		INNER JOIN dbo.ProgramacionCarrier programacionCarrier WITH (NOLOCK) ON programacionCarrier.idGuiaHouseDetalle = guiaHouseDetalle.id  
		INNER JOIN dbo.Transportes subCarrier ON programacionCarrier.idCarrier = subCarrier.id  
		INNER JOIN dbo.Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id  
		INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad AND parametroCatalogo.idParametroLista = @idParametroDelivery  
		LEFT JOIN v_ClientsEntities VCE_BillTo WITH(NOLOCK) ON guiaHouse.BillToConsigneeId = VCE_BillTo.id 
		LEFT JOIN dbo.ProgramacionManifiesto programacionManifiesto ON programacionManifiesto.idProgramacionCarrier = programacionCarrier.id                
		LEFT JOIN dbo.ManifiestosDespacho manifiestoDespacho ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho  
		LEFT JOIN DocumentosDespacho dcd ON manifiestoDespacho.id = dcd.idManifiesto AND dcd.idDocumento = 'DOC052395'  
		LEFT JOIN dbo.PalletsDetalles pld ON guiaHouseDetalle.id = pld.idGuiasHouseDetalle  
		LEFT JOIN dbo.Pallets pal ON pld.idPallet = pal.id  
		OUTER APPLY (SELECT TOP (1) solicitud.id,  
									solicitud.nroOrden  
									FROM dbo.SolicitudDeVentaDetalles solicitudDetalle  
									LEFT JOIN dbo.SolicitudDeVenta solicitud  
										ON solicitud.id = solicitudDetalle.idSolicitud  
									WHERE solicitudDetalle.idGuiaHouseDetalle = guiaHouseDetalle.id  
									ORDER BY solicitud.fechaSolicitud DESC) AS svc  
		INNER JOIN dbo.CodigosRelacionSistemas AS codigoRelacion  
		ON programacionCarrier.idCarrier = codigoRelacion.idEntidad AND codigoRelacion.tipoEntidad = 'CARRIER' AND codigoRelacion.idSistemaEntidad = 100  
		LEFT JOIN UbicacionPiezas AS ubicacionPiezas ON guiaHouseDetalle.id = ubicacionPiezas.idGuiaHouseDetalle  
		LEFT JOIN Ubicaciones AS ubicaciones ON ubicacionPiezas.idUbicacion = ubicaciones.id  
		LEFT JOIN UbicacionesBodega AS ubicacionesBodega ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id  
		LEFT JOIN Bodegas AS bodegaGuia ON guiaHouse.idBodega = bodegaGuia.id  
		LEFT JOIN Bodegas AS bodegaPieza ON ubicacionesBodega.idBodega = bodegaPieza.id  
  
		WHERE guiaHouse.idEmpresa = @idEmpresa   
		AND parametroCatalogo.valor = 'NO'  
		AND programacionCarrier.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta  
		AND (@NroDocumento IS NULL OR guiaHouse.nroGuia LIKE '%' + @NroDocumento + '%')  
		AND (@Po IS NULL OR guiaHouseDetalle.po LIKE '%' + @Po + '%')  
		AND (
			-- Prioridad Consignee (si llega cualquiera de los dos, ignora BillTo porque desde el front ya filtra los consignees relacionados al billto)
			(@IdConsignee IS NOT NULL AND guiaHouse.ConsigneeId = @IdConsignee)
			OR
			(@NombreClienteConsignee IS NOT NULL AND guiaHouse.ConsigneeId IN (SELECT id FROM #TMP_ConsigneeByName))
			OR
			-- Prioridad BillTo (solo aplica si NO llegó ningún Consignee)
			(@IdConsignee IS NULL AND @NombreClienteConsignee IS NULL AND @IdBillTo IS NOT NULL AND guiaHouse.BillToConsigneeId IN (SELECT id FROM #TMP_BillToById))
			OR
			(@IdConsignee IS NULL AND @NombreClienteConsignee IS NULL AND @NombreBillTo IS NOT NULL AND guiaHouse.BillToConsigneeId IN (SELECT id FROM #TMP_BillToByName))
			OR
			-- Sin filtro
			(@IdConsignee IS NULL AND @NombreClienteConsignee IS NULL AND @IdBillTo IS NULL AND @NombreBillTo IS NULL)
		)
		AND (@NroPOD IS NULL OR manifiestoDespacho.nroManifiesto LIKE '%' + @NroPOD + '%')  
		AND (@CodigoBarras IS NULL OR guiaHouseDetalle.codigoBarra LIKE '%' + @CodigoBarras + '%')  
		AND (@NombreComercialExportador IS NULL OR guiaHouse.idExportador IN ( SELECT id FROM Exportadores WHERE nombre LIKE '%' + @NombreComercialExportador + '%' ))  
		AND (@PalletLabel IS NULL OR   pal.pallet LIKE '%' + @PalletLabel + '%')  
  
		GROUP BY   
		VCE.id,
		guiaHouseDetalle.ShipToId,  
		ISNULL(VCE.nombre, VCE.BillToName),
		CASE  
		WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
		THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega  
		END,   
		CASE  
		WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
		THEN bodegaGuia.nombre ELSE bodegaPieza.nombre  
		END,   
		programacionCarrier.fechaDespacho,  
		manifiestoDespacho.id,  
		programacionCarrier.idCarrier,  
		subCarrier.nombre,  
		dcd.esPOD,  
		svc.nroOrden,  
		svc.id,  
		codigoRelacion.codigo  
		HAVING COUNT(1) = SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0));  
  
        END  
  
        SELECT        
			tmp.Id									AS Id,  
			tmp.IdClienteFinal,
			tmp.IdShipTo,  
			tmp.NombreClienteFinal,  
			tmp.IdBodega,  
			tmp.NombreBodega,  
			tmp.IdManifiesto,  
			tmp.IdCarrier,  
			tmp.NombreCarrier,    
			tmp.FechaPickUpProgramada,  
			tmp.FechaPickUpEntrega,  
			CONVERT(TIME, tmp.FechaPickUpEntrega)	AS HoraEntrega,  
			tmp.TotalPending						AS PcsPending,  
			tmp.TotalHold							AS PcsHold,  
			tmp.TotalShort							AS PcsShort,  
			tmp.TotalReceived						AS PcsReceivedWh,  
			tmp.TotalStandBy						AS PcsStandby,  
			tmp.TotalDespachado						AS TotalDespachado,  
			tmp.Total								AS Total,    
			CONVERT(BIT, 0)							AS Enviado,  
			CONVERT(BIT, 0)							AS Procesado,  
			NULL									AS TipoNubeDocs,  
			NULL									AS Estatus,  
			tmp.idOrdenventa,  
			tmp.codigoCarrier  
  
		FROM #TablaAgrupacionGuiasHouseScheduled AS tmp  
		WHERE tmp.EsPod = 1   
  
        DROP TABLE #TablaAgrupacionGuiasHouseScheduled;  
  
	END TRY  
	BEGIN CATCH  
		EXEC [dbo].[pro_LogError];  
    END CATCH;  
END;