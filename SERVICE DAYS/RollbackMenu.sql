/*
VERSION     MODIFIEDBY              MODIFIEDDATE    HU          MODIFICATION
1           Marlon Pizarro          2026-02-20      57830       Rollback Day service catalog menu
*/

BEGIN TRY
    BEGIN TRAN;

    DECLARE @IdMenuPadre VARCHAR(32);

    -- Obtener ID del menú padre
    SELECT @IdMenuPadre = M.id
    FROM dbo.Menu M WITH(NOLOCK)
    WHERE M.nombre = 'Días de Servicio'
      AND M.esMenu = 1;

    -- Eliminar hijos primero
    DELETE FROM dbo.Menu
    WHERE idPadre = @IdMenuPadre
      AND url IN (
            '/catalog/days-of-service/list',
            '/catalog/days-of-service/insert',
            '/catalog/days-of-service/edit',
            '/catalog/days-of-service/delete'
      );

    -- Eliminar menú principal
    DELETE FROM dbo.Menu
    WHERE id = @IdMenuPadre
      AND nombre = 'Días de Servicio'
      AND esMenu = 1;

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    THROW;
END CATCH;
