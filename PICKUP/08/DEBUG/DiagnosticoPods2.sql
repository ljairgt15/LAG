DECLARE @FechaDesde DATE = '2026-01-04';
DECLARE @FechaHasta DATE = '2026-01-05';
DECLARE @IdEmpresa VARCHAR(16) = 'EMP014';
DECLARE @IdParametroDelivery VARCHAR(16);

SELECT @IdParametroDelivery = id FROM ParametrosLista WITH (NOLOCK) WHERE codigo = 'EsDelivery' AND idEmpresa = @IdEmpresa;

-- 1. Obtenemos la DATA CRUDA (Sin agrupar todavía)
SELECT 
    GHD.idClienteFinal AS Old_ID,
    GHD.ShipToId AS New_GUID,
    GHD.EstadoPieza,
    GH.NroGuia
INTO #RawData
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
INNER JOIN Transportes subCarrier ON PC.idCarrier = subCarrier.id
INNER JOIN Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
INNER JOIN ParametrosCatalogos PCA ON carrier.id = PCA.idEntidad AND PCA.idParametroLista = @IdParametroDelivery
WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND GH.idEmpresa = @IdEmpresa
  AND PCA.valor = 'NO';

-------------------------------------------------------------------------
-- ANÁLISIS 1: El "Efecto Divorcio" (Clientes que se parten en dos)
-- ¿Hay algún ID antiguo que tenga MÁS DE UN GUID nuevo asociado en estas fechas?
-------------------------------------------------------------------------
SELECT 
    'DIVORCIO DETECTADO' AS Tipo_Error,
    Old_ID AS Cliente_Antiguo,
    COUNT(DISTINCT New_GUID) AS Cantidad_De_GUIDs_Nuevos,
    STRING_AGG(CAST(New_GUID AS VARCHAR(MAX)), ', ') AS Lista_De_GUIDs
FROM #RawData
GROUP BY Old_ID
HAVING COUNT(DISTINCT New_GUID) > 1;

-------------------------------------------------------------------------
-- ANÁLISIS 2: El "Falso Positivo" (Comportamiento ante el HAVING)
-- Comparamos si el grupo PASA o NO PASA el filtro de "Completado" en cada versión
-------------------------------------------------------------------------
;WITH OldLogic AS (
    SELECT 
        Old_ID,
        CASE WHEN COUNT(1) = SUM(IIF(EstadoPieza = 'DISPATCHED WH', 1, 0)) THEN 1 ELSE 0 END AS Pasa_Filtro_Viejo
    FROM #RawData
    GROUP BY Old_ID
),
NewLogic AS (
    SELECT 
        Old_ID, -- Usamos el Old_ID solo para poder cruzar y comparar
        New_GUID,
        CASE WHEN COUNT(1) = SUM(IIF(EstadoPieza = 'DISPATCHED WH', 1, 0)) THEN 1 ELSE 0 END AS Pasa_Filtro_Nuevo
    FROM #RawData
    GROUP BY Old_ID, New_GUID
)
SELECT 
    'CAMBIO DE COMPORTAMIENTO' AS Tipo_Error,
    N.Old_ID AS Cliente_Antiguo,
    N.New_GUID AS GUID_Nuevo,
    CASE WHEN O.Pasa_Filtro_Viejo = 1 THEN 'SI' ELSE 'NO' END AS [Pasaba_En_Viejo?],
    CASE WHEN N.Pasa_Filtro_Nuevo = 1 THEN 'SI' ELSE 'NO' END AS [Pasa_En_Nuevo?]
FROM NewLogic N
LEFT JOIN OldLogic O ON N.Old_ID = O.Old_ID
WHERE N.Pasa_Filtro_Nuevo <> O.Pasa_Filtro_Viejo
   OR (O.Pasa_Filtro_Viejo = 1 AND N.Pasa_Filtro_Nuevo = 1 AND (SELECT COUNT(*) FROM NewLogic N2 WHERE N2.Old_ID = N.Old_ID) > 1) -- Caso donde se dividió pero ambos pasan (aumenta el conteo)

DROP TABLE #RawData;