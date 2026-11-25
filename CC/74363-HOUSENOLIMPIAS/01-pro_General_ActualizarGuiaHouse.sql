/*    
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Raul Reyes          2019-01-15          ----            Creacion de Stored procedure PRO_General_ActualizarGuiaHouse para Recepcion 
2           Juan Domínguez      2020-07-09          ----            Se realiza una simplificación del SP, eliminan variables, y se quita el * de la ultima consulta
3           Luis De Andrade     2020-07-14          ----            Se desarrolla la parte del recalculo de estados de la Guia Master
4           Juan Domínguez      2020-07-20          HU-LAG-V08      Se elimina el calculo del estadoGuia en GuiaHouse las pcsStandby por pedido de la HU-LAG-V08 NO CONSIDERAR STANDBY PARA ESTATUS DE RECEPCION
5           Juan Domínguez      2020-07-22          ----            Se realizan actualizaciones en el calculo del estado, queda igual que el los servicios del api.
6           Jonathan Merino     2020-08-06          ----            Se actualiza el conteo de piezas por el nuevo estado SHORT que reemplaza a LOST
7           Raul Reyes          2020-11-09          ----            Se pasa toda la logica a al modulo de Recepcion
8           Raul Reyes          2020-11-16          ----            Quitamos la consulta de la guia house
9           Raul Reyes          2020-12-19          ----            Se agrega actualizacion a tabla GuiasHouseAgrupado
10          Jair Gomez          2026-11-25          CC HU-74363     Switch to a left join so that the update doesn't fail when there are no records in the details view
*/  

CREATE OR ALTER PROCEDURE [dbo].[pro_General_ActualizarGuiaHouse] (@idGuiaHouse UNIQUEIDENTIFIER)
AS
BEGIN
    SET NOCOUNT ON

	DECLARE @totalPcsHoldReceived INT

    UPDATE GH
    SET GH.pcsPending = ISNULL(vGuias.pcsPending, 0),
        GH.pcsReceivedDr = ISNULL(vGuias.pcsReceivedDr, 0),
        GH.pcsReceivedWh = ISNULL(vGuias.pcsReceivedWh, 0),
        GH.pcsDispatchedWh = ISNULL(vGuias.pcsDispatchedWh, 0),
        GH.pcsHold = ISNULL(vGuias.pcsHold, 0),
        GH.pcsShort = ISNULL(vGuias.pcsShort, 0),
		GH.pcsLost = ISNULL(vGuias.pcsLost, 0),
        GH.pcsStandby = ISNULL(vGuias.pcsStandby, 0),
        GH.totalFullHouse = ISNULL(vGuias.totalFullHouse, 0.00),
        GH.totalPcsHouse = ISNULL(vGuias.totalPcsHouse, 0),
        GH.pesoVolumenHouse = ISNULL(vGuias.pesoVolumenHouse, 0.00),
        GH.totalPcsCarrier = ISNULL(vGuias.totalPcsCarrier, 0)
    FROM dbo.GuiasHouse GH
    LEFT JOIN dbo.VistaGuiasIndexGuiasHouseDetalles vGuias
    ON vGuias.idGuiaHouse = GH.id
    WHERE GH.id = @idGuiaHouse	 
	 
END
/*
EXEC pro_General_ActualizarGuiaHouse @idGuiaHouse='E9319B7D-8E81-44A9-9F9E-752529541333'
*/