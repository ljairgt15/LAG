/* VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
   1		    Jair Gomez			2026-03-03	   58765		Initial Code - Based on pro_ListarDespachoPorClientexCliente. 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetDispatchByClient360]
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
        DECLARE @TipoCliente            VARCHAR(32),
                @IdSistema              INT, 
                @IdDocumentoManifiesto  VARCHAR(16),
                @IsPendigB              BIT,
                @FechaDestinoComodin    DATETIME,
                @Final                  VARCHAR(16),
                @Consignee              VARCHAR(16),
                @Consolidador           VARCHAR(16),
                @Pendiente              BIT,
                @Completado             BIT,
                @MailEnviado            BIT,
                @EsPod                  BIT;

        SELECT 
            @Final = NULL,
            @Consignee = NULL,
            @Consolidador = NULL,
            @Pendiente = 0,
            @Completado = 1,
            @MailEnviado = 0,
            @EsPod = 1;

        SELECT 
            @IsPendigB = CASE WHEN @IsPending = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
            @FechaDestinoComodin = DATEADD(DAY, -90, @FechaHasta);

        CREATE TABLE #TMP_ClientesRelacionados ( [IdCliente] VARCHAR(16) PRIMARY KEY );
        CREATE TABLE #TMP_Exportadores ( [Id] VARCHAR(16) PRIMARY KEY );
        CREATE TABLE #TMP_ClientesFinales ( [Id] VARCHAR(16) PRIMARY KEY );
        CREATE TABLE #TMP_ClientesConsignee ( [Id] VARCHAR(16) PRIMARY KEY );

        CREATE TABLE #TMP_GuiasHouseDetalles
        (
            [Id]                    UNIQUEIDENTIFIER,
            [IdGuiaHouse]           UNIQUEIDENTIFIER,
            [EstadoPieza]           VARCHAR(64),
            [EsPod]                 BIT,
            [AltoIn]                DECIMAL(18, 2),
            [LargoIn]               DECIMAL(18, 2),
            [AnchoIn]               DECIMAL(18, 2),
            [IdClienteFinal]        VARCHAR(16),
            [TruckId]               VARCHAR(16),
            [IdBodega]              VARCHAR(16) NULL,
            [IdProgramacionCarrier] UNIQUEIDENTIFIER,
            [IdCarrier]             VARCHAR(16) NULL,
            [FechaDespacho]         DATETIME
        );
        
        SELECT TOP 1 @IdSistema = Id FROM SistemasEntidades WHERE Codigo = 'UNIFICADO';
        SELECT TOP 1 @IdDocumentoManifiesto = Id FROM Documentos WHERE Codigo = 'MANIFEST';

    -- [PENDIENTE DE DEFINICIÓN] Lógica de Grupo vs Cliente Directo
        SELECT @TipoCliente = CAT.Identificador 
        FROM Clientes CLI
        INNER JOIN DetalleEntidades DET ON DET.IdEntidad = CLI.Id
        INNER JOIN Catalogos CAT ON CAT.Id = DET.IdCatalogo
        WHERE CLI.Id = @IdCliente;

        IF @TipoCliente = 'CLIENTE'
        BEGIN 
            INSERT INTO #TMP_ClientesRelacionados (IdCliente) 
            SELECT @IdCliente;
        END
        ELSE
        BEGIN 
            INSERT INTO #TMP_ClientesRelacionados (IdCliente) 
            SELECT IdCliente FROM GrupoClientes WHERE IdGrupoCliente = @IdCliente;
        END

        SELECT TOP 1 @Consolidador = 'CONSOLIDADOR'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @FechaDestinoComodin AND @FechaHasta AND GHO.House IS NULL;

        SELECT TOP 1 @Consignee ='CONSIGNEE'
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHO.ConsigneeId
        WHERE GHO.FechaDestino BETWEEN @FechaDestinoComodin AND @FechaHasta AND GHO.House IS NOT NULL;

        SELECT TOP 1 @Final = 'FINAL'
        FROM GuiasHouseDetalles GHD WITH(NOLOCK)
        INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHD.ShipToId
        WHERE GHD.FechaCreacion BETWEEN @FechaDestinoComodin AND @FechaHasta;

        IF @IsPendigB = 0
        BEGIN
            SELECT @FechaDestinoComodin = DATEADD(DAY, -30, @FechaHasta);
        END

        IF @NombreExportador IS NOT NULL
        BEGIN 
            SELECT @NombreExportador = UPPER(@NombreExportador);

            INSERT INTO #TMP_Exportadores (Id)
            SELECT Id FROM Exportadores
            WHERE NombreComercial LIKE '%' + @NombreExportador + '%' OR Nombre LIKE '%' + @NombreExportador + '%';
        END

        IF @NombreClienteFinal IS NOT NULL
        BEGIN
            INSERT INTO #TMP_ClientesFinales (Id)
            SELECT Id FROM dbo.f_SearchEntities(@NombreClienteFinal, 'ShipTo');
        END

        IF @NombreClienteConsignee IS NOT NULL
        BEGIN
            INSERT INTO #TMP_ClientesConsignee (Id)
            SELECT Id FROM dbo.f_SearchEntities(@NombreClienteConsignee, 'Consignee');
        END

        IF @NombreClienteFinal IS NULL AND @NombreClienteConsignee IS NULL AND @NombreExportador IS NULL 
           AND @Po IS NULL AND @NroGuia IS NULL AND @TruckId IS NULL AND @IdBodega IS NULL 
        BEGIN
            IF @Final IS NOT NULL 
            BEGIN
                INSERT INTO #TMP_GuiasHouseDetalles
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId AS IdClienteFinal, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id AS IdProgramacionCarrier, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM ProgramacionCarrier PCA WITH(NOLOCK)
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND GHD.FechaCreacion BETWEEN @FechaDestinoComodin AND @FechaHasta
                INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHD.ShipToId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta;              
            END
            
            IF @Consignee IS NOT NULL
            BEGIN
                INSERT INTO #TMP_GuiasHouseDetalles
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId AS IdClienteFinal, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id AS IdProgramacionCarrier, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHO.House IS NOT NULL AND GHO.FechaDestino BETWEEN @FechaDestinoComodin AND @FechaHasta;  
            END
            
            IF @Consolidador IS NOT NULL
            BEGIN
                INSERT INTO #TMP_GuiasHouseDetalles
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId AS IdClienteFinal, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id AS IdProgramacionCarrier, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHX.House IS NULL AND GHX.FechaDestino BETWEEN @FechaDestinoComodin AND @FechaHasta;  
            END 
        END
        ELSE
        BEGIN 
            IF @Final IS NOT NULL 
            BEGIN           
                INSERT INTO #TMP_GuiasHouseDetalles
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId AS IdClienteFinal, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id AS IdProgramacionCarrier, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouseDetalles GHD WITH(NOLOCK)
                INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHD.ShipToId
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.Id = GHD.IdGuiaHouse
                WHERE GHD.FechaCreacion BETWEEN @FechaDestinoComodin AND @FechaHasta
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT Id FROM #TMP_Exportadores))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT Id FROM #TMP_ClientesFinales))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT Id FROM #TMP_ClientesConsignee))
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%');                  
            END

            IF @Consignee IS NOT NULL
            BEGIN           
                INSERT INTO #TMP_GuiasHouseDetalles
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId AS IdClienteFinal, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id AS IdProgramacionCarrier, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho
                FROM GuiasHouse GHO WITH(NOLOCK)
                INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHO.ConsigneeId
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
                WHERE GHO.FechaDestino BETWEEN @FechaDestinoComodin AND @FechaHasta AND GHO.House IS NOT NULL 
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%')
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT Id FROM #TMP_Exportadores))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT Id FROM #TMP_ClientesFinales))
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT Id FROM #TMP_ClientesConsignee))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END
            
            IF @Consolidador IS NOT NULL
            BEGIN       
                INSERT INTO #TMP_GuiasHouseDetalles
                SELECT DISTINCT
                    GHD.Id, 
                    GHD.IdGuiaHouse, 
                    GHD.EstadoPieza, 
                    GHD.EsPod, 
                    GHD.AltoIn, 
                    GHD.LargoIn, 
                    GHD.AnchoIn,
                    GHD.ShipToId AS IdClienteFinal, 
                    GHD.TruckId, 
                    GHO.IdBodega, 
                    PCA.Id AS IdProgramacionCarrier, 
                    PCA.IdCarrier, 
                    PCA.FechaDespacho 
                FROM GuiasHouse GHX WITH(NOLOCK)
                INNER JOIN #TMP_ClientesRelacionados REL ON REL.IdCliente = GHX.ConsigneeId
                INNER JOIN GuiasHouse GHO WITH(NOLOCK) ON GHO.IdGuia = GHX.IdGuia
                INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
                INNER JOIN ProgramacionCarrier PCA WITH(NOLOCK) ON GHD.Id = PCA.IdGuiaHouseDetalle 
                    AND PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
                WHERE GHX.FechaDestino BETWEEN @FechaDestinoComodin AND @FechaHasta
                    AND GHX.House IS NULL 
                    AND (@NroGuia IS NULL OR GHO.NroGuia LIKE '%' + @NroGuia + '%')
                    AND (@NombreExportador IS NULL OR GHO.IdExportador IN (SELECT Id FROM #TMP_Exportadores))
                    AND (@NombreClienteFinal IS NULL OR GHD.ShipToId IN (SELECT Id FROM #TMP_ClientesFinales))
                    AND (@NombreClienteConsignee IS NULL OR GHO.ConsigneeId IN (SELECT Id FROM #TMP_ClientesConsignee))
                    AND (@TruckId IS NULL OR GHD.TruckId LIKE '%' + @TruckId + '%')
                    AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%');
            END 
        END
        
        SELECT
            GHD.EstadoPieza,
            GHD.FechaDespacho,
            MAN.NroManifiesto,
            SUM(GHD.AltoIn * GHD.LargoIn * GHD.AnchoIn) AS CapacidadCarga,
            COUNT(1) AS TotalPiezas,
            GHD.IdClienteFinal,
            GHD.TruckId,
            ISNULL(UBO.IdBodega, GHD.IdBodega) AS IdBodega,
            GHD.IdCarrier,
            PTE.IdTe,
            MAN.Id AS IdManifiesto,
            CAST (CASE 
                WHEN SVE.TipoVenta = 5 AND SVD.TipoPieza = 1 THEN 1
                WHEN SVE.TipoVenta < 4 THEN 1
                ELSE 0 
            END AS BIT) AS EsInventario,
            DDO.NombreDocumentoDespacho,
            DDO.IdDocumentosDespacho,
            DDO.MailEnviado,
            GHD.EsPod
        INTO #TMP_Detalle
        FROM
            (
                SELECT DISTINCT
                    TMP.Id, 
                    TMP.EstadoPieza, 
                    TMP.FechaDespacho, 
                    TMP.IdProgramacionCarrier,
                    TMP.AltoIn, 
                    TMP.LargoIn, 
                    TMP.AnchoIn, 
                    TMP.IdClienteFinal, 
                    TMP.TruckId,
                    TMP.IdBodega, 
                    TMP.IdCarrier, 
                    TMP.EsPod
                FROM #TMP_GuiasHouseDetalles TMP
            ) GHD
            LEFT JOIN ProgramacionTe PTE ON PTE.IdProgramacionCarrier = GHD.IdProgramacionCarrier
            LEFT JOIN ProgramacionManifiesto PMA WITH(NOLOCK) ON PMA.IdProgramacionCarrier = GHD.IdProgramacionCarrier
            LEFT JOIN ManifiestosDespacho MAN ON MAN.Id = PMA.IdManifiestoDespacho
            OUTER APPLY (
                SELECT TOP 1 
                    DDE.EsPod, 
                    DDE.MailEnviado, 
                    DDE.NombreArchivo AS NombreDocumentoDespacho, 
                    DDE.Id AS IdDocumentosDespacho
                FROM DocumentosDespacho DDE
                WHERE DDE.IdManifiesto = MAN.Id 
                AND DDE.IdDocumento = @IdDocumentoManifiesto
                ORDER BY DDE.EsPod DESC
            ) DDO
            LEFT JOIN UbicacionPiezas UBP WITH(NOLOCK) ON GHD.Id = UBP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones UBI ON UBP.IdUbicacion = UBI.Id 
            LEFT JOIN UbicacionesBodega UBO ON UBI.IdUbicacionBodega = UBO.Id 
            LEFT JOIN SolicitudDeVentaDetalles SVD ON SVD.IdGuiaHouseDetalle = GHD.Id
            LEFT JOIN SolicitudDeVenta SVE ON SVE.Id = SVD.IdSolicitud
        WHERE
            CASE 
                WHEN @IsPendigB = 1 AND (GHD.EsPod = @IsPendigB OR DDO.MailEnviado = @IsPendigB) THEN 1 
                WHEN @IsPendigB = 0 AND (GHD.EsPod = @IsPendigB OR ISNULL(DDO.MailEnviado, @IsPendigB) = @IsPendigB) THEN 1 
                WHEN @IsPendigB = 0 AND (GHD.EsPod = 1 OR ISNULL(DDO.MailEnviado, @IsPendigB) = 0) THEN 1 
                ELSE 0
            END = 1
        GROUP BY 
            GHD.EstadoPieza, 
            GHD.FechaDespacho, 
            MAN.NroManifiesto, 
            GHD.IdClienteFinal,
            GHD.TruckId, 
            GHD.IdBodega, 
            UBO.IdBodega, 
            GHD.IdCarrier, 
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
            GHD.EsPod;

        SELECT
            ROW_NUMBER() OVER (ORDER BY TMP.FechaDespacho) AS Id,
            TMP.EstadoPieza,
            TMP.FechaDespacho,
            TMP.NroManifiesto,
            TMP.CapacidadCarga,
            TMP.TotalPiezas,
            CLI.Nombre AS NombreClienteFinal,
            PAI.Nombre AS NombrePais,
            PAI.CodigoIso AS CodigoIsoPais,
            EST.CodigoIso AS CodigoIsoEstado,
            TRA.Nombre AS NombreCarrier,
            CRE.Codigo AS CodigoCarrier,
            PUE.CodigoAduana,
            BOD.Nombre AS NombreBodega,
            TMP.NombreDocumentoDespacho,
            TMP.MailEnviado,
            TMP.IdClienteFinal,
            TMP.TruckId,
            TMP.IdBodega,
            TMP.IdCarrier,
            TMP.IdManifiesto,
            PAI.Id AS IdPais,
            EST.Id AS IdEstado,
            TMP.IdDocumentosDespacho,
            TMP.EsInventario,
            TMP.EsPod
        FROM #TMP_Detalle TMP
        INNER JOIN Bodegas BOD ON TMP.IdBodega = BOD.Id
        INNER JOIN Transportes TRA ON TMP.IdCarrier = TRA.Id
        INNER JOIN v_ClientsEntities CLI ON TMP.IdClienteFinal = CLI.ConsigneeId
        INNER JOIN Paises PAI ON CLI.IdPais = PAI.Id
        INNER JOIN Estados EST ON CLI.IdEstado = EST.Id
        LEFT JOIN CodigosRelacionSistemas CRE ON TMP.IdCarrier = CRE.IdEntidad AND CRE.TipoEntidad = 'CARRIER' AND CRE.IdSistemaEntidad = @IdSistema
        LEFT JOIN TransportacionExportacion TEX ON TMP.IdTe = TEX.Id
        LEFT JOIN Puertos PUE ON TEX.IdPuerto = PUE.Id
        WHERE TMP.IdBodega = ISNULL(@IdBodega, TMP.IdBodega);

        DROP TABLE #TMP_ClientesRelacionados;
        DROP TABLE #TMP_Exportadores;
        DROP TABLE #TMP_ClientesFinales;
        DROP TABLE #TMP_ClientesConsignee;
        DROP TABLE #TMP_GuiasHouseDetalles;
        DROP TABLE #TMP_Detalle;

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH
END
/*
EXEC [dbo].[pro_GetDispatchByClient360]
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