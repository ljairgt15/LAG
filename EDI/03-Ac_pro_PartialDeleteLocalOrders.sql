ALTER   Procedure [dbo].[Ac_pro_PartialDeleteLocalOrders](@ListaCodigosBarras VARCHAR(MAX))

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
						'pro_OrdenesLocales_EliminacionParcial'
					from GuiasHouseDetalles detalle					
					INNER JOIN ProgramacionCarrier progra ON detalle.id = progra.idGuiaHouseDetalle
					INNER JOIN Clientes cli ON detalle.idClienteFinal = cli.id
					INNER JOIN Transportes carrier ON progra.idCarrier = carrier.id
					INNER JOIN @table tabTemp on  detalle.codigoBarra= tabTemp.codigoBarra;
	
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