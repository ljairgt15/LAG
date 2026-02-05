/* VERSION     MODIFIEDBY        MODIFIEDDATE    HU     MODIFICATION
1              Jair GOMEZ        2026-02-03      57731    Initial Code,store procedure based on pro_Despacho_PickupDetalleCompletedScheduled changed with v_ClientEntities - Refactoring based on standards
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_Despacho_PickupDetalleCompletedScheduled] 
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
        DECLARE @EmptyUid UNIQUEIDENTIFIER = 0x0;

        CREATE TABLE #TMP_HouseGuideGrouping 
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
            NombreBodega            NVARCHAR(512)      NULL,
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
        );

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
            NombreBodega            NVARCHAR(512)      NULL,
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
        );

        IF (@NroDocumento IS NULL
            AND @Po IS NULL
            AND @NombreClienteConsignee IS NULL
            AND @NroPod IS NULL
            AND @CodigoBarras IS NULL
            AND @NombreComercialExportador IS NULL
            AND @BillTo IS NULL)
        BEGIN
            INSERT INTO #TMP_HouseGuideGrouping (
                IdClienteFinal, NombreClienteFinal, 
                IdClienteConsignee, NombreClienteConsignee,
                FechaPickUpProgramada, FechaPickUpEntrega, IdUsuarioLog, 
                TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
                IdBodega, NombreBodega,
                IdManifiesto, IdCarrier, NombreCarrier, IdGuia, NroDocumento, IdOrdenVenta, NroOrdenVenta, ConPod, Enviado, Procesado
            )
            SELECT 
                 GHD.ShipToId
                ,ST.Nombre   -- ShipTo Name
                ,GH.ConsigneeId
                ,C.Nombre    -- Consignee/BillTo Name
                ,PC.FechaDespacho
                ,MAX(GHD.FechaCambio)
                ,GHD.IdUsuarioLog
                ,SUM(CASE WHEN GHD.EstadoPieza = 'PENDING' THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'HOLD' THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'SHORT' THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'RECEIVED WH' THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'STANDBY' THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END)
                ,COUNT(1)
                ,CASE WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') THEN GH.IdBodega ELSE UB.IdBodega END
                ,ISNULL(BUB.Nombre, BGH.Nombre)
                ,MD.Id
                ,PC.IdCarrier
                ,T.Nombre -- SubCarrier
                ,GH.IdGuia
                ,GH.NroGuia
                ,SDV.Id
                ,SDV.NroOrden
                ,MAX(CASE WHEN ISNULL(DD.EsPod, 0) = 1 THEN 1 ELSE 0 END)
                ,MAX(CASE WHEN DD.MailEnviado = 1 THEN 1 ELSE 0 END)
                ,MAX(CASE WHEN DD.PodProcesado = 1 THEN 1 ELSE 0 END)
            FROM dbo.GuiasHouseDetalles GHD WITH(NOLOCK) 
            INNER JOIN dbo.GuiasHouse GH WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
            INNER JOIN v_ClientsEntities ST WITH (NOLOCK) ON ST.Id = GHD.ShipToId
            LEFT JOIN v_ClientsEntities C WITH (NOLOCK) ON C.Id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
            INNER JOIN dbo.ProgramacionCarrier PC WITH(NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id
            INNER JOIN dbo.Transportes T ON PC.IdCarrier = T.Id -- SubCarrier
            INNER JOIN dbo.Transportes TP ON T.IdTransportePrincipal = TP.Id -- Carrier Principal
            INNER JOIN dbo.ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad
            INNER JOIN dbo.ParametrosLista PL ON PCAT.IdParametroLista = PL.Id
                                             AND PL.Codigo = 'EsDelivery'
                                             AND PL.IdEmpresa = GH.IdEmpresa
            LEFT JOIN dbo.ProgramacionManifiesto PM WITH(NOLOCK) ON PM.IdProgramacionCarrier = PC.Id
            LEFT JOIN dbo.ManifiestosDespacho MD ON MD.Id = PM.IdManifiestoDespacho
            OUTER APPLY (
            SELECT TOP 1 D.EsPod, D.NombreArchivo, D.MailEnviado, D.PodProcesado
            FROM dbo.DocumentosDespacho D
            WHERE D.IdManifiesto = MD.Id AND D.IdDocumento = 'DOC052395'
            ORDER BY D.EsPod DESC
            ) DD
            OUTER APPLY (
                SELECT TOP (1) S.Id, S.NroOrden
                FROM dbo.SolicitudDeVentaDetalles SLL
                LEFT JOIN dbo.SolicitudDeVenta S ON S.Id = SLL.IdSolicitud
                WHERE SLL.IdGuiaHouseDetalle = GHD.Id
                ORDER BY S.FechaSolicitud DESC 
            ) AS SDV
            LEFT JOIN dbo.PalletsDetalles PD WITH(NOLOCK) ON GHD.Id = PD.IdGuiasHouseDetalle
            LEFT JOIN dbo.Pallets PAL WITH(NOLOCK) ON PD.IdPallet = PAL.Id
            LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle
            LEFT JOIN Ubicaciones U ON UP.IdUbicacion = U.Id
            LEFT JOIN UbicacionesBodega UB ON U.IdUbicacionBodega = UB.Id
            LEFT JOIN Bodegas BGH ON GH.IdBodega = BGH.Id
            LEFT JOIN Bodegas BUB ON UB.IdBodega = BUB.Id
            WHERE GH.IdEmpresa = @IdEmpresa
              AND PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
              AND PCAT.Valor = 'NO'
              AND (@PalletLabel IS NULL OR PAL.Pallet LIKE '%' + @PalletLabel + '%')
              AND ISNULL(DD.EsPod, 0) = 1
            GROUP BY 
                 GHD.ShipToId
                ,ST.Nombre
                ,GH.ConsigneeId
                ,C.Nombre
                ,CASE WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') THEN GH.IdBodega ELSE UB.IdBodega END
                ,ISNULL(BUB.Nombre, BGH.Nombre)
                ,PC.FechaDespacho
                ,MD.Id
                ,PC.IdCarrier
                ,T.Nombre
                ,GHD.IdUsuarioLog
                ,GH.IdGuia
                ,GH.NroGuia
                ,SDV.Id
                ,SDV.NroOrden
            HAVING COUNT(1) = SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END);
        END;
        ELSE
        BEGIN
        INSERT INTO #TMP_HouseGuideGrouping (
            IdClienteFinal, NombreClienteFinal, 
            IdClienteConsignee, NombreClienteConsignee,
            FechaPickUpProgramada, FechaPickUpEntrega, IdUsuarioLog, 
            TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
            IdBodega, NombreBodega,
            IdManifiesto, IdCarrier, NombreCarrier, IdGuia, NroDocumento, IdOrdenVenta, NroOrdenVenta, ConPod, Enviado, Procesado
        )
        SELECT 
             GHD.ShipToId
            ,ST.Nombre
            ,GH.ConsigneeId
            ,C.Nombre
            ,PC.FechaDespacho
            ,MAX(GHD.FechaCambio)
            ,GHD.IdUsuarioLog
            ,SUM(CASE WHEN GHD.EstadoPieza = 'PENDING' THEN 1 ELSE 0 END)
            ,SUM(CASE WHEN GHD.EstadoPieza = 'HOLD' THEN 1 ELSE 0 END)
            ,SUM(CASE WHEN GHD.EstadoPieza = 'SHORT' THEN 1 ELSE 0 END)
            ,SUM(CASE WHEN GHD.EstadoPieza = 'RECEIVED WH' THEN 1 ELSE 0 END)
            ,SUM(CASE WHEN GHD.EstadoPieza = 'STANDBY' THEN 1 ELSE 0 END)
            ,SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END)
            ,COUNT(1)
                ,CASE WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') THEN GH.IdBodega ELSE UB.IdBodega END
            ,ISNULL(BUB.Nombre, BGH.Nombre)
            ,MD.Id
            ,PC.IdCarrier
                ,T.Nombre
            ,GH.IdGuia
            ,GH.NroGuia
            ,SDV.Id
            ,SDV.NroOrden
            ,MAX(CASE WHEN ISNULL(DD.EsPod, 0) = 1 THEN 1 ELSE 0 END)
            ,MAX(CASE WHEN DD.MailEnviado = 1 THEN 1 ELSE 0 END)
            ,MAX(CASE WHEN DD.PodProcesado = 1 THEN 1 ELSE 0 END)
        FROM dbo.GuiasHouseDetalles GHD WITH(NOLOCK) 
        INNER JOIN dbo.GuiasHouse GH WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
        INNER JOIN v_ClientsEntities ST WITH (NOLOCK) ON ST.Id = GHD.ShipToId
        LEFT JOIN v_ClientsEntities C WITH (NOLOCK) ON C.Id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
        INNER JOIN dbo.Exportadores EXP ON GH.IdExportador = EXP.Id
        INNER JOIN dbo.ProgramacionCarrier PC WITH(NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id
        INNER JOIN dbo.Transportes T ON PC.IdCarrier = T.Id 
        INNER JOIN dbo.Transportes TP ON T.IdTransportePrincipal = TP.Id
        INNER JOIN dbo.ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad
        INNER JOIN dbo.ParametrosLista PL ON PCAT.IdParametroLista = PL.Id
                                         AND PL.Codigo = 'EsDelivery'
                                         AND PL.IdEmpresa = GH.IdEmpresa
        LEFT JOIN dbo.ProgramacionManifiesto PM WITH(NOLOCK) ON PM.IdProgramacionCarrier = PC.Id
        LEFT JOIN dbo.ManifiestosDespacho MD ON MD.Id = PM.IdManifiestoDespacho
        OUTER APPLY (
            SELECT TOP 1 D.EsPod, D.NombreArchivo, D.MailEnviado, D.PodProcesado
            FROM dbo.DocumentosDespacho D
            WHERE D.IdManifiesto = MD.Id AND D.IdDocumento = 'DOC052395'
            ORDER BY D.EsPod DESC
        ) DD
        OUTER APPLY (
            SELECT TOP (1) S.Id, S.NroOrden
            FROM dbo.SolicitudDeVentaDetalles SLL
            LEFT JOIN dbo.SolicitudDeVenta S ON S.Id = SLL.IdSolicitud
            WHERE SLL.IdGuiaHouseDetalle = GHD.Id
            ORDER BY S.FechaSolicitud DESC 
        ) AS SDV
        LEFT JOIN dbo.PalletsDetalles PD WITH(NOLOCK) ON GHD.Id = PD.IdGuiasHouseDetalle
        LEFT JOIN dbo.Pallets PAL WITH(NOLOCK) ON PD.IdPallet = PAL.Id
        LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle
        LEFT JOIN Ubicaciones U ON UP.IdUbicacion = U.Id
        LEFT JOIN UbicacionesBodega UB ON U.IdUbicacionBodega = UB.Id
        LEFT JOIN Bodegas BGH ON GH.IdBodega = BGH.Id
        LEFT JOIN Bodegas BUB ON UB.IdBodega = BUB.Id
        WHERE GH.IdEmpresa = @IdEmpresa
          AND PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
          AND PCAT.Valor = 'NO'
          AND ISNULL(DD.EsPod, 0) = 1
          AND (@NroDocumento IS NULL OR GH.NroGuia LIKE '%' + @NroDocumento + '%')
          AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
          AND (@NombreClienteConsignee IS NULL OR C.Nombre LIKE '%' + @NombreClienteConsignee + '%')
          AND (@NroPod IS NULL OR MD.NroManifiesto LIKE '%' + @NroPod + '%')
          AND (@CodigoBarras IS NULL OR GHD.CodigoBarra LIKE '%' + @CodigoBarras + '%')
          AND (@NombreComercialExportador IS NULL OR EXP.NombreComercial LIKE '%' + @NombreComercialExportador + '%')
          AND (@PalletLabel IS NULL OR PAL.Pallet LIKE '%' + @PalletLabel + '%') 
          AND (@BillTo IS NULL OR (C.BillToId IS NOT NULL AND C.BillToName LIKE '%' + @BillTo + '%'))
        GROUP BY 
                 GHD.ShipToId
                ,ST.Nombre
                ,GH.ConsigneeId
                ,C.Nombre
                ,CASE WHEN (UB.IdBodega IS NULL OR UB.IdBodega = '') THEN GH.IdBodega ELSE UB.IdBodega END
                ,ISNULL(BUB.Nombre, BGH.Nombre)
                ,PC.FechaDespacho
                ,MD.Id
                ,PC.IdCarrier
                ,T.Nombre
                ,GHD.IdUsuarioLog
                ,GH.IdGuia
                ,GH.NroGuia
                ,SDV.Id
                ,SDV.NroOrden
        HAVING COUNT(1) = SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END);
        END;    
        
        INSERT INTO #TMP_HouseGuideGroupingFinal (
            IdClienteFinal, NombreClienteFinal,
            IdClienteConsignee, NombreClienteConsignee,
            FechaPickUpProgramada, FechaPickUpEntrega, IdUsuarioLog, 
            TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
            IdBodega, NombreBodega,
            IdManifiesto, IdCarrier, NombreCarrier, IdGuia, NroDocumento, IdOrdenVenta, NroOrdenVenta, ConPod, Enviado, Procesado
        )
        SELECT 
             TMP.IdClienteFinal
            ,TMP.NombreClienteFinal
            ,TMP.IdClienteConsignee
            ,TMP.NombreClienteConsignee
            ,TMP.FechaPickUpProgramada
            ,MAX(TMP.FechaPickUpEntrega) AS FechaPickUpEntrega
            ,(SELECT TOP (1) Sub.IdUsuarioLog
              FROM #TMP_HouseGuideGrouping Sub
              WHERE Sub.IdGuia = TMP.IdGuia
                AND CONVERT(DATE, Sub.FechaPickUpEntrega) = CONVERT(DATE, TMP.FechaPickUpEntrega)
              ORDER BY Sub.FechaPickUpEntrega DESC
             ) AS IdUsuarioLog
            ,SUM(TMP.TotalPending)
            ,SUM(TMP.TotalHold)
            ,SUM(TMP.TotalShort)
            ,SUM(TMP.TotalReceived)
            ,SUM(TMP.TotalStandBy)
            ,SUM(TMP.TotalDespachado)
            ,SUM(TMP.Total)
            ,TMP.IdBodega
            ,TMP.NombreBodega
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
             TMP.IdClienteFinal, TMP.NombreClienteFinal
            ,TMP.IdClienteConsignee, TMP.NombreClienteConsignee
            ,TMP.FechaPickUpProgramada
            ,CONVERT(DATE, TMP.FechaPickUpEntrega)
            ,TMP.IdBodega, TMP.NombreBodega
            ,TMP.IdManifiesto
            ,TMP.IdCarrier
            ,TMP.NombreCarrier
            ,TMP.ConPod, TMP.Enviado, TMP.Procesado
            ,TMP.IdGuia, TMP.NroDocumento
            ,TMP.IdOrdenVenta, TMP.NroOrdenVenta;

        IF @IdClienteFinal IS NULL
        BEGIN
        SELECT 
                 TMP.Id
                ,'Entregada' AS Estatus
                ,'dispatch-pick-up-delivered' AS ClaseCssEstatus       
                ,TMP.IdGuia
                ,TMP.NroDocumento
                ,TMP.IdOrdenVenta
                ,TMP.NroOrdenVenta                  
                ,TMP.IdClienteFinal
                ,TMP.NombreClienteFinal
                ,TMP.IdClienteConsignee
                ,TMP.NombreClienteConsignee
                ,TMP.FechaPickUpProgramada
                ,'' AS FechaPickUpProgramadaString
                ,TMP.FechaPickUpEntrega
                ,'' AS FechaPickUpEntregaString
                ,CONVERT(TIME, TMP.FechaPickUpEntrega) AS HoraEntrega
                ,TMP.TotalPending AS PcsPending
                ,TMP.TotalHold AS PcsHold
                ,TMP.TotalShort AS PcsShort
                ,TMP.TotalReceived AS PcsReceivedWh
                ,TMP.TotalStandBy AS PcsStandby
                ,TMP.TotalDespachado AS TotalDespachado
                ,TMP.Total
                ,TMP.IdBodega
                ,TMP.NombreBodega
                ,TMP.IdManifiesto
                ,TMP.IdCarrier
                ,TMP.NombreCarrier 
                ,ISNULL(U.Nombre, '') + ' ' AS UsuarioFechaCambio
                ,CONVERT(BIT, TMP.Enviado) AS Enviado
                ,CONVERT(BIT, TMP.Procesado) AS Procesado
        FROM #TMP_HouseGuideGroupingFinal AS TMP
            INNER JOIN dbo.Usuarios U ON U.Id = TMP.IdUsuarioLog;
        END;
        ELSE
        BEGIN
            SELECT 
                 TMP.Id
                ,'Entregada' AS Estatus
                ,'dispatch-pick-up-delivered' AS ClaseCssEstatus       
                ,TMP.IdGuia
                ,TMP.NroDocumento
                ,TMP.IdOrdenVenta
                ,TMP.NroOrdenVenta                  
                ,TMP.IdClienteFinal
                ,TMP.NombreClienteFinal
                ,TMP.IdClienteConsignee
                ,TMP.NombreClienteConsignee
                ,TMP.FechaPickUpProgramada
                ,'' AS FechaPickUpProgramadaString
                ,TMP.FechaPickUpEntrega
                ,'' AS FechaPickUpEntregaString
                ,CONVERT(TIME, TMP.FechaPickUpEntrega) AS HoraEntrega
                ,TMP.TotalPending AS PcsPending
                ,TMP.TotalHold AS PcsHold
                ,TMP.TotalShort AS PcsShort
                ,TMP.TotalReceived AS PcsReceivedWh
                ,TMP.TotalStandBy AS PcsStandby
                ,TMP.TotalDespachado AS TotalDespachado
                ,TMP.Total
                ,TMP.IdBodega
                ,TMP.NombreBodega
                ,TMP.IdManifiesto
                ,TMP.IdCarrier
                ,TMP.NombreCarrier 
                ,ISNULL(U.Nombre, '') + ' ' AS UsuarioFechaCambio
                ,CONVERT(BIT, TMP.Enviado) AS Enviado
                ,CONVERT(BIT, TMP.Procesado) AS Procesado
            FROM #TMP_HouseGuideGroupingFinal AS TMP
            INNER JOIN dbo.Usuarios U ON U.Id = TMP.IdUsuarioLog
            WHERE ISNULL(TMP.IdManifiesto, @EmptyUid) = ISNULL(@IdManifiesto, @EmptyUid)
              AND TMP.IdCarrier = @IdCarrier
              AND TMP.IdClienteFinal = @IdClienteFinal
              AND TMP.IdBodega = @IdBodega
              AND CONVERT(DATE, TMP.FechaPickUpEntrega) = @FechaPickUpEntrega
              AND TMP.FechaPickUpProgramada = @FechaPickUpProgramada;
        END;

        DROP TABLE #TMP_HouseGuideGrouping;
        DROP TABLE #TMP_HouseGuideGroupingFinal;

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH;
END;
/*
EXEC [dbo].[AC_Despacho_PickupDetalleCompletedScheduled] 
    @FechaDesde = '2026-01-03',
    @FechaHasta = '2026-01-35',
    @IdEmpresa  = 'EMP014';

    EXEC [dbo].[AC_Despacho_PickupDetalleCompletedScheduled]
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