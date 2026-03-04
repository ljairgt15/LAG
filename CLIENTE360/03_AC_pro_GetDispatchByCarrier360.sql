/* VERSION      MODIFIEDBY              MODIFIEDDATE    HU              MODIFICATION
   1            Jair Gomez              2026-03-04      58765           Initial Code - Based on pro_ListarDespachoPorCarrierXCarrier. 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByCarrier360]
(
    @FechaDesde             DATE,
    @FechaHasta             DATE,
    @IdCliente              VARCHAR(16),
    @IsPending              BIT,
    @NombreClienteFinal     VARCHAR(256) = NULL,
    @NombreClienteConsignee VARCHAR(512) = NULL,
    @NombreExportador       VARCHAR(256) = NULL,
    @IdBodega               VARCHAR(16) = NULL,
    @Po                     VARCHAR(64) = NULL,
    @NroGuia                VARCHAR(32) = NULL,
    @TruckId                VARCHAR(16) = NULL
)
AS
BEGIN   
    BEGIN TRY
                DECLARE @ClientType                 VARCHAR(32),
                @SystemId                   INT, 
                @ManifestDocumentId         VARCHAR(16),
                @IsPendingStatus            BIT,
                @WildcardDestinationDate    DATETIME,
                @FinalStatus                VARCHAR(16),
                @ConsigneeStatus            VARCHAR(16),
                @ConsolidatorStatus         VARCHAR(16);

        SELECT 
            @FinalStatus            = NULL,
            @ConsigneeStatus        = NULL,
            @ConsolidatorStatus     = NULL;

        SELECT 
            @IsPendingStatus         = CASE WHEN @IsPending = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
            @WildcardDestinationDate = DATEADD(DAY, -90, @FechaHasta);

        -- Tablas Temporales Optimizadas (Con PK)
        CREATE TABLE #TMP_RelatedClients ( [ClientId] VARCHAR(16) PRIMARY KEY );
        CREATE TABLE #TMP_Exporters ( [ExporterId] VARCHAR(16) PRIMARY KEY );
        CREATE TABLE #TMP_FinalClients ( [ShipToId] VARCHAR(16) PRIMARY KEY );
        CREATE TABLE #TMP_ConsigneeClients ( [ConsigneeClientId] VARCHAR(16) PRIMARY KEY );

        CREATE TABLE #TMP_HouseWaybillDetails
        (
            [Id]                    UNIQUEIDENTIFIER,
            [HouseWaybillId]        UNIQUEIDENTIFIER,
            [PieceStatus]           VARCHAR(64),
            [IsPod]                 BIT,
            [WarehouseId]           VARCHAR(16) NULL,
            [CarrierScheduleId]     UNIQUEIDENTIFIER,
            [CarrierId]             VARCHAR(16) NULL,
            [DispatchDate]          DATETIME,
            [IdBroker]              VARCHAR(16)
        );

        SELECT TOP 1 @SystemId = Id FROM SistemasEntidades WITH(NOLOCK) WHERE Codigo = 'UNIFICADO';
        SELECT TOP 1 @ManifestDocumentId = Id FROM Documentos WITH(NOLOCK) WHERE Codigo = 'MANIFEST';

        SELECT @ClientType = CAT.Identificador 
        FROM Clientes CLI WITH(NOLOCK)
        INNER JOIN DetalleEntidades DET WITH(NOLOCK) ON DET.IdEntidad = CLI.Id
        INNER JOIN Catalogos CAT WITH(NOLOCK) ON CAT.Id = DET.IdCatalogo
        WHERE CLI.Id = @IdCliente;

        IF @ClientType = 'CLIENTE'
        BEGIN 
            INSERT INTO #TMP_RelatedClients (ClientId) VALUES (@IdCliente);
        END
        ELSE
        BEGIN 
            INSERT INTO #TMP_RelatedClients (ClientId) 
            SELECT IdCliente FROM GrupoClientes WITH(NOLOCK) WHERE IdGrupoCliente = @IdCliente;
        END

        /* Validación Tipo de Clientes Operativos */
        SELECT TOP 1 @ConsolidatorStatus = 'CONSOLIDADOR'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta AND GHO.House IS NULL;

        SELECT TOP 1 @ConsigneeStatus ='CONSIGNEE'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta AND GHO.House IS NOT NULL;

        SELECT TOP 1 @FinalStatus = 'FINAL'
        FROM GuiasHouseDetalles GHD WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHD.ShipToId
        WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @FechaHasta;

        IF @IsPendingStatus = 0
        BEGIN
            SELECT @WildcardDestinationDate = DATEADD(DAY, -30, @FechaHasta);
        END

        -- =========================================================================
        -- PRE-CÁLCULO DE FILTROS TVF
        -- =========================================================================
        IF @NombreExportador IS NOT NULL
        BEGIN 
            SELECT @NombreExportador = UPPER(@NombreExportador);
            INSERT INTO #TMP_Exporters (ExporterId)
            SELECT Id FROM Exportadores WITH(NOLOCK)
            WHERE NombreComercial LIKE '%' + @NombreExportador + '%' OR Nombre LIKE '%' + @NombreExportador + '%';
        END

        IF @NombreClienteFinal IS NOT NULL
        BEGIN
            INSERT INTO #TMP_FinalClients (ShipToId)
            SELECT Id FROM dbo.f_SearchEntities(@NombreClienteFinal, 'ShipTo');
        END

        IF @NombreClienteConsignee IS NOT NULL
        BEGIN
            INSERT INTO #TMP_ConsigneeClients (ConsigneeClientId)
            SELECT Id FROM dbo.f_SearchEntities(@NombreClienteConsignee, 'Consignee');
        END
        -- =========================================================================

        IF @NombreClienteFinal IS NULL AND @NombreClienteConsignee IS NULL AND @NombreExportador IS NULL 
           AND @Po IS NULL AND @NroGuia IS NULL AND @TruckId IS NULL AND @IdBodega IS NULL 
        BEGIN
            IF @FinalStatus IS NOT NULL 
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, GHD.IdGuiaHouse, GHD.EstadoPieza, GHD.EsPod, GHO.IdBodega, PCA.Id, PCA.IdCarrier, PCA.FechaDespacho, GHO.IdBroker
                FROM ProgramacionCarrier PCA WITH(NOLOCK)
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @FechaHasta
                INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHD.ShipToId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta;
            END

            IF @ConsigneeStatus IS NOT NULL
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, GHD.IdGuiaHouse, GHD.EstadoPieza, GHD.EsPod, GHO.IdBodega, PCA.Id, PCA.IdCarrier, PCA.FechaDespacho, GHO.IdBroker
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHO.House IS NOT NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta;
            END

            IF @ConsolidatorStatus IS NOT NULL
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, GHD.IdGuiaHouse, GHD.EstadoPieza, GHD.EsPod, GHO.IdBodega, PCA.Id, PCA.IdCarrier, PCA.FechaDespacho, GHO.IdBroker
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta;
            END 
        END
        ELSE
        BEGIN 
            IF @FinalStatus IS NOT NULL 
            BEGIN           
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, GHD.IdGuiaHouse, GHD.EstadoPieza, GHD.EsPod, GHO.IdBodega, PCA.Id, PCA.IdCarrier, PCA.FechaDespacho, GHO.IdBroker
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHD.ShipToId
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @FechaHasta
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%');                  
            END

            IF @ConsigneeStatus IS NOT NULL
            BEGIN           
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, GHD.IdGuiaHouse, GHD.EstadoPieza, GHD.EsPod, GHO.IdBodega, PCA.Id, PCA.IdCarrier, PCA.FechaDespacho, GHO.IdBroker
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
                WHERE GHO.House IS NOT NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%')
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END

            IF @ConsolidatorStatus IS NOT NULL
            BEGIN       
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, GHD.IdGuiaHouse, GHD.EstadoPieza, GHD.EsPod, GHO.IdBodega, PCA.Id, PCA.IdCarrier, PCA.FechaDespacho, GHO.IdBroker
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ClientId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%')
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END 
        END
        
        SELECT
            GHD.PieceStatus AS EstadoPieza,
            GHD.DispatchDate AS FechaDespacho,
            SUM(IIF(DOC.EsPod = 1 AND DOC.MailEnviado = 1, 1, 0)) AS ConPodEnviado,
            SUM(IIF(MAN.Id IS NOT NULL, 1, 0)) AS PiezasManifiesto,
            COUNT(1) AS TotalPiezas,
            GHD.IsPod AS EsPod,
            ISNULL(UBO.IdBodega, GHD.WarehouseId) AS IdBodega,
            GHD.CarrierId AS IdCarrier,
            GHD.IdBroker,
            CAST(CASE 
                WHEN SVE.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                WHEN SVE.TipoVenta < 4 THEN 1
                ELSE 0 
                END AS BIT) AS EsInventario
        INTO #TMP_Detalle
        FROM (  
                SELECT DISTINCT
                    TMP.Id,
                    TMP.CarrierScheduleId,
                    TMP.PieceStatus,
                    TMP.DispatchDate,
                    TMP.IsPod,
                    TMP.WarehouseId,
                    TMP.CarrierId,
                    TMP.IdBroker
                FROM #TMP_HouseWaybillDetails TMP
            ) AS GHD
            LEFT JOIN ProgramacionTe PRO_TE WITH(NOLOCK) ON PRO_TE.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ProgramacionManifiesto PRO_MAN WITH(NOLOCK) ON PRO_MAN.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ManifiestosDespacho MAN WITH(NOLOCK) ON MAN.Id = PRO_MAN.IdManifiestoDespacho
            OUTER APPLY (
                SELECT TOP 1 DD.EsPod, DD.MailEnviado
                FROM DocumentosDespacho DD WITH(NOLOCK)
                WHERE DD.IdManifiesto = MAN.Id AND DD.IdDocumento = @ManifestDocumentId
                ORDER BY EsPod DESC
            ) DOC
            LEFT JOIN UbicacionPiezas UBP WITH(NOLOCK) ON GHD.Id = UBP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones UBI WITH(NOLOCK) ON UBP.IdUbicacion = UBI.Id 
            LEFT JOIN UbicacionesBodega UBO WITH(NOLOCK) ON UBI.IdUbicacionBodega = UBO.Id 
            LEFT JOIN SolicitudDeVentaDetalles SVD WITH(NOLOCK) ON SVD.IdGuiaHouseDetalle = GHD.Id
            LEFT JOIN SolicitudDeVenta SVE WITH(NOLOCK) ON SVE.Id = SVD.IdSolicitud
        WHERE 
            CASE 
                WHEN @IsPendingStatus = 1 AND (GHD.IsPod = @IsPendingStatus OR DOC.MailEnviado = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = @IsPendingStatus OR ISNULL(DOC.MailEnviado, @IsPendingStatus) = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = 1 OR ISNULL(DOC.MailEnviado, @IsPendingStatus) = 0) THEN 1 
                ELSE 0
            END = 1
        GROUP BY 
            GHD.PieceStatus,
            GHD.DispatchDate,
            GHD.IsPod,
            GHD.WarehouseId,
            UBO.IdBodega,
            GHD.CarrierId,
            GHD.IdBroker,
            CASE 
                WHEN SVE.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                WHEN SVE.TipoVenta < 4 THEN 1 
                ELSE 0 
            END;

        -- SELECCIÓN FINAL
        SELECT
            ROW_NUMBER() OVER (ORDER BY TMP.FechaDespacho) AS Id,
            TMP.EstadoPieza,
            TMP.FechaDespacho,
            TMP.ConPodEnviado,
            TMP.PiezasManifiesto,
            TMP.TotalPiezas,
            TRA.Nombre AS NombreCarrier,
            BOD.Nombre AS NombreBodega,
            TMP.IdBodega,
            TMP.IdCarrier,
            TMP.IdBroker,
            TMP.EsInventario
        FROM #TMP_Detalle TMP
            INNER JOIN Bodegas BOD WITH(NOLOCK) ON TMP.IdBodega = BOD.Id
            INNER JOIN Transportes TRA WITH(NOLOCK) ON TMP.IdCarrier = TRA.Id
        WHERE TMP.IdBodega = ISNULL(@IdBodega, TMP.IdBodega);

        DROP TABLE #TMP_RelatedClients;
        DROP TABLE #TMP_Exporters;
        DROP TABLE #TMP_FinalClients;
        DROP TABLE #TMP_ConsigneeClients;
        DROP TABLE #TMP_HouseWaybillDetails;
        DROP TABLE #TMP_Detalle;

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH
END
/*
EXEC [dbo].[AC_pro_GetDispatchByCarrier360]
    @FechaDesde = '2026-02-24',
    @FechaHasta = '2026-03-05',
    @IdCliente = 'CLI0120247',
    @IsPending = 1,
    @NombreClienteFinal = NULL,
    @NombreClienteConsignee = NULL,
    @NombreExportador = NULL,
    @IdBodega = NULL,
    @Po = NULL,
    @NroGuia = NULL,
    @TruckId = NULL;
*/