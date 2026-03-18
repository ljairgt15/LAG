/* 
VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
1		    Jair Gomez			2026-03-03	   58765	Based on pro_ListarDespachoPorClientexCliente
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByClient360_Opt]
(
    @DateFrom               DATE,
    @DateTo                 DATE,
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
                @FinalStatus                VARCHAR(16) = NULL,
                @ConsigneeStatus            VARCHAR(16) = NULL,
                @ConsolidatorStatus         VARCHAR(16) = NULL,
                @PendingStatus              BIT = 0,
                @CompletedStatus            BIT = 1,
                @MailSentStatus             BIT = 0,
                @IsPodStatus                BIT = 1

        SELECT 
            @IsPendingStatus         = CASE WHEN @IsPending = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
            @WildcardDestinationDate = DATEADD(DAY, -90, @DateTo)

        CREATE TABLE #TMP_RelatedClients (
        [EntityId]      VARCHAR(16),
        [IdCliente]     VARCHAR(16),
        [TipoCliente]   VARCHAR(32)
        )
        CREATE CLUSTERED INDEX IX_TMP_Related_Entity ON #TMP_RelatedClients(EntityId)
        
        CREATE TABLE #TMP_Exporters ( 
            [ExporterId] VARCHAR(16) PRIMARY KEY 
        )
        CREATE TABLE #TMP_FinalClients ( 
            [ShipToId] VARCHAR(16) PRIMARY KEY 
        )
        CREATE TABLE #TMP_ConsigneeClients (
            [ConsigneeClientId] VARCHAR(16) PRIMARY KEY 
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
            [ShipToId]         VARCHAR(16),
            [TruckId]               VARCHAR(16),
            [WarehouseId]           VARCHAR(16) NULL,
            [CarrierScheduleId]     UNIQUEIDENTIFIER,
            [CarrierId]             VARCHAR(16) NULL,
            [DispatchDate]          DATETIME
        )
        
        SELECT TOP 1 @SystemId = Id 
        FROM SistemasEntidades WITH(NOLOCK) 
        WHERE Codigo = 'UNIFICADO'

        SELECT TOP 1 @ManifestDocumentId = Id 
        FROM Documentos WITH(NOLOCK) 
        WHERE Codigo = 'MANIFEST'

        INSERT INTO #TMP_RelatedClients (EntityId, IdCliente, TipoCliente)
        EXEC [dbo].[AC_pro_GetClientsEntities] 
            @IdUsuario = @UserId

        SELECT TOP 1 @ConsolidatorStatus = 'CONSOLIDADOR'
        FROM GuiasHouse GH WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = ISNULL(GH.BilltoConsigneeId, GH.ConsigneeId)
        WHERE GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GH.House IS NULL

        SELECT TOP 1 @ConsigneeStatus ='CONSIGNEE'
        FROM GuiasHouse GH WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = ISNULL(GH.BilltoConsigneeId, GH.ConsigneeId)
        WHERE GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GH.House IS NOT NULL

        SELECT TOP 1 @FinalStatus = 'FINAL'
        FROM GuiasHouseDetalles GHD WITH(NOLOCK)
        INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
        WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo


        IF @IsPendingStatus = 0
        BEGIN
            SELECT @WildcardDestinationDate = DATEADD(DAY, -30, @DateTo)
        END

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
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GH.IdBodega, 
                    T.Id, 
                    T.IdCarrier, 
                    T.FechaDespacho
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
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GH.IdBodega, 
                    T.Id, 
                    T.IdCarrier, 
                    T.FechaDespacho
                FROM GuiasHouse GH WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = ISNULL(GH.BilltoConsigneeId, GH.ConsigneeId)
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
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GH.IdBodega, 
                    T.Id, 
                    T.IdCarrier, 
                    T.FechaDespacho
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = ISNULL(GHX.BilltoConsigneeId, GHX.ConsigneeId)
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON T.IdGuiaHouseDetalle = GHD.Id 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo  
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
                    GH.IdBodega, 
                    T.Id, 
                    T.IdCarrier, 
                    T.FechaDespacho
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = GHD.ShipToId
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.Id = GHD.IdGuiaHouse
                WHERE GHD.FechaCreacion BETWEEN @WildcardDestinationDate AND @DateTo
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
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GH.IdBodega, 
                    T.Id, 
                    T.IdCarrier, 
                    T.FechaDespacho
                FROM GuiasHouse GH WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = ISNULL(GH.BilltoConsigneeId, GH.ConsigneeId)
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo 
                WHERE GH.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo AND GH.House IS NOT NULL 
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
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId, 
                    GHD.TruckId, 
                    GH.IdBodega, 
                    T.Id, 
                    T.IdCarrier, 
                    T.FechaDespacho 
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_RelatedClients REL ON REL.EntityId = ISNULL(GHX.BilltoConsigneeId, GHX.ConsigneeId)
                INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GH.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
                INNER JOIN ProgramacionCarrier T WITH(NOLOCK) ON GHD.Id = T.IdGuiaHouseDetalle 
                    AND T.FechaDespacho BETWEEN @DateFrom AND @DateTo
                WHERE GHX.FechaDestino BETWEEN @WildcardDestinationDate AND @DateTo
                    AND GHX.House IS NULL 
                    AND (@WaybillNumber IS NULL OR GH.NroGuia LIKE '%' + @WaybillNumber + '%')
                    AND (@ExporterName IS NULL OR GH.IdExportador IN (SELECT ExporterId FROM #TMP_Exporters))
                    AND (@ShipToName IS NULL OR GHD.ShipToId IN (SELECT ShipToId FROM #TMP_FinalClients))
                    AND (@ConsigneeName IS NULL OR GH.ConsigneeId IN (SELECT ConsigneeClientId FROM #TMP_ConsigneeClients))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
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
            ISNULL(UB.IdBodega, GHD.WarehouseId) AS WarehouseId,
            GHD.CarrierId,
            PTE.IdTe,
            MAN.Id AS ManifiestoId,
            CAST(CASE 
                WHEN SV.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                WHEN SV.TipoVenta < 4 THEN 1
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
            LEFT JOIN ProgramacionManifiesto PM WITH(NOLOCK) ON PM.IdProgramacionCarrier = GHD.CarrierScheduleId
            LEFT JOIN ManifiestosDespacho MAN ON MAN.Id = PM.IdManifiestoDespacho
            OUTER APPLY (
                SELECT TOP 1 
                    DD.EsPod, 
                    DD.MailEnviado, 
                    DD.NombreArchivo AS NombreDocumentoDespacho, 
                    DD.Id AS IdDocumentosDespacho
                FROM DocumentosDespacho DD
                WHERE DD.IdManifiesto = MAN.Id 
                AND DD.IdDocumento = @ManifestDocumentId
                ORDER BY DD.EsPod DESC
            ) DDO
            LEFT JOIN UbicacionPiezas UP WITH(NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones U ON UP.IdUbicacion = U.Id 
            LEFT JOIN UbicacionesBodega UB ON U.IdUbicacionBodega = UB.Id 
            LEFT JOIN SolicitudDeVentaDetalles SVD ON SVD.IdGuiaHouseDetalle = GHD.Id
            LEFT JOIN SolicitudDeVenta SV ON SV.Id = SVD.IdSolicitud
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
            UB.IdBodega, 
            GHD.CarrierId, 
            PTE.IdTe, 
            MAN.Id,
            CASE 
                WHEN SV.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1 
                WHEN SV.TipoVenta < 4 THEN 1 
                ELSE 0 
            END,
            DDO.NombreDocumentoDespacho, 
            DDO.IdDocumentosDespacho, 
            DDO.MailEnviado, 
            GHD.IsPod

        SELECT
            ROW_NUMBER() OVER (ORDER BY TMP.DispatchDate) AS Id,
            TMP.PieceStatus AS EstadoPieza,
            TMP.DispatchDate AS FechaDespacho,
            TMP.NroManifiesto,
            TMP.CapacidadCarga,
            TMP.TotalPiezas,
            VCE.Nombre AS NombreClienteFinal,
            PA.Nombre AS NombrePais,
            PA.CodigoIso AS CodigoIsoPais,
            EST.CodigoIso AS CodigoIsoEstado,
            TRA.Nombre AS NombreCarrier,
            CR.Codigo AS CodigoCarrier,
            PUE.CodigoAduana,
            BOD.Nombre AS NombreBodega,
            TMP.NombreDocumentoDespacho,
            TMP.MailEnviado,
            TMP.ShipToId AS IdClienteFinal,
            TMP.TruckId,
            TMP.WarehouseId AS IdBodega,
            TMP.CarrierId AS IdCarrier,
            TMP.ManifiestoId AS IdManifiesto,
            PA.Id AS IdPais,
            EST.Id AS IdEstado,
            TMP.IdDocumentosDespacho,
            TMP.EsInventario,
            TMP.IsPod AS EsPod
        FROM #TMP_Detalle TMP
        INNER JOIN Bodegas BOD ON TMP.WarehouseId = BOD.Id
        INNER JOIN Transportes TRA ON TMP.CarrierId = TRA.Id
        INNER JOIN v_ClientsEntities VCE ON TMP.ShipToId = VCE.Id
        INNER JOIN Paises PA ON VCE.IdPais = PA.Id
        INNER JOIN Estados EST ON VCE.IdEstado = EST.Id
        LEFT JOIN CodigosRelacionSistemas CR ON TMP.CarrierId = CR.IdEntidad AND CR.TipoEntidad = 'CARRIER' AND CR.IdSistemaEntidad = @SystemId
        LEFT JOIN TransportacionExportacion TE ON TMP.IdTe = TE.Id
        LEFT JOIN Puertos PUE ON TE.IdPuerto = PUE.Id
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
EXEC [dbo].[AC_pro_GetDispatchByClient360]
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
EXEC [dbo].[AC_pro_GetDispatchByClient360]
    @DateFrom = '2026-02-24',
    @DateTo = '2026-03-04',
    @ClientId = 'CLI0120247',
    @IsPending = 1,
    @ShipToName = 'NR MARIPOSA BOUQUET',
    @ConsigneeName = 'NARANJO FARMS LLC IN & OUT',
    @ExporterName = NULL,
    @WarehouseId = NULL,
    @Po = NULL,
    @WaybillNumber = NULL,
    @TruckId = NULL;
*/