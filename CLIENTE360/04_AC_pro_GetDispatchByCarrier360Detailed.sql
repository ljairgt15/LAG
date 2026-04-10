/* 
VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
1		    Jair Gomez			2026-03-03	   58765    Based on pro_ListarDespachoPorCarrierxDetallada 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByCarrier360Detailed]
(
    @DateFrom               DATE,
    @DateTo                 DATE,
    @EntityId               VARCHAR(16) = NULL,
    @UserType               VARCHAR(32) = NULL,
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
        [Id]      VARCHAR(16),
        [IdCliente]     VARCHAR(16),
        [BillToConsigneeId] VARCHAR(16),
        [BilltoId]     VARCHAR(16),
        [ConsigneeId]     VARCHAR(16)
        )
        
        CREATE TABLE #TMP_Exporters ( 
            [ExporterId] VARCHAR(16)
        )
        CREATE TABLE #TMP_FinalClients (
            [ShipToId] VARCHAR(16)
        )
        CREATE TABLE #TMP_ConsigneeClients (
            [ConsigneeClientId] VARCHAR(16)
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
            [HeaderLabelId]         UNIQUEIDENTIFIER,
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
            [ExporterId]            VARCHAR(16),
            [BrokerId]              VARCHAR(16)
        )

        SELECT TOP 1 @SystemId = Id 
        FROM SistemasEntidades 
        WHERE Codigo = 'UNIFICADO'

        SELECT TOP 1 @ManifestDocumentId = Id 
        FROM Documentos 
        WHERE Codigo = 'MANIFEST'

        INSERT INTO #TMP_RelatedClients (Id,IdCliente, BillToConsigneeId,BilltoId,ConsigneeId)
        EXEC [dbo].[AC_pro_GetClientsEntities] 
             @EntityId = @EntityId,
             @UserType = @UserType 

        SELECT TOP 1 @ConsolidatorStatus = 'CONSOLIDADOR'
        FROM GuiasHouse GH WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GH.ConsigneeId
        WHERE GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GH.House IS NULL

        SELECT TOP 1 @ConsigneeStatus ='CONSIGNEE'
        FROM GuiasHouse GH WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GH.ConsigneeId
        WHERE GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GH.House IS NOT NULL

        SELECT TOP 1 @FinalStatus = 'FINAL'
        FROM GuiasHouseDetalles GHD WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
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
                    GHD.IdHeaderLabel AS HeaderLabelId, 
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
                    GH.IdExportador AS ExporterId, 
                    GH.IdBroker AS BrokerId
                FROM ProgramacionCarrier T WITH(NOLOCK)
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
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
                    GHD.IdHeaderLabel AS HeaderLabelId, 
                    GHD.TruckId, GH.IdBodega AS WarehouseId, 
                    T.Id AS CarrierScheduleId, 
                    T.IdCarrier AS CarrierId, 
                    T.FechaDespacho AS DispatchDate,
                    GH.NroGuia AS GuideNumber, 
                    GH.ConsigneeId AS ConsigneeClientId,
                    GH.BillToConsigneeId,
                    GHD.Po, 
                    GH.House, 
                    GH.IdGuia AS GuideId, 
                    GH.IdExportador AS ExporterId, 
                    GH.IdBroker AS BrokerId
                FROM GuiasHouse GH WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GH.ConsigneeId
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
                    GHD.IdHeaderLabel AS HeaderLabelId, 
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
                    GH.IdExportador AS ExporterId, 
                    GH.IdBroker AS BrokerId
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON T.IdGuiaHouseDetalle = GHD.Id 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
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
                    GHD.IdHeaderLabel AS HeaderLabelId, 
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
                    GH.IdExportador AS ExporterId, 
                    GH.IdBroker AS BrokerId
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.Id = GHD.IdGuiaHouse
                WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@ExporterName IS NULL OR GH.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
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
                    GHD.IdHeaderLabel AS HeaderLabelId, 
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
                    GH.IdExportador AS ExporterId, 
                    GH.IdBroker AS BrokerId
                FROM GuiasHouse GH WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GH.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo 
                WHERE GH.House IS NOT NULL AND GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
                    AND (@WaybillNumber IS NULL OR GH.NroGuia LIKE '%' + @WaybillNumber + '%')
                    AND (@ExporterName IS NULL OR GH.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ConsigneeName IS NULL OR GH.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
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
                    GHD.IdHeaderLabel AS HeaderLabelId, 
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
                    GH.IdExportador AS ExporterId, 
                    GH.IdBroker AS BrokerId
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHX.ConsigneeId
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
                    AND (@WaybillNumber IS NULL OR GH.NroGuia LIKE '%' + @WaybillNumber + '%')
                    AND (@ExporterName IS NULL OR GH.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ConsigneeName IS NULL OR GH.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
            END 
        END
        
        SELECT DISTINCT
            GHD.Id,
            GHD.PieceStatus,
            GHD.DispatchDate,
            MAN.NroManifiesto,
            GHD.HeightIn,
            GHD.LengthIn,
            GHD.WidthIn,
            GHD.ShipToId,
            GHD.HeaderLabelId,
            GHD.TruckId,
            ISNULL(UB.IdBodega, GHD.WarehouseId) AS WarehouseId,
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
            GHD.BrokerId,
            CAST(CASE 
                    WHEN SV.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                    WHEN SV.TipoVenta < 4 THEN 1
                    ELSE 0
                END AS BIT) AS EsInventario,
            DDO.Id AS IdDocumentosDespacho, 
            CONVERT(VARCHAR(36), DDO.Id) AS IdDocumentosDespachoString, 
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
                DD.EsPod, DD.MailEnviado, DD.Id, DD.NombreArchivo AS NombreDocumentoDespacho
            FROM DocumentosDespacho DD WITH(NOLOCK)
            WHERE DD.IdManifiesto = MAN.Id AND DD.IdDocumento = @ManifestDocumentId
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

        SELECT DISTINCT
            NEWID() AS Id,
            TMP.HouseWaybillId AS IdGuiaHouse, 
            '' AS IdGuia, 
            TMP.Id AS IdGuiaHouseDetalle,
            TMP.DispatchDate AS FechaDespacho, 
            TMP.WarehouseId AS IdBodega, 
            BOD.Nombre AS NombreBodega, 
            TRA.Id AS IdCarrier, 
            TRA.Nombre AS NombreCarrier, 
            COR.Codigo AS CodigoCarrier, 
            '' AS IdClienteConsignee, 
            VCC.Nombre AS NombreClienteConsignee,  
            '' AS IdPaisConsignee,
            '' AS NombrePaisConsignee,
            VCS.Nombre AS NombreClienteFinalAlt, 
            '' AS NombreClienteFinalClienteFinalAlt,
            '' AS IdEstadoConsignee,
            '' AS CodigoIsoEstadoConsignee,
            P.Id AS IdPaisAlt, 
            P.Nombre AS NombrePaisAlt, 
            '' AS CodigoIsoPaisAlt, 
            ES.Id AS IdEstadoAlt, 
            ES.CodigoISO AS CodigoIsoEstadoAlt, 
            TMP.ShipToId AS IdClienteFinal, 
            VCS.Nombre AS NombreClienteFinal, 
            P.Id AS IdPais, 
            P.Nombre AS NombrePais,  
            '' AS CodigoIsoPais, 
            ES.Id AS IdEstado, 
            ES.CodigoISO AS CodigoIsoEstado, 
            TMP.ManifiestoId AS IdManifiesto, 
            TMP.NroManifiesto, 
            '' AS ColorEstadoManifiesto,
            '' AS ColorEnvioTE,
            PUE.CodigoAduana AS DescripcionPuertoFronterizo, 
            0 AS PcsPending, 0 AS PcsReceivedDr, 0 AS PcsReceivedWh, 0 AS PcsHold, 0 AS PcsLost, 0 AS PcsDispatchedWh, 0 AS PcsStandby, 0 AS TotalPcs,
            TMP.PieceStatus AS [Status], 
            CAST(0 AS BIT) AS CargaTransito,
            CAST(0 AS BIT) AS CargaTransitoNull,
            '' AS TipoNubeDocs,
            TMP.IdDocumentosDespacho,
            TMP.IdDocumentosDespachoString, 
            TMP.EmailEnviado, 
            CAST(0 AS BIT) AS [TransportExportEnviado], 
            '' AS UsuarioEnvioTE,
            '' AS FechaEnvioTE,
            '' AS TextoTooltipTE,
            '' AS NroGuia, 
            '' AS NroOrdenLocal,
            '' AS NroDocumento,
            TMP.TruckId, 
            '' AS TruckIdText,
            0.00 AS CapacidadCarga,
            TMP.Po, 
            '' AS CuttOfTime,
            '' AS CodigoSubCarrier, 
            '' AS NombreSubCarrier, 
            HEA.HeaderLabel, 
            NULL AS IdHeaderLabel,
            '' AS IdExportador,
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
            '' AS House, 
            CAST(0 AS BIT) AS Modificado,
            '' AS Pallet,
            NULL AS IdOrdenVenta,
            '' AS Puerta,
            '' AS Placa,
            '' AS NroDespacho,
            NULL AS FechaOrdenVenta,
            TMP.BrokerId AS IdBroker, 
            E.NombreComercial AS NombreExportador,
            TMP.EsInventario
        FROM #TMP_Detalle TMP
        INNER JOIN Bodegas BOD ON TMP.WarehouseId = BOD.Id
        INNER JOIN Transportes TRA ON TMP.CarrierId = TRA.Id
        INNER JOIN v_ClientsEntities VCS ON TMP.ShipToId = VCS.Id
        INNER JOIN v_ClientsEntities VCC ON ISNULL(TMP.BillToConsigneeId, TMP.ConsigneeClientId) = VCC.Id
        INNER JOIN Exportadores E ON TMP.ExporterId = E.Id
        LEFT JOIN Paises P ON VCS.IdPais = P.Id
        LEFT JOIN Estados ES ON VCS.IdEstado = ES.Id
        LEFT JOIN HeaderLabels HEA ON TMP.HeaderLabelId = HEA.Id
        LEFT JOIN CodigosRelacionSistemas COR ON TMP.CarrierId = COR.IdEntidad AND COR.TipoEntidad = 'CARRIER' AND COR.IdSistemaEntidad = @SystemId 
        LEFT JOIN TransportacionExportacion TEX ON TMP.IdTe = TEX.Id
        LEFT JOIN Puertos PUE ON TEX.IdPuerto = PUE.Id
        LEFT JOIN Transportes CSC ON TMP.CarrierId = CSC.Id
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
EXEC [dbo].[AC_pro_GetDispatchByCarrier360Detailed]
    @DateFrom = '2026-02-24',
    @DateTo = '2026-03-04',
    @IsPending = 1,
    @ShipToName = NULL,
    @ConsigneeName = NULL,
    @ExporterName = NULL,
    @WarehouseId = NULL,
    @Po = NULL,
    @WaybillNumber = NULL,
    @TruckId = NULL,
    @IsInventory = NULL;
EXEC [dbo].[AC_pro_GetDispatchByCarrier360Detailed]
    @DateFrom = '2026-02-24',
    @DateTo = '2026-03-04',
    @IsPending = 1,
    @ShipToName = 'NR MARIPOSA BOUQUET',
    @ConsigneeName = 'NARANJO FARMS LLC IN & OUT',
    @ExporterName = NULL,
    @WarehouseId = NULL,
    @Po = NULL,
    @WaybillNumber = NULL,
    @TruckId = NULL,
    @IsInventory = NULL;
*/