USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_Reportes_EncabezadoCCI]    Script Date: 15/06/2026 04:26:59 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
VERSION		AUTOR				FECHA			HU			CAMBIO
1			Damián Briones		25/04/2024		37065		Codigo Inicial - Creacion del SP
*/

ALTER   PROCEDURE [dbo].[pro_Reportes_EncabezadoCCI]
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
		CF.direccion DireccionClienteFinalAlt, 
		CCL.nombre CiudadClienteFinalAlt, 
		PCL.nombre PaisClienteFinalAlt, 
		CF.nombreClienteFinal, 
		ICF.codigozip CodigoZipClienteFinal, 
		CF.codigozip CodigoZipClienteFinalAlt, 
		CF.nombre NombreClienteFinalAlt, 
		ICF.direccion DireccionClienteFinal, 
		CLF.nombre CiudadClienteFinal, 
		PCF.nombre PaisClienteFinal, 
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
	INNER JOIN Clientes CF WITH (NOLOCK) ON GHD.idClienteFinal = CF.id
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
	INNER JOIN Clientes CC WITH (NOLOCK) ON GH.idCliente = CC.id
	INNER JOIN Ciudades CCC WITH (NOLOCK) ON CC.idCiudad = CCC.id
	INNER JOIN Paises PCC WITH (NOLOCK) ON CC.idPais = PCC.id
	LEFT JOIN Paises PCL WITH (NOLOCK) ON CF.idPais = PCL.id
	LEFT JOIN Estados ECL WITH (NOLOCK) ON CF.idEstado = ECL.id
	LEFT JOIN Ciudades CCL WITH (NOLOCK) ON CF.idCiudad = CCL.id
	LEFT JOIN InformacionClienteFinal ICF WITH (NOLOCK) ON CF.id = ICF.id
	LEFT JOIN Paises PCF WITH (NOLOCK) ON ICF.idPais = PCF.id
	LEFT JOIN Estados ECF WITH (NOLOCK) ON ICF.idEstado = ECF.id
	LEFT JOIN Estados CLF WITH (NOLOCK) ON ICF.idCiudad = CLF.id
	WHERE
		MD.id = @IdManifiestoDespacho
		AND GHD.estadoPieza NOT IN ('HOLD', 'SHORT', 'STANDBY')
		AND E.id = @IdExportador

END

/*
EXEC dbo.pro_Reportes_EncabezadoCCI 'A854AE21-AF51-4478-8008-5C74523F478A', 'EXP051623';
*/
