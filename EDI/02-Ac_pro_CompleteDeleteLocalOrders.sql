/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-08-17		  58719			 Based on pro_OrdenesLocales_EliminacionCompleta
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_CompleteDeleteLocalOrders](@NroOrden VARCHAR(16))

AS
 
DECLARE @IdOrden [uniqueidentifier]
DECLARE @IdPO [uniqueidentifier]
DECLARE @IdGuiaHouse [uniqueidentifier]

BEGIN
BEGIN TRY
	SELECT @IdOrden = id FROM OrdenesLocales WHERE nroOrden = @NroOrden
	SELECT @IdPO = id FROM PoEncabezado WHERE idOrdenLocal = @IdOrden
	SELECT @IdGuiaHouse = id FROM GuiasHouse WHERE nroGuia = @NroOrden AND house = 'LOCAL'

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
						GHD.Id, 
						GHD.ShiptoId as IdCliente,
                        CLI.nombre as NombreCliente,
						PRO.IdCarrier,
						TRA.nombre as NombreCarrier,
						PRO.FechaDespacho,
						GETDATE() as FechaCambio,
						PRO.IdUsuarioLog,
						NULL,
						'E',
						'AC_pro_OrdenesLocales_EliminacionCompleta'
					FROM GuiasHouseDetalles GHD					
					INNER JOIN ProgramacionCarrier PRO ON GHD.id = PRO.idGuiaHouseDetalle
					INNER JOIN v_ClientsEntities CLI ON GHD.ShiptoId = CLI.Id
					INNER JOIN Transportes TRA ON PRO.idCarrier = TRA.id
					WHERE GHD.idGuiaHouse = @idGuiaHouse;
	DELETE FROM ProgramacionCarrier WHERE idGuiaHouseDetalle IN (SELECT id FROM GuiasHouseDetalles WHERE idGuiaHouse = @idGuiaHouse	)
	DELETE FROM UbicacionPiezas WHERE idGuiaHouseDetalle IN (SELECT id FROM GuiasHouseDetalles WHERE idGuiaHouse = @idGuiaHouse	)
	DELETE FROM GuiasHouseDetalles WHERE idGuiaHouse = @idGuiaHouse
	DELETE FROM PoDetalles WHERE idPo = @idPO
	DELETE FROM PoEncabezado WHERE idOrdenLocal = @idOrden
	DELETE FROM OrdenesLocales WHERE nroOrden =@NroOrden
	DELETE FROM GuiasHouse WHERE nroGuia  = @NroOrden
	COMMIT TRANSACTION EliminaRegistros;

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION EliminaRegistros;
	EXEC [dbo].[pro_LogError] 
END CATCH
END