/*
VERSION     MODIFIEDBY          MODIFIEDDATE    HU      MODIFICATION
1           Jair Gomez          2026-02-11      57746   Based on pro_reportes_analiticadespachoconsolidado. 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetConsolidatedDispatchAnalytics_Billto_Optimized]
(
    @ConsigneeIds   VARCHAR(MAX) = NULL,
    @BillToIds      VARCHAR(MAX) = NULL,
    @StartDate      DATETIME,
    @EndDate        DATETIME
)
AS
BEGIN
    BEGIN TRY

        /* TABLAS TEMPORALES PARA FILTROS OPCIONALES */
        CREATE TABLE #FilterConsignees  (
            Id VARCHAR(16) PRIMARY KEY
        );
        CREATE TABLE #FilterBillTos     (
            Id VARCHAR(16) PRIMARY KEY
        );

        DECLARE @FilterByConsignee  BIT = 0;
        DECLARE @FilterByBillTo     BIT = 0;

        IF (@ConsigneeIds IS NOT NULL AND @ConsigneeIds <> '')
        BEGIN
            INSERT INTO #FilterConsignees (Id)
            SELECT TRIM(VALUE)
            FROM STRING_SPLIT(@ConsigneeIds, ',')
            WHERE TRIM(VALUE) <> '';

            SET @FilterByConsignee = 1;
        END

        IF (@BillToIds IS NOT NULL AND @BillToIds <> '')
        BEGIN
            INSERT INTO #FilterBillTos (Id)
            SELECT Id
            FROM dbo.f_SearchEntities(@BillToIds, 'IdBillTo');
             SET @FilterByBillTo = 1;
        END

        CREATE TABLE #TMP_DispatchAnalytics (
            Shipper             NVARCHAR(256),
            [Status]            VARCHAR(64),
            Awb                 VARCHAR(32),
            Origin              NVARCHAR(128),
            PoNumber            VARCHAR(64),
            [Type]              VARCHAR(8),
            Equivalencia        DECIMAL(18,5),
            Alto                DECIMAL(18,3),
            Largo               DECIMAL(18,3),
            Ancho               DECIMAL(18,3),
            Boxes               INT,
            TotalPcsHouse       INT,
            TotalFullHouse      DECIMAL(18,3),
            FechaDespacho       DATETIME,
            IdGuiaHouse         UNIQUEIDENTIFIER,
            IdGuiaHouseDetalle  UNIQUEIDENTIFIER,
            IdPo                UNIQUEIDENTIFIER,
            IdPoDetalle         UNIQUEIDENTIFIER,
            Carrier             NVARCHAR(256),
            Shipto              NVARCHAR(256)
        );

        INSERT INTO #TMP_DispatchAnalytics
        SELECT
            Shipper             = EX.Nombre,
            [Status]            = GHD.EstadoPieza,
            Awb                 = GH.NroGuia,
            Origin              = CD.Nombre,
            PoNumber            = CASE WHEN GHD.po = '' THEN NULL ELSE GHD.po END,
            [Type]              = TP.TipoPieza,
            Equivalencia        = TP.Equivalencia,
            Alto                = GHD.AltoIn,
            Largo               = GHD.LargoIn,
            Ancho               = GHD.AnchoIn,
            Boxes               = 1,
            TotalPcsHouse       = GH.TotalPcsHouse,
            TotalFullHouse      = GH.TotalFullHouse,
            FechaDespacho       = PC.FechaDespacho,
            IdGuiaHouse         = GH.Id,
            IdGuiaHouseDetalle  = GHD.Id,
            IdPo                = GHD.IdPoDetalle,
            IdPoDetalle         = GHD.IdPoDetalle,
            Carrier             = TS.Nombre,
            Shipto              = ST.Nombre
        FROM GuiasHouse             GH  WITH(NOLOCK)
        INNER JOIN GuiasHouseDetalles   GHD WITH(NOLOCK) ON GHD.IdGuiaHouse        = GH.Id
        INNER JOIN ProgramacionCarrier  PC  WITH(NOLOCK) ON PC.IdGuiaHouseDetalle   = GHD.Id
        INNER JOIN v_ClientsEntities    ST  WITH(NOLOCK) ON GHD.ShipToId            = ST.Id
        INNER JOIN Exportadores         EX  WITH(NOLOCK) ON EX.Id                   = GH.IdExportador
        INNER JOIN TiposDePieza         TP  WITH(NOLOCK) ON TP.Id                   = GHD.IdTipoDePieza
        INNER JOIN Ciudades             CD  WITH(NOLOCK) ON CD.Id                   = GH.IdCiudadPuertoOrigen
        INNER JOIN Transportes          TS  WITH(NOLOCK) ON PC.IdCarrier             = TS.Id
        -- Filtro opcional por Consignee
        LEFT JOIN #FilterConsignees     FC                ON FC.Id                   = GH.ConsigneeId
        -- Filtro opcional por BillTo (requiere pasar por la vista para resolver BillToId)
        LEFT JOIN v_ClientsEntities     BTC WITH(NOLOCK) ON BTC.Id                  = GH.BillToConsigneeId
        LEFT JOIN #FilterBillTos        FB                ON FB.Id                   = ISNULL(BTC.BillToId, BTC.EntityId)
        WHERE
            PC.FechaDespacho BETWEEN @StartDate AND @EndDate
            AND GHD.EstadoPieza IN ('DISPATCHED WH', 'RECEIVED DR', 'RECEIVED WH', 'PENDING')
            AND (@FilterByConsignee = 0 OR FC.Id IS NOT NULL)
            AND (@FilterByBillTo    = 0 OR FB.Id IS NOT NULL)
        OPTION (RECOMPILE);

        /* ELIMINAR REGISTROS CON ORDENES LOCALES CANCELADAS */
        DELETE TMP
        FROM #TMP_DispatchAnalytics TMP
        INNER JOIN PoDetalles    PD WITH(NOLOCK) ON TMP.IdPoDetalle         = PD.Id
        INNER JOIN PoEncabezado  PE WITH(NOLOCK) ON PD.IdPo                 = PE.Id
        INNER JOIN OrdenesLocales OL WITH(NOLOCK) ON PE.IdOrdenLocal        = OL.Id
        INNER JOIN Catalogos     CA WITH(NOLOCK) ON OL.IdCatalogoStatus     = CA.Id
        WHERE CA.CodigoRelacion = 'CANCELADO';

        UPDATE TMP
        SET
            TMP.Origin  = CD.Nombre,
            TMP.IdPo    = CASE WHEN OL.Id IS NOT NULL THEN PE.Id  ELSE TMP.IdPo  END,
            TMP.Awb     = CASE WHEN OL.Id IS NOT NULL THEN 'LOCAL' ELSE TMP.Awb  END
        FROM #TMP_DispatchAnalytics TMP
        INNER JOIN PoDetalles    PD  WITH(NOLOCK) ON TMP.IdPoDetalle    = PD.Id
        INNER JOIN PoEncabezado  PE  WITH(NOLOCK) ON PD.IdPo            = PE.Id
        INNER JOIN Empresas      EMP WITH(NOLOCK) ON PE.IdEmpresa        = EMP.Id
        INNER JOIN Ciudades      CD  WITH(NOLOCK) ON EMP.IdCiudad        = CD.Id
        LEFT JOIN  OrdenesLocales OL WITH(NOLOCK) ON PE.IdOrdenLocal     = OL.Id;

        SELECT
            Id              = CONVERT(VARCHAR(16), ROW_NUMBER() OVER (ORDER BY TMP.PoNumber, TMP.Shipper)),
            IdConsignatario = '',
            Consignatario   = '',
            TMP.Shipper,
            Boxes           = SUM(TMP.Boxes),
            TMP.[Type],
            Fb              = ROUND(SUM(TMP.Equivalencia), 2),
            TMP.Largo,
            TMP.Ancho,
            TMP.Alto,
            Cubic           = ROUND(SUM(TMP.Alto * TMP.Largo * TMP.Ancho / 1728), 2),
            TMP.[Status],
            TMP.Awb,
            TMP.Origin,
            TMP.PoNumber,
            TMP.Carrier,
            TMP.Shipto,
            TMP.FechaDespacho
        FROM #TMP_DispatchAnalytics TMP
        GROUP BY
            TMP.Shipper,
            TMP.[Type],
            TMP.Largo,
            TMP.Alto,
            TMP.Ancho,
            TMP.[Status],
            TMP.Awb,
            TMP.Origin,
            TMP.PoNumber,
            TMP.Carrier,
            TMP.Shipto,
            TMP.FechaDespacho
        ORDER BY TMP.Awb;

        DROP TABLE #TMP_DispatchAnalytics;
        DROP TABLE #FilterConsignees;
        DROP TABLE #FilterBillTos;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TMP_DispatchAnalytics')  IS NOT NULL DROP TABLE #TMP_DispatchAnalytics;
        IF OBJECT_ID('tempdb..#FilterConsignees')       IS NOT NULL DROP TABLE #FilterConsignees;
        IF OBJECT_ID('tempdb..#FilterBillTos')          IS NOT NULL DROP TABLE #FilterBillTos;
        EXEC [dbo].[pro_LogError];
    END CATCH;
END;

/*
DECLARE @StartDate      DATETIME        = '2026-01-02T00:00:00';
DECLARE @EndDate        DATETIME        = '2026-01-02T00:00:00';
DECLARE @ConsigneeIds   VARCHAR(MAX)    = 'ETY0000000008162,ETY0000000008707';
DECLARE @BillToIds      VARCHAR(MAX)    = NULL;

EXECUTE [dbo].[AC_pro_GetConsolidatedDispatchAnalytics] @ConsigneeIds, @BillToIds, @StartDate, @EndDate;
*/