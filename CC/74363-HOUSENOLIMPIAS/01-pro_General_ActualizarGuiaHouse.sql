/*    
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Raul Reyes          2019-01-15          NA              Creacion de Stored procedure PRO_General_ActualizarGuiaHouse para Recepcion 
2           Juan Domínguez      2020-07-09          NA              Se realiza una simplificación del SP, eliminan variables, y se quita el * de la ultima consulta
3           Luis De Andrade     2020-07-14          NA              Se desarrolla la parte del recalculo de estados de la Guia Master
4           Juan Domínguez      2020-07-20          HU-LAG-V08      Se elimina el calculo del estadoGuia en GuiaHouse las pcsStandby por pedido de la HU-LAG-V08 NO CONSIDERAR STANDBY PARA ESTATUS DE RECEPCION
5           Juan Domínguez      2020-07-22          NA              Se realizan actualizaciones en el calculo del estado, queda igual que el los servicios del api.
6           Jonathan Merino     2020-08-06          NA              Se actualiza el conteo de piezas por el nuevo estado SHORT que reemplaza a LOST
7           Raul Reyes          2020-11-09          NA              Se pasa toda la logica a al modulo de Recepcion
8           Raul Reyes          2020-11-16          NA              Quitamos la consulta de la guia house
9           Raul Reyes          2020-12-19          NA              Se agrega actualizacion a tabla GuiasHouseAgrupado
10          Jair Gomez          2026-11-25          CC HU-74363     Switch to a left join VistaGuiasIndexGuiasHouseDetalles so that the update doesn't fail when there are no records in the details view
*/  

CREATE OR ALTER PROCEDURE [dbo].[pro_General_ActualizarGuiaHouse1] 
(@idGuiaHouse UNIQUEIDENTIFIER)
AS
BEGIN
    UPDATE GH
    SET GH.pcsPending = ISNULL(VG.pcsPending, 0),
        GH.pcsReceivedDr = ISNULL(VG.pcsReceivedDr, 0),
        GH.pcsReceivedWh = ISNULL(VG.pcsReceivedWh, 0),
        GH.pcsDispatchedWh = ISNULL(VG.pcsDispatchedWh, 0),
        GH.pcsHold = ISNULL(VG.pcsHold, 0),
        GH.pcsShort = ISNULL(VG.pcsShort, 0),
		GH.pcsLost = ISNULL(VG.pcsLost, 0),
        GH.pcsStandby = ISNULL(VG.pcsStandby, 0),
        GH.totalFullHouse = ISNULL(VG.totalFullHouse, 0.00),
        GH.totalPcsHouse = ISNULL(VG.totalPcsHouse, 0),
        GH.pesoVolumenHouse = ISNULL(VG.pesoVolumenHouse, 0.00),
        GH.totalPcsCarrier = ISNULL(VG.totalPcsCarrier, 0),
		GH.fechaCambio = GETDATE()
    FROM GuiasHouse GH
    LEFT JOIN VistaGuiasIndexGuiasHouseDetalles VG ON VG.idGuiaHouse = GH.id
    WHERE GH.id = @idGuiaHouse	 
	 
END
