DECLARE @IdDocMiami VARCHAR(32);

SELECT @IdDocMiami = Id 
FROM Documentos 
WHERE Codigo = 'DESPACHOMIAMI' -- O el código real que usen en C#
  AND TipoGeneracion = 'GUIA'; -- Ajusta según tu Enum en C#

PRINT 'El ID del documento es: ' + ISNULL(@IdDocMiami, 'NO ENCONTRADO');

-- Query B: Ver CUÁNTOS registros estarias trayendo a memoria HOY
SELECT COUNT(*) AS TotalRegistrosInnecesarios
FROM DocumentosDespacho WITH (NOLOCK)
WHERE IdDocumento = @IdDocMiami;

-- Query C: Ver una muestra de los datos (para confirmar que son históricos)
SELECT TOP 100 *
FROM DocumentosDespacho WITH (NOLOCK)
WHERE IdDocumento = @IdDocMiami
ORDER BY FechaDespacho DESC; -- Para ver los más recientes