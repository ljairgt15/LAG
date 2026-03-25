DECLARE @FechaDesde DATE = '2026-01-04';
DECLARE @FechaHasta DATE = '2026-01-05';
DECLARE @IdEmpresa VARCHAR(16) = 'EMP014';

-- -------------------------------------------------------------------------------
-- PASO 1: Filtro Base (Fechas y ProgramacionCarrier)
-- -------------------------------------------------------------------------------
SELECT 'PASO 1: PC FechaDespacho' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta;

-- -------------------------------------------------------------------------------
-- PASO 2: Filtro "EsDelivery = NO"
-- (Unión con Transportes y Parametros)
-- -------------------------------------------------------------------------------
SELECT 'PASO 2: Carrier No Delivery' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes subCarrier ON PC.idCarrier = subCarrier.id
INNER JOIN Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad
INNER JOIN ParametrosLista parametroLista ON parametroCatalogo.idParametroLista = parametroLista.id
WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND parametroLista.codigo = 'EsDelivery'
  AND parametroLista.idEmpresa = @IdEmpresa
  AND parametroCatalogo.valor = 'NO';

-- -------------------------------------------------------------------------------
-- PASO 3: Cruce con GuiasHouse y Detalles
-- -------------------------------------------------------------------------------
SELECT 'PASO 3: GuiasHouse + Detalles' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes subCarrier ON PC.idCarrier = subCarrier.id
INNER JOIN Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad
INNER JOIN ParametrosLista parametroLista ON parametroCatalogo.idParametroLista = parametroLista.id
    AND parametroLista.codigo = 'EsDelivery' AND parametroLista.idEmpresa = @IdEmpresa
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND parametroCatalogo.valor = 'NO'
  AND GH.idEmpresa = @IdEmpresa;

-- -------------------------------------------------------------------------------
-- PASO 4: La lógica "COMPLETED" (HAVING)
-- El SP filtra grupos donde TODO está despachado.
-- Aquí simulamos el filtro contando solo las líneas con estado 'DISPATCHED WH'
-- -------------------------------------------------------------------------------
SELECT 'PASO 4: Filtro DISPATCHED WH' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes subCarrier ON PC.idCarrier = subCarrier.id
INNER JOIN Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad
INNER JOIN ParametrosLista parametroLista ON parametroCatalogo.idParametroLista = parametroLista.id
    AND parametroLista.codigo = 'EsDelivery' AND parametroLista.idEmpresa = @IdEmpresa
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND parametroCatalogo.valor = 'NO'
  AND GH.idEmpresa = @IdEmpresa
  AND GHD.estadoPieza = 'DISPATCHED WH'; -- Simulacion del HAVING

-- -------------------------------------------------------------------------------
-- PASO 5: JOIN CON TABLA CLIENTES (Antiguo)
-- Aquí es donde el antiguo suele ganar registros si la migración falla
-- -------------------------------------------------------------------------------
SELECT 'PASO 5: Tabla CLIENTES (Final+Consignee)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes subCarrier ON PC.idCarrier = subCarrier.id
INNER JOIN Transportes carrier ON subCarrier.idTransportePrincipal = carrier.id
INNER JOIN ParametrosCatalogos parametroCatalogo ON carrier.id = parametroCatalogo.idEntidad
INNER JOIN ParametrosLista parametroLista ON parametroCatalogo.idParametroLista = parametroLista.id
    AND parametroLista.codigo = 'EsDelivery' AND parametroLista.idEmpresa = @IdEmpresa
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
-- JOINS DEL SP ANTIGUO:
INNER JOIN Clientes CLF ON GHD.idClienteFinal = CLF.id
INNER JOIN Clientes CLC ON GH.idCliente = CLC.id
INNER JOIN Exportadores EXP ON GH.IdExportador = EXP.Id
WHERE PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta
  AND parametroCatalogo.valor = 'NO'
  AND GH.idEmpresa = @IdEmpresa
  AND GHD.estadoPieza = 'DISPATCHED WH';