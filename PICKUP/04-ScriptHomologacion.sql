/*
================================================================================
SCRIPT DE HOMOLOGACION - GuiasHouseDetalles + GuiasHouse (Pickup)
Actualiza ShipToId y ConsigneeId en GuiasHouseDetalles
y ConsigneeId / BillToConsigneeId en GuiasHouse
desde EntityTypes usando la misma lógica de filtro de los SPs de PickUp

INSTRUCCIONES:
- Ejecutar en horario de bajo tráfico
- Monitorear bloqueos con: SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id <> 0
- Ajustar @BatchSize según comportamiento del servidor (recomendado: 500-1000)
- Ejecutar primero en ambiente de pruebas
================================================================================
*/

SET NOCOUNT ON;

DECLARE @IdEmpresa      VARCHAR(16) = 'EMP014'
DECLARE @BatchSize      INT         = 500
DECLARE @WaitTime       VARCHAR(10) = '00:00:02'
DECLARE @FechaCorte     DATETIME    = DATEADD(MONTH, -4, GETDATE())
DECLARE @RowsAffected   INT         = 0
DECLARE @TotalShipTo    INT         = 0
DECLARE @TotalConsignee INT         = 0
DECLARE @TotalGHConsignee     INT   = 0
DECLARE @BatchNumber    INT         = 0

--------------------------------------------------------------------------------
-- PASO 0A: Identificar GHD de pickup que necesitan homologacion
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#TMP_GHD_Homologacion') IS NOT NULL
    DROP TABLE #TMP_GHD_Homologacion;

SELECT DISTINCT 
     GHD.Id                 AS IdGuiaHouseDetalle
    ,GHD.IdClienteFinal     AS OldShipToId
    ,GHD.IdClienteConsignee AS OldConsigneeId
    ,GHD.ShipToId           AS CurrentShipToId
    ,GHD.ConsigneeId        AS CurrentConsigneeId
INTO #TMP_GHD_Homologacion
FROM dbo.GuiasHouseDetalles GHD WITH (NOLOCK)
INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) 
    ON GHD.IdGuiaHouse = GH.Id
INNER JOIN dbo.ProgramacionCarrier PC WITH (NOLOCK) 
    ON PC.IdGuiaHouseDetalle = GHD.Id
INNER JOIN dbo.Transportes T WITH (NOLOCK) 
    ON PC.IdCarrier = T.Id
INNER JOIN dbo.Transportes TP WITH (NOLOCK) 
    ON T.IdTransportePrincipal = TP.Id
INNER JOIN dbo.ParametrosCatalogos PCAT WITH (NOLOCK) 
    ON TP.Id = PCAT.IdEntidad
INNER JOIN dbo.ParametrosLista PL WITH (NOLOCK) 
    ON PCAT.IdParametroLista = PL.Id
    AND PL.Codigo = 'EsDelivery'
    AND PL.IdEmpresa = @IdEmpresa
WHERE PCAT.Valor = 'NO'
  AND GH.IdEmpresa = @IdEmpresa
  AND PC.FechaDespacho >= @FechaCorte
  AND (
        GHD.ShipToId IS NULL
        OR EXISTS (
            SELECT 1 FROM dbo.EntityTypes ET 
            WHERE ET.ReferenceId = GHD.IdClienteFinal 
              AND ET.Id <> GHD.ShipToId
        )
        OR GHD.ConsigneeId IS NULL
        OR EXISTS (
            SELECT 1 FROM dbo.EntityTypes ET 
            WHERE ET.ReferenceId = GHD.IdClienteConsignee 
              AND ET.Id <> GHD.ConsigneeId
        )
      );

PRINT '>> GHD registros identificados: ' + CAST(@@ROWCOUNT AS VARCHAR);

--------------------------------------------------------------------------------
-- PASO 0B: Identificar GuiasHouse que necesitan homologacion
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#TMP_GH_Homologacion') IS NOT NULL
    DROP TABLE #TMP_GH_Homologacion;

SELECT DISTINCT 
     GH.Id                  AS IdGuiaHouse
    ,GH.IdCliente           AS OldConsigneeId
    ,GH.ConsigneeId         AS CurrentConsigneeId
    ,GH.BillToConsigneeId   AS CurrentBillToConsigneeId
INTO #TMP_GH_Homologacion
FROM dbo.GuiasHouse GH WITH (NOLOCK)
INNER JOIN dbo.GuiasHouseDetalles GHD WITH (NOLOCK) 
    ON GHD.IdGuiaHouse = GH.Id
INNER JOIN dbo.ProgramacionCarrier PC WITH (NOLOCK) 
    ON PC.IdGuiaHouseDetalle = GHD.Id
INNER JOIN dbo.Transportes T WITH (NOLOCK) 
    ON PC.IdCarrier = T.Id
INNER JOIN dbo.Transportes TP WITH (NOLOCK) 
    ON T.IdTransportePrincipal = TP.Id
INNER JOIN dbo.ParametrosCatalogos PCAT WITH (NOLOCK) 
    ON TP.Id = PCAT.IdEntidad
INNER JOIN dbo.ParametrosLista PL WITH (NOLOCK) 
    ON PCAT.IdParametroLista = PL.Id
    AND PL.Codigo = 'EsDelivery'
    AND PL.IdEmpresa = @IdEmpresa
WHERE PCAT.Valor = 'NO'
  AND GH.IdEmpresa = @IdEmpresa
  AND PC.FechaDespacho >= @FechaCorte
  AND (
        GH.ConsigneeId IS NULL
        OR EXISTS (
            SELECT 1 FROM dbo.EntityTypes ET 
            WHERE ET.ReferenceId = GH.IdCliente 
              AND ET.Id <> GH.ConsigneeId
        )
      );

PRINT '>> GH registros identificados: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '>> Fecha corte: ' + CAST(@FechaCorte AS VARCHAR);
PRINT '>> Iniciando homologacion...';
PRINT '';

--------------------------------------------------------------------------------
-- PASO 1: Homologar GHD.ShipToId (viene de GHD.idClienteFinal)
--------------------------------------------------------------------------------
PRINT '-- PASO 1: Actualizando GHD.ShipToId --';

SET @BatchNumber  = 0;
SET @RowsAffected = 0;

WHILE 1 = 1
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY

        UPDATE TOP (@BatchSize) GHD
        SET GHD.ShipToId    = ET.Id
           ,GHD.FechaCambio = GETDATE()
           ,GHD.Nota        = 'homologacion'
        FROM dbo.GuiasHouseDetalles GHD
        INNER JOIN #TMP_GHD_Homologacion TMP 
            ON GHD.Id = TMP.IdGuiaHouseDetalle
        INNER JOIN dbo.EntityTypes ET WITH (NOLOCK) 
            ON ET.ReferenceId = GHD.IdClienteFinal
        WHERE GHD.IdClienteFinal IS NOT NULL
          AND ET.ReferenceId     IS NOT NULL
          AND (
                GHD.ShipToId IS NULL
                OR GHD.ShipToId <> ET.Id
              );

        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalShipTo  = @TotalShipTo + @RowsAffected;
        SET @BatchNumber  = @BatchNumber + 1;

        COMMIT TRANSACTION;

        PRINT '  Batch ' + CAST(@BatchNumber AS VARCHAR)
            + ' | Filas: ' + CAST(@RowsAffected AS VARCHAR)
            + ' | Acumulado: ' + CAST(@TotalShipTo AS VARCHAR);

        IF @RowsAffected = 0 BREAK;
        WAITFOR DELAY @WaitTime;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '!! ERROR batch ' + CAST(@BatchNumber AS VARCHAR) + ': ' + ERROR_MESSAGE();
        BREAK;
    END CATCH;
END;

PRINT '';
PRINT '>> GHD.ShipToId completado. Total: ' + CAST(@TotalShipTo AS VARCHAR);
PRINT '';

--------------------------------------------------------------------------------
-- PASO 2: Homologar GHD.ConsigneeId (viene de GHD.idClienteConsignee)
--------------------------------------------------------------------------------
PRINT '-- PASO 2: Actualizando GHD.ConsigneeId --';

SET @BatchNumber  = 0;
SET @RowsAffected = 0;

WHILE 1 = 1
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY

        UPDATE TOP (@BatchSize) GHD
        SET GHD.ConsigneeId = ET.Id
           ,GHD.FechaCambio = GETDATE()
           ,GHD.Nota        = 'homologacion'
        FROM dbo.GuiasHouseDetalles GHD
        INNER JOIN #TMP_GHD_Homologacion TMP 
            ON GHD.Id = TMP.IdGuiaHouseDetalle
        INNER JOIN dbo.EntityTypes ET WITH (NOLOCK) 
            ON ET.ReferenceId = GHD.IdClienteConsignee
        WHERE GHD.IdClienteConsignee IS NOT NULL
          AND ET.ReferenceId         IS NOT NULL
          AND (
                GHD.ConsigneeId IS NULL
                OR GHD.ConsigneeId <> ET.Id
              );

        SET @RowsAffected   = @@ROWCOUNT;
        SET @TotalConsignee = @TotalConsignee + @RowsAffected;
        SET @BatchNumber    = @BatchNumber + 1;

        COMMIT TRANSACTION;

        PRINT '  Batch ' + CAST(@BatchNumber AS VARCHAR)
            + ' | Filas: ' + CAST(@RowsAffected AS VARCHAR)
            + ' | Acumulado: ' + CAST(@TotalConsignee AS VARCHAR);

        IF @RowsAffected = 0 BREAK;
        WAITFOR DELAY @WaitTime;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '!! ERROR batch ' + CAST(@BatchNumber AS VARCHAR) + ': ' + ERROR_MESSAGE();
        BREAK;
    END CATCH;
END;

PRINT '';
PRINT '>> GHD.ConsigneeId completado. Total: ' + CAST(@TotalConsignee AS VARCHAR);
PRINT '';

--------------------------------------------------------------------------------
-- PASO 3: Homologar GH.ConsigneeId (viene de GH.idCliente)
--------------------------------------------------------------------------------
PRINT '-- PASO 3: Actualizando GH.ConsigneeId --';

SET @BatchNumber  = 0;
SET @RowsAffected = 0;

WHILE 1 = 1
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY

        UPDATE TOP (@BatchSize) GH
        SET GH.ConsigneeId  = ET.Id
           ,GH.FechaCambio  = GETDATE()
           ,GH.Nota         = 'homologacion'
        FROM dbo.GuiasHouse GH
        INNER JOIN #TMP_GH_Homologacion TMP 
            ON GH.Id = TMP.IdGuiaHouse
        INNER JOIN dbo.EntityTypes ET WITH (NOLOCK) 
            ON ET.ReferenceId = GH.IdCliente
        WHERE GH.IdCliente   IS NOT NULL
          AND ET.ReferenceId IS NOT NULL
          AND (
                GH.ConsigneeId IS NULL
                OR GH.ConsigneeId <> ET.Id
              );

        SET @RowsAffected     = @@ROWCOUNT;
        SET @TotalGHConsignee = @TotalGHConsignee + @RowsAffected;
        SET @BatchNumber      = @BatchNumber + 1;

        COMMIT TRANSACTION;

        PRINT '  Batch ' + CAST(@BatchNumber AS VARCHAR)
            + ' | Filas: ' + CAST(@RowsAffected AS VARCHAR)
            + ' | Acumulado: ' + CAST(@TotalGHConsignee AS VARCHAR);

        IF @RowsAffected = 0 BREAK;
        WAITFOR DELAY @WaitTime;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '!! ERROR batch ' + CAST(@BatchNumber AS VARCHAR) + ': ' + ERROR_MESSAGE();
        BREAK;
    END CATCH;
END;

PRINT '';
PRINT '>> GH.ConsigneeId completado. Total: ' + CAST(@TotalGHConsignee AS VARCHAR);
PRINT '';

--------------------------------------------------------------------------------
-- PASO 4: Verificacion final
--------------------------------------------------------------------------------
PRINT '-- VERIFICACION FINAL --';

PRINT '  GHD:';
SELECT 
     COUNT(*)                                                               AS TotalGHD
    ,SUM(CASE WHEN GHD.ShipToId    IS NULL THEN 1 ELSE 0 END)              AS PendientesShipTo
    ,SUM(CASE WHEN GHD.ConsigneeId IS NULL THEN 1 ELSE 0 END)              AS PendientesConsigneeId
    ,SUM(CASE WHEN GHD.ShipToId    IS NOT NULL 
              AND GHD.ConsigneeId  IS NOT NULL THEN 1 ELSE 0 END)          AS Homologados
    ,SUM(CASE WHEN GHD.Nota = 'homologacion'   THEN 1 ELSE 0 END)          AS ActualizadosEnEstaEjecucion
FROM dbo.GuiasHouseDetalles GHD
INNER JOIN #TMP_GHD_Homologacion TMP ON GHD.Id = TMP.IdGuiaHouseDetalle;

PRINT '  GH:';
SELECT 
     COUNT(*)                                                               AS TotalGH
    ,SUM(CASE WHEN GH.ConsigneeId  IS NULL THEN 1 ELSE 0 END)              AS PendientesConsigneeId
    ,SUM(CASE WHEN GH.ConsigneeId  IS NOT NULL THEN 1 ELSE 0 END)          AS Homologados
    ,SUM(CASE WHEN GH.Nota = 'homologacion'    THEN 1 ELSE 0 END)          AS ActualizadosEnEstaEjecucion
FROM dbo.GuiasHouse GH
INNER JOIN #TMP_GH_Homologacion TMP ON GH.Id = TMP.IdGuiaHouse;

DROP TABLE #TMP_GHD_Homologacion;
DROP TABLE #TMP_GH_Homologacion;

PRINT '';
PRINT '>> Homologacion finalizada.';
PRINT '>> GHD.ShipToId    actualizados : ' + CAST(@TotalShipTo      AS VARCHAR);
PRINT '>> GHD.ConsigneeId actualizados : ' + CAST(@TotalConsignee   AS VARCHAR);
PRINT '>> GH.ConsigneeId  actualizados : ' + CAST(@TotalGHConsignee AS VARCHAR);
PRINT '>> Total general                : ' + CAST(@TotalShipTo + @TotalConsignee + @TotalGHConsignee AS VARCHAR);