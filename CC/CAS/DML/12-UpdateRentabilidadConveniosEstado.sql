/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Update RentabilidadConvenios inactive 
*/

UPDATE TOP (100) RC
SET 
    RC.activo = 0,
    RC.fechamodificacion = GETDATE()
FROM RentabilidadConvenios RC
WHERE RC.fechahasta < DATEADD(MONTH, -2, GETDATE())
AND RC.activo = 1;