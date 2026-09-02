/* 
VERSION     MODIFIEDBY        MODIFIEDDATE    HU     MODIFICATION
1           Jair Gomez        2026-02-03      57731  Based on pro_Despacho_PickUpDetalleCompleteScheduled
2           Jair Gomez        2026-09-01      70084  Merging the POD filter and cleaning up redundant JOINs
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetCompletedScheduledPickupDetail] 
(
    @FechaDesde                 DATE,
    @FechaHasta                 DATE,
    @NroDocumento               VARCHAR(32) = NULL,
    @Po                         VARCHAR(32) = NULL,
    @NombreClienteConsignee     VARCHAR(512)= NULL,
    @NroPod                     VARCHAR(16) = NULL,
    @CodigoBarras               VARCHAR(32) = NULL,
    @NombreComercialExportador  VARCHAR(50) = NULL,
    @IdManifiesto               UNIQUEIDENTIFIER = NULL,
    @IdCarrier                  VARCHAR(16) = NULL,
    @IdClienteFinal             VARCHAR(16) = NULL,
    @IdBodega                   VARCHAR(16) = NULL,
    @FechaPickUpProgramada      DATE = NULL,
    @FechaPickUpEntrega         DATE = NULL,
    @PalletLabel                VARCHAR(20) = NULL,
    @IdEmpresa                  VARCHAR(16) = NULL,
    @BillTo                     VARCHAR(128)= NULL
)
AS
BEGIN
    BEGIN TRY
        DECLARE @EmptyUid UNIQUEIDENTIFIER = 0x0

        CREATE TABLE #TMP_HouseGuideGrouping 
        (
            Id                      INT IDENTITY(1, 1) NOT NULL,
            IdClienteFinal          VARCHAR(16)        NULL,
            NombreClienteFinal      VARCHAR(512)       NULL,
            IdClienteConsignee      VARCHAR(16)        NULL,
            NombreClienteConsignee  VARCHAR(512)       NULL,
            FechaPickUpProgramada   DATETIME           NOT NULL,
            FechaPickUpEntrega      DATETIME           NOT NULL,
            IdUsuarioLog            VARCHAR(32)        NULL,
            TotalPending            INT                NOT NULL,
            TotalHold               INT                NOT NULL,
            TotalShort              INT                NOT NULL,
            TotalReceived           INT                NOT NULL,
            TotalStandBy            INT                NOT NULL,
            TotalDespachado         INT                NOT NULL,
            Total                   INT                NOT NULL,
            IdBodega                VARCHAR(16)        NULL,
            IdManifiesto            UNIQUEIDENTIFIER   NULL,
            IdCarrier               VARCHAR(16)        NOT NULL,
            NombreCarrier           VARCHAR(512)       NOT NULL,
            IdGuia                  VARCHAR(128)       NOT NULL,
            NroDocumento            VARCHAR(32)        NOT NULL,
            IdOrdenVenta            UNIQUEIDENTIFIER   NULL,
            NroOrdenVenta           VARCHAR(32)        NULL,
            ConPod                  INT                NOT NULL,
            Enviado                 INT                NOT NULL,
            Procesado               INT                NOT NULL
        )

        CREATE TABLE #TMP_HouseGuideGroupingFinal 
        (
            Id                      INT IDENTITY(1, 1) NOT NULL,
            IdClienteFinal          VARCHAR(16)        NOT NULL,
            NombreClienteFinal      VARCHAR(512)       NULL,
            IdClienteConsignee      VARCHAR(16)        NOT NULL,
            NombreClienteConsignee  VARCHAR(512)       NULL,
            FechaPickUpProgramada   DATETIME           NOT NULL,
            FechaPickUpEntrega      DATETIME           NOT NULL,
            IdUsuarioLog            VARCHAR(32)        NULL,
            TotalPending            INT                NOT NULL,
            TotalHold               INT                NOT NULL,
            TotalShort              INT                NOT NULL,
            TotalReceived           INT                NOT NULL,
            TotalStandBy            INT                NOT NULL,
            TotalDespachado         INT                NOT NULL,
            Total                   INT                NOT NULL,
            IdBodega                VARCHAR(16)        NULL,
            IdManifiesto            UNIQUEIDENTIFIER   NULL,
            IdCarrier               VARCHAR(16)        NOT NULL,
            NombreCarrier           VARCHAR(512)       NOT NULL,
            IdGuia                  VARCHAR(128)       NOT NULL,
            NroDocumento            VARCHAR(32)        NOT NULL,
            IdOrdenVenta            UNIQUEIDENTIFIER   NULL,
            NroOrdenVenta           VARCHAR(32)        NULL,
            ConPod                  INT                NOT NULL,
            Enviado                 INT                NOT NULL,
            Procesado               INT                NOT NULL
        )

        SELECT
             PL.IdEmpresa
            ,TR1.Id
            ,TR1.Nombre
        INTO #TMP_Transports
        FROM Transportes TR1
        INNER JOIN Transportes TR2 ON TR1.IdTransportePrincipal = TR2.Id
        INNER JOIN ParametrosCatalogos PCT ON TR2.Id = PCT.IdEntidad
        INNER JOIN ParametrosLista PL ON PCT.IdParametroLista = PL.Id
            AND PL.Codigo = 'EsDelivery'
        WHERE PCT.Valor = 'NO'

        IF (@NroDocumento IS NULL
            AND @Po IS NULL
            AND @NombreClienteConsignee IS NULL
            AND @NroPod IS NULL
            AND @CodigoBarras IS NULL
            AND @NombreComercialExportador IS NULL
            AND @BillTo IS NULL)
        BEGIN
            INSERT INTO #TMP_HouseGuideGrouping (
                IdClienteFinal, 
                NombreClienteFinal, 
                IdClienteConsignee, 
                NombreClienteConsignee,
                FechaPickUpProgramada, 
                FechaPickUpEntrega, 
                IdUsuarioLog, 
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
                ConPod, 
                Enviado, 
                Procesado
            )
            SELECT 
                 GHD.ShipToId
                ,CLF.Nombre
                ,GH.ConsigneeId
                ,CGN.Nombre
                ,PC.FechaDespacho
                ,MAX(GHD.FechaCambio)
                ,GHD.IdUsuarioLog
                ,SUM(CASE WHEN GHD.EstadoPieza = 'PENDING'       THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'HOLD'          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'SHORT'         THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'RECEIVED WH'   THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'STANDBY'       THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END)
                ,COUNT(1)
                ,CASE 
                WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') 
                THEN GH.IdBodega ELSE UB.IdBodega END
                ,MD.Id
                ,PC.IdCarrier
                ,TRP.Nombre
                ,GH.IdGuia
                ,GH.NroGuia
                ,SDV.Id
                ,SDV.NroOrden
                ,MAX(CASE WHEN DCD.NombreArchivo LIKE 'POD%' THEN 1 ELSE 0 END)
                ,MAX(CASE WHEN DCD.MailEnviado = 1 THEN 1 ELSE 0 END)
                ,MAX(CASE WHEN DCD.PodProcesado = 1 THEN 1 ELSE 0 END)
            FROM GuiasHouseDetalles GHD WITH(NOLOCK)        
            INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
            LEFT JOIN v_ClientsEntities CLF WITH(NOLOCK) ON CLF.Id = GHD.ShipToId
            LEFT JOIN v_ClientsEntities CGN WITH(NOLOCK) ON CGN.Id = GH.BillToConsigneeId
            INNER JOIN ProgramacionCarrier PC WITH(NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
            INNER JOIN #TMP_Transports TRP ON PC.IdCarrier = TRP.Id AND TRP.IdEmpresa = GH.IdEmpresa
            LEFT JOIN ProgramacionManifiesto PM WITH(NOLOCK) ON PM.IdProgramacionCarrier = PC.Id 
            LEFT JOIN ManifiestosDespacho MD ON MD.Id = PM.IdManifiestoDespacho
            OUTER APPLY (
                SELECT TOP 1 DD.EsPod, DD.NombreArchivo, DD.MailEnviado, DD.PodProcesado
                FROM DocumentosDespacho DD 
                WHERE DD.IdManifiesto = MD.Id 
                  AND DD.IdDocumento = 'DOC052395'
                ORDER BY EsPod DESC
            ) DCD
            OUTER APPLY (   
                SELECT TOP (1) SD.Id, SD.NroOrden
                FROM SolicitudDeVentaDetalles SVD 
                LEFT JOIN SolicitudDeVenta SD ON SD.Id = SVD.IdSolicitud
                WHERE SVD.IdGuiaHouseDetalle = GHD.Id
                ORDER BY SD.FechaSolicitud DESC
            ) SDV
            LEFT JOIN PalletsDetalles PLD WITH(NOLOCK) ON GHD.Id = PLD.IdGuiasHouseDetalle
            LEFT JOIN Pallets PAL WITH(NOLOCK) ON PLD.IdPallet = PAL.Id
            LEFT JOIN UbicacionPiezas UP WITH(NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones U ON UP.IdUbicacion = U.Id
            LEFT JOIN UbicacionesBodega UB ON U.IdUbicacionBodega = UB.Id
            WHERE GH.IdEmpresa = @IdEmpresa
              AND DCD.EsPod = 1 
              AND PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
              AND (@PalletLabel IS NULL OR PAL.Pallet LIKE '%' + @PalletLabel + '%') 
            GROUP BY 
                 GHD.ShipToId
                ,CLF.Nombre
                ,GH.ConsigneeId
                ,CGN.Nombre
                ,CASE 
                WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') 
                THEN GH.IdBodega ELSE UB.IdBodega END
                ,PC.FechaDespacho
                ,CONVERT(DATE, GHD.FechaCambio)
                ,MD.Id
                ,PC.IdCarrier
                ,TRP.Nombre
                ,GHD.IdUsuarioLog
                ,GH.IdGuia
                ,GH.NroGuia
                ,SDV.Id
                ,SDV.NroOrden
            HAVING COUNT(1) = SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END)
        END
        ELSE
        BEGIN
            INSERT INTO #TMP_HouseGuideGrouping (
                IdClienteFinal, 
                NombreClienteFinal, 
                IdClienteConsignee, 
                NombreClienteConsignee,
                FechaPickUpProgramada, 
                FechaPickUpEntrega, 
                IdUsuarioLog, 
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
                ConPod, 
                Enviado, 
                Procesado
            )
            SELECT 
                 GHD.ShipToId
                ,CLF.Nombre
                ,GH.ConsigneeId
                ,CGN.Nombre
                ,PC.FechaDespacho
                ,MAX(GHD.FechaCambio)
                ,GHD.IdUsuarioLog
                ,SUM(CASE WHEN GHD.EstadoPieza = 'PENDING'       THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'HOLD'          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'SHORT'         THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'RECEIVED WH'   THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'STANDBY'       THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END)
                ,COUNT(1)
                ,CASE 
                WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') 
                THEN GH.IdBodega ELSE UB.IdBodega END
                ,MD.Id
                ,PC.IdCarrier
                ,TRP.Nombre
                ,GH.IdGuia
                ,GH.NroGuia
                ,SDV.Id
                ,SDV.NroOrden
                ,MAX(CASE WHEN DCD.NombreArchivo LIKE 'POD%' THEN 1 ELSE 0 END)
                ,MAX(CASE WHEN DCD.MailEnviado = 1 THEN 1 ELSE 0 END)
                ,MAX(CASE WHEN DCD.PodProcesado = 1 THEN 1 ELSE 0 END)
            FROM GuiasHouseDetalles GHD WITH(NOLOCK) 
            INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
            LEFT JOIN v_ClientsEntities CLF WITH(NOLOCK) ON CLF.Id = GHD.ShipToId
            LEFT JOIN v_ClientsEntities CGN WITH(NOLOCK) ON CGN.Id = GH.BillToConsigneeId
            INNER JOIN Exportadores EXS ON GH.IdExportador = EXS.Id
            INNER JOIN ProgramacionCarrier PC WITH(NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
            INNER JOIN #TMP_Transports TRP ON PC.IdCarrier = TRP.Id AND TRP.IdEmpresa = GH.IdEmpresa
            LEFT JOIN ProgramacionManifiesto PM WITH(NOLOCK) ON PM.IdProgramacionCarrier = PC.Id 
            LEFT JOIN ManifiestosDespacho MD ON MD.Id = PM.IdManifiestoDespacho
            OUTER APPLY (
                SELECT TOP 1 DD.EsPod, DD.NombreArchivo, DD.MailEnviado, DD.PodProcesado
                FROM DocumentosDespacho DD 
                WHERE DD.IdManifiesto = MD.Id 
                  AND DD.IdDocumento = 'DOC052395'
                ORDER BY EsPod DESC
            ) DCD
            OUTER APPLY (
                SELECT TOP (1) SD.Id, SD.NroOrden
                FROM SolicitudDeVentaDetalles SVD 
                LEFT JOIN SolicitudDeVenta SD ON SD.Id = SVD.IdSolicitud
                WHERE SVD.IdGuiaHouseDetalle = GHD.Id
                ORDER BY SD.FechaSolicitud DESC
            ) SDV
            LEFT JOIN PalletsDetalles PLD WITH(NOLOCK) ON GHD.Id = PLD.IdGuiasHouseDetalle
            LEFT JOIN Pallets PAL WITH(NOLOCK) ON PLD.IdPallet = PAL.Id
            LEFT JOIN UbicacionPiezas UP WITH(NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones U ON UP.IdUbicacion = U.Id
            LEFT JOIN UbicacionesBodega UB ON U.IdUbicacionBodega = UB.Id
            WHERE GH.IdEmpresa = @IdEmpresa
              AND PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
              AND DCD.EsPod = 1
              AND (@NroDocumento IS NULL OR GH.NroGuia LIKE '%' + @NroDocumento + '%')
              AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
              AND (@NombreClienteConsignee IS NULL OR @NombreClienteConsignee = ''
                  OR CGN.Id IN (SELECT Id FROM dbo.f_SearchEntities(@NombreClienteConsignee, 'Consignee')))    
              AND (@BillTo IS NULL OR @BillTo = '' 
                  OR CGN.Id IN (SELECT Id FROM dbo.f_SearchEntities(@BillTo, 'BillTo')))
              AND (@NroPod IS NULL OR MD.NroManifiesto LIKE '%' + @NroPod + '%')
              AND (@CodigoBarras IS NULL OR GHD.CodigoBarra LIKE '%' + @CodigoBarras + '%')
              AND (@NombreComercialExportador IS NULL OR EXS.NombreComercial LIKE '%' + @NombreComercialExportador + '%')
              AND (@PalletLabel IS NULL OR PAL.Pallet LIKE '%' + @PalletLabel + '%')          
            GROUP BY 
                 GHD.ShipToId
                ,CLF.Nombre
                ,GH.ConsigneeId
                ,CGN.Nombre
                ,CASE 
                WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') 
                THEN GH.IdBodega ELSE UB.IdBodega END
                ,PC.FechaDespacho
                ,CONVERT(DATE, GHD.FechaCambio)
                ,MD.Id
                ,PC.IdCarrier
                ,TRP.Nombre
                ,GHD.IdUsuarioLog
                ,GH.IdGuia
                ,GH.NroGuia
                ,SDV.Id
                ,SDV.NroOrden
            HAVING COUNT(1) = SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END)
        END

        INSERT INTO #TMP_HouseGuideGroupingFinal (
            IdClienteFinal,
            NombreClienteFinal, 
            IdClienteConsignee, 
            NombreClienteConsignee,
            FechaPickUpProgramada, 
            FechaPickUpEntrega, 
            IdUsuarioLog, 
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
            ConPod, 
            Enviado, 
            Procesado
        )
        SELECT 
             TMP.IdClienteFinal
            ,TMP.NombreClienteFinal
            ,TMP.IdClienteConsignee
            ,TMP.NombreClienteConsignee
            ,TMP.FechaPickUpProgramada
            ,MAX(TMP.FechaPickUpEntrega) 
            ,(SELECT TOP (1) SUB.IdUsuarioLog 
                FROM #TMP_HouseGuideGrouping SUB 
                WHERE SUB.IdGuia = TMP.IdGuia 
                AND CONVERT(DATE, SUB.FechaPickUpEntrega) = CONVERT(DATE, TMP.FechaPickUpEntrega) 
              ORDER BY SUB.FechaPickUpEntrega DESC
             ) AS IdUsuarioLog
            ,SUM(TMP.TotalPending)
            ,SUM(TMP.TotalHold)
            ,SUM(TMP.TotalShort)
            ,SUM(TMP.TotalReceived)
            ,SUM(TMP.TotalStandBy)
            ,SUM(TMP.TotalDespachado)
            ,SUM(TMP.Total)
            ,TMP.IdBodega
            ,TMP.IdManifiesto
            ,TMP.IdCarrier
            ,TMP.NombreCarrier
            ,TMP.IdGuia
            ,TMP.NroDocumento
            ,TMP.IdOrdenVenta
            ,TMP.NroOrdenVenta
            ,TMP.ConPod
            ,TMP.Enviado
            ,TMP.Procesado
        FROM #TMP_HouseGuideGrouping TMP
        GROUP BY 
             TMP.IdClienteFinal
            ,TMP.NombreClienteFinal
            ,TMP.IdClienteConsignee
            ,TMP.NombreClienteConsignee
            ,TMP.FechaPickUpProgramada
            ,CONVERT(DATE, TMP.FechaPickUpEntrega)
            ,TMP.IdBodega
            ,TMP.IdManifiesto
            ,TMP.IdCarrier
            ,TMP.NombreCarrier
            ,TMP.ConPod
            ,TMP.Enviado
            ,TMP.Procesado
            ,TMP.IdGuia
            ,TMP.NroDocumento
            ,TMP.IdOrdenVenta
            ,TMP.NroOrdenVenta

        IF @IdClienteFinal IS NULL
        BEGIN
            SELECT 
                 FIN.Id
                ,'Entregada' AS Estatus
                ,'dispatch-pick-up-delivered' AS ClaseCssEstatus
                ,FIN.IdGuia
                ,FIN.NroDocumento
                ,FIN.IdOrdenVenta
                ,FIN.NroOrdenVenta                  
                ,FIN.IdClienteFinal
                ,FIN.NombreClienteFinal
                ,FIN.IdClienteConsignee
                ,FIN.NombreClienteConsignee
                ,FIN.FechaPickUpProgramada
                ,'' AS FechaPickUpProgramadaString
                ,FIN.FechaPickUpEntrega
                ,'' AS FechaPickUpEntregaString
                ,CONVERT(TIME, FIN.FechaPickUpEntrega) AS HoraEntrega
                ,FIN.TotalPending AS PcsPending
                ,FIN.TotalHold AS PcsHold
                ,FIN.TotalShort AS PcsShort
                ,FIN.TotalReceived AS PcsReceivedWh
                ,FIN.TotalStandBy AS PcsStandby
                ,FIN.TotalDespachado AS TotalDespachado
                ,FIN.Total
                ,FIN.IdBodega
                ,B.Nombre AS NombreBodega
                ,FIN.IdManifiesto
                ,FIN.IdCarrier
                ,FIN.NombreCarrier
                ,ISNULL(USR.Nombre, '') + ' ' AS UsuarioFechaCambio
                ,CONVERT(BIT, FIN.Enviado) AS Enviado
                ,CONVERT(BIT, FIN.Procesado) AS Procesado
            FROM #TMP_HouseGuideGroupingFinal FIN
            INNER JOIN Bodegas B ON FIN.IdBodega = B.Id
            INNER JOIN Usuarios USR ON USR.Id = FIN.IdUsuarioLog
        END
        ELSE
        BEGIN
            SELECT 
                 FIN.Id
                ,'Entregada' AS Estatus
                ,'dispatch-pick-up-delivered' AS ClaseCssEstatus
                ,FIN.IdGuia
                ,FIN.NroDocumento
                ,FIN.IdOrdenVenta
                ,FIN.NroOrdenVenta                  
                ,FIN.IdClienteFinal
                ,FIN.NombreClienteFinal
                ,FIN.IdClienteConsignee
                ,FIN.NombreClienteConsignee
                ,FIN.FechaPickUpProgramada
                ,'' AS FechaPickUpProgramadaString
                ,FIN.FechaPickUpEntrega
                ,'' AS FechaPickUpEntregaString
                ,CONVERT(TIME, FIN.FechaPickUpEntrega) AS HoraEntrega
                ,FIN.TotalPending AS PcsPending
                ,FIN.TotalHold AS PcsHold
                ,FIN.TotalShort AS PcsShort
                ,FIN.TotalReceived AS PcsReceivedWh
                ,FIN.TotalStandBy AS PcsStandby
                ,FIN.TotalDespachado AS TotalDespachado
                ,FIN.Total
                ,FIN.IdBodega
                ,B.Nombre AS NombreBodega
                ,FIN.IdManifiesto
                ,FIN.IdCarrier
                ,FIN.NombreCarrier
                ,ISNULL(USR.Nombre, '') + ' ' AS UsuarioFechaCambio
                ,CONVERT(BIT, FIN.Enviado) AS Enviado
                ,CONVERT(BIT, FIN.Procesado) AS Procesado
            FROM #TMP_HouseGuideGroupingFinal FIN
            INNER JOIN Bodegas B ON FIN.IdBodega = B.Id
            INNER JOIN Usuarios USR ON USR.Id = FIN.IdUsuarioLog
            WHERE ISNULL(FIN.IdManifiesto, @EmptyUid) = ISNULL(@IdManifiesto, @EmptyUid)
              AND FIN.IdCarrier = @IdCarrier
              AND FIN.IdClienteFinal = @IdClienteFinal
              AND FIN.IdBodega = @IdBodega
              AND CONVERT(DATE, FIN.FechaPickUpEntrega) = @FechaPickUpEntrega
              AND FIN.FechaPickUpProgramada = @FechaPickUpProgramada
        END

        DROP TABLE #TMP_HouseGuideGrouping
        DROP TABLE #TMP_HouseGuideGroupingFinal
        DROP TABLE #TMP_Transports

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH;
END;
/*
    EXEC [dbo].[AC_pro_GetCompletedScheduledPickupDetail] 
    @FechaDesde = '2026-01-03',
    @FechaHasta = '2026-01-05',
    @IdEmpresa  = 'EMP014';

    EXEC [dbo].[AC_pro_GetCompletedScheduledPickupDetail]
    @FechaDesde                 = '2026-01-03',
    @FechaHasta                 = '2026-01-05',
    @NroDocumento               = NULL,
    @Po                          = NULL,
    @NombreClienteConsignee     = NULL,
    @NroPod                     = NULL,
    @CodigoBarras               = NULL,
    @NombreComercialExportador  = NULL,
    @IdManifiesto               = 'BFB80C7A-AF03-415A-8517-2A2121F13D7B',
    @IdCarrier                  = 'ZWYOb294',
    @IdClienteFinal             = 'ETY000121625',
    @IdBodega                   = 'QK6s23du',
    @FechaPickUpProgramada      = '2026-01-03',
    @FechaPickUpEntrega         = '2026-01-02',
    @PalletLabel                = NULL,
    @IdEmpresa                  = 'EMP014',
    @BillTo                     = NULL;


*/