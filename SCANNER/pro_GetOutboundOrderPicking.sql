USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_GetOutboundOrderPicking]    Script Date: 14/07/2026 12:51:58 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*    
VERSION       AUTOR                  FECHA            HU             CAMBIO
1			  Edwin Casa  			 03-03-2024	SC	  39191  		 Codigo Inicial: sp para listar informacion de piezas por bodega y FechaDespacho de Order Picking Timeout: 90s
2			  Edwin Casa  			 09-01-2025		  WMS-47592		 Se elimina el union para realizar la consulta una sola vez a las tablas transaccionales
3			  Cristian Ponce  		 16-01-2025		  47755		  	 Se agrega condición para datos de tipo de venta inventario y que el estado de la pieza sea DISPATCHED WH 
*/
ALTER     PROCEDURE [dbo].[pro_GetOutboundOrderPicking]
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
			id [UNIQUEIDENTIFIER],
			idGuiaHouse [UNIQUEIDENTIFIER],
			idClienteFinal [VARCHAR](16),
			estadoPieza [VARCHAR](32),
			idTipoDePieza [VARCHAR](16), 
			esPOD [BIT],
			idProgramacionCarrier [UNIQUEIDENTIFIER],
			fechaDespacho [DATETIME],
			idCarrier [VARCHAR](16),
			idUsuarioLogPicking [VARCHAR](16),
			idBodega [VARCHAR](16),
			idCatalogoAccion [UNIQUEIDENTIFIER]
		)

		CREATE TABLE #GuiasHouseDetalles(
			id [UNIQUEIDENTIFIER],
			idGuiaHouse [UNIQUEIDENTIFIER],
			idClienteFinal [VARCHAR](16),
			estadoPieza [VARCHAR](32),
			esPOD [BIT],
			idTipoDePieza [VARCHAR](16), 
			fechaDespacho [DATETIME],
			idCarrier [VARCHAR](16),
			totalPieces [INT],
			piecesPicked [INT],
			nroManifiesto [VARCHAR](32),
			piecesManifest [INT],
			esDelivery [BIT]
		)
	
		CREATE TABLE #TempPickingList
		(
			id [VARCHAR](16),
			totalPieces [INT],
			piecesPicked [INT],
			piecesDispatched [INT],
			hasManifest [INT],
			nroManifiesto [VARCHAR](32)
		)
		CREATE TABLE #CatalogosAccion(
			id [UNIQUEIDENTIFIER]
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
			   GHD.idClienteFinal,
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
			G.idClienteFinal,
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
				G.idClienteFinal,
				COUNT(G.idClienteFinal) AS total, 
				SUM(G.piecesManifest) as hasManifest, 
				SUM(IIF(G.estadoPieza = 'DISPATCHED WH',1,0)) totalDispatched,
				SUM(G.piecesPicked) AS picked,
				G.esDelivery,
				G.nroManifiesto
			FROM #GuiasHouseDetalles G
			GROUP by 
				G.idCarrier,
				G.idClienteFinal, 
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

/*

exec pro_GetOutboundOrderPicking @fechaDespacho='20240925',@idBodega=N'LXgyot5M',@isPending=1,@idEmpresa=N'EMP014'	
exec pro_GetOutboundOrderPicking @fechaDespacho='20240930',@idBodega=N'LXgyot5M',@isPending=1,@idEmpresa=N'EMP014'
exec pro_GetOutboundOrderPicking @fechaDespacho='20241001',@idBodega=N'LXgyot5M',@isPending=1,@idEmpresa=N'EMP014'
exec pro_GetOutboundOrderPicking @fechaDespacho='20241010',@idBodega=N'LXgyot5M',@isPending=1,@idEmpresa=N'EMP014'

exec pro_GetOutboundOrderPicking @fechaDespacho='20241107 00:00:00',@idBodega=N'LXgyot5M',@isPending=0,@idEmpresa=N'EMP014'

exec pro_GetOutboundOrderPicking @fechaDespacho='20241209 00:00:00',@idBodega=N'LXgyot5M',@isPending=1,@idEmpresa=N'EMP014'
exec pro_GetOutboundOrderPicking @fechaDespacho='2021209 00:00:00',@idBodega=N'QK6s23du',@isPending=1,@idEmpresa=N'EMP014'
exec pro_GetOutboundOrderPicking @fechaDespacho='20241207 00:00:00',@idBodega=N'LXgyot5M',@isPending=1,@idEmpresa=N'EMP014'
exec pro_GetOutboundOrderPicking @fechaDespacho='20241206 00:00:00',@idBodega=N'LXgyot5M',@isPending=1,@idEmpresa=N'EMP014'

exec pro_GetOutboundOrderPicking @fechaDespacho='20241107 00:00:00',@idBodega=N'LXgyot5M',@isPending=0,@idEmpresa=N'EMP014'

exec pro_GetOutboundOrderPicking @fechaDespacho='20241007 00:00:00',@idBodega=N'LXgyot5M',@isPending=0,@idEmpresa=N'EMP014'

exec pro_GetOutboundOrderPicking_test @fechaDespacho='20250114 00:00:00',@idBodega=N'QK6s23du',@isPending=1,@idEmpresa=N'EMP014'

exec sp_executesql N'dbo.pro_ConsultarInformacionPiezasPorClientePicking @idBodega, @idCarrier, @fechaDespacho, @isPending, @idclienteFinal, @nroManifiesto, @nroPo, @nroGuia  ',N'@idBodega nvarchar(8),@fechaDespacho datetime,@idCarrier nvarchar(12),@idclienteFinal nvarchar(10),@isPending bit,@nroManifiesto nvarchar(4000),@nroPo nvarchar(6),@nroGuia nvarchar(4000)',@idBodega=N'LXgyot5M',@fechaDespacho='20241007 00:00:00',@idCarrier=N'IQpYt7sMRwUk',@idclienteFinal=N'CLI0116641',@isPending=1,@nroManifiesto=NULL,@nroPo=N'479499',@nroGuia=NULL

*/

