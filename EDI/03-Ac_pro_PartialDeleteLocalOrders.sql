/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-08-17		  58719			 Based on pro_OrdenesLocales_EliminacionParcial
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_PartialDeleteLocalOrders](@ListaCodigosBarras VARCHAR(MAX))

AS

BEGIN

DECLARE @table TABLE ( id INT IDENTITY(1,1), codigoBarra VARCHAR(16))

INSERT INTO @table(codigoBarra)
SELECT codigoBarra
FROM OPENJSON(@ListaCodigosBarras)
WITH (codigoBarra VARCHAR(32)'$.codigoBarra')

BEGIN TRY
    --BORRAR
    BEGIN TRAN EliminaRegistros

    --Guardamos la programacion anterior
                    INSERT INTO DatosProgramacionAnterior (Id,
                                                           IdGuiaHouseDetalle,
                                                           IdCliente,
                                                           NombreCliente,
                                                           IdCarrier,
                                                           NombreCarrier,
                                                           FechaDespacho,
                                                           FechaCambio,
                                                           IdUsuarioProgramacion,
                                                           IdUsuarioLog,
                                                           Accion,
                                                           Nota)
                    SELECT NEWID(),
                        GHD.id,
                        GHD.ShipToId AS IdCliente,
                        CLI.nombre AS NombreCliente,
                        PRO.IdCarrier,
                        TRA.Nombre AS NombreCarrier,
                        PRO.FechaDespacho,
                        GETDATE() AS FechaCambio,
                        PRO.IdUsuarioLog,
                        NULL,
                        'E',
                        'AC_pro_OrdenesLocales_EliminacionParcial'
                    FROM GuiasHouseDetalles GHD
                    INNER JOIN ProgramacionCarrier PRO ON GHD.id = PRO.idGuiaHouseDetalle
                    INNER JOIN v_ClientsEntities CLI ON GHD.ShipToId = CLI.id
                    INNER JOIN Transportes TRA ON PRO.idCarrier = TRA.id
                    INNER JOIN @table tabTemp ON GHD.codigoBarra = tabTemp.codigoBarra;

    DELETE pc FROM ProgramacionCarrier pc
    INNER JOIN GuiasHouseDetalles ghd ON pc.idGuiaHouseDetalle = ghd.id
    INNER JOIN @table tabTemp ON ghd.codigoBarra = tabTemp.codigoBarra

    DELETE up FROM UbicacionPiezas up
    INNER JOIN GuiasHouseDetalles ghd ON up.idGuiaHouseDetalle = ghd.id
    INNER JOIN @table tabTemp ON ghd.codigoBarra = tabTemp.codigoBarra

    --obtencion para encabezados
    SELECT ghd.idGuiaHouse INTO #tempGuiaHouse FROM GuiasHouseDetalles ghd
    INNER JOIN @table tabTemp ON ghd.codigoBarra = tabTemp.codigoBarra

    DELETE ghd FROM GuiasHouseDetalles ghd
    INNER JOIN @table tabTemp ON ghd.codigoBarra = tabTemp.codigoBarra

    --obtencion para poEncabezado
    SELECT pd.idPo INTO #tempPoEncabezado FROM PoDetalles pd
    INNER JOIN @table tabTemp ON pd.codigoBarra = tabTemp.codigoBarra

    SELECT pe.idOrdenLocal INTO #tempOrdenLocal FROM PoEncabezado pe
    INNER JOIN #tempPoEncabezado tabTemp ON pe.id = tabTemp.idPo

    DELETE pd FROM PoDetalles pd
    INNER JOIN @table tabTemp ON pd.codigoBarra = tabTemp.codigoBarra

    --Eliminacion encabezados
    SELECT pe.id, COUNT(pd.id) AS cantidadDetalle INTO #poEncabezadoDetalle FROM PoEncabezado pe
    LEFT JOIN PoDetalles pd ON pe.id = pd.idPo
    INNER JOIN #tempPoEncabezado temp ON pe.id = temp.idPo
    GROUP BY pe.id

    SELECT ol.id, COUNT(pe.id) AS cantidadDetalle INTO #ordenLocalDetalle FROM OrdenesLocales ol
    LEFT JOIN PoEncabezado pe ON ol.id = pe.idOrdenLocal
    INNER JOIN #tempOrdenLocal temp ON ol.id = temp.idOrdenLocal
    GROUP BY ol.id

    DELETE pe FROM PoEncabezado pe
    INNER JOIN #poEncabezadoDetalle temp ON pe.id = temp.id
    WHERE temp.cantidadDetalle = 0

    DELETE ol FROM OrdenesLocales ol
    INNER JOIN #ordenLocalDetalle temp ON ol.id = temp.id
    WHERE temp.cantidadDetalle = 0

    COMMIT TRANSACTION EliminaRegistros;

    DROP TABLE #tempGuiaHouse
    DROP TABLE #tempPoEncabezado
    DROP TABLE #poEncabezadoDetalle
    DROP TABLE #ordenLocalDetalle

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION EliminaRegistros;
    EXEC [dbo].[pro_LogError]
END CATCH
END
/*
EXEC AC_pro_PartialDeleteLocalOrders @ListaCodigosBarras ='[{"codigoBarra":"U300000001"}]'
*/