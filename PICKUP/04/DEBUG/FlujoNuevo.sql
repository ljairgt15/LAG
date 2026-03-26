DECLARE @IdEmpresa        VARCHAR(16) = 'EMP014'
DECLARE @FechaDesde       INT = 2
--DECLARE @FechaHasta       INT = 1
DECLARE @Consulta         INT = 2
DECLARE @IdParametroDelivery VARCHAR(16)

-- 0. Obtener Parámetro Delivery (Igual que en el SP)
SELECT @IdParametroDelivery = id 
FROM ParametrosLista WITH (NOLOCK) 
WHERE codigo = 'EsDelivery' AND idEmpresa = @IdEmpresa;

PRINT 'IdParametroDelivery: ' + ISNULL(@IdParametroDelivery, 'NO ENCONTRADO');

-----------------------------------------------------------------------------------
-- PASO 1: Filtro de Fechas en ProgramacionCarrier
-- (Debe coincidir con el debug del nuevo, si no, el problema es de fechas)
-----------------------------------------------------------------------------------
SELECT 'PASO 1: PC FechaDespacho' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
WHERE PC.fechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())


-----------------------------------------------------------------------------------
-- PASO 2: Filtro Carrier No Delivery
-- (Debe coincidir con el debug del nuevo)
-----------------------------------------------------------------------------------
SELECT 'PASO 2: Carrier No Delivery' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id
INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON t.idTransportePrincipal = PCA.idEntidad 
    AND PCA.idParametroLista = @IdParametroDelivery 
    AND PCA.valor = 'NO'
WHERE PC.fechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())


-----------------------------------------------------------------------------------
-- PASO 3: Cruce con Guias y Filtro Empresa
-- (Debe coincidir con el debug del nuevo)
-----------------------------------------------------------------------------------
SELECT 'PASO 3: Guias + Empresa' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.idCarrier = T.id
INNER JOIN ParametrosCatalogos PCA ON t.idTransportePrincipal = PCA.idEntidad AND PCA.idParametroLista = @IdParametroDelivery AND PCA.valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
WHERE PC.fechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.idEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 4: Parametro TipoManifiestoDespacho
-- (Debe coincidir con el debug del nuevo)
-----------------------------------------------------------------------------------
SELECT 'PASO 4: Param TipoManifiesto' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.idCarrier = T.id
INNER JOIN ParametrosCatalogos PCA ON t.idTransportePrincipal = PCA.idEntidad AND PCA.idParametroLista = @IdParametroDelivery AND PCA.valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
INNER JOIN ParametrosLista PLC WITH (NOLOCK) ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
WHERE PC.fechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.idEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 5: JOIN CON TABLA CLIENTES (Cliente Final)
-- *** AQUÍ ESTÁ LA DIFERENCIA CRÍTICA ***
-- El SP nuevo usa v_ClientsEntities con ShipToId.
-- El SP antiguo usa la tabla Clientes con idClienteFinal.
-----------------------------------------------------------------------------------
SELECT 'PASO 5: Tabla CLIENTES (ClienteFinal)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.idCarrier = T.id
INNER JOIN ParametrosCatalogos PCA ON t.idTransportePrincipal = PCA.idEntidad AND PCA.idParametroLista = @IdParametroDelivery AND PCA.valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
INNER JOIN Clientes CLF ON GHD.idClienteFinal = CLF.id -- <--- TABLA DIRECTA
WHERE PC.fechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.idEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 6: JOIN CON TABLA CLIENTES (Consignee)
-- *** OTRA DIFERENCIA ***
-- El SP antiguo hace JOIN directo con GH.idCliente.
-----------------------------------------------------------------------------------
SELECT 'PASO 6: Tabla CLIENTES (Consignee)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.idCarrier = T.id
INNER JOIN ParametrosCatalogos PCA ON t.idTransportePrincipal = PCA.idEntidad AND PCA.idParametroLista = @IdParametroDelivery AND PCA.valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
INNER JOIN Clientes CLF ON GHD.idClienteFinal = CLF.id
INNER JOIN Clientes CLI ON GH.idCliente = CLI.id -- <--- TABLA DIRECTA
WHERE PC.fechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.idEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 7: Filtro Final (EsPOD = 0)
-- Si este número es 1195, confirma que la data existe y el problema es
-- puramente la migración a v_ClientsEntities.
-----------------------------------------------------------------------------------
SELECT 'PASO 7: Filtro EsPOD = 0 (FINAL)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.idCarrier = T.id
INNER JOIN ParametrosCatalogos PCA ON t.idTransportePrincipal = PCA.idEntidad AND PCA.idParametroLista = @IdParametroDelivery AND PCA.valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
INNER JOIN Clientes CLF ON GHD.idClienteFinal = CLF.id
INNER JOIN Clientes CLI ON GH.idCliente = CLI.id
WHERE PC.fechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.idEmpresa = @IdEmpresa
  AND GHD.esPOD = 0;