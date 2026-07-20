-- =============================================
/*  
 Fecha de Creación: 16/09/2021
 Objeto: Procedimiento                                              
 Nombre: pro_DespachoDeliveryPiezasContador
 Modulo: Despacho
 Responsable Creación: Jesus Yandun
 Observacion: Sp para Contador de piezas en scanner delivery
 Responsable Creación: Jairo Gonzalez
 Observacion: Quitar bodega
*/
-- =============================================
ALTER    PROCEDURE [dbo].[pro_DespachoDeliveryPiezasContador]
(
	@idClienteFinal VARCHAR(16),
	@idCarrier VARCHAR(16),
	@idBodega VARCHAR(16),
	@fechaDespacho DATETIME
)
AS
BEGIN
	DECLARE @fechaLimite date = DATEADD(MM,-2,convert(date,getdate()));
	
	BEGIN TRY

		select 
		temp.id, 
		temp.idClienteFinal, 
		temp.nroGuia,
		maniDespacho.nroManifiesto, 
		temp.estadoPieza, 
		temp.fechaDespacho, 
		temp.idCarrier,
		encabezaDes.idVehiculo,
		temp.codigoBarra,
		temp.idBodega
		from (
			select
			detalle.id, 
			detalle.idClienteFinal, 
			house.nroGuia, 
			detalle.estadoPieza, 
			progra.fechaDespacho, 
			progra.idCarrier,
			transporte.idTransportePrincipal,
			house.idEmpresa,
			progra.id idProgramacion,
			detalle.fechaCambio,
			detalle.fechaRecepcion,
			detalle.codigoBarra,
			house.idBodega
			from GuiasHouse house WITH(NOLOCK)
			inner join GuiasHouseDetalles detalle WITH(NOLOCK) on house.id = detalle.idGuiaHouse
			inner join ProgramacionCarrier progra WITH(NOLOCK) on detalle.id = progra.idGuiaHouseDetalle
			inner join Transportes transporte on progra.idCarrier = transporte.id
			where detalle.idClienteFinal = @idClienteFinal
			and progra.fechaDespacho = @fechaDespacho
		) temp
		left join ProgramacionManifiesto prograMani WITH(NOLOCK) on temp.idProgramacion = prograMani.idProgramacionCarrier
		left join DocumentosDespacho despacho WITH(NOLOCK) on prograMani.idManifiestoDespacho = despacho.id AND despacho.idDocumento = 'DOC052395'
		left join ManifiestosDespacho maniDespacho WITH(NOLOCK) on prograMani.idManifiestoDespacho = maniDespacho.id
		left join DetalleDespacho detalleDes WITH(NOLOCK) on temp.id = detalleDes.idGuiaHouseDetalle
		left join EncabezadoDespacho encabezaDes WITH(NOLOCK) on detalleDes.idEncabezadoDespacho = encabezaDes.id
		where ((temp.estadoPieza = 'DISPATCHED WH' AND (despacho.esPOD = 0 OR despacho.esPOD IS NULL))
		  OR (temp.estadoPieza = 'RECEIVED WH' AND (despacho.esPOD = 0 OR despacho.esPOD IS NULL))
		  OR (temp.estadoPieza = 'PENDING'));

  END TRY
    BEGIN CATCH
		EXEC [dbo].[pro_LogError] 
    END CATCH;
END