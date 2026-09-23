/*
VERSION     MODIFIEDBY      MODIFIEDDATE    HU      MODIFICATION
1           Jair Gomez     2026-09-23       64492   Deactivates agreements that have been past their expiration date by more than 6 months
*/

CREATE PROCEDURE [dbo].[AC_Pro_DesactiveExpiredAgreements]
AS
BEGIN
    BEGIN TRY
        WHILE (1 = 1)
        BEGIN
            UPDATE TOP (100) RC
            SET 
                RC.activo = 0,
                RC.fechamodificacion = GETDATE()
            FROM RentabilidadConvenios RC
            WHERE RC.activo = 1 
              AND RC.fechahasta IS NOT NULL 
              AND RC.fechahasta < DATEADD(MONTH, - 6, GETDATE());
            
            IF @@ROWCOUNT = 0 
                BREAK;
            
            -- Pausa de 2 segundos para liberar bloqueos y procesar otras transacciones
            WAITFOR DELAY '00:00:02'; 
        END
    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH
END
GO

/*
EXEC [dbo].[Ac_Pro_DesactiveExpiredAgreements];
*/