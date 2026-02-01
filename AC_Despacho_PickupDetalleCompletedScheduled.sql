USE [alliance_testing]
GO
/****** Object:  StoredProcedure [dbo].[pro_Despacho_PickUpDetalleCompleteScheduled_BORRAR]    Script Date: 01/02/2026 03:17:46 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER     PROCEDURE [dbo].[AC_Despacho_PickupDetalleCompletedScheduled] (
@FechaDesde DATE,
@FechaHasta DATE,
@NroDocumento VARCHAR(32) = NULL,
@Po VARCHAR(32) = NULL,
@NombreClienteConsignee VARCHAR(512) = NULL,
@NroPOD VARCHAR(16) = NULL,
@CodigoBarras VARCHAR(32) = NULL,
@NombreComercialExportador VARCHAR(50) = NULL,
@IdManifiesto UNIQUEIDENTIFIER = NULL,
@IdCarrier VARCHAR(16) = NULL,
@IdClienteFinal VARCHAR(16) = NULL,
@IdBodega VARCHAR(16) = NULL,
@FechaPickUpProgramada DATE = NULL,
@FechaPickUpEntrega DATE = NULL,
@PalletLabel VARCHAR(20) = NULL,
@idEmpresa VARCHAR(16) = NULL)
AS
BEGIN
    BEGIN TRY

        DECLARE @emptyUID UNIQUEIDENTIFIER = 0x0;

        CREATE TABLE #TablaAgrupacionGuiasHouse (Id INT IDENTITY(1, 1) NOT NULL,
                                                 IdClienteFinal VARCHAR(16) NOT NULL,
                                                 NombreClienteFinal VARCHAR(512) NULL, -- NUEVO
                                                 IdClienteConsignee VARCHAR(16) NOT NULL,
                                                 NombreClienteConsignee VARCHAR(512) NULL, -- NUEVO
                                                 FechaPickUpProgramada DATETIME NOT NULL,
                                                 FechaPickUpEntrega DATETIME NOT NULL,
                                                 idUsuarioLog VARCHAR(32) NULL,
												 TotalPending INT NOT NULL,
												 TotalHold INT NOT NULL,
												 TotalShort INT NOT NULL,
												 TotalReceived INT NOT NULL,
												 TotalStandBy INT NOT NULL,
                                                 TotalDespachado INT NOT NULL,
                                                 Total INT NOT NULL,
                                                 IdBodega VARCHAR(16) NULL,
                                                 NombreBodega NVARCHAR(512) NULL, -- NUEVO
                                                 IdManifiesto UNIQUEIDENTIFIER NULL,
                                                 IdCarrier VARCHAR(16) NOT NULL,
                                                 NombreCarrier VARCHAR(512) NOT NULL,
                                                 IdGuia VARCHAR(128) NOT NULL,
                                                 NroDocumento VARCHAR(32) NOT NULL,
                                                 IdOrdenVenta UNIQUEIDENTIFIER NULL,
                                                 NroOrdenVenta VARCHAR(32) NULL,
                                                 ConPOD INT NOT NULL,
                                                 Enviado INT NOT NULL,
                                                 Procesado INT NOT NULL);
		

        CREATE TABLE #TablaAgrupacionGuiasHouseFinal (Id INT IDENTITY(1, 1) NOT NULL,
                                                      IdClienteFinal VARCHAR(16) NOT NULL,
                                                      NombreClienteFinal VARCHAR(512) NULL, -- NUEVO
                                                      IdClienteConsignee VARCHAR(16) NOT NULL,
                                                      NombreClienteConsignee VARCHAR(512) NULL, -- NUEVO
                                                      FechaPickUpProgramada DATETIME NOT NULL,
                                                      FechaPickUpEntrega DATETIME NOT NULL,
                                                      idUsuarioLog VARCHAR(32) NULL,
													  TotalPending INT NOT NULL,
													  TotalHold INT NOT NULL,
													  TotalShort INT NOT NULL,
													  TotalReceived INT NOT NULL,
													  TotalStandBy INT NOT NULL,
                                                      TotalDespachado INT NOT NULL,
                                                      Total INT NOT NULL,
                                                      IdBodega VARCHAR(16) NULL,
                                                      NombreBodega NVARCHAR(512) NULL, -- NUEVO
                                                      IdManifiesto UNIQUEIDENTIFIER NULL,
                                                      IdCarrier VARCHAR(16) NOT NULL,
                                                      NombreCarrier VARCHAR(512) NOT NULL,
                                                      IdGuia VARCHAR(128) NOT NULL,
                                                      NroDocumento VARCHAR(32) NOT NULL,
                                                      IdOrdenVenta UNIQUEIDENTIFIER NULL,
                                                      NroOrdenVenta VARCHAR(32) NULL,
                                                      ConPOD INT NOT NULL,
                                                      Enviado INT NOT NULL,
                                                      Procesado INT NOT NULL);
									


        IF (   @NroDocumento IS NULL
         AND   @Po IS NULL
         AND   @NombreClienteConsignee IS NULL
         AND   @NroPOD IS NULL
         AND   @CodigoBarras IS NULL
         AND   @NombreComercialExportador IS NULL)
        BEGIN

            INSERT INTO #TablaAgrupacionGuiasHouse (IdClienteFinal,
                                                    IdClienteConsignee,
                                                    FechaPickUpProgramada,
                                                    FechaPickUpEntrega,
                                                    idUsuarioLog,
													TotalPending,
													TotalHold,
													TotalShort,
													TotalReceived,
													TotalStandBy,
                                                    TotalDespachado,
                                                    Total,
                                                    IdBodega,
                                                    IdManifiesto,
                                                    IdCarrier,
                                                    NombreCarrier,
                                                    IdGuia,
                                                    NroDocumento,
                                                    IdOrdenVenta,
                                                    NroOrdenVenta,
                                                    ConPOD,
                                                    Enviado,
                                                    Procesado)
										
            SELECT       guiaHouseDetalle.idClienteFinal AS IdClienteFinal,
                         guiaHouse.idCliente AS IdClienteConsignee,
                         programacionCarrier.fechaDespacho AS FechaPickUpProgramada,
                         MAX(guiaHouseDetalle.fechaCambio) AS FechaPickUpEntrega,
                         guiaHouseDetalle.idUsuarioLog,
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
                         manifiestoDespacho.id AS IdManifiesto,
                         programacionCarrier.idCarrier AS IdCarrier,
                         subCarrier.nombre AS NombreCarrier,
                         guiaHouse.idGuia AS IdGuia,
                         guiaHouse.nroGuia AS NroDocumento,
                         solicitud.id AS IdOrdenVenta,
                         solicitud.nroOrden AS NroOrdenVenta,
                         MAX(IIF(documentosDespacho.nombreArchivo LIKE 'POD%', 1, 0)) AS ConPOD,
                         MAX(IIF(documentosDespacho.mailEnviado = 1, 1, 0)) AS Enviado,
                         MAX(IIF(documentosDespacho.podProcesado = 1, 1, 0)) AS Procesado
					
              FROM       dbo.GuiasHouseDetalles guiaHouseDetalle
             INNER JOIN  dbo.GuiasHouse guiaHouse
                ON guiaHouseDetalle.idGuiaHouse = guiaHouse.id
             INNER JOIN  dbo.ProgramacionCarrier programacionCarrier
                ON programacionCarrier.idGuiaHouseDetalle = guiaHouseDetalle.id
             INNER JOIN  dbo.Transportes subCarrier
                ON programacionCarrier.idCarrier = subCarrier.id
             INNER JOIN  dbo.Transportes carrier
                ON subCarrier.idTransportePrincipal = carrier.id
             INNER JOIN  dbo.ParametrosCatalogos parametroCatalogo
                ON carrier.id = parametroCatalogo.idEntidad
             INNER JOIN  dbo.ParametrosLista parametroLista
                ON parametroCatalogo.idParametroLista = parametroLista.id
               AND parametroLista.codigo = 'EsDelivery'
               AND parametroLista.idEmpresa = guiaHouse.idEmpresa
              LEFT JOIN  dbo.ProgramacionManifiesto programacionManifiesto
                ON programacionManifiesto.idProgramacionCarrier = programacionCarrier.id
              LEFT JOIN  dbo.DocumentosDespacho documentosDespacho
                ON programacionManifiesto.idManifiestoDespacho = documentosDespacho.idManifiesto
               AND documentosDespacho.idDocumento = 'DOC052395'
              LEFT JOIN  dbo.ManifiestosDespacho manifiestoDespacho
                ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho
             OUTER APPLY (   SELECT      TOP (1) solicitud.id,
                                                 solicitud.nroOrden
                               FROM      dbo.SolicitudDeVentaDetalles solicitudDetalle
                               LEFT JOIN dbo.SolicitudDeVenta solicitud
                                 ON solicitud.id = solicitudDetalle.idSolicitud
                              WHERE      solicitudDetalle.idGuiaHouseDetalle = guiaHouseDetalle.id
                              ORDER BY solicitud.fechaSolicitud DESC) AS solicitud
			LEFT JOIN dbo.PalletsDetalles pld ON guiaHouseDetalle.id = pld.idGuiasHouseDetalle
		    LEFT JOIN dbo.Pallets pal ON pld.idPallet = pal.id
			LEFT JOIN UbicacionPiezas AS ubicacionPiezas ON guiaHouseDetalle.id = ubicacionPiezas.idGuiaHouseDetalle
			LEFT JOIN Ubicaciones AS ubicaciones ON ubicacionPiezas.idUbicacion = ubicaciones.id
			LEFT JOIN UbicacionesBodega AS ubicacionesBodega ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id
             WHERE       guiaHouse.idEmpresa = @idEmpresa
			   AND       programacionCarrier.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
			   AND   	 parametroCatalogo.valor = 'NO'               
			   AND (@PalletLabel IS NULL OR   pal.pallet LIKE '%' + @PalletLabel + '%')			   

             GROUP BY guiaHouseDetalle.idClienteFinal,
					  guiaHouse.idCliente,
                      CASE
						WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')
						THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega
					  END, 
                      programacionCarrier.fechaDespacho,
                      CONVERT(DATE, guiaHouseDetalle.fechaCambio),
                      manifiestoDespacho.id,
                      programacionCarrier.idCarrier,
                      subCarrier.nombre,
                      guiaHouseDetalle.idUsuarioLog,
                      guiaHouseDetalle.idClienteConsignee,
                      guiaHouse.idGuia,
                      guiaHouse.nroGuia,
                      solicitud.id,
                      solicitud.nroOrden
		
            HAVING       COUNT(1) = SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0))

        END;	

        ELSE
        BEGIN

            INSERT INTO #TablaAgrupacionGuiasHouse (IdClienteFinal,
                                                    IdClienteConsignee,
                                                    FechaPickUpProgramada,
                                                    FechaPickUpEntrega,
                                                    idUsuarioLog,
													TotalPending,
													TotalHold,
													TotalShort,
													TotalReceived,
													TotalStandBy,
                                                    TotalDespachado,
                                                    Total,
                                                    IdBodega,
                                                    IdManifiesto,
                                                    IdCarrier,
                                                    NombreCarrier,
                                                    IdGuia,
                                                    NroDocumento,
                                                    IdOrdenVenta,
                                                    NroOrdenVenta,
                                                    ConPOD,
                                                    Enviado,
                                                    Procesado)
											
            SELECT       guiaHouseDetalle.idClienteFinal AS IdClienteFinal,
                         guiaHouse.idCliente AS IdClienteConsignee,
                         programacionCarrier.fechaDespacho AS FechaPickUpProgramada,
                         MAX(guiaHouseDetalle.fechaCambio) AS FechaPickUpEntrega,
                         guiaHouseDetalle.idUsuarioLog,
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
                         manifiestoDespacho.id AS IdManifiesto,
                         programacionCarrier.idCarrier AS IdCarrier,
                         subCarrier.nombre AS NombreCarrier,
                         guiaHouse.idGuia AS IdGuia,
                         guiaHouse.nroGuia AS NroDocumento,
                         solicitud.id AS IdOrdenVenta,
                         solicitud.nroOrden AS NroOrdenVenta,
                         MAX(IIF(documentosDespacho.nombreArchivo LIKE 'POD%', 1, 0)) AS ConPOD,
                         MAX(IIF(documentosDespacho.mailEnviado = 1, 1, 0)) AS Enviado,
                         MAX(IIF(documentosDespacho.podProcesado = 1, 1, 0)) AS Procesado
						
              FROM       dbo.GuiasHouseDetalles guiaHouseDetalle
             INNER JOIN  dbo.GuiasHouse guiaHouse
                ON guiaHouseDetalle.idGuiaHouse = guiaHouse.id
             INNER JOIN  dbo.Clientes AS clienteConsignatario
                ON guiaHouse.idCliente = clienteConsignatario.id
             INNER JOIN  dbo.Exportadores exportador
                ON guiaHouse.idExportador = exportador.id
             INNER JOIN  dbo.ProgramacionCarrier programacionCarrier
                ON programacionCarrier.idGuiaHouseDetalle = guiaHouseDetalle.id
             INNER JOIN  dbo.Transportes subCarrier
                ON programacionCarrier.idCarrier = subCarrier.id
             INNER JOIN  dbo.Transportes carrier
                ON subCarrier.idTransportePrincipal = carrier.id
             INNER JOIN  dbo.ParametrosCatalogos parametroCatalogo
                ON carrier.id = parametroCatalogo.idEntidad
             INNER JOIN  dbo.ParametrosLista parametroLista
                ON parametroCatalogo.idParametroLista = parametroLista.id
               AND parametroLista.codigo = 'EsDelivery'
               AND parametroLista.idEmpresa = guiaHouse.idEmpresa
              LEFT JOIN  dbo.ProgramacionManifiesto programacionManifiesto
                ON programacionManifiesto.idProgramacionCarrier = programacionCarrier.id
              LEFT JOIN  dbo.DocumentosDespacho documentosDespacho
                ON programacionManifiesto.idManifiestoDespacho = documentosDespacho.idManifiesto
               AND documentosDespacho.idDocumento = 'DOC052395'
              LEFT JOIN  dbo.ManifiestosDespacho manifiestoDespacho
                ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho
             OUTER APPLY (   SELECT      TOP (1) solicitud.id,
                                                 solicitud.nroOrden
                               FROM      dbo.SolicitudDeVentaDetalles solicitudDetalle
                               LEFT JOIN dbo.SolicitudDeVenta solicitud
                                 ON solicitud.id = solicitudDetalle.idSolicitud
                              WHERE      solicitudDetalle.idGuiaHouseDetalle = guiaHouseDetalle.id
                              ORDER BY solicitud.fechaSolicitud DESC) AS solicitud
			LEFT JOIN dbo.PalletsDetalles pld ON guiaHouseDetalle.id = pld.idGuiasHouseDetalle
		    LEFT JOIN dbo.Pallets pal ON pld.idPallet = pal.id
			LEFT JOIN UbicacionPiezas AS ubicacionPiezas ON guiaHouseDetalle.id = ubicacionPiezas.idGuiaHouseDetalle
			LEFT JOIN Ubicaciones AS ubicaciones ON ubicacionPiezas.idUbicacion = ubicaciones.id
			LEFT JOIN UbicacionesBodega AS ubicacionesBodega ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id
             WHERE       guiaHouse.idEmpresa = @idEmpresa
			   AND       programacionCarrier.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
			   AND		 parametroCatalogo.valor = 'NO'               
               AND       (   @NroDocumento IS NULL
                        OR   guiaHouse.nroGuia LIKE '%' + @NroDocumento + '%')
               AND       (   @Po IS NULL
                        OR   guiaHouseDetalle.po LIKE '%' + @Po + '%')
               AND       (   @NombreClienteConsignee IS NULL
                        OR   clienteConsignatario.nombre LIKE '%' + @NombreClienteConsignee + '%')
               AND       (   @NroPOD IS NULL
                        OR   manifiestoDespacho.nroManifiesto LIKE '%' + @NroPOD + '%')
               AND       (   @CodigoBarras IS NULL
                        OR   guiaHouseDetalle.codigoBarra LIKE '%' + @CodigoBarras + '%')
               AND       (   @NombreComercialExportador IS NULL
                        OR   exportador.nombreComercial LIKE '%' + @NombreComercialExportador + '%')
			   AND (@PalletLabel IS NULL OR   pal.pallet LIKE '%' + @PalletLabel + '%')


             GROUP BY guiaHouseDetalle.idClienteFinal,
					  guiaHouse.idCliente,
                      CASE
						WHEN (ubicacionesBodega.idBodega IS NULL OR ubicacionesBodega.idBodega = '')
						THEN guiaHouse.idBodega ELSE ubicacionesBodega.idBodega
					  END, 
                      programacionCarrier.fechaDespacho,
                      manifiestoDespacho.id,
                      programacionCarrier.idCarrier,
                      subCarrier.nombre,
                      guiaHouseDetalle.idUsuarioLog,
                      guiaHouseDetalle.idClienteConsignee,
                      guiaHouse.idGuia,
                      guiaHouse.nroGuia,
                      solicitud.id,
                      solicitud.nroOrden
			
            HAVING       COUNT(1) = SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0))

        END;



        INSERT INTO #TablaAgrupacionGuiasHouseFinal (IdClienteFinal,
                                                     IdClienteConsignee,
                                                     FechaPickUpProgramada,
                                                     FechaPickUpEntrega,
                                                     idUsuarioLog,
													 TotalPending,
													 TotalHold,
													 TotalShort,
													 TotalReceived,
													 TotalStandBy,
                                                     TotalDespachado,
                                                     Total,
                                                     IdBodega,
                                                     IdManifiesto,
                                                     IdCarrier,
                                                     NombreCarrier,
                                                     IdGuia,
                                                     NroDocumento,
                                                     IdOrdenVenta,
                                                     NroOrdenVenta,
                                                     ConPOD,
                                                     Enviado,
                                                     Procesado)
											
        SELECT tbl.IdClienteFinal,
               tbl.IdClienteConsignee,
               tbl.FechaPickUpProgramada,
               MAX(tbl.FechaPickUpEntrega) AS FechaPickUpEntrega,
               (   SELECT TOP (1) tblSubQuery.idUsuarioLog
                     FROM #TablaAgrupacionGuiasHouse AS tblSubQuery
                    WHERE tblSubQuery.IdClienteFinal                  = tblSubQuery.IdClienteFinal
                      AND tblSubQuery.IdClienteConsignee              = tblSubQuery.IdClienteConsignee
                      AND tblSubQuery.FechaPickUpEntrega              = MAX(tbl.FechaPickUpEntrega)
                      AND tblSubQuery.IdBodega                        = tblSubQuery.IdBodega
                      AND ISNULL(tblSubQuery.IdManifiesto, @emptyUID) = ISNULL(tblSubQuery.IdManifiesto, @emptyUID)
                      AND tblSubQuery.IdCarrier                       = tblSubQuery.IdCarrier
                      AND tblSubQuery.NombreCarrier                   = tblSubQuery.NombreCarrier
                      AND tblSubQuery.NroDocumento                    = tblSubQuery.NroDocumento
                      AND tblSubQuery.ConPOD                          = tblSubQuery.ConPOD
                      AND tblSubQuery.Enviado                         = tblSubQuery.Enviado) AS IdUsuarioLog,
               SUM(tbl.TotalPending) AS PcsPending,
			   SUM(tbl.TotalHold) AS PcsHold,
			   SUM(tbl.TotalShort) AS PcsShort,
			   SUM(tbl.TotalReceived) AS PcsReceivedWh,
			   SUM(tbl.TotalStandBy) AS PcsStandby,
			   SUM(tbl.TotalDespachado) AS TotalDespachado,
               SUM(tbl.Total) AS Total,
               tbl.IdBodega,
               tbl.IdManifiesto,
               tbl.IdCarrier,
               tbl.NombreCarrier,
               tbl.IdGuia,
               tbl.NroDocumento,
               tbl.IdOrdenVenta,
               tbl.NroOrdenVenta,
               tbl.ConPOD,
               tbl.Enviado,
               tbl.Procesado
			
          FROM #TablaAgrupacionGuiasHouse tbl
         GROUP BY tbl.IdClienteFinal,
                  tbl.IdClienteConsignee,
                  tbl.FechaPickUpProgramada,
                  CONVERT(DATE, tbl.FechaPickUpEntrega),
                  tbl.IdBodega,
                  tbl.IdManifiesto,
                  tbl.IdCarrier,
                  tbl.NombreCarrier,
                  tbl.ConPOD,
                  tbl.Enviado,
                  tbl.Procesado,
                  tbl.IdGuia,
                  tbl.NroDocumento,
                  tbl.IdOrdenVenta,
                  tbl.NroOrdenVenta
		

        IF @IdClienteFinal IS NULL
        BEGIN
            SELECT      tmp.Id AS Id,
                        'Entregada' AS Estatus,
                        'dispatch-pick-up-delivered' AS ClaseCssEstatus,      
						tmp.IdGuia,
                        tmp.NroDocumento,
                        tmp.IdOrdenVenta,
                        tmp.NroOrdenVenta,                  
                        tmp.IdClienteFinal,
                        CASE
                             WHEN clienteFinal.nombreClienteFinal IS NULL THEN clienteFinal.nombre
                             ELSE clienteFinal.nombreClienteFinal END AS NombreClienteFinal,
                        tmp.IdClienteConsignee,
                        clienteConsignatario.nombre AS NombreClienteConsignee,
                        tmp.FechaPickUpProgramada,
                        '' AS FechaPickUpProgramadaString,
                        tmp.FechaPickUpEntrega,
                        '' AS FechaPickUpEntregaString,
                        CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega,
                        tmp.TotalPending AS PcsPending,
						tmp.TotalHold AS PcsHold,
						tmp.TotalShort AS PcsShort,
						tmp.TotalReceived AS PcsReceivedWh,
						tmp.TotalStandBy AS PcsStandby,
						tmp.TotalDespachado AS TotalDespachado,
						tmp.Total AS Total,
                        tmp.IdBodega,
                        bodega.nombre AS NombreBodega,
                        tmp.IdManifiesto,
                        tmp.IdCarrier,
                        tmp.NombreCarrier,                        
                        usuario.nombre + ' ' AS UsuarioFechaCambio,
                        CONVERT(BIT, tmp.Enviado) AS Enviado,
                        CONVERT(BIT, tmp.Procesado) AS Procesado
					
              FROM      #TablaAgrupacionGuiasHouseFinal AS tmp
             INNER JOIN dbo.Bodegas bodega
                ON tmp.IdBodega           = bodega.Id
             INNER JOIN dbo.Clientes clienteFinal
                ON tmp.IdClienteFinal     = clienteFinal.Id
             INNER JOIN dbo.Clientes AS clienteConsignatario
                ON tmp.IdClienteConsignee = clienteConsignatario.Id
             INNER JOIN dbo.Usuarios usuario
                ON usuario.Id             = tmp.idUsuarioLog

        END;
        ELSE
        BEGIN
            SELECT      tmp.Id AS Id,
                        'Entregada' AS Estatus,
                        'dispatch-pick-up-delivered' AS ClaseCssEstatus,      
						tmp.IdGuia,
                        tmp.NroDocumento,
                        tmp.IdOrdenVenta,
                        tmp.NroOrdenVenta,                  
                        tmp.IdClienteFinal,
                        CASE
                             WHEN clienteFinal.nombreClienteFinal IS NULL THEN clienteFinal.nombre
                             ELSE clienteFinal.nombreClienteFinal END AS NombreClienteFinal,
                        tmp.IdClienteConsignee,
                        clienteConsignatario.nombre AS NombreClienteConsignee,
                        tmp.FechaPickUpProgramada,
                        '' AS FechaPickUpProgramadaString,
                        tmp.FechaPickUpEntrega,
                        '' AS FechaPickUpEntregaString,
                        CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega,
                        SUM(tmp.TotalPending) AS PcsPending,
					    SUM(tmp.TotalHold) AS PcsHold,
					    SUM(tmp.TotalShort) AS PcsShort,
					    SUM(tmp.TotalReceived) AS PcsReceivedWh,
					    SUM(tmp.TotalStandBy) AS PcsStandby,
					    SUM(tmp.TotalDespachado) AS TotalDespachado,
					    SUM(tmp.Total) AS Total,
                        tmp.IdBodega,
                        bodega.nombre AS NombreBodega,
                        tmp.IdManifiesto,
                        tmp.IdCarrier,
                        tmp.NombreCarrier,                        
                        usuario.nombre + ' ' AS UsuarioFechaCambio,
                        CONVERT(BIT, tmp.Enviado) AS Enviado,
                        CONVERT(BIT, tmp.Procesado) AS Procesado
              FROM      #TablaAgrupacionGuiasHouseFinal AS tmp
             INNER JOIN dbo.Bodegas bodega
                ON tmp.IdBodega           = bodega.Id
             INNER JOIN dbo.Clientes clienteFinal
                ON tmp.IdClienteFinal     = clienteFinal.Id
             INNER JOIN dbo.Clientes AS clienteConsignatario
                ON tmp.IdClienteConsignee = clienteConsignatario.Id
             INNER JOIN dbo.Usuarios usuario
                ON usuario.Id             = tmp.idUsuarioLog
             WHERE      ISNULL(tmp.IdManifiesto, @emptyUID)   = ISNULL(@IdManifiesto, @emptyUID)
               AND      tmp.IdCarrier                         = @IdCarrier
               AND      tmp.IdClienteFinal                    = @IdClienteFinal
               AND      tmp.IdBodega                          = @IdBodega
               AND      CONVERT(DATE, tmp.FechaPickUpEntrega) = @FechaPickUpEntrega
               AND      tmp.FechaPickUpProgramada             = @FechaPickUpProgramada

        END;
        DROP TABLE #TablaAgrupacionGuiasHouse;
        DROP TABLE #TablaAgrupacionGuiasHouseFinal;

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH;
END;