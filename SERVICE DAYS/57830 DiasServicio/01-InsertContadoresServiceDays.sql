/*
VERSION     MODIFIEDBY              MODIFIEDDATE    HU          MODIFICATION
1           Marlon Pizarro          2026-02-19      57830       Initial Code - New secuencial for table ServiceDays
*/
IF NOT EXISTS (
	SELECT 1 
	FROM Contadores 
	WHERE tabla = 'ServiceDays'
)
BEGIN
    DECLARE @newId INT;

	SELECT @newId = MAX(c.id) + 1
	FROM dbo.Contadores c

    INSERT INTO Contadores (id, tabla, contador, idEmpresa, prefijo, posfijo, maximoContador, cantidadCerosIzquierda, CreatedBy, CreatedDate)
    VALUES (@newId, 'ServiceDays', 0, NULL, 'SD', NULL, 99999999, 6, '613pMX0S', GETDATE());
END;

IF NOT EXISTS (
	SELECT 1 
	FROM Contadores 
	WHERE tabla = 'ServiceDaysDetails'
)
BEGIN
    DECLARE @idNewDetails INT;

	SELECT @idNewDetails = MAX(c.id) + 1
	FROM dbo.Contadores c

    INSERT INTO Contadores (id, tabla, contador, idEmpresa, prefijo, posfijo, maximoContador, cantidadCerosIzquierda, CreatedBy, CreatedDate)
    VALUES (@idNewDetails, 'ServiceDaysDetails', 0, NULL, 'SDD', NULL, 99999999, 6, '613pMX0S', GETDATE());
END;

IF NOT EXISTS (
	SELECT 1 
	FROM Contadores 
	WHERE tabla = 'ServiceDaysHistory'
)
BEGIN
    DECLARE @idNewHist INT;

	SELECT @idNewHist = MAX(c.id) + 1
	FROM dbo.Contadores c

    INSERT INTO Contadores (id, tabla, contador, idEmpresa, prefijo, posfijo, maximoContador, cantidadCerosIzquierda, CreatedBy, CreatedDate)
    VALUES (@idNewHist, 'ServiceDaysHistory', 0, NULL, 'SDH', NULL, 99999999, 6, '613pMX0S', GETDATE());
END;