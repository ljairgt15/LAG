/*    
VERSION       AUTOR                  FECHA            HU             CAMBIO
1			  Edwin Casa  			 10-03-2023		  39191		  	 Codigo Inicial: Procedimiento para abastraer informacion de picking para el scanner tercer nivel - timeout 90s
2			  Cristian Ponce  		 27-12-2024		  47755		  	 Eliminación filtro DISPATCHED WH en completados. 
3			  Edwin Casa  			 09-01-2025		  WMS-47592	     Se elimina el union para realizar la consulta una sola vez a las tablas transaccionales
4		      Cristian Ponce  		 16-01-2025		  47755		  	 Se agrega condición para datos de tipo de venta inventario y que el estado de la pieza sea DISPATCHED WH 
*/
ALTER     PROCEDURE [dbo].[pro_GetOutboundOrderPickingByShipTo]
(
	@idBodega VARCHAR(16),
	@idCarrier VARCHAR(16),
	@fechaDespacho DATETIME,
	@isPending BIT,
	@idClienteFinal VARCHAR(16),
	@nroManifiesto VARCHAR(32) = NULL,
	@nroPo VARCHAR(64) = NULL,
	@nroGuia VARCHAR(32) = NULL
)
AS
BEGIN
	BEGIN TRY
		DECLARE  @nombreCarrier VARCHAR(128),
			@totalPiecesByClient INT,
			@totalPiecesDispatched INT,
			@manifiestoDespacho VARCHAR(32),
			@idEmpresa VARCHAR(16),
			@idClienteConsignee VARCHAR(16),
			@valorEsDelivery VARCHAR(16),
			@actualizar VARCHAR(8) = 'NO'

		CREATE TABLE #TMP_GUIAS(
			id [UNIQUEIDENTIFIER],
			idGuiaHouse [UNIQUEIDENTIFIER],
			idClienteFinal [VARCHAR](16),
			idClienteConsignee [VARCHAR](16),
			nroGuia [VARCHAR](64),
			codigoBarra [VARCHAR](32),
			estadoPieza [VARCHAR](32),
			gate [VARCHAR](32),
			idTipoDePieza [VARCHAR](16), 
			esPOD [BIT],
			po [VARCHAR](64), 
			idProgramacionCarrier [UNIQUEIDENTIFIER],
			fechaDespacho [DATETIME],
			idCarrier [VARCHAR](16),
			idUsuarioLogPicking [VARCHAR](16),
			idBodega [VARCHAR](16),
			idEmpresa [VARCHAR](16),
			idCatalogoAccion [UNIQUEIDENTIFIER]
		)

		CREATE TABLE #GuiasHouseDetalles(
			id [UNIQUEIDENTIFIER],
			idGuiaHouse [UNIQUEIDENTIFIER],
			idClienteFinal [VARCHAR](32),
			estadoPieza [VARCHAR](32),
			esPOD [BIT],
			idTipoDePieza [VARCHAR](16), 
			fechaDespacho [DATETIME],
			idCarrier [VARCHAR](32),
			totalPieces [INT],
			piecesPicked [INT],
			barCode [VARCHAR](32),
			[location] [VARCHAR](32),
			[dock] [VARCHAR](32),
			nroManifiesto [VARCHAR](32),
			piecesManifest [INT],
			isPallet [BIT],
			nroPo [VARCHAR](64),
			idEmpresa [VARCHAR](16),
			idClienteConsignee [VARCHAR](16),
			esDelivery [BIT],
		)

		CREATE TABLE #CatalogosAccion(
			id [UNIQUEIDENTIFIER]
		)

		INSERT INTO #CatalogosAccion
		SELECT id
		FROM   Catalogos
		WHERE  codigoRelacion IN ('WAITING CUSTOMS CLEARANCE', 'WAITING INSPECTION')
				AND idEmpresa IS NULL
	
		SELECT  @nombreCarrier = nombre
		FROM  Transportes 
		WHERE ID = @idCarrier
		
		SELECT  @valorEsDelivery = PC.Valor 
		FROM ParametrosCatalogos PC
		INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.codigo = 'EsDelivery'
		WHERE PC.IdEntidad = @idCarrier
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


		INSERT INTO #TMP_GUIAS
		SELECT
			GHD.id,
			GHD.idGuiaHouse,
			GHD.idClienteFinal,
			GHD.idClienteConsignee,
			GH.nroGuia,
			ghd.codigoBarra,
			GHD.estadoPieza,
			ghd.gate,
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
		INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.ID = PC.idGuiaHouseDetalle AND  GHD.idClienteFinal = @idClienteFinal
		INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id = GHD.idGuiaHouse
		LEFT JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON SVD.idGuiaHouseDetalle = GHD.id
		LEFT JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SVD.idSolicitud = SV.id 
		WHERE  PC.idCarrier = @idCarrier 
			   AND PC.fechaDespacho = @fechaDespacho
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
			GHD.idClienteFinal,
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
			GHD.idClienteConsignee,
			CASE 
				WHEN @valorEsDelivery = 'NO' THEN 0
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
		LEFT JOIN ProgramacionManifiesto PMN WITH (NOLOCK) ON PMN.idProgramacionCarrier = ghd.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON MD.id =  PMN.idManifiestoDespacho
		WHERE (GHD.estadoPieza NOT IN ('HOLD','LOST','SHORT','STANDBY')
				OR (
						GHD.estadoPieza = 'HOLD'
						AND ghd.idCatalogoAccion IN (SELECT id FROM #CatalogosAccion)
					) 
			)
			AND GHD.esPOD <> 1
			AND ISNULL(UB1.idBodega, GHD.idBodega) =  @idBodega
			AND (@nroGuia IS NULL OR GHD.nroGuia = @nroGuia)
			AND (@nroManifiesto IS NULL OR MD.nroManifiesto = @nroManifiesto)
			AND (@nroPo IS NULL OR GHD.po = @nroPo)

		SELECT TOP 1 @idEmpresa = ghd.idEmpresa, 
					 @idClienteConsignee = ghd.idClienteConsignee
		FROM #GuiasHouseDetalles ghd
			
		SELECT @manifiestoDespacho = pc.valor
		FROM ParametrosLista AS pl WITH (NOLOCK)
		JOIN ParametrosCatalogos AS pc WITH (NOLOCK) ON pc.idParametroLista = pl.id
		WHERE pl.codigo = 'TipoManifiestoDespacho' 
			  AND pc.idEntidad = @idClienteFinal
			  AND pl.idEmpresa = @idEmpresa
		
		SELECT 
			G.idClienteFinal,
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
				G.idClienteFinal,
				COUNT(G.idClienteFinal) AS total, 
				SUM(G.piecesManifest) AS hasManifest, 
				SUM(IIF(G.estadoPieza = 'DISPATCHED WH',1,0)) totalDispatched,
				SUM(G.piecesPicked) AS picked,
				G.esDelivery,
				G.nroManifiesto
			FROM #GuiasHouseDetalles G
			GROUP BY G.idClienteFinal, 
				G.esDelivery,
				G.nroManifiesto
		) G
	
		IF @valorEsDelivery = 'NO'
		BEGIN
			
			IF (SELECT TOP 1 'SI' FROM #GroupData WHERE picked = total) = 'SI'
			BEGIN
				UPDATE #GuiasHouseDetalles
				SET piecesManifest = 1
				WHERE nroManifiesto = ''
					AND piecesPicked <> 0 
			END 
		END 
	
		IF @isPending = 1
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
					( @nroPo IS NULL AND @manifiestoDespacho = 'PO' AND  GHD.nroPo = '' )
					OR ( @nroPo IS NULL AND (@manifiestoDespacho != 'PO' OR @manifiestoDespacho IS NULL) )
				)
				OR GHD.nroPo = @nroPo 
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
				@totalPiecesByClient =COUNT(1),
				@totalPiecesDispatched = SUM(IIF(estadoPieza = 'DISPATCHED WH',1,0)) 
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
				AND @totalPiecesDispatched <> @totalPiecesByClient
		END
	
	END TRY
	BEGIN CATCH		
		EXEC [dbo].[pro_LogError] 
	END CATCH;	
	DROP TABLE #GuiasHouseDetalles
END
