USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_Despacho_PickUpDetalleCompleteDelivered]    Script Date: 30/01/2026 10:55:21 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER     PROCEDURE [dbo].[AC_Despacho_PickUpDetalleCompleteDelivered] (
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
@idEmpresa VARCHAR(16) = NULL),
@BillTo VARCHAR(100) = NULL
AS
BEGIN
    BEGIN TRY

        DECLARE @emptyUID UNIQUEIDENTIFIER = 0x0;

        -- Se agregan campos de Nombres para evitar Joins al final
        CREATE TABLE #TablaAgrupacionGuiasHouse (
            Id INT IDENTITY(1, 1) NOT NULL,
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
            Procesado INT NOT NULL
        );

        -- Misma estructura para la tabla final
        CREATE TABLE #TablaAgrupacionGuiasHouseFinal (
            Id INT IDENTITY(1, 1) NOT NULL,
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
            Procesado INT NOT NULL
        );

        -- Tablas auxiliares se mantienen igual
        SELECT parametroLista.idEmpresa, subCarrier.id, subCarrier.nombre
        INTO #TMP_TRANS
        FROM  dbo.Transportes subCarrier
        INNER JOIN  dbo.Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
        INNER JOIN  dbo.ParametrosCatalogos parametroCatalogo
        ON carrier.id = parametroCatalogo.idEntidad
        INNER JOIN  dbo.ParametrosLista parametroLista
        ON parametroCatalogo.idParametroLista = parametroLista.id
        AND parametroLista.codigo = 'EsDelivery'
        WHERE parametroCatalogo.valor = 'NO';

        SELECT	GHH.idGuiaHouseDetalle
              , MAX(GHH.fechaCambio) AS fechaCambio 
        INTO #GuiaHouseDetalleHistoricoTemp
        FROM GuiasHouseDetallesHistorico GHH WITH (NOLOCK)
        WHERE GHH.fechaCambio BETWEEN @FechaDesde AND @FechaHasta
        AND GHH.VALOR = 'DISPATCHED WH'
        GROUP BY GHH.idGuiaHouseDetalle;

        IF (   @NroDocumento IS NULL
           AND @Po IS NULL
           AND @NombreClienteConsignee IS NULL
           AND @BillTo IS NULL
           AND @NroPOD IS NULL
           AND @CodigoBarras IS NULL
           AND @NombreComercialExportador IS NULL)
        BEGIN
            INSERT INTO #TablaAgrupacionGuiasHouse (
                IdClienteFinal, NombreClienteFinal, -- Agregado Nombre
                IdClienteConsignee, NombreClienteConsignee, -- Agregado Nombre
                FechaPickUpProgramada, FechaPickUpEntrega, idUsuarioLog, 
                TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
                IdBodega, NombreBodega, -- Agregado Nombre
                IdManifiesto, IdCarrier, NombreCarrier, 
                IdGuia, 
                NroDocumento, 
                IdOrdenVenta, 
                NroOrdenVenta, 
                ConPOD, 
                Enviado, 
                Procesado
            )
            SELECT GHD.ShipToId -- (IdClienteFinal)
                 , CLF.nombre   -- (NombreClienteFinal)
                 , GH.ConsigneeId -- (IdClienteConsignee)
                 , CGN.nombre   -- (NombreClienteConsignee)
                 , PC.fechaDespacho
                 , MAX(A.fechaCambio)
                 , GHD.idUsuarioLog
                 , SUM(IIF(GHD.estadoPieza = 'PENDING', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'HOLD', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'SHORT', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'RECEIVED WH', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'STANDBY', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0))
                 , COUNT(1)
                 , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                 , ISNULL(BUB.nombre, BGH.nombre) -- Nombre Bodega (Prioridad Ubicacion vs Header)
                 , MD.id
                 , PC.idCarrier
                 , T.nombre
                 , GH.idGuia
                 , GH.nroGuia
                 , solicitud.id
                 , solicitud.nroOrden
                 , MAX(IIF(DD.nombreArchivo LIKE 'POD%', 1, 0))
                 , MAX(IIF(DD.mailEnviado = 1, 1, 0))
                 , MAX(IIF(DD.podProcesado = 1, 1, 0))
            FROM #GuiaHouseDetalleHistoricoTemp A       
            INNER JOIN dbo.GuiasHouseDetalles GHD WITH(NOLOCK) ON A.idGuiaHouseDetalle = GHD.id
            INNER JOIN dbo.GuiasHouse GH WITH(NOLOCK) ON GHD.idGuiaHouse = GH.id
            -- BREAKING CHANGE: VISTAS
            INNER JOIN v_ClientsEntities CLF WITH (NOLOCK) ON CLF.id = GHD.ShipToId
            INNER JOIN v_ClientsEntities CGN WITH (NOLOCK) ON CGN.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
            
            INNER JOIN dbo.ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
            INNER JOIN #TMP_TRANS T ON PC.idCarrier = T.id AND T.idEmpresa = GH.idEmpresa
            LEFT JOIN dbo.ProgramacionManifiesto PM WITH(NOLOCK) ON PM.idProgramacionCarrier = PC.id
            LEFT JOIN dbo.DocumentosDespacho DD ON PM.idManifiestoDespacho = DD.idManifiesto AND DD.idDocumento = 'DOC052395'
            LEFT JOIN dbo.ManifiestosDespacho MD ON MD.id = PM.idManifiestoDespacho
            OUTER APPLY (   
                SELECT TOP (1) S.id, S.nroOrden
                FROM dbo.SolicitudDeVentaDetalles SD WITH(NOLOCK)
                LEFT JOIN dbo.SolicitudDeVenta S WITH(NOLOCK) ON S.id = SD.idSolicitud
                WHERE SD.idGuiaHouseDetalle = GHD.id
                ORDER BY S.fechaSolicitud DESC
            ) AS solicitud
            LEFT JOIN dbo.PalletsDetalles pld WITH(NOLOCK) ON GHD.id = pld.idGuiasHouseDetalle
            LEFT JOIN dbo.Pallets pal ON WITH(NOLOCK) pld.idPallet = pal.id
            LEFT JOIN UbicacionPiezas AS WITH(NOLOCK) UP ON GHD.id = UP.idGuiaHouseDetalle
            LEFT JOIN Ubicaciones AS U ON UP.idUbicacion = U.id
            LEFT JOIN UbicacionesBodega AS UB ON U.idUbicacionBodega = UB.id
            LEFT JOIN Bodegas BGH ON GH.idBodega = BGH.id
            LEFT JOIN Bodegas BUB ON UB.idBodega = BUB.id

            WHERE GH.idEmpresa = @idEmpresa
              AND (@PalletLabel IS NULL OR pal.pallet LIKE '%' + @PalletLabel + '%') 
              
            GROUP BY GHD.ShipToId
                   , CLF.nombre
                   , GH.ConsigneeId
                   , CGN.nombre
                   , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                   , ISNULL(BUB.nombre, BGH.nombre)
                   , PC.fechaDespacho
                   , CONVERT(DATE, A.fechaCambio)
                   , MD.id
                   , PC.idCarrier
                   , T.nombre
                   , GHD.idUsuarioLog
                   , GH.idGuia
                   , GH.nroGuia
                   , solicitud.id
                   , solicitud.nroOrden
            HAVING COUNT(1) = SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0));
        END;
        ELSE
        BEGIN
            INSERT INTO #TablaAgrupacionGuiasHouse (
                IdClienteFinal, NombreClienteFinal,
                IdClienteConsignee, NombreClienteConsignee,
                FechaPickUpProgramada, FechaPickUpEntrega, idUsuarioLog, 
                TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
                IdBodega, 
                NombreBodega,
                IdManifiesto, 
                IdCarrier, 
                NombreCarrier, 
                IdGuia, 
                NroDocumento, 
                IdOrdenVenta, 
                NroOrdenVenta, 
                ConPOD, 
                Enviado, 
                Procesado
            )
            SELECT GHD.ShipToId
                 , CLF.nombre
                 , GH.ConsigneeId
                 , CGN.nombre
                 , PC.fechaDespacho
                 , MAX(A.fechaCambio)
                 , GHD.idUsuarioLog
                 , SUM(IIF(GHD.estadoPieza = 'PENDING', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'HOLD', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'SHORT', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'RECEIVED WH', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'STANDBY', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0))
                 , COUNT(1)
                 , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                 , ISNULL(BUB.nombre, BGH.nombre)
                 , MD.id
                 , PC.idCarrier
                 , T.nombre
                 , GH.idGuia
                 , GH.nroGuia
                 , solicitud.id
                 , solicitud.nroOrden
                 , MAX(IIF(DD.nombreArchivo LIKE 'POD%', 1, 0))
                 , MAX(IIF(DD.mailEnviado = 1, 1, 0))
                 , MAX(IIF(DD.podProcesado = 1, 1, 0))

            FROM #GuiaHouseDetalleHistoricoTemp A       
            INNER JOIN dbo.GuiasHouseDetalles GHD WITH(NOLOCK) ON A.idGuiaHouseDetalle = GHD.id
            INNER JOIN dbo.GuiasHouse GH WITH(NOLOCK) ON GHD.idGuiaHouse = GH.id
            -- BREAKING CHANGE
            INNER JOIN v_ClientsEntities CLF WITH (NOLOCK) ON CLF.id = GHD.ShipToId
            INNER JOIN v_ClientsEntities CGN WITH (NOLOCK) ON CGN.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
            INNER JOIN dbo.Exportadores EXP ON GH.idExportador = EXP.id
            
            INNER JOIN dbo.ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
            INNER JOIN #TMP_TRANS T ON PC.idCarrier = T.id AND T.idEmpresa = GH.idEmpresa
            LEFT JOIN dbo.ProgramacionManifiesto PM WITH(NOLOCK) ON PM.idProgramacionCarrier = PC.id
            LEFT JOIN dbo.DocumentosDespacho DD ON PM.idManifiestoDespacho = DD.idManifiesto AND DD.idDocumento = 'DOC052395'
            LEFT JOIN dbo.ManifiestosDespacho MD ON MD.id = PM.idManifiestoDespacho
            
            OUTER APPLY (SELECT TOP (1) S.id, S.nroOrden
                         FROM dbo.SolicitudDeVentaDetalles SD WITH(NOLOCK)
                         LEFT JOIN dbo.SolicitudDeVenta S WITH(NOLOCK) ON S.id = SD.idSolicitud
                         WHERE SD.idGuiaHouseDetalle = GHD.id
                         ORDER BY S.fechaSolicitud DESC) AS solicitud

            LEFT JOIN dbo.PalletsDetalles pld WITH(NOLOCK) ON GHD.id = pld.idGuiasHouseDetalle
            LEFT JOIN dbo.Pallets pal WITH(NOLOCK) ON pld.idPallet = pal.id
            LEFT JOIN UbicacionPiezas UP WITH(NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
            LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
            LEFT JOIN UbicacionesBodega UB ON U.idUbicacionBodega = UB.id
            LEFT JOIN Bodegas BGH ON GH.idBodega = BGH.id
            LEFT JOIN Bodegas BUB ON UB.idBodega = BUB.id

            WHERE GH.idEmpresa = @idEmpresa
              AND (@NroDocumento IS NULL OR GH.nroGuia LIKE '%' + @NroDocumento + '%')
              AND (@Po IS NULL OR GHD.po LIKE '%' + @Po + '%')
              AND (@NombreClienteConsignee IS NULL OR CGN.nombre LIKE '%' + @NombreClienteConsignee + '%') -- Usa nombre de la vista
              AND (@BillTo IS NULL OR (CGN.BillToId IS NOT NULL AND CGN.BillToName LIKE '%' + @BillTo + '%'))
              AND (@NroPOD IS NULL OR MD.nroManifiesto LIKE '%' + @NroPOD + '%')
              AND (@CodigoBarras IS NULL OR GHD.codigoBarra LIKE '%' + @CodigoBarras + '%')
              AND (@NombreComercialExportador IS NULL OR EXP.nombreComercial LIKE '%' + @NombreComercialExportador + '%')
              AND (@PalletLabel IS NULL OR pal.pallet LIKE '%' + @PalletLabel + '%')          

            GROUP BY GHD.ShipToId
                   , CLF.nombre
                   , GH.ConsigneeId
                   , CGN.nombre
                   , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                   , ISNULL(BUB.nombre, BGH.nombre)
                   , PC.fechaDespacho
                   , MD.id
                   , PC.idCarrier
                   , T.nombre
                   , GHD.idUsuarioLog
                   , GH.idGuia
                   , GH.nroGuia
                   , solicitud.id
                   , solicitud.nroOrden
            HAVING COUNT(1) = SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0));
        END;
        INSERT INTO #TablaAgrupacionGuiasHouseFinal (
            IdClienteFinal, NombreClienteFinal,
            IdClienteConsignee, NombreClienteConsignee,
            FechaPickUpProgramada, FechaPickUpEntrega, idUsuarioLog, 
            TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
            IdBodega, NombreBodega,
            IdManifiesto, IdCarrier, NombreCarrier, IdGuia, NroDocumento, IdOrdenVenta, NroOrdenVenta, ConPOD, Enviado, Procesado
        )
        SELECT tbl.IdClienteFinal
             , tbl.NombreClienteFinal
             , tbl.IdClienteConsignee
             , tbl.NombreClienteConsignee
             , tbl.FechaPickUpProgramada
             , MAX(tbl.FechaPickUpEntrega) 
             , (SELECT TOP (1) sub.idUsuarioLog
                FROM #TablaAgrupacionGuiasHouse sub
                WHERE sub.IdGuia = tbl.IdGuia -- 1. Match por Guía (Vinculamos con el Padre)
                  -- 2. Match por Fecha (Aseguramos que sea del mismo día del grupo)
                  AND CONVERT(DATE, sub.FechaPickUpEntrega) = CONVERT(DATE, tbl.FechaPickUpEntrega)
                ORDER BY sub.FechaPickUpEntrega DESC
               ) AS IdUsuarioLog
             , SUM(tbl.TotalPending)
             , SUM(tbl.TotalHold)
             , SUM(tbl.TotalShort)
             , SUM(tbl.TotalReceived)
             , SUM(tbl.TotalStandBy)
             , SUM(tbl.TotalDespachado)
             , SUM(tbl.Total)
             , tbl.IdBodega
             , tbl.NombreBodega
             , tbl.IdManifiesto
             , tbl.IdCarrier
             , tbl.NombreCarrier
             , tbl.IdGuia
             , tbl.NroDocumento
             , tbl.IdOrdenVenta
             , tbl.NroOrdenVenta
             , tbl.ConPOD
             , tbl.Enviado
             , tbl.Procesado
        FROM #TablaAgrupacionGuiasHouse tbl
        GROUP BY tbl.IdClienteFinal, tbl.NombreClienteFinal
               , tbl.IdClienteConsignee, tbl.NombreClienteConsignee
               , tbl.FechaPickUpProgramada
               , CONVERT(DATE, tbl.FechaPickUpEntrega)
               , tbl.IdBodega, tbl.NombreBodega
               , tbl.IdManifiesto
               , tbl.IdCarrier
               , tbl.NombreCarrier
               , tbl.ConPOD, tbl.Enviado, tbl.Procesado
               , tbl.IdGuia, tbl.NroDocumento
               , tbl.IdOrdenVenta, tbl.NroOrdenVenta;          
        -- =================================================================================
        -- BLOQUE FINAL: OUTPUT
        -- =================================================================================
        
        -- CASO 1: SIN FILTROS (Trae todo lo de la tabla final)
        IF @IdClienteFinal IS NULL
        BEGIN
            SELECT tmp.Id
                 , 'Entregada' AS Estatus
                 , 'dispatch-pick-up-delivered' AS ClaseCssEstatus       
                 , tmp.IdGuia
                 , tmp.NroDocumento
                 , tmp.IdOrdenVenta
                 , tmp.NroOrdenVenta                  
                 , tmp.IdClienteFinal
                 , tmp.NombreClienteFinal --Sin Join
                 , tmp.IdClienteConsignee
                 , tmp.NombreClienteConsignee --  Sin Join
                 , tmp.FechaPickUpProgramada
                 , '' AS FechaPickUpProgramadaString
                 , tmp.FechaPickUpEntrega
                 , '' AS FechaPickUpEntregaString
                 , CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega
                 , tmp.TotalPending AS PcsPending
                 , tmp.TotalHold AS PcsHold
                 , tmp.TotalShort AS PcsShort
                 , tmp.TotalReceived AS PcsReceivedWh
                 , tmp.TotalStandBy AS PcsStandby
                 , tmp.TotalDespachado AS TotalDespachado
                 , tmp.Total
                 , tmp.IdBodega
                 , tmp.NombreBodega --Sin Join
                 , tmp.IdManifiesto
                 , tmp.IdCarrier
                 , tmp.NombreCarrier
                 , ISNULL(usuario.nombre, '') + ' ' AS UsuarioFechaCambio
                 , CONVERT(BIT, tmp.Enviado) AS Enviado
                 , CONVERT(BIT, tmp.Procesado) AS Procesado

            FROM #TablaAgrupacionGuiasHouseFinal AS tmp
            -- Único JOIN necesario (si no guardaste nombre de usuario antes)
            INNER JOIN dbo.Usuarios usuario ON usuario.Id = tmp.idUsuarioLog
        END;
        -- CASO 2: CON FILTROS (Aplica WHERE sobre la tabla final)
        ELSE
        BEGIN
            SELECT tmp.Id
                 , 'Entregada' AS Estatus
                 , 'dispatch-pick-up-delivered' AS ClaseCssEstatus       
                 , tmp.IdGuia
                 , tmp.NroDocumento
                 , tmp.IdOrdenVenta
                 , tmp.NroOrdenVenta                  
                 , tmp.IdClienteFinal
                 , tmp.NombreClienteFinal -- Optimizado
                 , tmp.IdClienteConsignee
                 , tmp.NombreClienteConsignee -- Optimizado
                 , tmp.FechaPickUpProgramada
                 , '' AS FechaPickUpProgramadaString
                 , tmp.FechaPickUpEntrega
                 , '' AS FechaPickUpEntregaString
                 , CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega
                 , tmp.TotalPending AS PcsPending
                 , tmp.TotalHold AS PcsHold
                 , tmp.TotalShort AS PcsShort
                 , tmp.TotalReceived AS PcsReceivedWh
                 , tmp.TotalStandBy AS PcsStandby
                 , tmp.TotalDespachado AS TotalDespachado
                 , tmp.Total
                 , tmp.IdBodega
                 , tmp.NombreBodega -- Optimizado
                 , tmp.IdManifiesto
                 , tmp.IdCarrier
                 , tmp.NombreCarrier
                 , ISNULL(usuario.nombre, '') + ' ' AS UsuarioFechaCambio
                 , CONVERT(BIT, tmp.Enviado) AS Enviado
                 , CONVERT(BIT, tmp.Procesado) AS Procesado

            FROM #TablaAgrupacionGuiasHouseFinal AS tmp
            INNER JOIN dbo.Usuarios usuario ON usuario.Id = tmp.idUsuarioLog
            WHERE ISNULL(tmp.IdManifiesto, @emptyUID) = ISNULL(@IdManifiesto, @emptyUID)
              AND tmp.IdCarrier = @IdCarrier
              AND tmp.IdClienteFinal = @IdClienteFinal
              AND tmp.IdBodega = @IdBodega
              AND CONVERT(DATE, tmp.FechaPickUpEntrega) = @FechaPickUpEntrega
              AND tmp.FechaPickUpProgramada = @FechaPickUpProgramada
        END;

        DROP TABLE #TablaAgrupacionGuiasHouse;
        DROP TABLE #TablaAgrupacionGuiasHouseFinal;
        DROP TABLE #TMP_TRANS;
        DROP TABLE #GuiaHouseDetalleHistoricoTemp;

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH;
END;