/* 
VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
1		    Jair Gomez			2026-03-03	   58765	Based on pro_ListarDespachoPorClientexDetallada
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByClient360Detailed]
(
    @DateFrom               DATE,
    @DateTo                 DATE,
    @EntityId               VARCHAR(16) = NULL,
    @UserType               VARCHAR(32) = NULL,
    @ShipToId               VARCHAR(16) = NULL,
    @IsPending              BIT,
    @ShipToName             VARCHAR(256) = NULL,
    @ConsigneeName          VARCHAR(512) = NULL,
    @ExporterName           VARCHAR(256) = NULL,
    @WarehouseId            VARCHAR(16) = NULL,
    @Po                     VARCHAR(64) = NULL,
    @WaybillNumber          VARCHAR(32) = NULL,
    @TruckId                VARCHAR(16) = NULL,
    @IsInventory            BIT = NULL
)
AS
BEGIN   
    BEGIN TRY

        DECLARE @ClientType                 VARCHAR(32),
                @SystemId                   INT, 
                @ManifestDocumentId         VARCHAR(16),
                @IsPendingStatus            BIT,
                @WildcardDestinationDate    DATETIME,
                @FinalStatus                VARCHAR(16) = NULL,
                @ConsigneeStatus            VARCHAR(16) = NULL,
                @ConsolidatorStatus         VARCHAR(16) = NULL,
                @MailSentStatus             BIT = 0

        SELECT 
            @IsPendingStatus         = CASE WHEN @IsPending = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
            @WildcardDestinationDate = DATEADD(DAY, -90, @DateTo)

        CREATE TABLE #TMP_RelatedClients (
            [Id]                VARCHAR(16),
            [IdCliente]         VARCHAR(16),
            [BillToConsigneeId] VARCHAR(16),
            [BillToId]          VARCHAR(16),
            [ConsigneeId]       VARCHAR(16),
            [BillToName]        VARCHAR(256),
            [Name]              VARCHAR(256)
        )
        
        CREATE TABLE #TMP_FinalClients ( 
            [ShipToId] VARCHAR(16) 
        )
        CREATE TABLE #TMP_ConsigneeClients ( 
            [ConsigneeClientId] VARCHAR(16) 
        )
        CREATE TABLE #TMP_Exporters ( 
            [ExporterId] VARCHAR(16) 
        )
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
        )
        
        SELECT TOP 1 @SystemId = Id 
        FROM SistemasEntidades 
        WHERE Codigo = 'UNIFICADO'
        
        SELECT TOP 1 @ManifestDocumentId = Id 
        FROM Documentos 
        WHERE Codigo = 'MANIFEST'

        INSERT INTO #TMP_RelatedClients (Id,IdCliente, BillToConsigneeId,BilltoId,ConsigneeId, BillToName, [Name])
        EXEC [dbo].[AC_pro_GetClientsEntities]
             @EntityId = @EntityId,
             @UserType = @UserType 

        SELECT TOP 1 @ConsolidatorStatus = 'CONSOLIDADOR'
        FROM GuiasHouse GH WITH(NOLOCK)
         INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GH.ConsigneeId
        WHERE GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GH.House IS NULL

        SELECT TOP 1 @ConsigneeStatus ='CONSIGNEE'
        FROM GuiasHouse GH WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GH.ConsigneeId
        WHERE GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GH.House IS NOT NULL

        SELECT TOP 1 @FinalStatus = 'FINAL'
        FROM GuiasHouseDetalles GHD WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GHD.ShipToId
        WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo

        IF @IsPendingStatus = 0
        BEGIN
            SELECT @WildcardDestinationDate = DATEADD(DAY, -30, @DateTo)
        END

        IF @ShipToName IS NULL 
            AND @ConsigneeName IS NULL 
            AND @ExporterName IS NULL 
            AND @Po IS NULL 
            AND @WaybillNumber IS NULL 
            AND @TruckId IS NULL 
            AND @WarehouseId IS NULL 
            AND @ShipToId IS NULL
        BEGIN
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
                    GH.IdBodega AS WarehouseId, 
                    T.Id AS CarrierScheduleId, 
                    T.IdCarrier AS CarrierId, 
                    T.FechaDespacho AS DispatchDate,
                    GH.NroGuia AS GuideNumber, 
                    GH.ConsigneeId AS ConsigneeClientId,
                    GH.BillToConsigneeId,
                    GHD.Po, 
                    GH.House, 
                    GH.IdGuia AS GuideId, 
                    GH.IdExportador AS ExporterId
                FROM ProgramacionCarrier T WITH(NOLOCK)
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo
                INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GHD.ShipToId
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.Id = GHD.IdGuiaHouse
                WHERE T.FechaDespacho BETWEEN @DateFrom AND @DateTo
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
                    GH.IdBodega AS WarehouseId, 
                    T.Id AS CarrierScheduleId, 
                    T.IdCarrier AS CarrierId, 
                    T.FechaDespacho AS DispatchDate,
                    GH.NroGuia AS GuideNumber, 
                    GH.ConsigneeId AS ConsigneeClientId,
                    GH.BillToConsigneeId,
                    GHD.Po, 
                    GH.House, 
                    GH.IdGuia AS GuideId, 
                    GH.IdExportador AS ExporterId
                FROM GuiasHouse GH WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GH.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON T.IdGuiaHouseDetalle = GHD.Id 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GH.House IS NOT NULL AND GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
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
                    GH.IdBodega AS WarehouseId, 
                    T.Id AS CarrierScheduleId, 
                    T.IdCarrier AS CarrierId, 
                    T.FechaDespacho AS DispatchDate,
                    GH.NroGuia AS GuideNumber, 
                    GH.ConsigneeId AS ConsigneeClientId,
                    GH.BillToConsigneeId,
                    GHD.Po, 
                    GH.House, 
                    GH.IdGuia AS GuideId, 
                    GH.IdExportador AS ExporterId
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GHO.ConsigneeId
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.IdGuia = GHO.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON T.IdGuiaHouseDetalle = GHD.Id 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHO.House IS NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
            END 
        END
        ELSE
        BEGIN
            IF @ExporterName IS NOT NULL
            BEGIN 
                SELECT @ExporterName = UPPER(@ExporterName)
                INSERT INTO #TMP_Exporters (ExporterId)
                SELECT Id FROM Exportadores
                WHERE NombreComercial LIKE '%' + @ExporterName + '%' OR Nombre LIKE '%' + @ExporterName + '%'
            END

            IF @ShipToName IS NOT NULL
            BEGIN
                INSERT INTO #TMP_FinalClients (ShipToId)
                SELECT Id FROM dbo.f_SearchEntities(@ShipToName, 'ShipTo')
            END

            IF @ConsigneeName IS NOT NULL
            BEGIN
                INSERT INTO #TMP_ConsigneeClients (ConsigneeClientId)
                SELECT Id FROM dbo.f_SearchEntities(@ConsigneeName, 'Consignee')
            END         
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
                    GH.IdBodega AS WarehouseId, 
                    T.Id AS CarrierScheduleId, 
                    T.IdCarrier AS CarrierId, 
                    T.FechaDespacho AS DispatchDate,
                    GH.NroGuia AS GuideNumber, 
                    GH.ConsigneeId AS ConsigneeClientId, 
                    GH.BillToConsigneeId,
                    GHD.Po, 
                    GH.House, 
                    GH.IdGuia AS GuideId, 
                    GH.IdExportador AS ExporterId
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GHD.ShipToId
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.Id = GHD.IdGuiaHouse
                WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo
                    AND GHD.ShipToId = ISNULL(@ShipToId, GHD.ShipToId)
                    AND (@ExporterName IS NULL OR GH.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
                    AND (@ConsigneeName IS NULL OR GH.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@WaybillNumber IS NULL OR GH.NroGuia LIKE '%' + @WaybillNumber + '%')                  
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
                    GH.IdBodega AS WarehouseId, 
                    T.Id AS CarrierScheduleId, 
                    T.IdCarrier AS CarrierId, 
                    T.FechaDespacho AS DispatchDate,
                    GH.NroGuia AS GuideNumber, 
                    GH.ConsigneeId AS ConsigneeClientId, 
                    GH.BillToConsigneeId,
                    GHD.Po, 
                    GH.House, 
                    GH.IdGuia AS GuideId, 
                    GH.IdExportador AS ExporterId
                FROM GuiasHouse GH WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GH.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                LEFT JOIN #TMP_HouseWaybillDetails GHTEMP ON GHTEMP.Id = GHD.Id
                WHERE GH.House IS NOT NULL AND GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
                    AND GHTEMP.Id IS NULL
                    AND GHD.ShipToId = ISNULL(@ShipToId, GHD.ShipToId)
                    AND (@WaybillNumber IS NULL OR GH.NroGuia LIKE '%' + @WaybillNumber + '%')
                    AND (@ExporterName IS NULL OR GH.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@ConsigneeName IS NULL OR GH.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
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
                    GH.IdBodega AS WarehouseId, 
                    T.Id AS CarrierScheduleId, 
                    T.IdCarrier AS CarrierId, 
                    T.FechaDespacho AS DispatchDate,
                    GH.NroGuia AS GuideNumber, 
                    GH.ConsigneeId AS ConsigneeClientId,
                    GH.BillToConsigneeId, 
                    GHD.Po, 
                    GH.House, 
                    GH.IdGuia AS GuideId, 
                    GH.IdExportador AS ExporterId
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.ConsigneeId = GHO.ConsigneeId
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.IdGuia = GHO.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                LEFT JOIN #TMP_HouseWaybillDetails GHTEMP ON GHTEMP.Id = GHD.Id
                WHERE GHO.House IS NULL AND GHO.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
                    AND GHTEMP.Id IS NULL
                    AND GHD.ShipToId = ISNULL(@ShipToId, GHD.ShipToId)
                    AND (@WaybillNumber IS NULL OR GH.NroGuia LIKE '%' + @WaybillNumber + '%')
                    AND (@ExporterName IS NULL OR GH.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@ConsigneeName IS NULL OR GH.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
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
            ISNULL(UB.IdBodega, GHD.WarehouseId) AS WarehouseId,
            GHD.CarrierId,
            PT.IdTe,
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
                WHEN SV.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                WHEN SV.TipoVenta < 4 THEN 1
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
            LEFT JOIN ProgramacionTe PT WITH(NOLOCK) ON PT.IdProgramacionCarrier = GHD.CarrierScheduleId
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
            LEFT JOIN UbicacionPiezas UP WITH(NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones U WITH(NOLOCK) ON UP.IdUbicacion = U.Id 
            LEFT JOIN UbicacionesBodega UB WITH(NOLOCK) ON U.IdUbicacionBodega = UB.Id 
            LEFT JOIN SolicitudDeVentaDetalles SVD WITH(NOLOCK) ON SVD.IdGuiaHouseDetalle = GHD.Id
            LEFT JOIN SolicitudDeVenta SV WITH(NOLOCK) ON SV.Id = SVD.IdSolicitud
        WHERE 
            CASE 
                WHEN @IsPendingStatus = 1 AND (GHD.IsPod = @IsPendingStatus OR DDO.MailEnviado = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = @IsPendingStatus OR ISNULL(DDO.MailEnviado, @IsPendingStatus) = @IsPendingStatus) THEN 1 
                WHEN @IsPendingStatus = 0 AND (GHD.IsPod = 1 OR ISNULL(DDO.MailEnviado, @IsPendingStatus) = 0) THEN 1 
                ELSE 0
            END = 1
            AND CASE 
                    WHEN @IsInventory IS NULL THEN 1
                    WHEN @IsInventory = 0 AND SV.Id IS NULL THEN 1
                    WHEN @IsInventory = 0 AND SV.TipoVenta = 5 AND SVD.TipoPieza = 2 THEN 1
                    WHEN @IsInventory = 0 AND SV.TipoVenta = 4 THEN 1
                    WHEN @IsInventory = 1 AND SV.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                    WHEN @IsInventory = 1 AND SV.TipoVenta < 4 THEN 1 
                    ELSE 0 
                END = 1

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
        WHERE TMP.WarehouseId = ISNULL(@WarehouseId, TMP.WarehouseId)

        DROP TABLE #TMP_RelatedClients
        DROP TABLE #TMP_Exporters
        DROP TABLE #TMP_FinalClients
        DROP TABLE #TMP_ConsigneeClients
        DROP TABLE #TMP_HouseWaybillDetails
        DROP TABLE #TMP_Detalle

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError]
    END CATCH
END
/*
EXEC [dbo].[AC_pro_GetDispatchByClient360Detailed]
    @DateFrom = '2026-02-24',
    @DateTo = '2026-03-04',
    @ShipToId = NULL,
    @IsPending = 1,
    @ShipToName = NULL,
    @ConsigneeName = NULL,
    @ExporterName = NULL,
    @WarehouseId = NULL,
    @Po = NULL,
    @WaybillNumber = NULL,
    @TruckId = NULL,
    @IsInventory = NULL;
    
EXEC [dbo].[AC_pro_GetDispatchByClient360Detailed]
    @DateFrom = '2026-02-24',
    @DateTo = '2026-03-04',
    @ShipToId = 'ETY0000000029728',
    @IsPending = 1,
    @ShipToName ='NR MARIPOSA BOUQUET',
    @ConsigneeName ='NARANJO FARMS LLC IN & OUT',
    @ExporterName = NULL,
    @WarehouseId = NULL,
    @Po = NULL,
    @WaybillNumber = NULL,
    @TruckId = NULL,
    @IsInventory = NULL;
*/