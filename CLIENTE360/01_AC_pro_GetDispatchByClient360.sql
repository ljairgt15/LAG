/* VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
   1		    Jair Gomez			2026-03-03	   58765		Initial Code - Based on pro_ListarDespachoPorClientexCliente. 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByClient360]
(
    @FechaDesde             DATE,
    @FechaHasta             DATE,
    @IdCliente              VARCHAR(16) = NULL,
    @IdUsuario              VARCHAR(16) = NULL,
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
                @ConsolidatorStatus         VARCHAR(16),
                @PendingStatus              BIT,
                @CompletedStatus            BIT,
                @MailSentStatus             BIT,
                @IsPodStatus                BIT;

        SELECT 
            @FinalStatus            = NULL,
            @ConsigneeStatus        = NULL,
            @ConsolidatorStatus     = NULL,
            @PendingStatus          = 0,
            @CompletedStatus        = 1,
            @MailSentStatus         = 0,
            @IsPodStatus            = 1;

        SELECT 
            @IsPendingStatus         = CASE WHEN @IsPending = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
            @WildcardDestinationDate = DATEADD(DAY, -90, @FechaHasta);

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
            [HeightIn]              DECIMAL(18, 2),
            [LengthIn]              DECIMAL(18, 2),
            [WidthIn]               DECIMAL(18, 2),
            [ShipToId]         VARCHAR(16),
            [TruckId]               VARCHAR(16),
            [WarehouseId]           VARCHAR(16) NULL,
            [CarrierScheduleId]     UNIQUEIDENTIFIER,
            [CarrierId]             VARCHAR(16) NULL,
            [DispatchDate]          DATETIME
        );
        
        SELECT TOP 1 @SystemId = Id FROM SistemasEntidades WHERE Codigo = 'UNIFICADO';
        SELECT TOP 1 @ManifestDocumentId = Id FROM Documentos WHERE Codigo = 'MANIFEST';

        INSERT INTO #TMP_RelatedClients (EntityId, IdCliente, TipoCliente)
        EXEC [dbo].[AC_pro_GetClientsEntities] 
            @EntityId = @IdCliente, 
            @IdUsuario = @IdUsuario;

        SELECT TOP 1 @ConsolidatorStatus = 'CONSOLIDADOR'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta AND GHO.House IS NULL;

        SELECT TOP 1 @ConsigneeStatus ='CONSIGNEE'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta AND GHO.House IS NOT NULL;

        SELECT TOP 1 @FinalStatus = 'FINAL'
        FROM GuiasHouseDetalles GHD WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
        WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @FechaHasta;

        IF @IsPendingStatus = 0
        BEGIN
            SELECT @WildcardDestinationDate = DATEADD(DAY, -30, @FechaHasta);
        END

        IF @NombreExportador IS NOT NULL
        BEGIN 
            SELECT @NombreExportador = UPPER(@NombreExportador);

            INSERT INTO #TMP_Exporters (ExporterId)
            SELECT Id FROM Exportadores
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

        IF @NombreClienteFinal IS NULL AND @NombreClienteConsignee IS NULL AND @NombreExportador IS NULL 
           AND @Po IS NULL AND @NroGuia IS NULL AND @TruckId IS NULL AND @IdBodega IS NULL 
        BEGIN
            IF @FinalStatus IS NOT NULL 
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM ProgramacionCarrier PCA WITH(NOLOCK)
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @FechaHasta
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta;              
            END
            
            IF @ConsigneeStatus IS NOT NULL
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHO.House IS NOT NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta;  
            END
            
            IF @ConsolidatorStatus IS NOT NULL
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHX.ConsigneeId
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
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
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
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
                WHERE GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta AND GHO.House IS NOT NULL 
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
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho 
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta
                    AND GHX.House IS NULL 
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%')
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END 
        END
        
        SELECT
            GHD.PieceStatus,
            GHD.DispatchDate,
            MAN.NroManifiesto,
            SUM(GHD.HeightIn * GHD.LengthIn * GHD.WidthIn) AS CapacidadCarga,
            COUNT(1) AS TotalPiezas,
            GHD.ShipToId,
            GHD.TruckId,
            ISNULL(UBO.IdBodega, GHD.WarehouseId) AS WarehouseId,
            GHD.CarrierId,
            PTE.IdTe,
            MAN.Id AS ManifiestoId,
            CAST(CASE 
                WHEN SVE.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                WHEN SVE.TipoVenta < 4 THEN 1
                ELSE 0 
            END AS BIT) AS EsInventario,
            DDO.NombreDocumentoDespacho,
            DDO.IdDocumentosDespacho,
            DDO.MailEnviado,
            GHD.IsPod
        INTO #TMP_Detalle
        FROM
            (
                SELECT DISTINCT
                    TMP.Id, 
                    TMP.PieceStatus, 
                    TMP.DispatchDate, 
                    TMP.CarrierScheduleId,
                    TMP.HeightIn, 
                    TMP.LengthIn, 
                    TMP.WidthIn, 
                    TMP.ShipToId, 
                    TMP.TruckId,
                    TMP.WarehouseId, 
                    TMP.CarrierId, 
                    TMP.IsPod
                FROM #TMP_HouseWaybillDetails TMP
            ) GHD
            LEFT JOIN ProgramacionTe PTE ON PTE.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ProgramacionManifiesto PMA WITH(NOLOCK) ON PMA.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ManifiestosDespacho MAN ON MAN.Id = PMA.IdManifiestoDespacho
            OUTER APPLY (
                SELECT TOP 1 
                    DDE.EsPod, 
                    DDE.MailEnviado, 
                    DDE.NombreArchivo AS NombreDocumentoDespacho, 
                    DDE.Id AS IdDocumentosDespacho
                FROM DocumentosDespacho DDE
                WHERE DDE.IdManifiesto = MAN.Id 
                AND DDE.IdDocumento = @ManifestDocumentId
                ORDER BY DDE.EsPod DESC
            ) DDO
            LEFT JOIN UbicacionPiezas UBP WITH(NOLOCK) ON GHD.Id = UBP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones UBI ON UBP.IdUbicacion = UBI.Id 
            LEFT JOIN UbicacionesBodega UBO ON UBI.IdUbicacionBodega = UBO.Id 
            LEFT JOIN SolicitudDeVentaDetalles SVD ON SVD.IdGuiaHouseDetalle = GHD.Id
            LEFT JOIN SolicitudDeVenta SVE ON SVE.Id = SVD.IdSolicitud
        WHERE
            CASE 
                WHEN @IsPendingStatus = 1 AND (GHD.IsPod = @IsPendingStatus OR DDO.MailEnviado = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = @IsPendingStatus OR ISNULL(DDO.MailEnviado, @IsPendingStatus) = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = 1 OR ISNULL(DDO.MailEnviado, @IsPendingStatus) = 0) THEN 1 
                ELSE 0
            END = 1
        GROUP BY 
            GHD.PieceStatus, 
            GHD.DispatchDate, 
            MAN.NroManifiesto, 
            GHD.ShipToId,
            GHD.TruckId, 
            GHD.WarehouseId, 
            UBO.IdBodega, 
            GHD.CarrierId, 
            PTE.IdTe, 
            MAN.Id,
            CASE 
                WHEN SVE.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1 
                WHEN SVE.TipoVenta < 4 THEN 1 
                ELSE 0 
            END,
            DDO.NombreDocumentoDespacho, 
            DDO.IdDocumentosDespacho, 
            DDO.MailEnviado, 
            GHD.IsPod;

        SELECT
            ROW_NUMBER() OVER (ORDER BY TMP.DispatchDate) AS Id,
            TMP.PieceStatus AS EstadoPieza,
            TMP.DispatchDate AS FechaDespacho,
            TMP.NroManifiesto,
            TMP.CapacidadCarga,
            TMP.TotalPiezas,
            VCE.Nombre AS NombreClienteFinal,
            PAI.Nombre AS NombrePais,
            PAI.CodigoIso AS CodigoIsoPais,
            EST.CodigoIso AS CodigoIsoEstado,
            TRA.Nombre AS NombreCarrier,
            CRS.Codigo AS CodigoCarrier,
            PUE.CodigoAduana,
            BOD.Nombre AS NombreBodega,
            TMP.NombreDocumentoDespacho,
            TMP.MailEnviado,
            TMP.ShipToId AS IdClienteFinal,
            TMP.TruckId,
            TMP.WarehouseId AS IdBodega,
            TMP.CarrierId AS IdCarrier,
            TMP.ManifiestoId AS IdManifiesto,
            PAI.Id AS IdPais,
            EST.Id AS IdEstado,
            TMP.IdDocumentosDespacho,
            TMP.EsInventario,
            TMP.IsPod AS EsPod
        FROM #TMP_Detalle TMP
        INNER JOIN Bodegas BOD ON TMP.WarehouseId = BOD.Id
        INNER JOIN Transportes TRA ON TMP.CarrierId = TRA.Id
        INNER JOIN v_ClientsEntities VCE ON TMP.ShipToId = VCE.Id
        INNER JOIN Paises PAI ON VCE.IdPais = PAI.Id
        INNER JOIN Estados EST ON VCE.IdEstado = EST.Id
        LEFT JOIN CodigosRelacionSistemas CRS ON TMP.CarrierId = CRS.IdEntidad AND CRS.TipoEntidad = 'CARRIER' AND CRS.IdSistemaEntidad = @SystemId
        LEFT JOIN TransportacionExportacion TEX ON TMP.IdTe = TEX.Id
        LEFT JOIN Puertos PUE ON TEX.IdPuerto = PUE.Id
        WHERE TMP.WarehouseId = ISNULL(@IdBodega, TMP.WarehouseId);

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
EXEC [dbo].[AC_pro_GetDispatchByClient360]
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