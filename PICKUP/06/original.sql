USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_Despacho_PickUpShipToCompleteScheduled]    Script Date: 26/03/2026 09:45:19 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  
VERSION		AUTOR				FECHA			HU		CAMBIO  
1			Luchin Campos		05/08/2021				No agrupar por totales, house, idGuiaHouse - No hacer join con DocumentoDespacho - No hacer join con Usuarios - Remover campos no usados  
2			Jonathan Merino		26/08/2021				Modificacion para mostrar en completados solo las piezas con Manifiesto POD  
3			Jonathan Merino		08/11/2021				Modificacion para agrupar por orden de venta  
4			Luchin Campos		15/04/2022				Mostrar Bodega de acuerdo con la ubicación de la pieza  
5			Jean  Martillo		25/11/2023		29121	Modificacion de sp para filtro de idempresa en guiasHouse
*/  
  
ALTER   PROCEDURE [dbo].[pro_Despacho_PickUpShipToCompleteScheduled]   
(  
 @FechaDesde DATE,  
 @FechaHasta DATE,  
 @NroDocumento VARCHAR(32) = NULL,  
 @Po VARCHAR(32) = NULL,  
 @NombreClienteConsignee VARCHAR(512) = NULL,  
 @NroPOD VARCHAR(16) = NULL,  
 @CodigoBarras VARCHAR(32) = NULL,  
 @NombreComercialExportador VARCHAR(50) = NULL,  
 @PalletLabel VARCHAR(20) = NULL,  
 @idEmpresa VARCHAR(16)  
)  
AS  
BEGIN  
    BEGIN TRY  
  
  DECLARE @idParametroDelivery VARCHAR(16);  
  
        CREATE TABLE #TablaAgrupacionGuiasHouseScheduled  
  (  
   Id INT IDENTITY(1, 1) NOT NULL,  
   IdClienteFinal VARCHAR(16),  
   nombreClienteFinal VARCHAR(1024),    
   FechaPickUpProgramada DATETIME,  
   FechaPickUpEntrega DATETIME,  
   TotalPending INT,  
   TotalHold INT,  
   TotalShort INT,  
   TotalReceived INT,  
   TotalStandBy INT,  
   TotalDespachado INT,  
   Total INT,  
   IdBodega VARCHAR(16),  
   nombreBodega VARCHAR(1024),    
   IdManifiesto UNIQUEIDENTIFIER,  
   IdCarrier VARCHAR(16),  
   NombreCarrier VARCHAR(512),  
   EsPod BIT NOT NULL DEFAULT 0,  
   idOrdenventa uniqueidentifier,  
      codigoCarrier NVARCHAR(16)  
  );  
         
  select @idParametroDelivery = id   
  from ParametrosLista parametroLista  
  where parametroLista.codigo = 'EsDelivery'  
  and parametroLista.idEmpresa = @idEmpresa;  
  
        IF   
  (     
   @NroDocumento IS NULL  
   AND   @Po IS NULL  
   AND   @NombreClienteConsignee IS NULL  
   AND   @NroPOD IS NULL  
   AND   @CodigoBarras IS NULL  
   AND   @NombreComercialExportador IS NULL  
   )  
        BEGIN  
  
   INSERT INTO #TablaAgrupacionGuiasHouseScheduled  
   SELECT        
   guiaHouseDetalle.idClienteFinal AS IdClienteFinal,  
   CASE  
   WHEN clienteFinal.nombreClienteFinal IS NULL THEN clienteFinal.nombre  
   ELSE clienteFinal.nombreClienteFinal END AS NombreClienteFinal,  
   programacionCarrier.fechaDespacho AS FechaPickUpProgramada,  
   MAX(guiaHouseDetalle.fechaCambio) AS FechaPickUpEntrega,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'PENDING', 1, 0)) AS TotalPending,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'HOLD', 1, 0)) AS TotalHold,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'SHORT', 1, 0)) AS TotalShort,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'RECEIVED WH', 1, 0)) AS TotalReceived,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'STANDBY', 1, 0)) AS TotalStandBy,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0)) AS TotalDespachado,  
   COUNT(1) AS Total,  
   CASE  
    WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
    THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega  
   END AS idBodega,   
   CASE  
    WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
    THEN bodegaGuia.nombre ELSE bodegaPieza.nombre  
   END AS nombreBodega,   
   manifiestoDespacho.id AS IdManifiesto,  
   programacionCarrier.idCarrier AS IdCarrier,  
   subCarrier.nombre AS NombreCarrier,  
   IIF(dcd.esPOD  IS NULL, CONVERT(BIT,0), dcd.esPOD),  
      svc.id,  
      codigoRelacion.codigo  
  
   FROM dbo.GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK)    
   INNER JOIN dbo.GuiasHouse guiaHouse ON guiaHouseDetalle.idGuiaHouse = guiaHouse.id  
   INNER JOIN dbo.Clientes clienteFinal ON guiaHouseDetalle.IdClienteFinal = clienteFinal.Id  
   INNER JOIN dbo.ProgramacionCarrier programacionCarrier WITH (NOLOCK) ON programacionCarrier.idGuiaHouseDetalle = guiaHouseDetalle.id  
   INNER JOIN dbo.Transportes subCarrier ON programacionCarrier.idCarrier = subCarrier.id  
   INNER JOIN dbo.Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id  
   INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad AND parametroCatalogo.idParametroLista = @idParametroDelivery  
   LEFT JOIN dbo.ProgramacionManifiesto programacionManifiesto ON programacionManifiesto.idProgramacionCarrier = programacionCarrier.id                
   LEFT JOIN dbo.ManifiestosDespacho manifiestoDespacho ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho  
   LEFT JOIN DocumentosDespacho dcd ON manifiestoDespacho.id = dcd.idManifiesto AND dcd.idDocumento = 'DOC052395'  
   LEFT JOIN dbo.PalletsDetalles pld ON guiaHouseDetalle.id = pld.idGuiasHouseDetalle  
      LEFT JOIN dbo.Pallets pal ON pld.idPallet = pal.id  
   OUTER APPLY (   SELECT      TOP (1) solicitud.id,  
                                                 solicitud.nroOrden  
                               FROM      dbo.SolicitudDeVentaDetalles solicitudDetalle  
                               LEFT JOIN dbo.SolicitudDeVenta solicitud  
                                 ON solicitud.id = solicitudDetalle.idSolicitud  
                              WHERE      solicitudDetalle.idGuiaHouseDetalle = guiaHouseDetalle.id  
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
   guiaHouseDetalle.idClienteFinal,  
   CASE  
   WHEN clienteFinal.nombreClienteFinal IS NULL THEN clienteFinal.nombre  
   ELSE clienteFinal.nombreClienteFinal END,  
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
   HAVING   COUNT(1) = SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0));  
  
        END  
        ELSE  
        BEGIN  
  
            INSERT INTO #TablaAgrupacionGuiasHouseScheduled  
   SELECT        
   guiaHouseDetalle.idClienteFinal AS IdClienteFinal,  
   CASE  
   WHEN clienteFinal.nombreClienteFinal IS NULL THEN clienteFinal.nombre  
   ELSE clienteFinal.nombreClienteFinal END AS NombreClienteFinal,  
   programacionCarrier.fechaDespacho AS FechaPickUpProgramada,  
   MAX(guiaHouseDetalle.fechaCambio) AS FechaPickUpEntrega,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'PENDING', 1, 0)) AS TotalPending,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'HOLD', 1, 0)) AS TotalHold,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'SHORT', 1, 0)) AS TotalShort,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'RECEIVED WH', 1, 0)) AS TotalReceived,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'STANDBY', 1, 0)) AS TotalStandBy,  
   SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0)) AS TotalDespachado,  
   COUNT(1) AS Total,  
   CASE  
    WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
    THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega  
   END AS idBodega,   
   CASE  
    WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')  
    THEN bodegaGuia.nombre ELSE bodegaPieza.nombre  
   END AS nombreBodega,   
   manifiestoDespacho.id AS IdManifiesto,  
   programacionCarrier.idCarrier AS IdCarrier,  
   subCarrier.nombre AS NombreCarrier,  
   IIF(dcd.esPOD  IS NULL, CONVERT(BIT,0), dcd.esPOD),  
   svc.id,  
   codigoRelacion.codigo  
  
   FROM dbo.GuiasHouseDetalles guiaHouseDetalle WITH (NOLOCK)   
   INNER JOIN dbo.GuiasHouse guiaHouse ON guiaHouseDetalle.idGuiaHouse = guiaHouse.id  
   INNER JOIN dbo.Clientes clienteFinal ON guiaHouseDetalle.IdClienteFinal = clienteFinal.Id  
   INNER JOIN dbo.ProgramacionCarrier programacionCarrier WITH (NOLOCK) ON programacionCarrier.idGuiaHouseDetalle = guiaHouseDetalle.id  
   INNER JOIN dbo.Transportes subCarrier ON programacionCarrier.idCarrier = subCarrier.id  
   INNER JOIN dbo.Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id  
   INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad AND parametroCatalogo.idParametroLista = @idParametroDelivery  
   LEFT JOIN dbo.ProgramacionManifiesto programacionManifiesto ON programacionManifiesto.idProgramacionCarrier = programacionCarrier.id                
   LEFT JOIN dbo.ManifiestosDespacho manifiestoDespacho ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho  
   LEFT JOIN DocumentosDespacho dcd ON manifiestoDespacho.id = dcd.idManifiesto AND dcd.idDocumento = 'DOC052395'  
   LEFT JOIN dbo.PalletsDetalles pld ON guiaHouseDetalle.id = pld.idGuiasHouseDetalle  
      LEFT JOIN dbo.Pallets pal ON pld.idPallet = pal.id  
   OUTER APPLY (   SELECT      TOP (1) solicitud.id,  
                                                 solicitud.nroOrden  
                               FROM      dbo.SolicitudDeVentaDetalles solicitudDetalle  
                               LEFT JOIN dbo.SolicitudDeVenta solicitud  
                                 ON solicitud.id = solicitudDetalle.idSolicitud  
                              WHERE      solicitudDetalle.idGuiaHouseDetalle = guiaHouseDetalle.id  
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
   AND (@NombreClienteConsignee IS NULL OR guiaHouse.idCliente IN ( SELECT id FROM Clientes WHERE nombre LIKE '%' + @NombreClienteConsignee + '%' ))  
   AND (@NroPOD IS NULL OR manifiestoDespacho.nroManifiesto LIKE '%' + @NroPOD + '%')  
   AND (@CodigoBarras IS NULL OR guiaHouseDetalle.codigoBarra LIKE '%' + @CodigoBarras + '%')  
   AND (@NombreComercialExportador IS NULL OR guiaHouse.idExportador IN ( SELECT id FROM Exportadores WHERE nombre LIKE '%' + @NombreComercialExportador + '%' ))  
   AND (@PalletLabel IS NULL OR   pal.pallet LIKE '%' + @PalletLabel + '%')  
  
            GROUP BY   
   guiaHouseDetalle.idClienteFinal,  
   CASE  
   WHEN clienteFinal.nombreClienteFinal IS NULL THEN clienteFinal.nombre  
   ELSE clienteFinal.nombreClienteFinal END,  
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
   HAVING   COUNT(1) = SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0));  
  
        END  
  
        SELECT        
  tmp.Id AS Id,  
  tmp.IdClienteFinal,  
  tmp.NombreClienteFinal,  
  tmp.IdBodega,  
  tmp.NombreBodega,  
  tmp.IdManifiesto,  
  tmp.IdCarrier,  
  tmp.NombreCarrier,  
  tmp.FechaPickUpProgramada,  
  tmp.FechaPickUpEntrega,  
  CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega,  
  tmp.TotalPending AS PcsPending,  
  tmp.TotalHold AS PcsHold,  
  tmp.TotalShort AS PcsShort,  
  tmp.TotalReceived AS PcsReceivedWh,  
  tmp.TotalStandBy AS PcsStandby,  
  tmp.TotalDespachado AS TotalDespachado,  
  tmp.Total AS Total,    
  CONVERT(BIT, 0) AS Enviado,  
  CONVERT(BIT, 0) AS Procesado,  
  NULL AS TipoNubeDocs,  
  NULL  AS Estatus,  
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