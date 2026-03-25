/*
================================================================================
SCRIPT DE HOMOLOGACION - GuiasHouseDetalles (Pickup)
Actualiza ShipToId y ConsigneeId desde EntityTypes
usando la misma lógica de filtro de los SPs de PickUp

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
DECLARE @FechaCorte     DATETIME    = DATEADD(MONTH, -3, GETDATE()) -- ajustar a -3 si prefieres
DECLARE @RowsAffected   INT         = 0
DECLARE @TotalShipTo    INT         = 0
DECLARE @TotalConsignee INT         = 0
DECLARE @BatchNumber    INT         = 0

--------------------------------------------------------------------------------
-- PASO 0: Identificar los GHD de pickup que necesitan homologacion
-- Se usa la misma lógica de los SPs: EsDelivery = NO via ProgramacionCarrier
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#TMP_PickupPendingHomologacion') IS NOT NULL
    DROP TABLE #TMP_PickupPendingHomologacion;

SELECT DISTINCT GHD.Id                  AS IdGuiaHouseDetalle
               ,GHD.IdClienteFinal      AS OldShipToId
               ,GHD.IdClienteConsignee  AS OldConsigneeId
               ,GHD.ShipToId            AS CurrentShipToId
               ,GHD.ConsigneeId         AS CurrentConsigneeId
INTO #TMP_PickupPendingHomologacion
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
  AND PC.FechaDespacho >= @FechaCorte        -- solo ultimos 4 meses
  AND (
        GHD.ShipToId   IS NULL
        OR GHD.ConsigneeId IS NULL
      );

PRINT '>> Registros identificados para homologar: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '>> Iniciando homologacion...';
PRINT '';

--------------------------------------------------------------------------------
-- PASO 1: Homologar ShipToId (viene de idClienteFinal)
--------------------------------------------------------------------------------
PRINT '-- PASO 1: Actualizando ShipToId --';

SET @BatchNumber = 0;

WHILE 1 = 1
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY

        UPDATE TOP (@BatchSize) GHD
        SET GHD.ShipToId    = ET.Id
           ,GHD.FechaCambio = GETDATE()
           ,GHD.Nota        = 'homologacion'
        FROM dbo.GuiasHouseDetalles GHD
        INNER JOIN #TMP_PickupPendingHomologacion TMP 
            ON GHD.Id = TMP.IdGuiaHouseDetalle
        INNER JOIN dbo.EntityTypes ET WITH (NOLOCK) 
            ON ET.ReferenceId = GHD.IdClienteFinal
        WHERE GHD.ShipToId      IS NULL
          AND GHD.IdClienteFinal IS NOT NULL
          AND ET.ReferenceId     IS NOT NULL;

        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalShipTo  = @TotalShipTo + @RowsAffected;
        SET @BatchNumber  = @BatchNumber + 1;

        COMMIT TRANSACTION;

        PRINT '  Batch ' + CAST(@BatchNumber AS VARCHAR) 
            + ' | Filas actualizadas: ' + CAST(@RowsAffected AS VARCHAR)
            + ' | Total acumulado: '    + CAST(@TotalShipTo AS VARCHAR);

        IF @RowsAffected = 0 BREAK;

        -- Pausa entre batches para liberar bloqueos
        WAITFOR DELAY @WaitTime;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '!! ERROR en batch ' + CAST(@BatchNumber AS VARCHAR) 
            + ': ' + ERROR_MESSAGE();
        BREAK;
    END CATCH;
END;

PRINT '';
PRINT '>> ShipToId completado. Total filas: ' + CAST(@TotalShipTo AS VARCHAR);
PRINT '';

--------------------------------------------------------------------------------
-- PASO 2: Homologar ConsigneeId (viene de idClienteConsignee)
--------------------------------------------------------------------------------
PRINT '-- PASO 2: Actualizando ConsigneeId --';

SET @BatchNumber    = 0;
SET @RowsAffected   = 0;

WHILE 1 = 1
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY

        UPDATE TOP (@BatchSize) GHD
        SET GHD.ConsigneeId = ET.Id
           ,GHD.FechaCambio = GETDATE()
           ,GHD.Nota        = 'homologacion'
        FROM dbo.GuiasHouseDetalles GHD
        INNER JOIN #TMP_PickupPendingHomologacion TMP 
            ON GHD.Id = TMP.IdGuiaHouseDetalle
        INNER JOIN dbo.EntityTypes ET WITH (NOLOCK) 
            ON ET.ReferenceId = GHD.IdClienteConsignee
        WHERE GHD.ConsigneeId       IS NULL
          AND GHD.IdClienteConsignee IS NOT NULL
          AND ET.ReferenceId         IS NOT NULL;

        SET @RowsAffected   = @@ROWCOUNT;
        SET @TotalConsignee = @TotalConsignee + @RowsAffected;
        SET @BatchNumber    = @BatchNumber + 1;

        COMMIT TRANSACTION;

        PRINT '  Batch ' + CAST(@BatchNumber AS VARCHAR) 
            + ' | Filas actualizadas: ' + CAST(@RowsAffected AS VARCHAR)
            + ' | Total acumulado: '    + CAST(@TotalConsignee AS VARCHAR);

        IF @RowsAffected = 0 BREAK;

        WAITFOR DELAY @WaitTime;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '!! ERROR en batch ' + CAST(@BatchNumber AS VARCHAR) 
            + ': ' + ERROR_MESSAGE();
        BREAK;
    END CATCH;
END;

PRINT '';
PRINT '>> ConsigneeId completado. Total filas: ' + CAST(@TotalConsignee AS VARCHAR);
PRINT '';

--------------------------------------------------------------------------------
-- PASO 3: Verificacion final
--------------------------------------------------------------------------------
PRINT '-- VERIFICACION FINAL --';

SELECT 
     COUNT(*)                                           AS TotalRegistros
    ,SUM(CASE WHEN GHD.ShipToId   IS NULL THEN 1 ELSE 0 END) AS PendientesShipTo
    ,SUM(CASE WHEN GHD.ConsigneeId IS NULL THEN 1 ELSE 0 END) AS PendientesConsigneeId
    ,SUM(CASE WHEN GHD.ShipToId   IS NOT NULL 
              AND GHD.ConsigneeId IS NOT NULL THEN 1 ELSE 0 END) AS Homologados
FROM dbo.GuiasHouseDetalles GHD
INNER JOIN #TMP_PickupPendingHomologacion TMP 
    ON GHD.Id = TMP.IdGuiaHouseDetalle;

DROP TABLE #TMP_PickupPendingHomologacion;

PRINT '>> Homologacion finalizada.';