/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-04-29		  58788			 Based on pro_GetOutboundOrderPickingByCarrier
*/
ALTER     PROCEDURE [dbo].[Ac_pro_GetOutboundOrderPickingByCarrier]
(
	@idBodega VARCHAR(16),
	@idCarrier VARCHAR(16),
	@fechaDespacho DATETIME,
	@idEmpresa VARCHAR(16),
	@isPending BIT
)
AS
BEGIN
	BEGIN TRY
		DECLARE @tipoPorDefecto VARCHAR(32),
				@codigoTipoPorDefecto VARCHAR(64) = 'DefaultManifestType',
				@valorEsDelivery VARCHAR(16)

		CREATE TABLE #TMP_GUIAS(
			id [UNIQUEIDENTIFIER],
			idGuiaHouse [UNIQUEIDENTIFIER],
			idClienteFinal [VARCHAR](16),
			idCliente [VARCHAR](16),
			nroGuia [VARCHAR](64),
			estadoPieza [VARCHAR](32),
			idTipoDePieza [VARCHAR](16), 
			esPOD [BIT],
			po [VARCHAR](64), 
			idProgramacionCarrier [UNIQUEIDENTIFIER],
			fechaDespacho [DATETIME],
			idCarrier [VARCHAR](16),
			idUsuarioLogPicking [VARCHAR](16),
			idBodega [VARCHAR](16),
			idCatalogoAccion [UNIQUEIDENTIFIER]
		)

		CREATE TABLE #CatalogosAccion(
			id [UNIQUEIDENTIFIER]
		)

		INSERT INTO #TMP_GUIAS
		SELECT
			GHD.id,
			GHD.idGuiaHouse,
			GHD.idClienteFinal,
			GH.idCliente,
			gh.nroGuia,
			GHD.estadoPieza,
			GHD.idTipoDePieza,
			GHD.esPOD,
			GHD.po,
			PC.id AS idProgramacionCarrier,
			PC.fechaDespacho,
			PC.idCarrier,
			ISNULL(IIF(SVD.picking = 1, '1', NULL), PC.idUsuarioLogPicking) AS idUsuarioLogPicking,
			GH.idBodega,
			GHD.idCatalogoAccion
		FROM ProgramacionCarrier PC  WITH (NOLOCK)		
		INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.ID = PC.idGuiaHouseDetalle
		INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id = GHD.idGuiaHouse
		LEFT JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON SVD.idGuiaHouseDetalle = GHD.id
		LEFT JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SVD.idSolicitud = SV.id 
		WHERE PC.idCarrier = @idCarrier 
			AND PC.fechaDespacho = @fechaDespacho
			AND GH.idEmpresa = @idEmpresa
			AND CASE 
				WHEN SVD.id IS NULL THEN 1
				WHEN SV.tipoVenta = 4 THEN 1
				WHEN SV.tipoVenta IN (1,2,3) AND SVD.picking = 1 THEN 1
				WHEN SV.tipoVenta IN (1,2,3) AND GHD.estadoPieza = 'DISPATCHED WH'  THEN 1 
				WHEN SV.tipoVenta = 5  AND SVD.tipoPieza = 2 THEN 1
				WHEN SV.tipoVenta = 5  AND SVD.tipoPieza = 1  AND SVD.picking = 1 THEN 1
				WHEN SV.tipoVenta = 5  AND SVD.tipoPieza = 1  AND GHD.estadoPieza = 'DISPATCHED WH' THEN 1
				ELSE 0 
			END  = 1
		
		SELECT  @valorEsDelivery = PC.Valor 
		FROM  ParametrosCatalogos PC
		INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.codigo = 'EsDelivery'
		WHERE  PC.IdEntidad = @idCarrier
			AND PC.valor = 'NO'
			AND PL.Actor IN ('CARRIER', 'TERRESTRE')

		IF @valorEsDelivery IS NULL
		BEGIN
			SELECT @valorEsDelivery = PC.Valor
			FROM  Transportes T
			INNER JOIN ParametrosCatalogos PC ON T.idTransportePrincipal = PC.IdEntidad
			INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.codigo = 'EsDelivery'
			WHERE  T.id = @idCarrier
				AND PC.valor = 'NO'
				AND PL.Actor IN ('CARRIER', 'TERRESTRE')
		END 

		SELECT 
			GHD.id,
			GHD.idGuiaHouse,
			GHD.idCliente AS idClienteConsignee,
			GHD.idClienteFinal,
			GHD.estadoPieza,
			GHD.esPOD,
			GHD.idTipoDePieza, 
			GHD.fechaDespacho,
			GHD.idCarrier,
			PMN.nota,
			1 AS totalPieces,
			CASE
				WHEN GHD.idUsuarioLogPicking IS NOT NULL
				THEN 1
				WHEN GHD.estadoPieza = 'DISPATCHED WH'
				THEN 1
			ELSE 0 END AS piecesPicked,
			ISNULL(MD.nroManifiesto, '') AS nroManifiesto,
			CASE
				WHEN PMN.id IS NOT NULL 
					AND PMN.nota = 'Escaner Picking'
				THEN 1
				ELSE 0
			END AS piecesManifest,
			ISNULL(GHD.po, '') AS po,
			ISNULL(GHD.nroGuia, '') AS nroGuia,
			CASE 
				WHEN @valorEsDelivery = 'NO' THEN 0
				ELSE 1 
			END AS esDelivery
		FROM #TMP_GUIAS GHD WITH (NOLOCK)
		LEFT JOIN UbicacionPiezas UP  WITH (NOLOCK) ON UP.idGuiaHouseDetalle =  GHD.id
		LEFT JOIN Ubicaciones U ON U.ID = UP.idUbicacion
		LEFT JOIN UbicacionesBodega UB  ON UB.id = U.idUbicacionBodega
		LEFT JOIN ProgramacionManifiesto PMN WITH (NOLOCK) ON PMN.idProgramacionCarrier = GHD.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON MD.id =  PMN.idManifiestoDespacho
		WHERE (GHD.estadoPieza NOT IN ('HOLD','LOST','SHORT','STANDBY')
				OR (
						GHD.estadoPieza = 'HOLD'
						AND ghd.idCatalogoAccion IN (SELECT id FROM #CatalogosAccion)
					) 
			)
			AND GHD.esPOD <> 1
			AND ISNULL(UB.idBodega, GHD.idBodega) =  @idBodega	
	END TRY
	BEGIN CATCH		
		EXEC [dbo].[pro_LogError] 
	END CATCH;	
END
