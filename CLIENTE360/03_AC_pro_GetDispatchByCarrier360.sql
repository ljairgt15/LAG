/* VERSION      MODIFIEDBY          MODIFIEDDATE    HU      MODIFICATION
   1            Jair Gomez          2026-03-04     58765    Based on pro_ListarDespachoPorCarrierXCarrier 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByCarrier360]
(
    @DateFrom               DATE,
    @DateTo                 DATE,
    @ClientId               VARCHAR(16) = NULL,
    @UserId                 VARCHAR(16) = NULL,
    @IsPending              BIT,
    @ShipToName             VARCHAR(256) = NULL,
    @ConsigneeName          VARCHAR(512) = NULL,
    @ExporterName           VARCHAR(256) = NULL,
    @WarehouseId            VARCHAR(16) = NULL,
    @Po                     VARCHAR(64) = NULL,
    @WaybillNumber          VARCHAR(32) = NULL,
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
            @WildcardDestinationDate = DATEADD(DAY, -90, @DateTo);

        CREATE TABLE #TMP_RelatedClients (
        [EntityId]      VARCHAR(16),
        [IdCliente]     VARCHAR(16),
        [TipoCliente]   VARCHAR(32)
        );
        CREATE CLUSTERED INDEX IX_TMP_Related_Entity ON #TMP_RelatedClients(EntityId);
        
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
            [BrokerId]              VARCHAR(16)
        );

        SELECT TOP 1 @SystemId = Id FROM SistemasEntidades WHERE Codigo = 'UNIFICADO';
        SELECT TOP 1 @ManifestDocumentId = Id FROM Documentos WHERE Codigo = 'MANIFEST';

        INSERT INTO #TMP_RelatedClients (EntityId, IdCliente, TipoCliente)
        EXEC [dbo].[AC_pro_GetClientsEntities] 
            @EntityId = @ClientId, 
            @IdUsuario = @UserId;

        /* Validación Tipo de Clientes Operativos */
        SELECT TOP 1 @ConsolidatorStatus = 'CONSOLIDADOR'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GHO.House IS NULL;

        SELECT TOP 1 @ConsigneeStatus ='CONSIGNEE'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GHO.House IS NOT NULL;

        SELECT TOP 1 @FinalStatus = 'FINAL'
        FROM GuiasHouseDetalles GHD WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
        WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo;

        IF @IsPendingStatus = 0
        BEGIN
            SELECT @WildcardDestinationDate = DATEADD(DAY, -30, @DateTo);
        END

        -- =========================================================================
        -- PRE-CÁLCULO DE FILTROS TVF
        -- =========================================================================
        IF @ExporterName IS NOT NULL
        BEGIN 
            SELECT @ExporterName = UPPER(@ExporterName);
            INSERT INTO #TMP_Exporters (ExporterId)
            SELECT Id FROM Exportadores 
            WHERE NombreComercial LIKE '%' + @ExporterName + '%' OR Nombre LIKE '%' + @ExporterName + '%';
        END

        IF @ShipToName IS NOT NULL
        BEGIN
            INSERT INTO #TMP_FinalClients (ShipToId)
            SELECT Id FROM dbo.f_SearchEntities(@ShipToName, 'ShipTo');
        END

        IF @ConsigneeName IS NOT NULL
        BEGIN
            INSERT INTO #TMP_ConsigneeClients (ConsigneeClientId)
            SELECT Id FROM dbo.f_SearchEntities(@ConsigneeName, 'Consignee');
        END
        -- =========================================================================

        IF @ShipToName IS NULL AND @ConsigneeName IS NULL AND @ExporterName IS NULL 
           AND @Po IS NULL AND @WaybillNumber IS NULL AND @TruckId IS NULL AND @WarehouseId IS NULL 
        BEGIN
            IF @FinalStatus IS NOT NULL 
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate, 
                    GHO.IdBroker AS BrokerId
                FROM ProgramacionCarrier PCA WITH(NOLOCK)
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE PCA.FechaDespacho BETWEEN @DateFrom AND @DateTo;
            END

            IF @ConsigneeStatus IS NOT NULL
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate, 
                    GHO.IdBroker AS BrokerId
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id 
                    AND PCA.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHO.House IS NOT NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo;
            END

            IF @ConsolidatorStatus IS NOT NULL
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate, 
                    GHO.IdBroker AS BrokerId
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id 
                    AND PCA.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo;
            END 
        END
        ELSE
        BEGIN 
            IF @FinalStatus IS NOT NULL 
            BEGIN           
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate, 
                    GHO.IdBroker AS BrokerId
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @DateFrom AND @DateTo
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo
                    AND (@ExporterName IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
                    AND (@ConsigneeName IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@WaybillNumber IS NULL OR GHO.NroGuia LIKE '%' + @WaybillNumber + '%');                  
            END

            IF @ConsigneeStatus IS NOT NULL
            BEGIN           
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate, 
                    GHO.IdBroker AS BrokerId
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @DateFrom AND @DateTo 
                WHERE GHO.House IS NOT NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
                    AND (@WaybillNumber IS NULL OR GHO.NroGuia LIKE '%' + @WaybillNumber + '%')
                    AND (@ExporterName IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@ConsigneeName IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END

            IF @ConsolidatorStatus IS NOT NULL
            BEGIN       
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate, 
                    GHO.IdBroker AS BrokerId
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
                    AND (@WaybillNumber IS NULL OR GHO.NroGuia LIKE '%' + @WaybillNumber + '%')
                    AND (@ExporterName IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@ConsigneeName IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END 
        END
        
        SELECT
            GHD.PieceStatus AS EstadoPieza,
            GHD.DispatchDate AS FechaDespacho,
            SUM(CASE WHEN DOC.EsPod = 1 AND DOC.MailEnviado = 1 THEN 1 ELSE 0 END) AS ConPodEnviado,
            SUM(CASE WHEN MAN.Id IS NOT NULL THEN 1 ELSE 0 END) AS PiezasManifiesto,
            COUNT(1) AS TotalPiezas,
            GHD.IsPod AS EsPod,
            ISNULL(UBO.IdBodega, GHD.WarehouseId) AS IdBodega,
            GHD.CarrierId AS IdCarrier,
            GHD.BrokerId AS IdBroker,
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
                    TMP.BrokerId
                FROM #TMP_HouseWaybillDetails TMP
            ) AS GHD
            LEFT JOIN ProgramacionTe PTE WITH(NOLOCK) ON PTE.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ProgramacionManifiesto PMA WITH(NOLOCK) ON PMA.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ManifiestosDespacho MAN WITH(NOLOCK) ON MAN.Id = PMA.IdManifiestoDespacho
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
            GHD.BrokerId,
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
            INNER JOIN Bodegas BOD ON TMP.IdBodega = BOD.Id
            INNER JOIN Transportes TRA ON TMP.IdCarrier = TRA.Id
        WHERE TMP.IdBodega = ISNULL(@WarehouseId, TMP.IdBodega);

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
    @DateFrom = '2026-02-24',
    @DateTo = '2026-03-04',
    @ClientId = 'CLI0120247',
    @IsPending = 1,
    @ShipToName = NULL,
    @ConsigneeName = NULL,
    @ExporterName = NULL,
    @WarehouseId = NULL,
    @Po = NULL,
    @WaybillNumber = NULL,
    @TruckId = NULL;
*/