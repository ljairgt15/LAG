USE [alliance_testing]
GO
/****** Object:  StoredProcedure [dbo].[pro_modulo_DespachoPickup]    Script Date: 17/05/2026 09:27:40 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
VERSION		MODIFIEDBY			MODIFIEDDATE	HU			MODIFICATION
1			Jesús Yandún		2021-01-11		NA			Extrae información para modulo de pickup
2			Jonathan Merino		2021-04-09		NA			se modifica listado para devolver TipoManifiesto en base al parametro del cliente Consignee
3			Jonathan Merino		2021-06-10		NA			se retorna documentoDes.modificado para validar manifiesto modificado y pintar de color rojo la nube
4			Luchin				2021-08-05		NA			No agrupar por totales, house, idGuiaHouse - No hacer join con DocumentoDespacho - No hacer join con Usuarios - Remover campos no usados
5			Jonathan Merino		2021-08-25		NA	  		modificacion del listado para mostrar en pendientes piezas que no tengan manifiesto o cuyo manifiesto no se EPOD
6			Jonathan Merino		2021-10-01		NA	  		modificacion para filtrar informacion por pallet
7			Jonathan Merino		2021-11-04		NA	  		modificacion para agrupar por orden de venta y total de picking para estado sold
8			Saul Mendez			2021-12-27	  	NA			se agrega los campos de carrier
9			Saul Mendez			2021-12-30		NA 			Mostrar Bodega de acuerdo con la ubicación de la pieza
10			Luchin				2022-04-15		NA 			Mostrar Bodega de acuerdo con la ubicación de la pieza
11			Luchin / Paty		2022-12-27		15337		Mejoras SP
12			Jose Ganchozo		2023-05-30		25674		Agregar columnas despachadoDestino y totalPickingLoading
13			Jean Martillo		2023-11-24      29121		Agregar a la suma de piezas cuando es lost y short
14			Jose Ganchozo		2023-11-27		33811		Cambiar el filtro a la primera consulta tabla #TMP_PROGRAM de numero po
15			Oscar Yunda			2023-12-19		CC33054		Se modifica el listado para obtener el idTE de ProgramacionTE y el IdPais de Cliente y IdPais Cliente Final
16			Fernando Ordoñez	2024-09-13		HU 41334	Agregar inventario
17			Jose Ganchozo		2024-11-29		Bug-46654	Se corrige la logica para las piezas que son de inventario
18			Ismael Flores		2024-12-06		HU 41334	Se aplica OUTER APPLY para la consulta de idDocumento = 'DOC052395'
19			PCHICAIZA 			2026-03-19		NA			Add new parameters with @V for improving performance
*/
ALTER PROCEDURE [dbo].[pro_modulo_DespachoPickup]
    @nroDocument VARCHAR(32) = NULL,
    @po VARCHAR(64) = NULL,
    @Consignee NVARCHAR(512) = NULL,
    @status VARCHAR(32) = NULL,
    @nroManifiesto VARCHAR(32) = NULL,
    @barcode VARCHAR(32) = NULL,
    @supplier NVARCHAR(512) = NULL,
    @idEmpresa VARCHAR(16),
    @consulta INT,
	@fechaDesde INT,
	@palletLabel VARCHAR(16) = NULL
AS
BEGIN
	BEGIN TRY
		DECLARE
		@VnroDocument VARCHAR(32) = @nroDocument,
		@Vpo VARCHAR(64) = @po,
		@VConsignee NVARCHAR(512) = @Consignee,
		@Vstatus VARCHAR(32) = @status,
		@VnroManifiesto VARCHAR(32) = @nroManifiesto,
		@Vbarcode VARCHAR(32) = @barcode,
		@Vsupplier NVARCHAR(512) = @supplier,
		@VidEmpresa VARCHAR(16) = @idEmpresa,
		@Vconsulta INT = @consulta,		
		@VpalletLabel VARCHAR(16) = @palletLabel,
		@fechaDespacho DATETIME = DATEADD(MM, -@fechaDesde, GETDATE()),
		@idParametroDelivery VARCHAR(16),
		@idParametroTipo VARCHAR(16)

		CREATE TABLE #TablaAgrupacionGuiasPickUp(
			idManifiesto		UNIQUEIDENTIFIER,
			nroManifiesto		VARCHAR(32),	
			idClienteFinal		VARCHAR(32),
			nombreClienteFinal	NVARCHAR(512),		
			idBodega			VARCHAR(32),
			nombreBodega		NVARCHAR(512),		
			idCarrier			VARCHAR(32),				
			truckId				VARCHAR(16),
			fechaDespacho		DATETIME,
			valor				VARCHAR(1024),
			totalPiezas			INT,
			totalDespachado		INT,
			totalStandBy		INT,
			totalHold			INT,
			totalPending		INT,
			totalRecibido		INT,
			totalShort			INT,
			EsPod				BIT NOT NULL DEFAULT 0,
			ordenVenta			VARCHAR(16) NULL,
			totalPicking		INT,
			idOrdenVenta		UNIQUEIDENTIFIER,
			nombreCarrier		NVARCHAR(512),
			codigoCarrier		VARCHAR(32),
			totalPickingLoading INT,
			idPaisCliente		VARCHAR(16),
			idPaisAlt			VARCHAR(16),
			idTEGuid			UNIQUEIDENTIFIER NULL,
			esInventario		BIT)

		SELECT @idParametroDelivery = id 
		FROM ParametrosLista PL WITH (NOLOCK) 
		WHERE PL.codigo = 'EsDelivery'
		AND PL.idEmpresa = @VidEmpresa;

		SELECT @idParametroTipo = id 
		FROM ParametrosLista PL WITH (NOLOCK) 
		WHERE PL.codigo = 'TipoManifiestoDespacho'
		AND PL.idEmpresa = @VidEmpresa;

		SELECT C.idEntidad, C.codigo
		INTO #TMP_CodigosRelacionSistemas
		FROM CodigosRelacionSistemas C WITH (NOLOCK) 
		WHERE C.tipoEntidad = 'CARRIER' 
		AND C.idSistemaEntidad = 100;

		SELECT 
		PC.id,
		T.id idCarrier,
		PC.fechaDespacho,
		T.nombre nombreTransporte,
		GHD.id idGuiaHouseDetalle,
		GHD.idGuiaHouse,
		GHD.idPoDetalle,
		GHD.codigoBarra,
		GHD.estadoPieza,
		GHD.idClienteFinal,
		GHD.truckId,
		GHD.despachadoDestino,
		PC.idUsuarioLogPicking,
		TE.idTE
		INTO #TMP_PROGRAM
		FROM ProgramacionCarrier PC WITH (NOLOCK) 		
		INNER JOIN Transportes T WITH (NOLOCK) ON pc.idCarrier = t.id
		INNER JOIN ParametrosCatalogos P WITH (NOLOCK) ON t.idTransportePrincipal = P.idEntidad AND P.idParametroLista = @idParametroDelivery AND P.valor = 'NO'
		INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle
		LEFT JOIN ProgramacionTe TE WITH (NOLOCK) ON pc.id = te.idProgramacionCarrier  
		WHERE PC.fechaDespacho > @fechaDespacho
		AND (@Vpo IS NULL OR ghd.po LIKE @Vpo + '%')
	
		IF(@VnroDocument IS NULL AND @Vpo IS NULL AND @VConsignee IS NULL AND @VnroManifiesto IS NULL AND @Vsupplier IS NULL AND @Vbarcode IS NULL AND @VpalletLabel IS NULL)
		BEGIN
			INSERT INTO #TablaAgrupacionGuiasPickUp -- with nulls
			SELECT 
			MD.id, 
			MD.nroManifiesto,
			PR.idClienteFinal, 
			ISNULL (CL.nombreClienteFinal, CL.nombre) NombreClienteFinal,
			ISNULL(UB.idBodega, H.idBodega) idBodega, 
			ISNULL(BP.nombre, BG.nombre) nombreBodega,
			PR.idCarrier, 		
			PR.truckId, 
			PR.fechaDespacho ,
			PCA.valor, 
			COUNT(PR.estadoPieza),
			SUM(IIF(PR.estadoPieza = 'DISPATCHED WH', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'STANDBY', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'HOLD', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'PENDING', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'RECEIVED WH', 1, 0)),
			SUM(IIF(PR.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),
			ISNULL(dcd.esPOD,0),
			SVC.nroOrden,
			SUM(IIF(SVC.picking = 1, 1, 0)),
			SVC.id,
			PR.nombreTransporte,
			T1.codigo,
			SUM(IIF(PR.idUsuarioLogPicking IS NOT NULL, 1, 0)) totalPickingLoading,
			PCF.id idPaisCliente,
			PAC.id idPaisAlt,
			PR.idTE idTEGuid,
			CASE 
				WHEN SVC.tipoVenta < 4 THEN 1 
				WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1  THEN 1 
				ELSE 0
			END esInventario
			FROM #TMP_PROGRAM PR		
				INNER JOIN #TMP_CodigosRelacionSistemas T1  ON PR.idCarrier = T1.idEntidad
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON PR.idGuiaHouse = gh.id
				INNER JOIN Clientes CL WITH (NOLOCK) ON PR.idClienteFinal = CL.id
				INNER JOIN Paises PAC ON CL.idPais = PAC.id  
				CROSS APPLY (	SELECT G.idCliente, idBodega
								FROM GuiasHouse G WITH (NOLOCK)
								WHERE PR.idGuiaHouse  = G.id ) H  
				LEFT JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON PCA.idEntidad = H.idCliente AND PCA.idParametroLista = @idParametroTipo
				LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PR.id = PM.idProgramacionCarrier
				LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id				
				OUTER APPLY (	SELECT TOP 1 DD.EsPod
								FROM DocumentosDespacho DD WITH (NOLOCK)
								WHERE DD.idManifiesto = MD.id 
								AND DD.idDocumento = 'DOC052395'
								ORDER BY EsPod DESC) DCD
				LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON PR.idGuiaHouseDetalle = UP.idGuiaHouseDetalle
				LEFT JOIN Ubicaciones U WITH (NOLOCK) ON UP.idUbicacion = U.id
				LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON U.idUbicacionBodega = UB.id
				LEFT JOIN Bodegas BG WITH (NOLOCK) ON H.idBodega = BG.id
				LEFT JOIN Bodegas BP WITH (NOLOCK) ON UB.idBodega = BP.id
				LEFT JOIN (	SELECT PR.idGuiaHouseDetalle,
							SV.id, 
							SV.nroOrden, 
							SVD.picking,
							SV.fechaSolicitud ,
							ROW_NUMBER() OVER (PARTITION BY PR.idGuiaHouseDetalle ORDER BY SV.fechaSolicitud DESC) rown,
							SV.tipoVenta,
							SVD.tipoPieza
							FROM #TMP_PROGRAM PR 
							INNER JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON PR.idGuiaHouseDetalle = SVD.idGuiaHouseDetalle
							INNER JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud ) SVC ON PR.idGuiaHouseDetalle = SVC.idGuiaHouseDetalle AND SVC.rown = 1
				LEFT JOIN InformacionClienteFinal ICF ON CL.id = ICF.id       
				LEFT JOIN Paises PCF ON ICF.idPais = PCF.id
			WHERE @VidEmpresa IS NULL OR gh.idEmpresa = @VidEmpresa
			GROUP BY 
			MD.id, 
			MD.nroManifiesto, 
			PR.idClienteFinal, 
			ISNULL (CL.nombreClienteFinal,CL.nombre) ,
			ISNULL(UB.idBodega, H.idBodega) , 
			ISNULL(BP.nombre, BG.nombre) ,
			PR.idCarrier, 
			PR.truckId, 
			PR.fechaDespacho, 
			PCA.valor,
			dcd.esPOD,
			SVC.nroOrden,
			SVC.id,
			PR.nombreTransporte,
			T1.codigo,
			PR.despachadoDestino,
			PR.idUsuarioLogPicking,
			PCF.id,
			PAC.id,
			PR.idTE,
			CASE 
				WHEN SVC.tipoVenta < 4 THEN 1 
				WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1  THEN 1 
				ELSE 0 
			END;
		END
		ELSE
		BEGIN
			INSERT INTO #TablaAgrupacionGuiasPickUp -- without nulls
			SELECT 
			MD.id, 
			MD.nroManifiesto,
			PR.idClienteFinal, 
			ISNULL (CL.nombreClienteFinal, CL.nombre) NombreClienteFinal,
			ISNULL(UB.idBodega, H.idBodega) idBodega, 
			ISNULL(BP.nombre, BG.nombre) nombreBodega,
			PR.idCarrier, 		
			PR.truckId, 
			PR.fechaDespacho ,
			PCA.valor, 
			COUNT(PR.estadoPieza),
			SUM(IIF(PR.estadoPieza = 'DISPATCHED WH', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'STANDBY', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'HOLD', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'PENDING', 1, 0)),
			SUM(IIF(PR.estadoPieza = 'RECEIVED WH', 1, 0)),
			SUM(IIF(PR.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),		
			ISNULL(dcd.esPOD,0),
			SVC.nroOrden,
			SUM(IIF(SVC.picking = 1, 1, 0)),
			SVC.id,
			PR.nombreTransporte,
			T1.codigo, 
			SUM(IIF(PR.idUsuarioLogPicking IS NOT  NULL, 1, 0)) totalPickingLoading,
			PCF.id idPaisCliente,
			PAC.id idPaisAlt,
			PR.idTE idTEGuid,
			CASE 
				WHEN SVC.tipoVenta < 4 THEN 1 
				WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1  THEN 1
				ELSE 0 
			END esInventario
			FROM #TMP_PROGRAM PR		
				INNER JOIN #TMP_CodigosRelacionSistemas T1 ON PR.idCarrier = T1.idEntidad
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON PR.idGuiaHouse = gh.id
				INNER JOIN Clientes CL WITH (NOLOCK) ON PR.idClienteFinal = CL.id	
				INNER JOIN Paises PAC ON CL.idPais = PAC.id   
				CROSS APPLY (	SELECT G.idCliente, idBodega, idExportador, nroGuia
								FROM GuiasHouse G WITH (NOLOCK)
								WHERE PR.idGuiaHouse  = G.id ) H  
				LEFT JOIN PalletsDetalles pld WITH (NOLOCK) ON PR.idGuiaHouseDetalle = pld.idGuiasHouseDetalle
				LEFT JOIN Pallets pal WITH (NOLOCK) ON pld.idPallet = pal.id
				LEFT JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON PCA.idEntidad = H.idCliente AND PCA.idParametroLista = @idParametroTipo
				LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PR.id = PM.idProgramacionCarrier
				LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id				
				OUTER APPLY (	SELECT TOP 1 DD.EsPod
								FROM DocumentosDespacho DD WITH (NOLOCK)
								WHERE DD.idManifiesto = MD.id 
								AND DD.idDocumento = 'DOC052395'
								ORDER BY EsPod DESC) DCD
				LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON PR.idGuiaHouseDetalle = UP.idGuiaHouseDetalle
				LEFT JOIN Ubicaciones U WITH (NOLOCK) ON UP.idUbicacion = U.id
				LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON U.idUbicacionBodega = UB.id
				LEFT JOIN Bodegas BG WITH (NOLOCK) ON H.idBodega = BG.id
				LEFT JOIN Bodegas BP WITH (NOLOCK) ON UB.idBodega = BP.id
				LEFT JOIN (	SELECT PR.idGuiaHouseDetalle,
							SV.id, 
							SV.nroOrden, 
							SVD.picking,
							SV.fechaSolicitud ,
							ROW_NUMBER() OVER (PARTITION BY PR.idGuiaHouseDetalle ORDER BY SV.fechaSolicitud DESC) AS rown,
							SV.tipoVenta,
							tipoPieza
							FROM #TMP_PROGRAM PR 
							INNER JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON PR.idGuiaHouseDetalle = SVD.idGuiaHouseDetalle
							INNER JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud ) SVC ON PR.idGuiaHouseDetalle = SVC.idGuiaHouseDetalle AND SVC.rown = 1
				LEFT JOIN InformacionClienteFinal ICF ON CL.id = ICF.id    
				LEFT JOIN Paises PCF ON ICF.idPais = PCF.id
			WHERE   (@VidEmpresa IS NULL OR gh.idEmpresa = @VidEmpresa)
				AND (@Vbarcode IS NULL OR PR.codigoBarra LIKE '%' + @Vbarcode + '%')
				AND (@VnroDocument IS NULL OR H.nroGuia LIKE '%' + @VnroDocument + '%')
				AND (@VConsignee IS NULL OR H.idCliente IN ( SELECT id FROM Clientes WITH (NOLOCK) WHERE nombre LIKE '%' + @VConsignee + '%' ))
				AND (@Vsupplier IS NULL OR H.idExportador IN ( SELECT id FROM Exportadores WITH (NOLOCK) WHERE nombre LIKE '%' + @Vsupplier + '%' ))
				AND (@VpalletLabel IS NULL OR pal.pallet LIKE '%' + @VpalletLabel + '%')
				AND (@VnroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @VnroManifiesto + '%')
			GROUP BY 
			MD.id, 
			MD.nroManifiesto, 
			PR.idClienteFinal, 
			ISNULL (CL.nombreClienteFinal, CL.nombre),
			ISNULL(UB.idBodega, H.idBodega), 
			ISNULL(BP.nombre, BG.nombre),
			PR.idCarrier, 
			PR.truckId, 
			PR.fechaDespacho, 
			PCA.valor,
			dcd.esPOD,
			SVC.nroOrden,
			SVC.id,
			PR.nombreTransporte,
			T1.codigo,
			PR.idUsuarioLogPicking,
			PCF.id,
			PAC.id,
			PR.idTE,
			CASE 
				WHEN SVC.tipoVenta < 4 THEN 1 
				WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1  THEN 1 
				ELSE 0 
			END;
		END

		SELECT      
			NEWID() id,
			RES.idManifiesto,
			RES.nroManifiesto,
			RES.idClienteFinal,		
			RES.fechaDespacho,
			RES.idBodega,
			RES.nombreBodega,		
			RES.nombreClienteFinal,
			RES.idCarrier,
			RES.truckId,		
			RES.valor,
			SUM(RES.totalPiezas) TotalPiezas,
			SUM(RES.totalDespachado) TotalDespachado,
			SUM(RES.totalStandBy) TotalStandBy,
			SUM(RES.totalHold) TotalHold,
			SUM(RES.totalPending) TotalPending,
			SUM(RES.totalRecibido) TotalRecibido,
			SUM(RES.totalShort) TotalShort,	
			RES.EsPod,	
			NULL mailEnviado,
			NULL tipoNubeDocs,
			NULL modificado,
			ordenVenta,
			SUM(RES.totalPicking) TotalPicking,
			idOrdenVenta,		
			RES.nombreCarrier,
			RES.codigoCarrier,
			NULL validarDiferenciaPiezas,
			SUM(RES.totalPickingLoading) TotalPickingLoading ,
			RES.idPaisCliente,
			RES.idPaisAlt,
			RES.idTEGuid,
			RES.esInventario
		FROM #TablaAgrupacionGuiasPickUp RES	
		GROUP BY 
			RES.idManifiesto,
			RES.nroManifiesto,
			RES.idClienteFinal,		
			RES.fechaDespacho,
			RES.idBodega,
			RES.nombreBodega,		
			RES.nombreClienteFinal,
			RES.idCarrier,
			RES.truckId,		
			RES.valor,
			RES.ordenVenta,
			RES.idOrdenventa,
			RES.nombreCarrier,
			RES.codigoCarrier,
			RES.EsPod,
			RES.idPaisCliente,
			RES.idPaisAlt,
			RES.idTEGuid,
			RES.esInventario
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError];
	END CATCH;
END
/*
EXEC pro_modulo_DespachoPickup NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'EMP014', 1, 3, NULL
EXEC pro_modulo_DespachoPickup NULL, NULL, NULL, NULL, NULL, '22333931453', NULL, 'EMP014', 2, 3, NULL
EXEC pro_modulo_DespachoPickup NULL, NULL, 'ALIS LUXURY BQTS CORP', NULL, NULL, NULL, NULL, 'EMP014', 1, 3, NULL
EXEC pro_modulo_DespachoPickup NULL, NULL, 'ALIS LUXURY BQTS CORP', NULL, NULL, NULL, 'LOPEZ ANDRADE MARIA ANABEL', 'EMP014', 1, 3, NULL
EXEC pro_modulo_DespachoPickup '8552', NULL, NULL, NULL, NULL, NULL, NULL, 'EMP014', 1, 3, NULL
*/
