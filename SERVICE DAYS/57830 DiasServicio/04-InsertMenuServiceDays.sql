/*
VERSION     MODIFIEDBY              MODIFIEDDATE    HU          MODIFICATION
1           Marlon Pizarro          2026-02-19      57830       LAG-CT-001​ Day service catalog menu
*/
DECLARE @IdRegistro VARCHAR(32);
IF NOT EXISTS (
    SELECT TOP 1 1
    FROM [Menu]
    WHERE [nombre] = 'Días de Servicio'
    AND [esMenu] = 1
)
BEGIN

    EXEC dbo.PRO_General_GenerarIdUnico @tabla = 'Menu', @IdUnico = @IdRegistro OUTPUT;

    INSERT INTO [Menu] 
    ([id], [idPadre], [idUsuarioLog], [nombre], [url], [accion], [orden], [esMenu], [nota], [fechaCambio], [status], [versionFila], [esNewTab], [instruccion], [nombreIngles], [config])
    VALUES 
    (@IdRegistro, 'MNU011', '613pMX0S', 'Días de Servicio', '/catalog/days-of-service', 'MENU', 0, 1, NULL, GETDATE(), 'ACTIVO', NULL, 0, 'MENU', 'Days of Service', '[     {    "url": "http://localhost:3000/",    "env": "local",    "vr": 2     },     {       "url": "https://sandwebcatalog.logiztikalliance.com/",    "env": "sandbox",    "vr": 2     },     {    "url": "https://dev.net/",    "env": "dev",    "vr": 2     },     {    "url": "https://catalog.logiztikalliance.com/",    "env": "production",    "vr": 2     },     {    "url": "https://sandwebcatalog1.logiztikalliance.com/",    "env": "sandboxaks",    "vr": 2     },   {"url":"https://blackbox.logiztikalliance.com/","env":"blackbox","vr":2},  {    "url": "https://blackboxcatalog.logiztikalliance.com/",    "env": "blackbox",    "vr": 2     },  {"url":"https://ac.logiztikalliance.com/","env":"production","vr":2}   ]');
END;


-- Agregar opción de listar `
DECLARE @IdRegistroListar VARCHAR(32);

IF NOT EXISTS (
    SELECT TOP 1 1
    FROM [Menu]
    WHERE [nombre] = 'Días de Servicio'
    AND [url] = '/catalog/days-of-service/list'
)
BEGIN

EXEC dbo.PRO_General_GenerarIdUnico @tabla = 'Menu', @IdUnico = @IdRegistroListar OUTPUT;
    INSERT INTO [Menu] 
    ([id], [idPadre], [idUsuarioLog], [nombre], [url], [accion], [orden], [esMenu], [nota], [fechaCambio], [status], [versionFila], [esNewTab], [instruccion], [nombreIngles])
    VALUES 
    (@IdRegistroListar, @IdRegistro, '613pMX0S', 'Días de Servicio', '/catalog/days-of-service/list', 'GET', 0, 0, NULL, GETDATE(), 'ACTIVO', NULL, 0, 'LIST', 'Days of Service');
END;

 DECLARE @IdRegistroInsertar VARCHAR(32);

IF NOT EXISTS (
    SELECT TOP 1 1
    FROM [Menu]
    WHERE [nombre] = 'Días de Servicio'
    AND [url] = '/catalog/days-of-service/insert'
)
BEGIN

EXEC dbo.PRO_General_GenerarIdUnico @tabla = 'Menu', @IdUnico = @IdRegistroInsertar OUTPUT;
    INSERT INTO [Menu] 
    ([id], [idPadre], [idUsuarioLog], [nombre], [url], [accion], [orden], [esMenu], [nota], [fechaCambio], [status], [versionFila], [esNewTab], [instruccion], [nombreIngles])
    VALUES 
    (@IdRegistroInsertar, @IdRegistro, '613pMX0S', 'Días de Servicio', '/catalog/days-of-service/insert', 'POST', 1, 0, NULL, GETDATE(), 'ACTIVO', NULL, 0, 'INSERT', 'Days of Service');
END;


DECLARE @IdRegistroEditar VARCHAR(32);

IF NOT EXISTS (
    SELECT TOP 1 1
    FROM [Menu]
    WHERE [nombre] = 'Días de Servicio'
    AND [url] = '/catalog/days-of-service/edit'
)
BEGIN

EXEC dbo.PRO_General_GenerarIdUnico @tabla = 'Menu', @IdUnico = @IdRegistroEditar OUTPUT;
    INSERT INTO [Menu] 
    ([id], [idPadre], [idUsuarioLog], [nombre], [url], [accion], [orden], [esMenu], [nota], [fechaCambio], [status], [versionFila], [esNewTab], [instruccion], [nombreIngles])
    VALUES 
    (@IdRegistroEditar, @IdRegistro, '613pMX0S', 'Días de Servicio', '/catalog/days-of-service/edit', 'POST', 2, 0, NULL, GETDATE(), 'ACTIVO', NULL, 0, 'EDIT', 'Days of Service');
END;

DECLARE @IdRegistroEliminar VARCHAR(32);

IF NOT EXISTS (
    SELECT TOP 1 1
    FROM [Menu]
    WHERE [nombre] = 'Días de Servicio'
    AND [url] = '/catalog/days-of-service/delete'
)
BEGIN

EXEC dbo.PRO_General_GenerarIdUnico @tabla = 'Menu', @IdUnico = @IdRegistroEliminar OUTPUT;
    INSERT INTO [Menu] 
    ([id], [idPadre], [idUsuarioLog], [nombre], [url], [accion], [orden], [esMenu], [nota], [fechaCambio], [status], [versionFila], [esNewTab], [instruccion], [nombreIngles])
    VALUES 
    (@IdRegistroEliminar, @IdRegistro, '613pMX0S', 'Días de Servicio', '/catalog/days-of-service/delete', 'POST', 3, 0, NULL, GETDATE(), 'ACTIVO', NULL, 0, 'DELETE', 'Days of Service');
END;

