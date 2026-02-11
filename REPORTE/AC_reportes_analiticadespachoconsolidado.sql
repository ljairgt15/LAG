/*
VERSION     MODIFIEDBY          MODIFIEDDATE    HU      MODIFICATION
1           Jair Gomez          2026-02-11      57746   Initial Code - Migration of pro_reportes_analiticadespachoconsolidado. 
                                                        Refactoring to use v_ClientsEntities and BillTo/Consignee logic.
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetConsolidatedDispatchAnalytics]
(
    @ConsigneeIds       VARCHAR(MAX) = NULL,
    @BillToIds          VARCHAR(MAX) = NULL,
    @FechaDesde         DATETIME,
    @FechaHasta         DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- 1. Variables tabla para filtros (Estandar < 2000 registros)
        DECLARE @TBL_FilterConsignees TABLE (Id VARCHAR(16) PRIMARY KEY);
        DECLARE @TBL_FilterBillTos TABLE (Id VARCHAR(16) PRIMARY KEY);

        -- 2. Llenado de filtros
        IF (@ConsigneeIds IS NOT NULL AND @ConsigneeIds <> '')
        BEGIN
            INSERT INTO @TBL_FilterConsignees (Id)
            SELECT VALUE FROM STRING_SPLIT(@ConsigneeIds, ',');
        END

        IF (@BillToIds IS NOT NULL AND @BillToIds <> '')
        BEGIN
            INSERT INTO @TBL_FilterBillTos (Id)
            SELECT VALUE FROM STRING_SPLIT(@BillToIds, ',');
        END

        -- 3. Tabla Temporal Principal
        -- Eliminado IdEmpresa (no se usa) y corregida la estrategia de IdPo
        CREATE TABLE #TMP_DispatchAnalytics (
            IdRow               UNIQUEIDENTIFIER DEFAULT NEWID(),
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
            IdPo                UNIQUEIDENTIFIER, -- Se llena solo si es Orden Local
            IdPoDetalle         UNIQUEIDENTIFIER, -- Se llena siempre
            CarrierName         NVARCHAR(256),
            ShipToName          NVARCHAR(256)
        );

        -- 4. Insercion Masiva
        INSERT INTO #TMP_DispatchAnalytics
        (
            ShipperName, StatusPieza, Awb, Origin,
            PoNumber, TypePieza, Equivalencia, Alto, Largo, Ancho, Boxes,
            TotalPcsHouse, TotalFullHouse, FechaDespacho, IdGuiaHouse,
            IdGuiaHouseDetalle, IdPoDetalle, CarrierName, ShipToName
        )
        SELECT
             EXP.Nombre
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
        INNER JOIN v_ClientsEntities    ST ON GHD.ShipToId = ST.Id
        LEFT JOIN v_ClientsEntities    BTC ON GHO.BillToConsigneeId = BTC.Id
        INNER JOIN Exportadores         EXP WITH(NOLOCK) ON EXP.Id = GHO.IdExportador
        INNER JOIN TiposDePieza         TYP WITH(NOLOCK) ON TYP.Id = GHD.IdTipoDePieza
        INNER JOIN Ciudades             CTY WITH(NOLOCK) ON CTY.Id = GHO.IdCiudadPuertoOrigen
        INNER JOIN Transportes          TRA WITH(NOLOCK) ON PCA.IdCarrier = TRA.Id
        WHERE PCA.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
          AND GHD.EstadoPieza IN ('DISPATCHED WH','RECEIVED DR','RECEIVED WH','PENDING')
          AND ((@BillToIds IS NULL OR BTC.BillToId IN (SELECT Id FROM @TBL_FilterBillTos)))
          AND ((@ConsigneeIds IS NULL OR GHO.ConsigneeId IN (SELECT Id FROM @TBL_FilterConsignees)));

        DELETE TMP
        FROM #TMP_DispatchAnalytics TMP
        INNER JOIN PoDetalles   POD WITH(NOLOCK) ON TMP.IdPoDetalle = POD.Id
        INNER JOIN PoEncabezado POE WITH(NOLOCK) ON POD.IdPo = POE.Id
        INNER JOIN OrdenesLocales OLO WITH(NOLOCK) ON POE.IdOrdenLocal = OLO.Id
        INNER JOIN Catalogos    CAT WITH(NOLOCK) ON OLO.IdCatalogoStatus = CAT.Id
        WHERE CAT.CodigoRelacion = 'CANCELADO';

        -- 6. Marcar Ordenes Locales
        UPDATE TMP
        SET 
            TMP.IdPo = POE.Id, -- AQUI llenamos IdPo solo para las locales
            TMP.Awb = 'LOCAL'
        FROM #TMP_DispatchAnalytics TMP
        INNER JOIN PoDetalles   POD WITH(NOLOCK) ON TMP.IdPoDetalle = POD.Id
        INNER JOIN PoEncabezado POE WITH(NOLOCK) ON POD.IdPo = POE.Id
        INNER JOIN OrdenesLocales OLO WITH(NOLOCK) ON POE.IdOrdenLocal = OLO.Id;

        -- 7. Corregir Origen para POs (CORREGIDO: Usando IdPoDetalle)
        -- Usamos la ruta Legacy: TMP -> PoDetalles -> PoEncabezado -> Empresas -> Ciudades
        UPDATE TMP
        SET TMP.Origin = CTY.Nombre
        FROM #TMP_DispatchAnalytics TMP
        INNER JOIN PoDetalles   POD WITH(NOLOCK) ON TMP.IdPoDetalle = POD.Id
        INNER JOIN PoEncabezado POE WITH(NOLOCK) ON POD.IdPo = POE.Id
        INNER JOIN Empresas     EMP WITH(NOLOCK) ON POE.IdEmpresa = EMP.Id
        INNER JOIN Ciudades     CTY WITH(NOLOCK) ON EMP.IdCiudad = CTY.Id;

        -- 8. Limpieza de datos
        UPDATE #TMP_DispatchAnalytics 
        SET PoNumber = NULL 
        WHERE PoNumber = '';

        -- 9. Resultado Final
        SELECT
            Id              = CONVERT(VARCHAR(64), NEWID()),
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