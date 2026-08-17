/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-08-17		  58719			 Based on pro_OrdenesLocales_EliminacionParcial
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_PartialDeleteLocalOrders](@ListaCodigosBarras VARCHAR(MAX))

AS 

BEGIN

DECLARE @table table ( id INT IDENTITY(1,1), codigoBarra varchar(16))

INSERT INTO @table(codigoBarra)
	SELECT codigoBarra
	FROM OPENJSON(@ListaCodigosBarras)
	WITH (codigoBarra varchar(32)'$.codigoBarra')

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
					select NEWID(),
						GHD.id, 
						GHD.ShipToId as IdCliente,
						CLI.nombre as NombreCliente,
						PRO.IdCarrier,
						TRA.Nombre as NombreCarrier,
						PRO.FechaDespacho,
						GETDATE() as FechaCambio,
						PRO.IdUsuarioLog,
						NULL,
						'E',
						'AC_pro_OrdenesLocales_EliminacionParcial'
					from GuiasHouseDetalles GHD					
					INNER JOIN ProgramacionCarrier PRO ON GHD.id = PRO.idGuiaHouseDetalle
					INNER JOIN v_ClientsEntities CLI ON GHD.ShipToId = CLI.id
					INNER JOIN Transportes TRA ON PRO.idCarrier = TRA.id
					INNER JOIN @table tabTemp on  GHD.codigoBarra= tabTemp.codigoBarra;
	
	DELETE pc FROM ProgramacionCarrier pc
	INNER JOIN GuiasHouseDetalles ghd on pc.idGuiaHouseDetalle = ghd.id
	INNER JOIN @table tabTemp on  ghd.codigoBarra= tabTemp.codigoBarra

	DELETE up FROM UbicacionPiezas up
	inner join GuiasHouseDetalles ghd on up.idGuiaHouseDetalle = ghd.id
	inner join @table tabTemp on ghd.codigoBarra = tabTemp.codigoBarra
	
	--obtencion para encabezados
	select ghd.idGuiaHouse into #tempGuiaHouse FROM GuiasHouseDetalles ghd
	inner join @table tabTemp on ghd.codigoBarra = tabTemp.codigoBarra

	DELETE ghd FROM GuiasHouseDetalles ghd
	inner join @table tabTemp on ghd.codigoBarra = tabTemp.codigoBarra

	--obtencion para poEncabezado
	select pd.idPo into #tempPoEncabezado FROM PoDetalles pd
	inner join @table tabTemp on pd.codigoBarra = tabTemp.codigoBarra

	select pe.idOrdenLocal into #tempOrdenLocal FROM PoEncabezado pe
	inner join #tempPoEncabezado tabTemp on pe.id = tabTemp.idPo
	
	DELETE pd FROM PoDetalles pd
	inner join @table tabTemp on pd.codigoBarra = tabTemp.codigoBarra
	

	--Eliminacion encabezados
	select pe.id,count(pd.id) as cantidadDetalle into #poEncabezadoDetalle from PoEncabezado pe
	left join PoDetalles pd on pe.id = pd.idPo
	inner join #tempPoEncabezado temp on pe.id = temp.idPo
	group by pe.id

	select ol.id, count(pe.id) as cantidadDetalle into #ordenLocalDetalle from OrdenesLocales ol
	left join PoEncabezado pe on ol.id = pe.idOrdenLocal
	inner join #tempOrdenLocal temp on ol.id = temp.idOrdenLocal
	group by ol.id

	delete pe from PoEncabezado pe
	inner join #poEncabezadoDetalle temp on pe.id = temp.id
	where temp.cantidadDetalle=0

	delete ol from OrdenesLocales ol
	inner join #ordenLocalDetalle temp on ol.id = temp.id
	where temp.cantidadDetalle=0

	COMMIT TRANSACTION EliminaRegistros;

	drop table #tempGuiaHouse
	drop table #tempPoEncabezado
	drop table #poEncabezadoDetalle
	drop table #ordenLocalDetalle

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION EliminaRegistros;
	EXEC [dbo].[pro_LogError] 
END CATCH
END