/*
VERSION     MODIFIEDBY              MODIFIEDDATE    HU          MODIFICATION
1           Marlon Pizarro          2026-02-19      57830       LAG-CT-001​ update catalogs tipotransporte
*/

-- MARÍTIMO
IF EXISTS (
    SELECT 1
    FROM Catalogos
    WHERE Codigo = 'TIPOTRANSPORTE'
      AND Status = 'ACTIVO'
      AND Identificador = 'MARITIMO'
      AND ISNULL(Clase, '') <> 'fa-solid fa-ship'
)
BEGIN
    UPDATE Catalogos
    SET Clase = 'fa-solid fa-ship',
		fechaCambio = GETDATE()
    WHERE Codigo = 'TIPOTRANSPORTE'
      AND [Status] = 'ACTIVO'
      AND Identificador = 'MARITIMO';
END;

-- AÉREO
IF EXISTS (
    SELECT 1
    FROM Catalogos
    WHERE Codigo = 'TIPOTRANSPORTE'
      AND [Status] = 'ACTIVO'
      AND Identificador = 'AEREO'
      AND ISNULL(Clase, '') <> 'fa-solid fa-plane'
)
BEGIN
    UPDATE Catalogos
    SET Clase = 'fa-solid fa-plane',
		fechaCambio = GETDATE()
    WHERE Codigo = 'TIPOTRANSPORTE'
      AND Status = 'ACTIVO'
      AND Identificador = 'AEREO';
END;

-- TERRESTRE
IF EXISTS (
    SELECT 1
    FROM Catalogos
    WHERE Codigo = 'TIPOTRANSPORTE'
      AND Status = 'ACTIVO'
      AND Identificador = 'TERRESTRE'
      AND ISNULL(Clase, '') <> 'fa-solid fa-truck'
)
BEGIN
    UPDATE Catalogos
    SET Clase = 'fa-solid fa-truck',
		fechaCambio = GETDATE()
    WHERE Codigo = 'TIPOTRANSPORTE'
      AND [Status] = 'ACTIVO'
      AND Identificador = 'TERRESTRE';
END;