DECLARE @FechaDesde DATE = '2026-01-04';
DECLARE @FechaHasta DATE = '2026-01-05';
DECLARE @IdEmpresa VARCHAR(16) = 'EMP014';

-- -------------------------------------------------------------------------------
-- PASO 1: Filtro Base (Igual al anterior)
-- -------------------------------------------------------------------------------
SELECT 'PASO 1: PC FechaDespacho' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
WHERE PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta;

-- -------------------------------------------------------------------------------
-- PASO 2: Carrier No Delivery (Igual al anterior)
-- -------------------------------------------------------------------------------
SELECT 'PASO 2: Carrier No Delivery' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN Transportes TP ON T.IdTransportePrincipal = TP.Id
INNER JOIN ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad
INNER JOIN ParametrosLista PL ON PCAT.IdParametroLista = PL.Id
WHERE PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND PL.Codigo = 'EsDelivery'
  AND PL.IdEmpresa = @IdEmpresa
  AND PCAT.Valor = 'NO';

-- -------------------------------------------------------------------------------
-- PASO 3: Cruce con GuiasHouse y Detalles (Igual al anterior)
-- -------------------------------------------------------------------------------
SELECT 'PASO 3: GuiasHouse + Detalles' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN Transportes TP ON T.IdTransportePrincipal = TP.Id
INNER JOIN ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad
INNER JOIN ParametrosLista PL ON PCAT.IdParametroLista = PL.Id
    AND PL.Codigo = 'EsDelivery' AND PL.IdEmpresa = @IdEmpresa
INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id
INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
WHERE PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND PCAT.Valor = 'NO'
  AND GH.IdEmpresa = @IdEmpresa;

-- -------------------------------------------------------------------------------
-- PASO 4: Filtro DISPATCHED WH (Lógica Completed)
-- -------------------------------------------------------------------------------
SELECT 'PASO 4: Filtro DISPATCHED WH' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN Transportes TP ON T.IdTransportePrincipal = TP.Id
INNER JOIN ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad
INNER JOIN ParametrosLista PL ON PCAT.IdParametroLista = PL.Id
    AND PL.Codigo = 'EsDelivery' AND PL.IdEmpresa = @IdEmpresa
INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id
INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
WHERE PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND PCAT.Valor = 'NO'
  AND GH.IdEmpresa = @IdEmpresa
  AND GHD.EstadoPieza = 'DISPATCHED WH';

-- -------------------------------------------------------------------------------
-- PASO 5: JOIN CON VISTAS (NUEVO)
-- *** PUNTO CRÍTICO ***
-- Aquí es donde comparamos si v_ClientsEntities trae menos datos
-- -------------------------------------------------------------------------------
SELECT 'PASO 5: v_ClientsEntities (ShipTo + Consignee)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN Transportes TP ON T.IdTransportePrincipal = TP.Id
INNER JOIN ParametrosCatalogos PCAT ON TP.Id = PCAT.IdEntidad
INNER JOIN ParametrosLista PL ON PCAT.IdParametroLista = PL.Id
    AND PL.Codigo = 'EsDelivery' AND PL.IdEmpresa = @IdEmpresa
INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id
INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GHD.IdGuiaHouse = GH.Id
-- JOINS DEL SP NUEVO:
INNER JOIN v_ClientsEntities ST WITH (NOLOCK) ON ST.Id = GHD.ShipToId -- ShipTo
INNER JOIN v_ClientsEntities C WITH (NOLOCK) ON C.Id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId) -- Consignee
WHERE PC.FechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND PCAT.Valor = 'NO'
  AND GH.IdEmpresa = @IdEmpresa
  AND GHD.EstadoPieza = 'DISPATCHED WH';