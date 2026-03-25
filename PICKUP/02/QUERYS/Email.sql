DECLARE @CodigoCatalogo_ModulosMenuScanner VARCHAR(50) = 'ModulosMenuScanner';
DECLARE @CodigosCatalogosVinculacion_MENUSCANNERESTADOS VARCHAR(50) = 'MENUSCANNER-ESTADOS';
DECLARE @CodigoCatalogo_EstadosPiezasWareHose VARCHAR(50) = 'EstadosPiezasWareHose';
DECLARE @idModulo VARCHAR(20) = 'MNU01440';

SELECT
ORT.*,
    ORT.Id,
    ORT.Nombre,
    ORT.Asunto,
    ORT.Descripcion AS Cuerpo,
    CEP.CodigoRelacion AS CatalogoCodigoRelacion,
    C1.IdEmpresa
FROM OpcionesRetraso ORT
LEFT JOIN Catalogos C1
    ON ORT.Id = C1.IdRegistroVinculado
   AND C1.Codigo = @CodigoCatalogo_ModulosMenuScanner
LEFT JOIN CatalogosVinculacion CV
    ON C1.Id = CV.IdCatalogo
   AND CV.Codigo = @CodigosCatalogosVinculacion_MENUSCANNERESTADOS
LEFT JOIN Catalogos CEP
    ON CV.IdCatalogoRelacionado = CEP.Id
   AND CEP.Codigo = @CodigoCatalogo_EstadosPiezasWareHose
WHERE ORT.Nombre like '%T&E%'
