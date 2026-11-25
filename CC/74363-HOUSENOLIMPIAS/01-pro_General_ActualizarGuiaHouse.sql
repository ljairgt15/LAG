USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_General_ActualizarGuiaHouse]    Script Date: 25/11/2026 09:15:55 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/* 
Fecha de Modificacion: 6 Agosto 2020
 Objeto: Procedimiento                                                
 Nombre: PRO_General_ActualizarGuiaHouse
 Modulo: General  
 Responsable Modificacion: Jonathan Merino
 Observacion: se actualiza el conteo de piezas por el nuevo estado SHORT que reemplaza a LOST


 Fecha de Modificacion: 15 Enero 2019
 Objeto: SP                                              
 Nombre: PRO_General_ActualizarGuiaHouse
 Modulo: Recepcion
 Responsable Creacion: Raul Reyes
 Observacion: Creacion de Stored procedure PRO_General_ActualizarGuiaHouse
 Modificacion: 09/07/2020 Juan Domínguez, se realiza una simplificación del SP, eliminan variables, y se quita el * de la ultima consulta
 Modificacion: 14/07/2020 Luis De Andrade, Se desarrolla la parte del recalculo de estados de la Guia Master
 Modificacion: 20/07/2020 Juan Domínguez, se elimina el calculo del estadoGuia en GuiaHouse las pcsStandby por pedido de la HU-LAG-V08 NO CONSIDERAR STANDBY PARA ESTATUS DE RECEPCION
               22/07/2020 Juan Domínguez se realizan actualizaciones en el calculo del estado, queda igual que el los servicios del api.
			   09/11/2020 RR - Se pasa toda la logica a al modulo de Recepcion
			   16/11/2020 RR - Quitamos la consulta de la guia house
			   29/12/2020 RR - Se agrega actualizacion a tabla GuiasHouseAgrupado
*/
ALTER PROCEDURE [dbo].[pro_General_ActualizarGuiaHouse] (@idGuiaHouse UNIQUEIDENTIFIER)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @totalPcsHoldReceived INT;

    UPDATE gH
    SET gH.pcsPending = ISNULL(vGuias.pcsPending, 0),
        gH.pcsReceivedDr = ISNULL(vGuias.pcsReceivedDr, 0),
        gH.pcsReceivedWh = ISNULL(vGuias.pcsReceivedWh, 0),
        gH.pcsDispatchedWh = ISNULL(vGuias.pcsDispatchedWh, 0),
        gH.pcsHold = ISNULL(vGuias.pcsHold, 0),
        gH.pcsShort = ISNULL(vGuias.pcsShort, 0),
		gH.pcsLost = ISNULL(vGuias.pcsLost, 0),
        gH.pcsStandby = ISNULL(vGuias.pcsStandby, 0),
        gH.totalFullHouse = ISNULL(vGuias.totalFullHouse, 0.00),
        gH.totalPcsHouse = ISNULL(vGuias.totalPcsHouse, 0),
        gH.pesoVolumenHouse = ISNULL(vGuias.pesoVolumenHouse, 0.00),
        gH.totalPcsCarrier = ISNULL(vGuias.totalPcsCarrier, 0)
    FROM dbo.GuiasHouse gH
        INNER JOIN dbo.VistaGuiasIndexGuiasHouseDetalles vGuias
            ON vGuias.idGuiaHouse = gH.id
    WHERE gH.id = @idGuiaHouse;	 
	 
END;
