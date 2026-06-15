/* 
VERSION     MODIFIEDBY        MODIFIEDDATE    HU     MODIFICATION
1           Jair Gomez        2026-06-15      57742  Based on pro_Reportes_EncabezadoCCI
*/
CREATE OR ALTER   PROCEDURE [dbo].[Ac_pro_ReportCCIHeader]
(
	@IdManifiestoDespacho UNIQUEIDENTIFIER,
	@IdExportador VARCHAR(16)
)
AS
BEGIN

	SELECT
		B.id IdBodega, 
		PB.nombreIngles PaisBodega, 
		PC.fechaDespacho, 
		MD.id IdManifiesto,
		MD.nroManifiesto, 
		GHD.po NroPo, 
		GH.idEmpresa, 
		CF.direccion DireccionClienteFinal, 
		CCL.nombre CiudadClienteFinal, 
		PCL.nombre PaisClienteFinal, 
		CF.nombre, 
		CF.codigozip CodigoZipClienteFinal, 
		PO.nombreIngles PaisOrigenProducto, 
		C.id IdCarrier, 
		C.nombre NombreCarrier, 
		E.razonSocial RazonSocialExportador, 
		E.direccion DireccionExportador, 
		CE.nombre CiudadExportador, 
		EE.codigoISO CodigoEstadoExportador, 
		PE.nombre PaisExportador, 
		E.codigozip CodigoZipExportador, 
		CC.id IdConsigneeDistribucion, 
		CC.nombre NombreConsigneeDistribucion, 
		CC.direccion DireccionConsigneeDistribucion, 
		CC.codigozip CodigoZipConsigneeDistribucion, 
		CCC.nombre CiudadConsigneeDistribucion, 
		PCC.nombre PaisConsigneeDistribucion, 
		CO.nombre CiudadOrigen, 
		SC.nombre NombreSubCarrier
	FROM ManifiestosDespacho MD WITH (NOLOCK)
	INNER JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
	INNER JOIN ProgramacionCarrier PC WITH (NOLOCK) ON PM.idProgramacionCarrier = PC.id
	INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
	INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
	INNER JOIN Exportadores E WITH (NOLOCK) ON GH.idExportador = E.id
	INNER JOIN Transportes SC WITH (NOLOCK) ON PC.idCarrier = SC.id
	INNER JOIN Transportes C WITH (NOLOCK) ON SC.idTransportePrincipal = C.id
	INNER JOIN v_ClientsEntities CF WITH (NOLOCK) ON GHD.ShipToId = CF.id
	INNER JOIN Ciudades CO WITH (NOLOCK) ON GH.idCiudadPuertoOrigen = CO.id
	INNER JOIN Estados EO WITH (NOLOCK) ON CO.idEstado = EO.id
	INNER JOIN Paises PO WITH (NOLOCK) ON EO.idPais = PO.id
	INNER JOIN Ciudades CE WITH (NOLOCK) ON E.idCiudad = CE.id
	INNER JOIN Estados EE WITH (NOLOCK) ON E.idEstado = EE.id
	INNER JOIN Paises PE WITH (NOLOCK) ON E.idPais = PE.id
	INNER JOIN Bodegas B WITH (NOLOCK) ON GH.idBodega = B.id
	INNER JOIN Ciudades CB WITH (NOLOCK) ON B.idCiudad = CB.id
	INNER JOIN Estados EB WITH (NOLOCK) ON CB.idEstado = EB.id
	INNER JOIN Paises PB WITH (NOLOCK) ON EB.idPais = PB.id
	INNER JOIN v_ClientsEntities CC WITH (NOLOCK) ON GH.ConsigneeId = CC.id
	INNER JOIN Ciudades CCC WITH (NOLOCK) ON CC.idCiudad = CCC.id
	INNER JOIN Paises PCC WITH (NOLOCK) ON CC.idPais = PCC.id
	LEFT JOIN Paises PCL WITH (NOLOCK) ON CF.idPais = PCL.id
	LEFT JOIN Estados ECL WITH (NOLOCK) ON CF.idEstado = ECL.id
	LEFT JOIN Ciudades CCL WITH (NOLOCK) ON CF.idCiudad = CCL.id
	WHERE
		MD.id = @IdManifiestoDespacho
		AND GHD.estadoPieza NOT IN ('HOLD', 'SHORT', 'STANDBY')
		AND E.id = @IdExportador

END

/*
EXEC dbo.Ac_pro_ReportCCIHeader 
@IdManifiestoDespacho = 'A854AE21-AF51-4478-8008-5C74523F478A', @IdExportador = 'EXP051623';
*/
