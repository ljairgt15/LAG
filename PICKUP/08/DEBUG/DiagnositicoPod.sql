DECLARE @FechaDesde DATE = '2026-01-04';
DECLARE @FechaHasta DATE = '2026-01-05';
DECLARE @IdEmpresa VARCHAR(16) = 'EMP014';

-- Obtener ID Parametro
DECLARE @IdParametroDelivery VARCHAR(16);
SELECT @IdParametroDelivery = id FROM ParametrosLista WITH (NOLOCK) WHERE codigo = 'EsDelivery' AND idEmpresa = @IdEmpresa;

-----------------------------------------------------------------------------------
-- PASO 6: "Pre-Agrupación" (Filas Totales antes de resumir)
-- Objetivo: Ver si los LEFT JOINS (Pallets, Manifiestos, Ubicaciones) están duplicando data
-----------------------------------------------------------------------------------

-- 6A. SP ANTIGUO (Cuento filas totales detalladas)
SELECT 'PASO 6A: Filas Totales (ANTIGUO) con Left Joins' AS Nivel, COUNT(*) AS Cantidad_Lineas
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
INNER JOIN Transportes subCarrier ON PC.idCarrier = subCarrier.id
INNER JOIN Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad AND parametroCatalogo.idParametroLista = @IdParametroDelivery
-- JOINS ANTIGUOS
LEFT JOIN ProgramacionManifiesto programacionManifiesto ON programacionManifiesto.idProgramacionCarrier = PC.id
LEFT JOIN DocumentosDespacho documentosDespacho ON programacionManifiesto.idManifiestoDespacho = documentosDespacho.idManifiesto AND documentosDespacho.idDocumento = 'DOC052395'
LEFT JOIN ManifiestosDespacho manifiestoDespacho ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho
LEFT JOIN PalletsDetalles pld ON GHD.id = pld.idGuiasHouseDetalle
LEFT JOIN Pallets pal ON pld.idPallet = pal.id
WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND GH.idEmpresa = @IdEmpresa
  AND parametroCatalogo.valor = 'NO';

-- 6B. SP NUEVO (Cuento filas totales detalladas)
SELECT 'PASO 6B: Filas Totales (NUEVO) con Left Joins' AS Nivel, COUNT(*) AS Cantidad_Lineas
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
INNER JOIN Transportes T ON PC.IdCarrier = T.Id 
INNER JOIN Transportes TP ON T.IdTransportePrincipal = TP.Id
INNER JOIN ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad AND PCAT.IdParametroLista = @IdParametroDelivery
-- JOINS NUEVOS
LEFT JOIN ProgramacionManifiesto PM WITH(NOLOCK) ON PM.IdProgramacionCarrier = PC.Id
LEFT JOIN DocumentosDespacho DD ON PM.IdManifiestoDespacho = DD.IdManifiesto AND DD.IdDocumento = 'DOC052395'
LEFT JOIN ManifiestosDespacho MD ON MD.Id = PM.IdManifiestoDespacho
LEFT JOIN PalletsDetalles PD WITH(NOLOCK) ON GHD.Id = PD.IdGuiasHouseDetalle
LEFT JOIN Pallets PAL WITH(NOLOCK) ON PD.IdPallet = PAL.Id
WHERE PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
  AND GH.IdEmpresa = @IdEmpresa
  AND PCAT.Valor = 'NO';

-----------------------------------------------------------------------------------
-- PASO 7: "Post-Agrupación" (El filtro HAVING)
-- Objetivo: Ver cuántos grupos pasan la regla "Total = Despachados"
-----------------------------------------------------------------------------------

-- 7A. SP ANTIGUO - Grupos Completados
SELECT 'PASO 7A: Grupos COMPLETADOS (ANTIGUO)' AS Nivel, COUNT(*) AS Cantidad_Grupos
FROM (
    SELECT 
        GHD.idClienteFinal, -- Agrupación clave del viejo
        SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0)) AS Despachados,
        COUNT(1) AS Total
    FROM ProgramacionCarrier PC WITH (NOLOCK)
    INNER JOIN GuiasHouseDetalles GHD ON PC.idGuiaHouseDetalle = GHD.id
    INNER JOIN GuiasHouse GH ON GHD.idGuiaHouse = GH.id
    INNER JOIN Transportes subCarrier ON PC.idCarrier = subCarrier.id
    INNER JOIN Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
    INNER JOIN ParametrosCatalogos PCA ON carrier.id = PCA.idEntidad AND PCA.idParametroLista = @IdParametroDelivery
    -- NOTA: Incluyo los Left Joins porque afectan el conteo del GROUP BY si duplican filas
    LEFT JOIN PalletsDetalles pld ON GHD.id = pld.idGuiasHouseDetalle
    WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
      AND GH.idEmpresa = @IdEmpresa
      AND PCA.valor = 'NO'
    GROUP BY 
        GHD.idClienteFinal, -- Agrupación simplificada para el test
        GH.idGuia,
        PC.fechaDespacho
    HAVING COUNT(1) = SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0))
) AS GruposViejos;

-- 7B. SP NUEVO - Grupos Completados
SELECT 'PASO 7B: Grupos COMPLETADOS (NUEVO)' AS Nivel, COUNT(*) AS Cantidad_Grupos
FROM (
    SELECT 
        GHD.ShipToId, -- Agrupación clave del nuevo
        SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END) AS Despachados,
        COUNT(1) AS Total
    FROM ProgramacionCarrier PC WITH (NOLOCK)
    INNER JOIN GuiasHouseDetalles GHD ON PC.idGuiaHouseDetalle = GHD.id
    INNER JOIN GuiasHouse GH ON GHD.idGuiaHouse = GH.id
    INNER JOIN Transportes T ON PC.IdCarrier = T.Id 
    INNER JOIN Transportes TP ON T.IdTransportePrincipal = TP.Id
    INNER JOIN ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad AND PCAT.IdParametroLista = @IdParametroDelivery
    -- Joins que pueden duplicar
    LEFT JOIN PalletsDetalles PD ON GHD.Id = PD.IdGuiasHouseDetalle
    WHERE PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
      AND GH.IdEmpresa = @IdEmpresa
      AND PCAT.Valor = 'NO'
    GROUP BY 
        GHD.ShipToId, -- Agrupación simplificada
        GH.IdGuia,
        PC.FechaDespacho
    HAVING COUNT(1) = SUM(CASE WHEN GHD.EstadoPieza = 'DISPATCHED WH' THEN 1 ELSE 0 END)
) AS GruposNuevos;