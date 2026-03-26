DECLARE @IdEmpresa VARCHAR(16) = 'EMP014'
DECLARE @FechaDesde INT = 2
DECLARE @FechaHasta INT = 1
DECLARE @IdParametroDelivery VARCHAR(16)

-- 1. Obtenemos el parámetro (igual que en tu SP)
SELECT @IdParametroDelivery = Id FROM ParametrosLista WITH (NOLOCK) 
WHERE Codigo = 'EsDelivery' AND IdEmpresa = @IdEmpresa;

SELECT 
    GH.NroGuia,
    GHD.Id AS IdDetalle,
    PC.FechaDespacho,
    
    -----------------------------------------------------
    -- LA CAUSA DEL ERROR (DIAGNÓSTICO)
    -----------------------------------------------------
    'CAUSA_DEL_FALLO' = CASE 
        WHEN GHD.ShipToId IS NULL THEN 'ERROR 1: Falta Homologar (ShipToId es NULL)'
        WHEN ET.Id IS NULL        THEN 'ERROR 2: GUID corrupto (No existe en EntityTypes)'
        WHEN E.Id IS NULL         THEN 'ERROR 3: GUID huérfano (No hay Entidad asociada)'
        WHEN ET.Status = 0      THEN 'ERROR 4: Cliente marcado como INACTIVO (INACTIVO=0, ACTIVO= 1)'
        ELSE 'ERROR 6: Filtro oculto (Revisar EntityType o Company)' 
    END,

    -----------------------------------------------------
    -- DATOS PARA ARREGLARLO
    -----------------------------------------------------
    GHD.idClienteFinal  AS [ID_Sistema_Viejo], -- El dato que sí tienes
    GHD.ShipToId        AS [GUID_Actual],      -- El dato que falla
    E.Name              AS [Nombre_Entidad],
    ET.EntityType       AS [Tipo_Entidad]      -- Si no es 2, la vista quizás lo borra

FROM ProgramacionCarrier PC WITH (NOLOCK)
INNER JOIN Transportes T WITH (NOLOCK) ON PC.IdCarrier = T.Id
INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) 
    ON T.IdTransportePrincipal = PCA.IdEntidad 
    AND PCA.IdParametroLista = @IdParametroDelivery 
    AND PCA.Valor = 'NO'
INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
INNER JOIN ParametrosLista PLC WITH (NOLOCK) 
    ON PLC.Codigo = 'TipoManifiestoDespacho' AND PLC.IdEmpresa = GH.IdEmpresa

-- 1. Intentamos unir con la VISTA (El paso que falla)
LEFT JOIN v_ClientsEntities CLF WITH (NOLOCK) ON CLF.Id = GHD.ShipToId

-- 2. Unimos con las TABLAS BASE (Para ver la verdad cruda)
LEFT JOIN EntityTypes ET WITH (NOLOCK) ON ET.Id = GHD.ShipToId
LEFT JOIN Entities E WITH (NOLOCK) ON E.Id = ET.EntityId

WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
  AND PC.FechaDespacho <= DATEADD(MM, -@FechaHasta, GETDATE())
  AND GH.IdEmpresa = @IdEmpresa
  
  -- EL FILTRO CLAVE: Solo muéstrame los que FALLARON en tu Paso 5
  AND CLF.Id IS NULL;