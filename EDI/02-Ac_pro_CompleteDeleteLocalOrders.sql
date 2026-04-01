CREATE OR ALTER   Procedure [dbo].[Ac_pro_CompleteDeleteLocalOrders](@NroOrden VARCHAR(16))

AS
 
DECLARE @idOrden [uniqueidentifier]
DECLARE @idPO [uniqueidentifier]
DECLARE @idGuiaHouse [uniqueidentifier]

BEGIN
BEGIN TRY
	SELECT @idOrden = id FROM OrdenesLocales WHERE nroOrden = @NroOrden
	SELECT @idPO = id FROM PoEncabezado WHERE idOrdenLocal = @idOrden
	SELECT @idGuiaHouse = id FROM GuiasHouse WHERE nroGuia = @NroOrden AND house = 'LOCAL'

	--BORRAR
	BEGIN TRAN EliminaRegistros
	--Guardamos la programacion anterior
					INSERT INTO DatosProgramacionAnterior (id,
														   idGuiaHouseDetalle,
														   idCliente,
														   nombreCliente,
														   idCarrier,
														   nombreCarrier,
														   fechaDespacho,
														   fechaCambio,
														   idUsuarioProgramacion,
														   idUsuarioLog,
														   accion,
														   nota)
					select NEWID(),
						detalle.id, 
						detalle.idClienteFinal as idCliente,
						case 
							when cli.nombreClienteFinal is not null then
								cli.nombreClienteFinal
							else
								cli.nombre
						end as nombreCliente,
						progra.idCarrier,
						carrier.nombre as nombreCarrier,
						progra.fechaDespacho,
						GETDATE() as fechaCambio,
						progra.idUsuarioLog,
						NULL,
						'E',
						'pro_OrdenesLocales_EliminacionCompleta'
					from GuiasHouseDetalles detalle					
					INNER JOIN ProgramacionCarrier progra ON detalle.id = progra.idGuiaHouseDetalle
					INNER JOIN Clientes cli ON detalle.idClienteFinal = cli.id
					INNER JOIN Transportes carrier ON progra.idCarrier = carrier.id
					WHERE detalle.idGuiaHouse = @idGuiaHouse;
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