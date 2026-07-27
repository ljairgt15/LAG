/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-05-25		  58788			 Based on pro_GetOutboundOrderPicking
*/
CREATE OR ALTER   PROCEDURE [dbo].[Ac_pro_GetOutboundOrderPicking]
(
	@fechaDespacho DATETIME,
	@idBodega VARCHAR(16),
	@isPending BIT,
	@idEmpresa VARCHAR(16)
)
AS
BEGIN
	BEGIN TRY	
		DECLARE @numeroDiaSemana INT,
				@idDiaSemana VARCHAR(16);

	   CREATE TABLE #TMP_GUIAS(
			Id [UNIQUEIDENTIFIER],
			IdGuiaHouse [UNIQUEIDENTIFIER],
			ShipToId [VARCHAR](16),
			EstadoPieza [VARCHAR](32),
			IdTipoDePieza [VARCHAR](16), 
			EsPOD [BIT],
			IdProgramacionCarrier [UNIQUEIDENTIFIER],
			FechaDespacho [DATETIME],
			IdCarrier [VARCHAR](16),
			IdUsuarioLogPicking [VARCHAR](16),
			IdBodega [VARCHAR](16),
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
			IdCarrier [VARCHAR](16),
			TotalPieces [INT],
			PiecesPicked [INT],
			NroManifiesto [VARCHAR](32),
			PiecesManifest [INT],
			EsDelivery [BIT]
		)
	
		CREATE TABLE #TempPickingList
		(
			Id [VARCHAR](16),
			TotalPieces [INT],
			PiecesPicked [INT],
			PiecesDispatched [INT],
			HasManifest [INT],
			NroManifiesto [VARCHAR](32)
		)
		CREATE TABLE #CatalogosAccion(
			Id [UNIQUEIDENTIFIER]
		)
	
		SELECT 
			@numeroDiaSemana = DATEPART(WEEKDAY, @fechaDespacho)
	
		IF(@numeroDiaSemana = 7)
		BEGIN
			SELECT @numeroDiaSemana = 0;
		END

		SELECT @idDiaSemana =  id
		FROM  DiasSemana 
		WHERE numero = @numeroDiaSemana

		INSERT INTO #CatalogosAccion
		SELECT id
		FROM   Catalogos
		WHERE  codigoRelacion IN ('WAITING CUSTOMS CLEARANCE', 'WAITING INSPECTION')
				AND idEmpresa IS NULL

		INSERT INTO #TMP_GUIAS
		SELECT GHD.id,
			   GHD.idGuiaHouse,
			   GHD.ShipToId,
			   GHD.estadoPieza,
			   GHD.idTipoDePieza,
			   GHD.esPOD,
			   PC.id AS idProgramacionCarrier,
			   PC.fechaDespacho,
			   PC.idCarrier,
			   ISNULL(IIF(SVD.picking = 1, '1', NULL), PC.idUsuarioLogPicking) AS idUsuarioLogPicking,
			   GH.idBodega,
			   GHD.idCatalogoAccion
		FROM   ProgramacionCarrier PC WITH (NOLOCK)
		INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON  GHD.ID = PC.idGuiaHouseDetalle
		INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.id = GHD.idGuiaHouse
		LEFT JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON SVD.idGuiaHouseDetalle = GHD.id
		LEFT JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SVD.idSolicitud = SV.id 
		WHERE  PC.fechaDespacho = @fechaDespacho
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
			ELSE 0 END AS picking,
			CASE 
				WHEN MD.nroManifiesto IS NOT NULL
				THEN MD.nroManifiesto
				ELSE '' END AS manifestNumber,
			CASE
				WHEN PM.nota = 'Escaner Picking'THEN 1
				ELSE 0
			END AS piecesManifest,
			CASE 
				WHEN PP.valor = 'NO' THEN 0
				ELSE 1 
			END AS esDelivery
		FROM #TMP_GUIAS GHD
		OUTER APPLY
		(
			SELECT PC.Valor AS valor
			FROM Transportes T
			INNER JOIN ParametrosCatalogos PC ON T.idTransportePrincipal = PC.IdEntidad
			INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.codigo = 'EsDelivery'
			WHERE T.id = GHD.idCarrier
			AND PC.valor = 'NO'
			AND PL.Actor IN ('CARRIER', 'TERRESTRE')
		) PP
		LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON UP.idGuiaHouseDetalle =  GHD.id
		LEFT JOIN Ubicaciones U WITH (NOLOCK) ON U.ID = UP.idUbicacion
		LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON UB.id = U.idUbicacionBodega
		LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PM.idProgramacionCarrier =  GHD.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON MD.id =  PM.idManifiestoDespacho
		WHERE (GHD.estadoPieza NOT IN ('HOLD','LOST','SHORT','STANDBY')
				OR (
						GHD.estadoPieza = 'HOLD'
						AND ghd.idCatalogoAccion IN (SELECT id FROM #CatalogosAccion)
					) 
			)
			AND ISNULL(UB.idBodega, GHD.idBodega) =  @idBodega	
			AND GHD.esPOD <> 1	

		SELECT 
			G.idCarrier,
			G.ShipToId,
			G.nroManifiesto,
			G.total,
			G.picked,
			G.totalDispatched,
			CASE 
				WHEN G.esDelivery  = 0 
					AND G.picked = G.total 
				THEN G.picked
				ELSE G.hasManifest END AS hasManifest
		INTO #GroupData
		FROM
		(
			SELECT 
				G.idCarrier,
				G.ShipToId,
				COUNT(1) AS total, 
				SUM(G.piecesManifest) as hasManifest, 
				SUM(IIF(G.estadoPieza = 'DISPATCHED WH',1,0)) totalDispatched,
				SUM(G.piecesPicked) AS picked,
				G.esDelivery,
				G.nroManifiesto
			FROM #GuiasHouseDetalles G
			GROUP by 
				G.idCarrier,
				G.ShipToId,
				G.esDelivery,
				G.nroManifiesto
		) G
	
		IF @isPending = 1  
		BEGIN
			INSERT INTO #TempPickingList(id, totalPieces, piecesPicked, nroManifiesto)
			SELECT
				GHD.idCarrier AS id, 
				SUM(GHD.total) AS totalPieces,
				SUM(GHD.picked) AS piecesPicked,
				GHD.nroManifiesto
			FROM #GroupData GHD
			WHERE GHD.total <> GHD.hasManifest OR GHD.total <> GHD.picked		
			GROUP BY  GHD.idCarrier, 
				GHD.nroManifiesto
		
			SELECT 
				ROW_NUMBER() OVER (ORDER BY GHD.id) AS id,
				GHD.id AS  idCarrier,
				TR.nombre AS [name],
				SUM(GHD.totalPieces) AS totalPieces,
				SUM(GHD.piecesPicked) AS piecesPicked,
				'' AS labelPieces,
				CONVERT( 
					VARCHAR(16), 
					ISNULL(ISNULL(HT.horaMaximaDespacho, HT1.horaMaximaDespacho),'00:00:00'), 
					108
				) AS cutOff,
				'' AS nroManifiesto
			FROM  #TempPickingList GHD
			LEFT JOIN Transportes TR ON TR.ID =  GHD.id
			LEFT JOIN Transportes TR1 ON TR1.ID =  TR.idTransportePrincipal
			LEFT JOIN HorarioTransportes HT ON HT.idTransporte = TR.id AND HT.idDiaSemana = @idDiaSemana
			LEFT JOIN HorarioTransportes HT1 ON HT1.idTransporte = TR1.id AND HT1.idDiaSemana = @idDiaSemana
			GROUP BY  GHD.id, 
				TR.nombre,
				HT.horaMaximaDespacho, 
				HT1.horaMaximaDespacho
		END
		ELSE
		BEGIN 
			INSERT INTO #TempPickingList(id, totalPieces, piecesPicked, piecesDispatched, nroManifiesto)
			SELECT
				GHD.idCarrier AS id, 
				SUM(GHD.total) AS totalPieces,
				SUM(GHD.picked) AS piecesPicked,
				SUM(totalDispatched) AS piecesDispatched,
				 GHD.nroManifiesto
			FROM #GroupData GHD
			WHERE GHD.total = GHD.hasManifest 
			AND GHD.total = GHD.picked 
			GROUP BY GHD.idCarrier, 
				GHD.nroManifiesto

			SELECT 
				ROW_NUMBER() OVER (ORDER BY GHD.id) AS id, 
				GHD.id AS  idCarrier,
				TR.nombre AS [name],
				SUM(GHD.totalPieces) AS totalPieces,
				SUM(GHD.piecesPicked) AS piecesPicked,
				'' AS labelPieces,
				CONVERT( 
					VARCHAR(16), 
					ISNULL(ISNULL(HT.horaMaximaDespacho, HT1.horaMaximaDespacho),'00:00:00'), 
					108
				) AS cutOff,
				'' AS nroManifiesto
			FROM #TempPickingList GHD
			LEFT JOIN Transportes TR ON TR.ID =  GHD.id
			LEFT JOIN Transportes TR1 ON TR1.ID =  TR.idTransportePrincipal
			LEFT JOIN HorarioTransportes HT ON HT.idTransporte = TR.id AND HT.idDiaSemana = @idDiaSemana
			LEFT JOIN HorarioTransportes HT1 ON HT1.idTransporte = TR1.id AND HT1.idDiaSemana = @idDiaSemana
			GROUP BY GHD.id, 
				TR.nombre,
				HT.horaMaximaDespacho, 
				HT1.horaMaximaDespacho

		END
	END TRY
	BEGIN CATCH		
		EXEC [dbo].[pro_LogError] 
	END CATCH;	
	DROP TABLE #GuiasHouseDetalles
	DROP TABLE #TMP_GUIAS
END
/*exec Ac_pro_GetOutboundOrderPicking
	@fechaDespacho='2026-05-02 00:00:00',
	@idBodega=N'LXgyot5M',
	@isPending=1,
	@idEmpresa=N'EMP014'
*/