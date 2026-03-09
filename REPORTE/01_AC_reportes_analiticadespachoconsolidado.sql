/*
VERSION     MODIFIEDBY          MODIFIEDDATE    HU      MODIFICATION
1           Jair Gomez          2026-02-11      57746   Based on pro_reportes_analiticadespachoconsolidado. 
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetConsolidatedDispatchAnalytics]
(
    @ConsigneeIds       VARCHAR(MAX),
    @StartDate         DATETIME,
    @EndDate         DATETIME
)
AS
BEGIN

    BEGIN TRY
        DECLARE @TBL_FilterConsignees TABLE (Id VARCHAR(16) PRIMARY KEY);

        IF (@ConsigneeIds IS NOT NULL AND @ConsigneeIds <> '')
        BEGIN
            INSERT INTO @TBL_FilterConsignees (Id)
            SELECT VALUE FROM STRING_SPLIT(@ConsigneeIds, ',');
        END

        CREATE TABLE #TMP_DispatchAnalytics (
            ShipperName         NVARCHAR(256),
            StatusPieza         VARCHAR(64),
            Awb                 VARCHAR(32),
            Origin              NVARCHAR(128),
            PoNumber            VARCHAR(64),
            TypePieza           VARCHAR(8),
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
            CarrierName         NVARCHAR(256),
            ShipToName          NVARCHAR(256)
        );

        INSERT INTO #TMP_DispatchAnalytics
        (
            ShipperName, StatusPieza, Awb, Origin,
            PoNumber, TypePieza, Equivalencia, Alto, Largo, Ancho, Boxes,
            TotalPcsHouse, TotalFullHouse, FechaDespacho, IdGuiaHouse,
            IdGuiaHouseDetalle, IdPoDetalle, CarrierName, ShipToName
        )
        SELECT
             EXS.Nombre
            ,GHD.EstadoPieza
            ,GHO.NroGuia
            ,CTY.Nombre
            ,GHD.Po
            ,TYP.TipoPieza
            ,TYP.Equivalencia
            ,GHD.AltoIn
            ,GHD.LargoIn
            ,GHD.AnchoIn
            ,1 AS Boxes
            ,GHO.TotalPcsHouse
            ,GHO.TotalFullHouse
            ,PCA.FechaDespacho
            ,GHO.Id
            ,GHD.Id
            ,GHD.IdPoDetalle
            ,TRA.Nombre
            ,ST.Nombre
        FROM GuiasHouse GHO WITH(NOLOCK)
        INNER JOIN GuiasHouseDetalles   GHD WITH(NOLOCK) ON GHD.IdGuiaHouse = GHO.Id
        INNER JOIN ProgramacionCarrier  PCA WITH(NOLOCK) ON PCA.IdGuiaHouseDetalle = GHD.Id
        INNER JOIN v_ClientsEntities    ST  WITH(NOLOCK) ON GHD.ShipToId = ST.Id
        INNER JOIN Exportadores         EXS WITH(NOLOCK) ON EXS.Id = GHO.IdExportador
        INNER JOIN TiposDePieza         TYP WITH(NOLOCK) ON TYP.Id = GHD.IdTipoDePieza
        INNER JOIN Ciudades             CTY WITH(NOLOCK) ON CTY.Id = GHO.IdCiudadPuertoOrigen
        INNER JOIN Transportes          TRA WITH(NOLOCK) ON PCA.IdCarrier = TRA.Id
        WHERE PCA.FechaDespacho BETWEEN @StartDate AND @EndDate
          AND GHD.EstadoPieza IN ('DISPATCHED WH','RECEIVED DR','RECEIVED WH','PENDING')
          AND (
              @ConsigneeIds IS NULL 
              OR GHO.ConsigneeId IN (SELECT Id FROM @TBL_FilterConsignees)
          );

        DELETE TMP
        FROM #TMP_DispatchAnalytics TMP
        INNER JOIN PoDetalles   POD WITH(NOLOCK) ON TMP.IdPoDetalle = POD.Id
        INNER JOIN PoEncabezado POE WITH(NOLOCK) ON POD.IdPo = POE.Id
        INNER JOIN OrdenesLocales OLO WITH(NOLOCK) ON POE.IdOrdenLocal = OLO.Id
        INNER JOIN Catalogos    CAT WITH(NOLOCK) ON OLO.IdCatalogoStatus = CAT.Id
        WHERE CAT.CodigoRelacion = 'CANCELADO';

        UPDATE TMP
        SET 
            TMP.Origin = CTY.Nombre,
            
            TMP.IdPo = CASE 
                           WHEN OLO.Id IS NOT NULL THEN POE.Id 
                           ELSE TMP.IdPo 
                       END,
            TMP.Awb  = CASE 
                           WHEN OLO.Id IS NOT NULL THEN 'LOCAL' 
                           ELSE TMP.Awb 
                       END
        FROM #TMP_DispatchAnalytics TMP
        INNER JOIN PoDetalles   POD WITH(NOLOCK) ON TMP.IdPoDetalle = POD.Id
        INNER JOIN PoEncabezado POE WITH(NOLOCK) ON POD.IdPo = POE.Id
        INNER JOIN Empresas     EMP WITH(NOLOCK) ON POE.IdEmpresa = EMP.Id
        INNER JOIN Ciudades     CTY WITH(NOLOCK) ON EMP.IdCiudad = CTY.Id
        LEFT JOIN OrdenesLocales OLO WITH(NOLOCK) ON POE.IdOrdenLocal = OLO.Id;

        UPDATE #TMP_DispatchAnalytics 
        SET PoNumber = NULL 
        WHERE PoNumber = '';

        SELECT
            Id              = CONVERT(VARCHAR(16), ROW_NUMBER() OVER (ORDER BY TMP.PoNumber, TMP.ShipperName)),
            IdConsignatario = '',
            Consignatario   = '',
            Shipper         = TMP.ShipperName,
            Boxes           = SUM(TMP.Boxes),
            [Type]          = TMP.TypePieza,
            Fb              = ROUND(SUM(TMP.Equivalencia), 2),
            Largo           = TMP.Largo,
            Ancho           = TMP.Ancho,
            Alto            = TMP.Alto,
            Cubic           = ROUND(SUM(TMP.Alto * TMP.Largo * TMP.Ancho / 1728), 2),
            [Status]        = TMP.StatusPieza,
            Awb             = TMP.Awb,
            Origin          = TMP.Origin,
            PoNumber        = TMP.PoNumber,
            Carrier         = TMP.CarrierName,
            ShipTo          = TMP.ShipToName,
            FechaDespacho   = TMP.FechaDespacho
        FROM #TMP_DispatchAnalytics TMP
        GROUP BY
            TMP.ShipperName,
            TMP.TypePieza,
            TMP.Largo,
            TMP.Alto,
            TMP.Ancho,
            TMP.StatusPieza,
            TMP.Awb,
            TMP.Origin,
            TMP.PoNumber,
            TMP.CarrierName,
            TMP.ShipToName,
            TMP.FechaDespacho
        ORDER BY TMP.Awb;

        DROP TABLE #TMP_DispatchAnalytics;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TMP_DispatchAnalytics') IS NOT NULL DROP TABLE #TMP_DispatchAnalytics;
        EXEC [dbo].[pro_LogError]
    END CATCH;
END;
/*
DECLARE @StartDate	DATETIME = '2026-01-02T00:00:00';
DECLARE @EndDate	DATETIME = '2026-01-02T00:00:00';
DECLARE @ConsigneeIds	VARCHAR(max) = 'ETY0000000008162,ETY0000000008707';

execute [dbo].[AC_pro_GetConsolidatedDispatchAnalytics] @ConsigneeIds, @StartDate, @EndDate;
*/