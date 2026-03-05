/* VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
   1		    Jair Gomez			2026-03-03	   58765		Initial Code - Based on pro_ListarDespachoPorClientexDetallada. 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByClient360Detailed]
(
    @FechaDesde             DATE,
    @FechaHasta             DATE,
    @IdCliente              VARCHAR(16) = NULL,
    @IdUsuario              VARCHAR(16) = NULL,
    @IdClienteFinal         VARCHAR(16) = NULL,
    @IsPending              BIT,
    @NombreClienteFinal     VARCHAR(256) = NULL,
    @NombreClienteConsignee VARCHAR(512) = NULL,
    @NombreExportador       VARCHAR(256) = NULL,
    @IdBodega               VARCHAR(16) = NULL,
    @Po                     VARCHAR(64) = NULL,
    @NroGuia                VARCHAR(32) = NULL,
    @TruckId                VARCHAR(16) = NULL,
    @EsInventario           BIT = NULL
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
                @MailSentStatus             BIT;

        SELECT 
            @FinalStatus            = NULL,
            @ConsigneeStatus        = NULL,
            @ConsolidatorStatus     = NULL,
            @MailSentStatus         = 0;

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
            [ShipToId]              VARCHAR(16),
            [TruckId]               VARCHAR(16),
            [WarehouseId]           VARCHAR(16) NULL,
            [CarrierScheduleId]     UNIQUEIDENTIFIER,
            [CarrierId]             VARCHAR(16) NULL,
            [DispatchDate]          DATETIME,
            [GuideNumber]           VARCHAR(32),
            [ConsigneeClientId]     VARCHAR(16),
            [BillToConsigneeId]     VARCHAR(16) NULL,
            [Po]                    VARCHAR(64),
            [House]                 VARCHAR(32),
            [GuideId]               VARCHAR(64),
            [ExporterId]            VARCHAR(16)
        );
        
        SELECT TOP 1 @SystemId = Id FROM SistemasEntidades WHERE Codigo = 'UNIFICADO';
        SELECT TOP 1 @ManifestDocumentId = Id FROM Documentos WHERE Codigo = 'MANIFEST';

        INSERT INTO #TMP_RelatedClients (EntityId, IdCliente, TipoCliente)
        EXEC [dbo].[AC_pro_GetClientsEntities] 
            @EntityId = @IdCliente, 
            @IdUsuario = @IdUsuario;

        /* Validación Tipo de Clientes Operativos */
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
        
        -- =========================================================================
        -- PRE-CÁLCULO DE FILTROS TVF
        -- =========================================================================
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
        -- =========================================================================

        /* INSERCIONES PRINCIPALES */
        IF @NombreClienteFinal IS NULL AND @NombreClienteConsignee IS NULL AND @NombreExportador IS NULL 
           AND @Po IS NULL AND @NroGuia IS NULL AND @TruckId IS NULL AND @IdBodega IS NULL AND @IdClienteFinal IS NULL
        BEGIN
            /* RAMA 1: SIN FILTROS DE TEXTO */
            IF @FinalStatus IS NOT NULL 
            BEGIN
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHD.AltoIn AS HeightIn, 
                    GHD.LargoIn AS LengthIn, 
                    GHD.AnchoIn AS WidthIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate,
                    GHO.NroGuia AS GuideNumber, 
                    GHO.ConsigneeId AS ConsigneeClientId,
                    GHO.BillToConsigneeId,
                    GHD.Po, 
                    GHO.House, 
                    GHO.IdGuia AS GuideId, 
                    GHO.IdExportador AS ExporterId
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
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHD.AltoIn AS HeightIn, 
                    GHD.LargoIn AS LengthIn, 
                    GHD.AnchoIn AS WidthIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate,
                    GHO.NroGuia AS GuideNumber, 
                    GHO.ConsigneeId AS ConsigneeClientId,
                    GHO.BillToConsigneeId,
                    GHD.Po, 
                    GHO.House, 
                    GHO.IdGuia AS GuideId, 
                    GHO.IdExportador AS ExporterId
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
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHD.AltoIn AS HeightIn, 
                    GHD.LargoIn AS LengthIn, 
                    GHD.AnchoIn AS WidthIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate,
                    GHO.NroGuia AS GuideNumber, 
                    GHO.ConsigneeId AS ConsigneeClientId,
                    GHO.BillToConsigneeId,
                    GHD.Po, 
                    GHO.House, 
                    GHO.IdGuia AS GuideId, 
                    GHO.IdExportador AS ExporterId
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
            /* RAMA 2: CON FILTROS DE TEXTO */
            IF @FinalStatus IS NOT NULL 
            BEGIN           
                INSERT INTO #TMP_HouseWaybillDetails
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHD.AltoIn AS HeightIn, 
                    GHD.LargoIn AS LengthIn, 
                    GHD.AnchoIn AS WidthIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate,
                    GHO.NroGuia AS GuideNumber, 
                    GHO.ConsigneeId AS ConsigneeClientId, 
                    GHO.BillToConsigneeId,
                    GHD.Po, 
                    GHO.House, 
                    GHO.IdGuia AS GuideId, 
                    GHO.IdExportador AS ExporterId
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @FechaHasta
                    AND GHD.ShipToId = ISNULL(@IdClienteFinal, GHD.ShipToId)
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
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHD.AltoIn AS HeightIn, 
                    GHD.LargoIn AS LengthIn, 
                    GHD.AnchoIn AS WidthIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate,
                    GHO.NroGuia AS GuideNumber, 
                    GHO.ConsigneeId AS ConsigneeClientId, 
                    GHO.BillToConsigneeId,
                    GHD.Po, 
                    GHO.House, 
                    GHO.IdGuia AS GuideId, 
                    GHO.IdExportador AS ExporterId
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                LEFT JOIN #TMP_HouseWaybillDetails GHTEMP ON GHTEMP.Id = GHD.Id
                WHERE GHO.House IS NOT NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta
                    AND GHTEMP.Id IS NULL
                    AND GHD.ShipToId = ISNULL(@IdClienteFinal, GHD.ShipToId)
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
                    GHD.IdGuiaHouse AS HouseWaybillId, 
                    GHD.EstadoPieza AS PieceStatus, 
                    GHD.EsPod AS IsPod, 
                    GHD.AltoIn AS HeightIn, 
                    GHD.LargoIn AS LengthIn, 
                    GHD.AnchoIn AS WidthIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GHO.IdBodega AS WarehouseId, 
                    PCA.Id AS CarrierScheduleId, 
                    PCA.IdCarrier AS CarrierId, 
                    PCA.FechaDespacho AS DispatchDate,
                    GHO.NroGuia AS GuideNumber, 
                    GHO.ConsigneeId AS ConsigneeClientId,
                    GHO.BillToConsigneeId, 
                    GHD.Po, 
                    GHO.House, 
                    GHO.IdGuia AS GuideId, 
                    GHO.IdExportador AS ExporterId
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                LEFT JOIN #TMP_HouseWaybillDetails GHTEMP ON GHTEMP.Id = GHD.Id
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @FechaHasta
                    AND GHTEMP.Id IS NULL
                    AND GHD.ShipToId = ISNULL(@IdClienteFinal, GHD.ShipToId)
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%')
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END 
        END
        
        -- PRE-AGRUPACIÓN Y RESOLUCIÓN DE DOCUMENTOS
        SELECT DISTINCT
            GHD.Id,
            GHD.PieceStatus,
            GHD.DispatchDate,
            MAN.NroManifiesto,
            GHD.HeightIn,
            GHD.LengthIn,
            GHD.WidthIn,
            GHD.ShipToId,
            GHD.TruckId,
            ISNULL(UBO.IdBodega, GHD.WarehouseId) AS WarehouseId,
            GHD.CarrierId,
            PTE.IdTe,
            MAN.Id AS ManifiestoId,
            GHD.GuideNumber,
            GHD.ConsigneeClientId,
            GHD.BillToConsigneeId,
            GHD.Po,
            GHD.House,
            GHD.GuideId,
            GHD.ExporterId,
            GHD.HouseWaybillId,
            CAST(CASE 
                WHEN SVE.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                WHEN SVE.TipoVenta < 4 THEN 1
                ELSE 0 
                END AS BIT) AS EsInventario,
            DDO.IdDocumentosDespacho, 
            CASE
                WHEN DDO.MailEnviado IS NULL OR DDO.MailEnviado = '' THEN CAST(0 AS BIT) 
                ELSE DDO.MailEnviado
            END AS EmailEnviado, 
            DDO.NombreDocumentoDespacho
        INTO #TMP_Detalle
        FROM #TMP_HouseWaybillDetails GHD
            LEFT JOIN ProgramacionTe PTE WITH(NOLOCK) ON PTE.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ProgramacionManifiesto PMA WITH(NOLOCK) ON PMA.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ManifiestosDespacho MAN WITH(NOLOCK) ON MAN.Id = PMA.IdManifiestoDespacho
            OUTER APPLY (
                SELECT TOP 1 
                    DDE.EsPod, 
                    DDE.MailEnviado, 
                    DDE.Id AS IdDocumentosDespacho, 
                    DDE.NombreArchivo AS NombreDocumentoDespacho
                FROM DocumentosDespacho DDE WITH(NOLOCK)
                WHERE DDE.IdManifiesto = MAN.Id AND DDE.IdDocumento = @ManifestDocumentId
                ORDER BY EsPod DESC
            ) DDO
            LEFT JOIN UbicacionPiezas UBP WITH(NOLOCK) ON GHD.Id = UBP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones UBI WITH(NOLOCK) ON UBP.IdUbicacion = UBI.Id 
            LEFT JOIN UbicacionesBodega UBO WITH(NOLOCK) ON UBI.IdUbicacionBodega = UBO.Id 
            LEFT JOIN SolicitudDeVentaDetalles SVD WITH(NOLOCK) ON SVD.IdGuiaHouseDetalle = GHD.Id
            LEFT JOIN SolicitudDeVenta SVE WITH(NOLOCK) ON SVE.Id = SVD.IdSolicitud
        WHERE 
            CASE 
                WHEN @IsPendingStatus = 1 AND (GHD.IsPod = @IsPendingStatus OR DDO.MailEnviado = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = @IsPendingStatus OR ISNULL(DDO.MailEnviado, @IsPendingStatus) = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = 1 OR ISNULL(DDO.MailEnviado, @IsPendingStatus) = 0) THEN 1 
                ELSE 0
            END = 1
            AND CASE 
                    WHEN @EsInventario IS NULL THEN 1
                    WHEN @EsInventario = 0 AND SVE.Id IS NULL THEN 1
                    WHEN @EsInventario = 0 AND SVE.TipoVenta = 5 AND SVD.TipoPieza = 2 THEN 1
                    WHEN @EsInventario = 0 AND SVE.TipoVenta = 4 THEN 1
                    WHEN @EsInventario = 1 AND SVE.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                    WHEN @EsInventario = 1 AND SVE.TipoVenta < 4 THEN 1 
                    ELSE 0 
                END = 1;

        SELECT
            NEWID() AS Id,
            TMP.HouseWaybillId AS IdGuiaHouse, 
            TMP.GuideId AS IdGuia, 
            TMP.Id AS IdGuiaHouseDetalle,
            TMP.DispatchDate AS FechaDespacho, 
            TMP.WarehouseId AS IdBodega, 
            BOD.Nombre AS NombreBodega, 
            TRA.Id AS IdCarrier, 
            TRA.Nombre AS NombreCarrier, 
            '' AS CodigoCarrier,
            TMP.ConsigneeClientId AS IdClienteConsignee, 
            VCC.Nombre AS NombreClienteConsignee, 
            '' AS IdPaisConsignee,
            '' AS NombrePaisConsignee,
            VCS.Nombre AS NombreClienteFinalAlt,
            '' AS NombreClienteFinalClienteFinalAlt,
            '' AS IdEstadoConsignee,
            '' AS CodigoIsoEstadoConsignee,
            PAS.Id AS IdPaisAlt, 
            PAS.Nombre AS NombrePaisAlt, 
            PAS.CodigoISO AS CodigoIsoPaisAlt, 
            ESS.Id AS IdEstadoAlt, 
            ESS.CodigoISO AS CodigoIsoEstadoAlt, 
            TMP.ShipToId AS IdClienteFinal, 
            VCS.Nombre AS NombreClienteFinal, 
            PAS.Id AS IdPais,  
            PAS.Nombre AS NombrePais, 
            PAS.CodigoISO AS CodigoIsoPais, 
            ESS.Id AS IdEstado, 
            ESS.CodigoISO AS CodigoIsoEstado,
            TMP.ManifiestoId AS IdManifiesto, 
            TMP.NroManifiesto, 
            '' AS ColorEstadoManifiesto,
            '' AS ColorEnvioTE,
            PUE.CodigoAduana AS DescripcionPuertoFronterizo,
            0 AS PcsPending, 
            0 AS PcsReceivedDr, 
            0 AS PcsReceivedWh, 
            0 AS PcsHold, 
            0 AS PcsLost, 
            0 AS PcsDispatchedWh, 
            0 AS PcsStandby, 
            0 AS TotalPcs,
            TMP.PieceStatus AS [Status], 
            CAST(0 AS BIT) AS CargaTransito,
            CAST(0 AS BIT) AS CargaTransitoNull,
            '' AS TipoNubeDocs,
            TMP.IdDocumentosDespacho, 
            TMP.EmailEnviado, 
            CASE
                WHEN TEX.[Id] IS NOT NULL
                THEN CASE 
                    WHEN TEX.[Enviado] = 1 
                    THEN CAST(1 AS BIT) 
                    ELSE CAST(0 AS BIT) 
                    END 
                ELSE CAST(0 AS BIT)
            END AS [TransportExportEnviado], 
            '' AS IdDocumentosDespachoString,
            CASE
                WHEN EMP.Id IS NOT NULL 
                THEN (EMP.Nombres + ' ') + EMP.Apellidos 
                WHEN ENU.Id IS NOT NULL 
                THEN ENU.[Name]
                ELSE ''
            END AS UsuarioEnvioTE,
            '' AS FechaEnvioTE,
            '' AS TextoTooltipTE,
            '' AS IdBroker,
            TMP.GuideNumber AS NroGuia, 
            '' AS NroOrdenLocal,
            '' AS NroDocumento,
            TMP.TruckId,
            '' AS TruckIdText,
            0.00 AS CapacidadCarga,
            TMP.Po, 
            '' AS CuttOfTime,
            CSU.CodigoIcao AS [CodigoSubCarrier], 
            CSU.Nombre AS [NombreSubCarrier],
            '' AS IdExportador,
            '' AS NombreExportador,
            '' AS Estatus,
            0 AS OrdenEstatus,
            '' AS ClaseCssEstado,
            '' AS TipoDocumentoDespacho,
            TMP.NombreDocumentoDespacho, 
            0 AS CantidadPODEnviados,
            0.00 AS PiesCubicosShipper,
            0.00 AS PiesCubicosTruckId,
            TMP.LengthIn AS LargoIn, 
            TMP.HeightIn AS AltoIn, 
            TMP.WidthIn AS AnchoIn, 
            0.00 AS MultiplicacionDimensiones,
            TMP.House, 
            CAST(0 AS BIT) AS Modificado,
            '' AS Pallet,
            NULL AS IdOrdenVenta,
            '' AS Puerta,
            '' AS Placa,
            '' AS NroDespacho,
            NULL AS FechaOrdenVenta, 
            TMP.EsInventario 
        FROM #TMP_Detalle TMP
            INNER JOIN Bodegas BOD ON TMP.WarehouseId = BOD.Id
            INNER JOIN Transportes TRA ON TMP.CarrierId = TRA.Id
            INNER JOIN v_ClientsEntities VCS ON TMP.ShipToId = VCS.Id
            INNER JOIN v_ClientsEntities VCC ON ISNULL(TMP.BillToConsigneeId, TMP.ConsigneeClientId) = VCC.Id
            INNER JOIN Exportadores EXL ON TMP.ExporterId = EXL.Id
            LEFT JOIN Paises PAS ON VCS.IdPais = PAS.Id
            LEFT JOIN Estados ESS ON VCS.IdEstado = ESS.Id
            LEFT JOIN CodigosRelacionSistemas CRS ON TMP.CarrierId = CRS.IdEntidad AND CRS.TipoEntidad = 'CARRIER' AND CRS.IdSistemaEntidad = @SystemId 
            LEFT JOIN TransportacionExportacion TEX ON TMP.IdTe = TEX.Id
            LEFT JOIN Puertos PUE ON TEX.IdPuerto = PUE.Id
            LEFT JOIN Transportes CSU ON TMP.CarrierId = CSU.Id
            LEFT JOIN Usuarios USR ON TEX.IdUsuarioEnvio = USR.Id
            LEFT JOIN Empleados EMP ON USR.IdEntidad = EMP.Id
            LEFT JOIN EntityTypes ETU ON USR.EntityTypeId = ETU.Id
            LEFT JOIN Entities ENU ON ETU.EntityId = ENU.Id
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
EXEC [dbo].[AC_pro_GetDispatchByClient360Detailed]
    @FechaDesde = '2026-02-24',
    @FechaHasta = '2026-03-05',
    @IdCliente = 'CLI0120247',
    @IdClienteFinal = NULL,
    @IsPending = 1,
    @NombreClienteFinal = NULL,
    @NombreClienteConsignee = NULL,
    @NombreExportador = NULL,
    @IdBodega = NULL,
    @Po = NULL,
    @NroGuia = NULL,
    @TruckId = NULL,
    @EsInventario = NULL;
*/