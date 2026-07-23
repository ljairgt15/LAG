/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-07-25		  58788			 Based on pro_GetOutboundOrderPickingByShipTo
*/
CREATE OR ALTER PROCEDURE [dbo].[Ac_pro_GetOutboundOrderPickingByShipTo]
(
	@IdBodega VARCHAR(16),
	@IdCarrier VARCHAR(16),
	@FechaDespacho DATETIME,
	@IsPending BIT,
	@IdClienteFinal VARCHAR(16),
	@BillToConsigneeId VARCHAR(16),
	@NroManifiesto VARCHAR(32) = NULL,
	@NroPo VARCHAR(64) = NULL,
	@NroGuia VARCHAR(32) = NULL
)
AS
BEGIN
	BEGIN TRY
		DECLARE  @NombreCarrier VARCHAR(128),
			@TotalPiecesByClient INT,
			@TotalPiecesDispatched INT,
			@ManifiestoDespacho VARCHAR(32),
			@IdEmpresa VARCHAR(16),
			@IdClienteConsignee VARCHAR(16),
			@ValorEsDelivery VARCHAR(16),
			@BillToId VARCHAR(16),
			@Actualizar VARCHAR(8) = 'NO'

		CREATE TABLE #TMP_GUIAS(
			Id [UNIQUEIDENTIFIER],
			IdGuiaHouse [UNIQUEIDENTIFIER],
			ShipToId [VARCHAR](16),
			ConsigneeId [VARCHAR](16),
			NroGuia [VARCHAR](64),
			CodigoBarra [VARCHAR](32),
			EstadoPieza [VARCHAR](32),
			Gate [VARCHAR](32),
			IdTipoDePieza [VARCHAR](16), 
			EsPOD [BIT],
			Po [VARCHAR](64), 
			IdProgramacionCarrier [UNIQUEIDENTIFIER],
			FechaDespacho [DATETIME],
			IdCarrier [VARCHAR](16),
			IdUsuarioLogPicking [VARCHAR](16),
			IdBodega [VARCHAR](16),
			IdEmpresa [VARCHAR](16),
			IdCatalogoAccion [UNIQUEIDENTIFIER]
		)

		CREATE TABLE #GuiasHouseDetalles(
			Id [UNIQUEIDENTIFIER],
			IdGuiaHouse [UNIQUEIDENTIFIER],
			ShipToId [VARCHAR](16),
			EstadoPieza [VARCHAR](32),
			EsPOD [BIT],
			IdTipoDePieza [VARCHAR](16), 
			FechaDespacho [DATETIME],
			IdCarrier [VARCHAR](32),
			TotalPieces [INT],
			PiecesPicked [INT],
			BarCode [VARCHAR](32),
			[Location] [VARCHAR](32),
			[Dock] [VARCHAR](32),
			NroManifiesto [VARCHAR](32),
			PiecesManifest [INT],
			IsPallet [BIT],
			NroPo [VARCHAR](64),
			IdEmpresa [VARCHAR](16),
			ConsigneeId [VARCHAR](16),
			EsDelivery [BIT],
		)

		CREATE TABLE #CatalogosAccion(
			Id [UNIQUEIDENTIFIER]
		)
		
		INSERT INTO #CatalogosAccion
		SELECT id
		FROM   Catalogos
		WHERE  codigoRelacion IN ('WAITING CUSTOMS CLEARANCE', 'WAITING INSPECTION')
				AND idEmpresa IS NULL
	
		SELECT  @NombreCarrier = nombre
		FROM  Transportes 
		WHERE ID = @IdCarrier
		
		SELECT  @ValorEsDelivery = PC.Valor 
		FROM ParametrosCatalogos PC
		INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.codigo = 'EsDelivery'
		WHERE PC.IdEntidad = @IdCarrier
			AND PC.valor = 'NO'
			AND PL.Actor IN ('CARRIER', 'TERRESTRE')

		IF @ValorEsDelivery IS NULL
		BEGIN
			SELECT @ValorEsDelivery = PC.Valor
			FROM  Transportes T
			INNER JOIN ParametrosCatalogos PC ON T.idTransportePrincipal = PC.IdEntidad
			INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.codigo = 'EsDelivery'
			WHERE  T.id = @IdCarrier
				AND PC.valor = 'NO'
				AND PL.Actor IN ('CARRIER', 'TERRESTRE')
		END 


		INSERT INTO #TMP_GUIAS
		SELECT
			GHD.id,
			GHD.idGuiaHouse,
			GHD.ShipToId,
			GH.ConsigneeId,
			GH.nroGuia,
			GHD.codigoBarra,
			GHD.estadoPieza,
			GHD.gate,
			GHD.idTipoDePieza,
			GHD.esPOD,
			GHD.po,
			PC.id AS idProgramacionCarrier,
			PC.fechaDespacho,
			PC.idCarrier,
			ISNULL(IIF(SVD.picking = 1, '1', NULL), PC.idUsuarioLogPicking) AS idUsuarioLogPicking,
			GH.idBodega,
			GH.idEmpresa,
			GHD.idCatalogoAccion
		FROM ProgramacionCarrier PC  WITH (NOLOCK)		
		INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.ID = PC.idGuiaHouseDetalle AND  GHD.ShipToId = @IdClienteFinal
		INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id = GHD.idGuiaHouse
		LEFT JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON SVD.idGuiaHouseDetalle = GHD.id
		LEFT JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SVD.idSolicitud = SV.id 
		WHERE  PC.idCarrier = @IdCarrier 
			   AND PC.fechaDespacho = @FechaDespacho
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
		  
		INSERT INTO #GuiasHouseDetalles
		SELECT 
			GHD.id,
			GHD.idGuiaHouse,
			GHD.ShipToId,
			GHD.estadoPieza,
			GHD.esPOD,
			GHD.idTipoDePieza, 
			GHD.fechaDespacho,
			GHD.idCarrier,
			1 AS totalPieces,
			CASE
				WHEN GHD.idUsuarioLogPicking IS NOT NULL
					THEN 1
				WHEN GHD.estadoPieza = 'DISPATCHED WH'
					THEN 1
				ELSE 0 
			END AS picking,
			ISNULL(PL.pallet, GHD.codigoBarra) AS barCode,
			CASE
				WHEN GHD.estadoPieza = 'RECEIVED WH'
					THEN ISNULL(U.codigo, U1.codigo)
				WHEN GHD.estadoPieza = 'DISPATCHED WH' AND PMN.id IS NOT NULL AND PMN.nota <> 'Escaner Picking'
					THEN ISNULL(U.codigo, U1.codigo)
				WHEN GHD.estadoPieza = 'DISPATCHED WH' AND U.codigo IS NULL AND U1.codigo IS NULL
					THEN GHD.nroGuia
				WHEN GHD.estadoPieza = 'DISPATCHED WH' AND PL.ID IS NOT NULL 
					THEN ISNULL(U.codigo, '')
				WHEN GHD.estadoPieza = 'DISPATCHED WH' AND ISNULL(U.codigo, U1.codigo) IS NOT NULL
					THEN ISNULL(U.codigo, U1.codigo)
				WHEN GHD.estadoPieza = 'HOLD' AND (U.codigo IS NOT NULL OR U1.codigo IS NOT NULL)
					THEN ISNULL(U.codigo, U1.codigo)
				ELSE GHD.nroGuia 
			END AS [location],
			ISNULL(ED.puerta, GHD.gate) AS dock,
			ISNULL(MD.nroManifiesto, ''),
			CASE
				WHEN PMN.id IS NOT NULL AND PMN.nota = 'Escaner Picking'
					THEN 1
				ELSE 0
			END AS piecesManifest,
			IIF(PL.pallet IS NULL, 0, 1) AS isPallet,
			ISNULL(GHD.po, ''),
			GHD.idEmpresa,
			GHD.ConsigneeId,
			CASE 
				WHEN @ValorEsDelivery = 'NO' THEN 0
				ELSE 1 
			END AS esDelivery
		FROM #TMP_GUIAS GHD 
		LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON UP.idGuiaHouseDetalle = GHD.id 
		LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON PLD.idGuiasHouseDetalle = GHD.id
		LEFT JOIN Pallets PL WITH (NOLOCK) ON PL.id = PLD.idPallet
		LEFT JOIN Ubicaciones U ON U.ID =  PL.idUbicacion
		LEFT JOIN Ubicaciones U1 ON U1.ID =  UP.idUbicacion
		LEFT JOIN UbicacionesBodega UB1 ON UB1.id = U1.idUbicacionBodega
		LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON GHD.[id] = DD.idGuiaHouseDetalle
		LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
		LEFT JOIN ProgramacionManifiesto PMN WITH (NOLOCK) ON PMN.idProgramacionCarrier = GHD.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON MD.id =  PMN.idManifiestoDespacho
		WHERE (GHD.estadoPieza NOT IN ('HOLD','LOST','SHORT','STANDBY')
				OR (
						GHD.estadoPieza = 'HOLD'
						AND GHD.idCatalogoAccion IN (SELECT id FROM #CatalogosAccion)
					) 
			)
			AND GHD.esPOD <> 1
			AND ISNULL(UB1.idBodega, GHD.idBodega) =  @IdBodega
			AND (@NroGuia IS NULL OR GHD.nroGuia = @NroGuia)
			AND (@NroManifiesto IS NULL OR MD.nroManifiesto = @NroManifiesto)
			AND (@NroPo IS NULL OR GHD.po = @NroPo)

		SELECT TOP 1 @IdEmpresa = GHD.idEmpresa 
		FROM #GuiasHouseDetalles GHD
		

		SELECT TOP 1 @BillToId = ER.EntityTypeId
		FROM EntityRelations ER WITH (NOLOCK)
		WHERE ER.Id = @BillToConsigneeId
		
		SELECT TOP 1 @ManifiestoDespacho = pc.valor
		FROM ParametrosLista AS pl WITH (NOLOCK)
		JOIN ParametrosCatalogos AS pc WITH (NOLOCK) ON pc.idParametroLista = pl.id
		WHERE pl.codigo = 'TipoManifiestoDespacho'
			AND pl.idEmpresa = @IdEmpresa
			AND pc.idEntidad IN (@BillToConsigneeId, @BillToId)
			AND LTRIM(RTRIM(ISNULL(pc.valor,''))) <> ''
		ORDER BY CASE WHEN pc.idEntidad = @BillToConsigneeId THEN 0 ELSE 1 END
		
		SELECT 
			G.ShipToId,
			G.nroManifiesto,
			G.total,
			G.picked,
			G.totalDispatched,
			G.esDelivery,
			CASE 
				WHEN G.esDelivery  = 0 
					AND G.picked = G.total 
					AND  G.nroManifiesto = ''
				THEN G.picked
				ELSE G.hasManifest 
			END AS hasManifest
		INTO #GroupData
		FROM (
			SELECT 
				G.ShipToId,
				COUNT(G.ShipToId) AS total, 
				SUM(G.piecesManifest) AS hasManifest, 
				SUM(IIF(G.estadoPieza = 'DISPATCHED WH',1,0)) totalDispatched,
				SUM(G.piecesPicked) AS picked,
				G.esDelivery,
				G.nroManifiesto
			FROM #GuiasHouseDetalles G
			GROUP BY G.ShipToId, 
				G.esDelivery,
				G.nroManifiesto
		) G
	
		IF @ValorEsDelivery = 'NO'
		BEGIN
			
			IF (SELECT TOP 1 'SI' FROM #GroupData WHERE picked = total) = 'SI'
			BEGIN
				UPDATE #GuiasHouseDetalles
				SET piecesManifest = 1
				WHERE nroManifiesto = ''
					AND piecesPicked <> 0 
			END 
		END 
	
		IF @IsPending = 1
		BEGIN
			SELECT 
			ROW_NUMBER() OVER (ORDER BY GHD.barCode) AS id, 
			barCode,
			[location],
			SUM(totalPieces) AS pieces,
			SUM(piecesPicked) AS piecesPicked,
			CONVERT(BIT,IIF(SUM(piecesPicked) > 0, 1, 0)) AS isPicked,
			dock AS dock,
			nroManifiesto,
			isPallet
			FROM #GuiasHouseDetalles GHD
			WHERE (
					( @NroPo IS NULL AND @ManifiestoDespacho = 'PO' AND  GHD.nroPo = '' )
					OR ( @NroPo IS NULL AND (@ManifiestoDespacho != 'PO' OR @ManifiestoDespacho IS NULL) )
				)
				OR GHD.nroPo = @NroPo 
			GROUP BY  barCode,
				[location],
				dock,
				nroManifiesto,
				isPallet
			HAVING  (SUM(GHD.totalPieces) > SUM(GHD.piecesPicked) 
				AND SUM(GHD.totalPieces) >= SUM(GHD.piecesManifest))
				OR (SUM(GHD.piecesPicked)  = SUM(GHD.totalPieces)
				AND SUM(GHD.piecesPicked) <> SUM(GHD.piecesManifest))
		END
		ELSE
		BEGIN 
			SELECT  
				@TotalPiecesByClient =COUNT(1),
				@TotalPiecesDispatched = SUM(IIF(estadoPieza = 'DISPATCHED WH',1,0)) 
			FROM #GuiasHouseDetalles

			;WITH TempResp AS(
				SELECT 
					GHD.barCode,
					[location],
					totalPieces,
					piecesPicked,
					dock,
					nroManifiesto,
					isPallet,
					piecesManifest
				FROM 
					#GuiasHouseDetalles GHD
			)
			SELECT 
				ROW_NUMBER() OVER (ORDER BY GHD.barCode) AS id,
				ISNULL(barCode, '') AS barCode,
				[location],
				SUM(totalPieces) AS pieces,
				SUM(piecesPicked) AS piecesPicked,
				CONVERT(BIT,IIF(SUM(piecesPicked) > 0, 1, 0)) AS isPicked,
				dock,
				nroManifiesto,
				isPallet
			FROM
				TempResp GHD
			GROUP BY 
				barCode,
				[location],
				dock,
				nroManifiesto,
				isPallet
			HAVING 
				SUM(GHD.totalPieces) = SUM(GHD.piecesPicked)
				AND SUM(GHD.totalPieces) = SUM(GHD.piecesManifest)
				AND @TotalPiecesDispatched <> @TotalPiecesByClient
		END
	
	END TRY
	BEGIN CATCH		
		EXEC [dbo].[pro_LogError] 
	END CATCH;	
	DROP TABLE #GuiasHouseDetalles
END
