/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-07-25		  58788			 Based on pro_DespachoDeliveryPiezasContador
*/
ALTER    PROCEDURE [dbo].[Ac_pro_PieceCounterDispatchDelivery]
(
	@IdClienteFinal VARCHAR(16),
	@IdCarrier VARCHAR(16),
	@IdBodega VARCHAR(16),
	@FechaDespacho DATETIME
)
AS
BEGIN
	DECLARE @fechaLimite date = DATEADD(MM,-2,convert(date,getdate()));
	
	BEGIN TRY

		select 
		TMP.id, 
		TMP.ShipToId AS IdClienteFinal, 
		TMP.nroGuia,
		maniDespacho.nroManifiesto, 
		TMP.estadoPieza, 
		TMP.fechaDespacho, 
		TMP.idCarrier,
		encabezaDes.idVehiculo,
		TMP.codigoBarra,
		TMP.idBodega
		from (
			select
			GHD.id, 
			GHD.ShipToId, 
			GH.nroGuia, 
			GHD.estadoPieza, 
			PRO.fechaDespacho, 
			PRO.idCarrier,
			TRA.idTransportePrincipal,
			GH.idEmpresa,
			PRO.id idProgramacion,
			GHD.fechaCambio,
			GHD.fechaRecepcion,
			GHD.codigoBarra,
			GH.idBodega
			from GuiasHouse GH WITH(NOLOCK)
			inner join GuiasHouseDetalles GHD WITH(NOLOCK) on GH.id = GHD.idGuiaHouse
			inner join ProgramacionCarrier PRO WITH(NOLOCK) on GHD.id = PRO.idGuiaHouseDetalle
			inner join Transportes TRA on PRO.idCarrier = TRA.id
			where GHD.ShipToId = @idClienteFinal
			and PRO.fechaDespacho = @fechaDespacho
		) TMP
		left join ProgramacionManifiesto prograMani WITH(NOLOCK) on TMP.idProgramacion = prograMani.idProgramacionCarrier
		left join DocumentosDespacho despacho WITH(NOLOCK) on prograMani.idManifiestoDespacho = despacho.id AND despacho.idDocumento = 'DOC052395'
		left join ManifiestosDespacho maniDespacho WITH(NOLOCK) on prograMani.idManifiestoDespacho = maniDespacho.id
		left join DetalleDespacho detalleDes WITH(NOLOCK) on TMP.id = detalleDes.idGuiaHouseDetalle
		left join EncabezadoDespacho encabezaDes WITH(NOLOCK) on detalleDes.idEncabezadoDespacho = encabezaDes.id
		where ((TMP.estadoPieza = 'DISPATCHED WH' AND (despacho.esPOD = 0 OR despacho.esPOD IS NULL))
		  OR (TMP.estadoPieza = 'RECEIVED WH' AND (despacho.esPOD = 0 OR despacho.esPOD IS NULL))
		  OR (TMP.estadoPieza = 'PENDING'));

  END TRY
    BEGIN CATCH
		EXEC [dbo].[pro_LogError] 
    END CATCH;
END