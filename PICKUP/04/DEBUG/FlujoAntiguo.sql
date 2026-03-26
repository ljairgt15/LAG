DECLARE @IdEmpresa        VARCHAR(16) = 'EMP014'
DECLARE @FechaDesde       INT = 2
DECLARE @FechaHasta       INT = 1
DECLARE @Consulta         INT = 2
DECLARE @IdParametroDelivery VARCHAR(16)

-- Obtenemos el ID del parámetro tal como lo hace el SP
SELECT @IdParametroDelivery = PL.Id 
FROM ParametrosLista PL 
WHERE PL.Codigo = 'EsDelivery' AND PL.IdEmpresa = @IdEmpresa;

PRINT 'IdParametroDelivery encontrado: ' + ISNULL(@IdParametroDelivery, 'NULL (Si es NULL, el query fallará en el paso 2)');

-----------------------------------------------------------------------------------
-- PASO 1: ¿Existen datos en ProgramacionCarrier en ese rango de fechas?
-----------------------------------------------------------------------------------
SELECT 'PASO 1: ProgramacionCarrier (Fecha)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())


-----------------------------------------------------------------------------------
-- PASO 2: ¿El Carrier está configurado correctamente como NO DELIVERY?
-- (Este es un punto de falla común por el INNER JOIN con ParametrosCatalogos)
-----------------------------------------------------------------------------------
SELECT 'PASO 2: Filtro EsDelivery = NO' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
    AND PCA.IdParametroLista = @IdParametroDelivery 
    AND PCA.Valor = 'NO'
WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

-----------------------------------------------------------------------------------
-- PASO 3: Cruce con GuiasHouse y filtro de Empresa
-- Verificamos si las guías ligadas pertenecen a la empresa 'EMP014'
-----------------------------------------------------------------------------------
SELECT 'PASO 3: GuiasHouse + Empresa' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
    AND PCA.IdParametroLista = @IdParametroDelivery AND PCA.Valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.IdEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 4: El parámetro 'TipoManifiestoDespacho'
-- Si este parámetro no existe para la empresa, el INNER JOIN matará todo
-----------------------------------------------------------------------------------
SELECT 'PASO 4: Parametro TipoManifiestoDespacho' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
    AND PCA.IdParametroLista = @IdParametroDelivery AND PCA.Valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
INNER JOIN ParametrosLista PLC ON PLC.Codigo = 'TipoManifiestoDespacho' AND PLC.IdEmpresa = GH.IdEmpresa
WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.IdEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 5: La Refactorización (v_ClientsEntities)
-- AQUI ES DONDE SUELE FALLAR AL CAMBIAR TABLAS POR VISTAS
-- Verificamos ShipTo (Cliente Final)
-----------------------------------------------------------------------------------
SELECT 'PASO 5: v_ClientsEntities (ShipTo)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
    AND PCA.IdParametroLista = @IdParametroDelivery AND PCA.Valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
INNER JOIN ParametrosLista PLC ON PLC.Codigo = 'TipoManifiestoDespacho' AND PLC.IdEmpresa = GH.IdEmpresa
INNER JOIN v_ClientsEntities CLF ON CLF.Id = GHD.ShipToId -- <--- CRITICO
WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.IdEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 6: v_ClientsEntities (Consignee/BillTo)
-- Verificamos la segunda referencia a la vista
-----------------------------------------------------------------------------------
SELECT 'PASO 6: v_ClientsEntities (Consignee)' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
    AND PCA.IdParametroLista = @IdParametroDelivery AND PCA.Valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
INNER JOIN ParametrosLista PLC ON PLC.Codigo = 'TipoManifiestoDespacho' AND PLC.IdEmpresa = GH.IdEmpresa
INNER JOIN v_ClientsEntities CLF ON CLF.Id = GHD.ShipToId
INNER JOIN v_ClientsEntities CGN ON CGN.Id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId) -- <--- CRITICO
WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.IdEmpresa = @IdEmpresa

-----------------------------------------------------------------------------------
-- PASO 7: Filtro Final (EsPOD = 0)
-- Si todo lo anterior pasó, verificamos si tal vez todo ya fue entregado (POD)
-----------------------------------------------------------------------------------
SELECT 'PASO 7: Filtro EsPOD = 0' AS Nivel, COUNT(*) AS Registros
FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T ON PC.IdCarrier = T.Id
INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
    AND PCA.IdParametroLista = @IdParametroDelivery AND PCA.Valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
INNER JOIN ParametrosLista PLC ON PLC.Codigo = 'TipoManifiestoDespacho' AND PLC.IdEmpresa = GH.IdEmpresa
INNER JOIN v_ClientsEntities CLF ON CLF.Id = GHD.ShipToId
INNER JOIN v_ClientsEntities CGN ON CGN.Id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
--AND PC.fechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())

  AND GH.IdEmpresa = @IdEmpresa
  AND GHD.EsPod = 0