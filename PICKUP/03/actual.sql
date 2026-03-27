USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[AC_pro_GetPendingPickup]    Script Date: 27/03/2026 09:19:59 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
VERSION     MODIFIEDBY			MODIFIEDDATE    HU      MODIFICATION
1           Ian Carlos Ortega	2026-01-26      57731   Based on dbo.pro_modulo_DespachoPickup
*/

ALTER   PROCEDURE [dbo].[AC_pro_GetPendingPickup]
(
	@NroDocument VARCHAR(32) = NULL,
	@Po VARCHAR(64) = NULL,
	@Consignee NVARCHAR(512) = NULL,
	@BillTo NVARCHAR(512) = NULL,
	@Status VARCHAR(32) = NULL,
	@NroManifiesto VARCHAR(32) = NULL,
	@Barcode VARCHAR(32) = NULL,
	@Supplier NVARCHAR(512) = NULL,
	@IdEmpresa VARCHAR(16),
	@Consulta INT,
	@FechaDesde INT,
	@PalletLabel VARCHAR(16) = NULL
)
AS
BEGIN
	BEGIN TRY
		DECLARE @FechaDespaho DATETIME = DATEADD(MM, -@FechaDesde, GETDATE()),
			@IdParametroDelivery VARCHAR(16),
			@IdParametroTipo VARCHAR(16)

		CREATE TABLE #TablaAgrupacionGuiasPickUp
		(
			idManifiesto UNIQUEIDENTIFIER,
			nroManifiesto VARCHAR(32),
			ShipToName VARCHAR(512),
			ShipToId VARCHAR(32),
			idBodega VARCHAR(32),
			nombreBodega VARCHAR(512),
			idCarrier VARCHAR(32),
			truckId VARCHAR(16),
			fechaDespacho DATETIME,
			valor VARCHAR(1024),
			totalPiezas INT,
			totalDespachado INT,
			totalStandBy INT,
			totalHold INT,
			totalPending INT,
			totalRecibido INT,
			totalShort INT,
			EsPod BIT NOT NULL DEFAULT 0,
			ordenVenta VARCHAR(16) NULL,
			totalPicking INT,
			idOrdenVenta UNIQUEIDENTIFIER,
			nombreCarrier VARCHAR(512),
			codigoCarrier VARCHAR(32),
			totalPickingLoading INT,
			idPaisCliente VARCHAR(16),
			idPaisAlt VARCHAR(16),
			idTEGuid UNIQUEIDENTIFIER NULL,
			esInventario BIT
		);

		SELECT @IdParametroDelivery = id
		FROM ParametrosLista PRL WITH (NOLOCK)
		WHERE PRL.codigo = 'EsDelivery'
			AND PRL.idEmpresa = @IdEmpresa;

		SELECT @IdParametroTipo = id
		FROM ParametrosLista PRL WITH (NOLOCK)
		WHERE PRL.codigo = 'TipoManifiestoDespacho'
			AND PRL.idEmpresa = @IdEmpresa;

		SELECT CRS.idEntidad, CRS.codigo
		INTO #TMP_CodigosRelacionSistemas
		FROM CodigosRelacionSistemas CRS WITH (NOLOCK)
		WHERE CRS.tipoEntidad = 'CARRIER'
			AND CRS.idSistemaEntidad = 100;

		SELECT
			PC.id,
			TR.id idCarrier,
			PC.fechaDespacho,
			TR.nombre nombreTransporte,
			GHD.id idGuiaHouseDetalle,
			GHD.idGuiaHouse,
			GHD.idPoDetalle,
			GHD.codigoBarra,
			GHD.estadoPieza,
			GHD.ShipToId,
			GHD.truckId,
			GHD.despachadoDestino,
			PC.idUsuarioLogPicking,
			TE.idTE
		INTO #TMP_PROGRAM
		FROM ProgramacionCarrier PC WITH (NOLOCK)
			INNER JOIN Transportes TR WITH (NOLOCK) ON PC.idCarrier = TR.id
			INNER JOIN ParametrosCatalogos PR WITH (NOLOCK) ON TR.idTransportePrincipal = PR.idEntidad 
				AND PR.idParametroLista = @IdParametroDelivery 
				AND PR.valor = 'NO'
			INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GHD.id = PC.idGuiaHouseDetalle
			LEFT JOIN ProgramacionTe TE WITH (NOLOCK) ON PC.id = TE.idProgramacionCarrier
		WHERE PC.fechaDespacho > @FechaDespaho
			AND (@Po IS NULL OR GHD.po LIKE @Po + '%')

		CREATE TABLE #TMP_BillToByName (
			id VARCHAR(16),
		);

		CREATE TABLE #TMP_ConsigneeByName (
			id VARCHAR(16)
		);

		IF @BillTo IS NOT NULL
		BEGIN
			INSERT INTO #TMP_BillToByName
			SELECT Id
			FROM f_SearchEntities(@billTo, 'BillTo') 
		END

		IF @Consignee IS NOT NULL
		BEGIN
			INSERT INTO #TMP_ConsigneeByName
			SELECT Id
			FROM f_SearchEntities(@Consignee, 'Consignee') 
		END

		IF (@NroDocument IS NULL AND @Po IS NULL AND @Consignee IS NULL AND @NroManifiesto IS NULL AND @Supplier IS NULL AND @Barcode IS NULL AND @PalletLabel IS NULL)
		BEGIN
			INSERT INTO #TablaAgrupacionGuiasPickUp
			SELECT
				MAD.id,
				MAD.nroManifiesto,
				VCE.nombre as ShipToName,
				PRO.ShipToId,
				ISNULL(ub.idBodega, H.idBodega) idBodega,
				ISNULL(BP.nombre, BG.nombre) nombreBodega,
				PRO.idCarrier,
				PRO.truckId,
				PRO.fechaDespacho,
				PRC.valor,
				COUNT(PRO.estadoPieza),
				SUM(IIF(PRO.estadoPieza = 'DISPATCHED WH', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'STANDBY', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'HOLD', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'PENDING', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'RECEIVED WH', 1, 0)),
				SUM(IIF(PRO.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),
				ISNULL(DCD.esPOD, 0),
				SVC.nroOrden,
				SUM(IIF(SVC.picking = 1, 1, 0)),
				SVC.id,
				PRO.nombreTransporte,
				T1.codigo,
				SUM(IIF(PRO.idUsuarioLogPicking IS NOT NULL, 1, 0)) totalPickingLoading,
				PAI.id idPaisCliente,
				P.id idPaisAlt,
				PRO.idTE idTEGuid,
				CASE
					WHEN SVC.tipoVenta < 4 THEN 1
					WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
					ELSE 0
				END esInventario
			FROM #TMP_PROGRAM PRO
				INNER JOIN #TMP_CodigosRelacionSistemas T1 ON PRO.idCarrier = T1.idEntidad
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON PRO.idGuiaHouse = GH.id
				INNER JOIN v_ClientsEntities VCE WITH (NOLOCK) ON VCE.id = PRO.ShipToId
				INNER JOIN dbo.Paises P ON VCE.idPais = P.id
				CROSS APPLY
				(
					SELECT G.ConsigneeId, idBodega
					FROM GuiasHouse G WITH (NOLOCK)
					WHERE PRO.idGuiaHouse = G.id
				) H
				LEFT JOIN ParametrosCatalogos PRC WITH (NOLOCK) ON PRC.idEntidad = H.ConsigneeId 
					AND PRC.idParametroLista = @IdParametroTipo
				LEFT JOIN ProgramacionManifiesto PRM WITH (NOLOCK) ON PRO.id = PRM.idProgramacionCarrier
				LEFT JOIN ManifiestosDespacho MAD WITH (NOLOCK) ON PRM.idManifiestoDespacho = MAD.id
				OUTER APPLY (
					SELECT TOP 1 DD.EsPod
					FROM DocumentosDespacho DD WITH (NOLOCK)
					WHERE DD.idManifiesto = MAD.id
					AND DD.idDocumento = 'DOC052395'
					ORDER BY EsPod DESC
				) DCD
				LEFT JOIN UbicacionPiezas UBP WITH (NOLOCK) ON PRO.idGuiaHouseDetalle = UBP.idGuiaHouseDetalle
				LEFT JOIN Ubicaciones U WITH (NOLOCK) ON UBP.idUbicacion = U.id
				LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON U.idUbicacionBodega = UB.id
				LEFT JOIN Bodegas BG WITH (NOLOCK) ON H.idBodega = BG.id
				LEFT JOIN Bodegas BP WITH (NOLOCK) ON UB.idBodega = BP.id
				LEFT JOIN
				(
					SELECT
						PRO.idGuiaHouseDetalle,
						SV.id,
						SV.nroOrden,
						SVD.picking,
						SV.fechaSolicitud,
						ROW_NUMBER() OVER (PARTITION BY PRO.idGuiaHouseDetalle ORDER BY SV.fechaSolicitud DESC) rown,
						SV.tipoVenta,
						SVD.tipoPieza
					FROM #TMP_PROGRAM PRO
					INNER JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON PRO.idGuiaHouseDetalle = SVD.idGuiaHouseDetalle
					INNER JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud
				) SVC ON PRO.idGuiaHouseDetalle = SVC.idGuiaHouseDetalle AND SVC.rown = 1
				LEFT JOIN Paises PAI ON VCE.idPais = PAI.id
			WHERE @IdEmpresa IS NULL OR GH.idEmpresa = @IdEmpresa
			GROUP BY
				MAD.id,
				MAD.nroManifiesto,
				VCE.nombre,
				PRO.ShipToId,
				ISNULL(UB.idBodega, H.idBodega),
				ISNULL(BP.nombre, BG.nombre),
				PRO.idCarrier,
				PRO.truckId,
				PRO.fechaDespacho,
				PRC.valor,
				DCD.esPOD,
				SVC.nroOrden,
				SVC.id,
				PRO.nombreTransporte,
				T1.codigo,
				PRO.despachadoDestino,
				PRO.idUsuarioLogPicking,
				PAI.id,
				P.id,
				PRO.idTE,
				CASE
					WHEN SVC.tipoVenta < 4 THEN 1
					WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
					ELSE 0
				END;
		END
		ELSE
		BEGIN
			INSERT INTO #TablaAgrupacionGuiasPickUp
			SELECT
				MAD.id,
				MAD.nroManifiesto,
				VCE.nombre AS ShipToName,
				PRO.ShipToId ShipToId,
				ISNULL(UB.idBodega, H.idBodega) idBodega,
				ISNULL(BP.nombre, BG.nombre) nombreBodega,
				PRO.idCarrier,
				PRO.truckId,
				PRO.fechaDespacho,
				PRC.valor,
				COUNT(PRO.estadoPieza),
				SUM(IIF(PRO.estadoPieza = 'DISPATCHED WH', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'STANDBY', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'HOLD', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'PENDING', 1, 0)),
				SUM(IIF(PRO.estadoPieza = 'RECEIVED WH', 1, 0)),
				SUM(IIF(PRO.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),
				ISNULL(DCD.esPOD, 0),
				SVC.nroOrden,
				SUM(IIF(SVC.picking = 1, 1, 0)),
				SVC.id,
				PRO.nombreTransporte,
				T1.codigo,
				SUM(IIF(PRO.idUsuarioLogPicking IS NOT NULL, 1, 0)) totalPickingLoading,
				PAI.id idPaisCliente,
				P.id idPaisAlt,
				PRO.idTE idTEGuid,
				CASE
					WHEN SVC.tipoVenta < 4 THEN 1
					WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
					ELSE 0
				END esInventario
			FROM #TMP_PROGRAM PRO
				INNER JOIN #TMP_CodigosRelacionSistemas T1 ON PRO.idCarrier = T1.idEntidad
				INNER JOIN GuiasHouse GH WITH (NOLOCK) ON PRO.idGuiaHouse = GH.id
				INNER JOIN v_ClientsEntities VCE WITH (NOLOCK) ON VCE.id = PRO.ShipToId
				INNER JOIN dbo.Paises P ON VCE.idPais = P.id
				CROSS APPLY
				(
					SELECT G.ConsigneeId, G.BillToConsigneeId, idBodega, idExportador, nroGuia
					FROM GuiasHouse G WITH (NOLOCK)
					WHERE PRO.idGuiaHouse = G.id
				) H
				LEFT JOIN dbo.PalletsDetalles PLD WITH (NOLOCK) ON PRO.idGuiaHouseDetalle = PLD.idGuiasHouseDetalle
				LEFT JOIN dbo.Pallets PAL WITH (NOLOCK) ON PLD.idPallet = PAL.id
				LEFT JOIN ParametrosCatalogos PRC WITH (NOLOCK) ON PRC.idEntidad = H.ConsigneeId AND PRC.idParametroLista = @IdParametroTipo
				LEFT JOIN ProgramacionManifiesto PRM WITH (NOLOCK) ON PRO.id = PRM.idProgramacionCarrier
				LEFT JOIN manifiestosDespacho MAD WITH (NOLOCK) ON PRM.idManifiestoDespacho = MAD.id
				OUTER APPLY (
					SELECT TOP 1 DD.EsPod
					FROM DocumentosDespacho DD WITH (NOLOCK)
					WHERE DD.idManifiesto = MAD.id
					AND DD.idDocumento = 'DOC052395'
					ORDER BY EsPod DESC
				) DCD
				LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON PRO.idGuiaHouseDetalle = UP.idGuiaHouseDetalle
				LEFT JOIN Ubicaciones U WITH (NOLOCK) ON UP.idUbicacion = U.id
				LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON U.idUbicacionBodega = UB.id
				LEFT JOIN Bodegas BG WITH (NOLOCK) ON H.idBodega = BG.id
				LEFT JOIN Bodegas BP WITH (NOLOCK) ON UB.idBodega = BP.id
				LEFT JOIN
				(
					SELECT
						PRO.idGuiaHouseDetalle,
						SV.id,
						SV.nroOrden,
						SVD.picking,
						SV.fechaSolicitud,
						ROW_NUMBER() OVER (PARTITION BY PRO.idGuiaHouseDetalle ORDER BY solicitud.fechaSolicitud DESC) AS rown,
						SV.tipoVenta,
						tipoPieza
					FROM #TMP_PROGRAM PRO
					INNER JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON PRO.idGuiaHouseDetalle = SVD.idGuiaHouseDetalle
					INNER JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud
				) svc ON PRO.idGuiaHouseDetalle = SVC.idGuiaHouseDetalle AND SVC.rown = 1
				LEFT JOIN dbo.Paises PAI ON VCE.idPais = PAI.id
			WHERE (@IdEmpresa IS NULL OR GH.idEmpresa = @IdEmpresa)
				AND (@Barcode IS NULL OR PRO.codigoBarra LIKE '%' + @Barcode + '%')
				AND (@NroDocument IS NULL OR H.nroGuia LIKE '%' + @NroDocument + '%')
				AND (@Consignee IS NULL OR (EXISTS(SELECT 1 FROM #TMP_ConsigneeByName) AND H.ConsigneeId IN (SELECT id FROM #TMP_ConsigneeByName)))
				AND (@BillTo IS NULL OR (EXISTS(SELECT 1 FROM #TMP_BillToByName) AND H.BillToConsigneeId IN (SELECT id FROM #TMP_BillToByName)))
				AND (@Supplier IS NULL OR H.idExportador IN (SELECT id FROM Exportadores WITH (NOLOCK) WHERE nombre LIKE '%' + @Supplier + '%'))
				AND (@PalletLabel IS NULL OR PAL.pallet LIKE '%' + @PalletLabel + '%')
				AND (@NroManifiesto IS NULL OR MAD.nroManifiesto LIKE '%' + @NroManifiesto + '%')
			GROUP BY
				MAD.id,
				MAD.nroManifiesto,
				VCE.nombre,
				PRO.ShipToId,
				ISNULL(UB.idBodega, H.idBodega),
				ISNULL(BP.nombre, BG.nombre),
				PRO.idCarrier,
				PRO.truckId,
				PRO.fechaDespacho,
				PRC.valor,
				DCD.esPOD,
				SVC.nroOrden,
				SVC.id,
				PRO.nombreTransporte,
				T1.codigo,
				PRO.idUsuarioLogPicking,
				PAI.id,
				P.id,
				PRO.idTE,
				CASE
					WHEN SVC.tipoVenta < 4 THEN 1
					WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
					ELSE 0
				END;
		END

		SELECT
			NEWID() id,
			guiasAgrupado.idManifiesto,
			guiasAgrupado.nroManifiesto,
			guiasAgrupado.ShipToId,
			guiasAgrupado.fechaDespacho,
			guiasAgrupado.idBodega,
			guiasAgrupado.nombreBodega,
			guiasAgrupado.ShipToName,
			guiasAgrupado.idCarrier,
			guiasAgrupado.truckId,
			guiasAgrupado.valor,
			SUM(guiasAgrupado.totalPiezas) TotalPiezas,
			SUM(guiasAgrupado.totalDespachado) TotalDespachado,
			SUM(guiasAgrupado.totalStandBy) TotalStandBy,
			SUM(guiasAgrupado.totalHold) TotalHold,
			SUM(guiasAgrupado.totalPending) TotalPending,
			SUM(guiasAgrupado.totalRecibido) TotalRecibido,
			SUM(guiasAgrupado.totalShort) TotalShort,
			guiasAgrupado.EsPod,
			NULL mailEnviado,
			NULL tipoNubeDocs,
			NULL modificado,
			ordenVenta,
			SUM(guiasAgrupado.totalPicking) TotalPicking,
			idOrdenVenta,
			guiasAgrupado.nombreCarrier,
			guiasAgrupado.codigoCarrier,
			NULL validarDiferenciaPiezas,
			SUM(guiasAgrupado.totalPickingLoading) TotalPickingLoading,
			guiasAgrupado.idPaisCliente,
			guiasAgrupado.idPaisAlt,
			guiasAgrupado.idTEGuid,
			guiasAgrupado.esInventario
		FROM #TablaAgrupacionGuiasPickUp guiasAgrupado
		GROUP BY
			guiasAgrupado.idManifiesto,
			guiasAgrupado.nroManifiesto,
			guiasAgrupado.ShipToId,
			guiasAgrupado.fechaDespacho,
			guiasAgrupado.idBodega,
			guiasAgrupado.nombreBodega,
			guiasAgrupado.ShipToName,
			guiasAgrupado.idCarrier,
			guiasAgrupado.truckId,
			guiasAgrupado.valor,
			guiasAgrupado.ordenVenta,
			guiasAgrupado.idOrdenventa,
			guiasAgrupado.nombreCarrier,
			guiasAgrupado.codigoCarrier,
			guiasAgrupado.EsPod,
			guiasAgrupado.idPaisCliente,
			guiasAgrupado.idPaisAlt,
			guiasAgrupado.idTEGuid,
			guiasAgrupado.esInventario
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError];
	END CATCH;
END
