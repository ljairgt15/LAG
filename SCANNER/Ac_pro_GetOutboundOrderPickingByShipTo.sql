/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-07-25		  58788			 Based on pro_GetOutboundOrderPickingByShipTo
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetOutboundOrderPickingByShipTo]
(
	@IdBodega VARCHAR(16),
	@IdCarrier VARCHAR(16),
	@FechaDespacho DATETIME,
	@IsPending BIT,
	@IdClienteFinal VARCHAR(16) = NULL,
	@BillToConsigneeId VARCHAR(16)= NULL,
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
		SELECT Id
		FROM   Catalogos
		WHERE  CodigoRelacion IN ('WAITING CUSTOMS CLEARANCE', 'WAITING INSPECTION')
				AND IdEmpresa IS NULL
	
		SELECT  @NombreCarrier = Nombre
		FROM  Transportes 
		WHERE ID = @IdCarrier
		
		SELECT  @ValorEsDelivery = PC.Valor 
		FROM ParametrosCatalogos PC
		INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.Codigo = 'EsDelivery'
		WHERE PC.IdEntidad = @IdCarrier
			AND PC.Valor = 'NO'
			AND PL.Actor IN ('CARRIER', 'TERRESTRE')

		IF @ValorEsDelivery IS NULL
		BEGIN
			SELECT @ValorEsDelivery = PC.Valor
			FROM  Transportes T
			INNER JOIN ParametrosCatalogos PC ON T.IdTransportePrincipal = PC.IdEntidad
			INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id AND PL.Codigo = 'EsDelivery'
			WHERE  T.Id = @IdCarrier
				AND PC.Valor = 'NO'
				AND PL.Actor IN ('CARRIER', 'TERRESTRE')
		END 


		INSERT INTO #TMP_GUIAS
		SELECT
			GHD.Id,
			GHD.IdGuiaHouse,
			GHD.ShipToId,
			GH.ConsigneeId,
			GH.NroGuia,
			GHD.CodigoBarra,
			GHD.EstadoPieza,
			GHD.Gate,
			GHD.IdTipoDePieza,
			GHD.EsPOD,
			GHD.Po,
			PC.Id AS IdProgramacionCarrier,
			PC.FechaDespacho,
			PC.IdCarrier,
			ISNULL(IIF(SVD.Picking = 1, '1', NULL), PC.IdUsuarioLogPicking) AS IdUsuarioLogPicking,
			GH.IdBodega,
			GH.IdEmpresa,
			GHD.IdCatalogoAccion
		FROM ProgramacionCarrier PC  WITH (NOLOCK)
		INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GHD.Id = PC.IdGuiaHouseDetalle 
            AND (GHD.ShipToId = @IdClienteFinal 
                OR (GHD.ShipToId IS NULL AND @IdClienteFinal IS NULL))	
		INNER JOIN GuiasHouse GH WITH (NOLOCK) ON  GH.Id = GHD.IdGuiaHouse
		LEFT JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON SVD.IdGuiaHouseDetalle = GHD.Id
		LEFT JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SVD.IdSolicitud = SV.Id 
		WHERE  PC.FechaDespacho = @FechaDespacho
			   AND PC.IdCarrier = @IdCarrier 
			   AND CASE 
					WHEN SVD.Id IS NULL THEN 1
					WHEN SV.TipoVenta = 4 THEN 1
					WHEN SV.TipoVenta IN (1,2,3) AND SVD.Picking = 1 THEN 1
					WHEN SV.TipoVenta IN (1,2,3) AND GHD.EstadoPieza = 'DISPATCHED WH'  THEN 1 
					WHEN SV.TipoVenta = 5  AND SVD.TipoPieza = 2 THEN 1
					WHEN SV.TipoVenta = 5  AND SVD.TipoPieza = 1  AND SVD.Picking = 1 THEN 1
					WHEN SV.TipoVenta = 5  AND SVD.TipoPieza = 1  AND GHD.EstadoPieza = 'DISPATCHED WH' THEN 1
					ELSE 0 
				END  = 1
		  
		INSERT INTO #GuiasHouseDetalles
		SELECT 
			GHD.Id,
			GHD.IdGuiaHouse,
			GHD.ShipToId,
			GHD.EstadoPieza,
			GHD.EsPOD,
			GHD.IdTipoDePieza, 
			GHD.FechaDespacho,
			GHD.IdCarrier,
			1 AS TotalPieces,
			CASE
				WHEN GHD.IdUsuarioLogPicking IS NOT NULL
					THEN 1
				WHEN GHD.EstadoPieza = 'DISPATCHED WH'
					THEN 1
				ELSE 0 
			END AS Picking,
			ISNULL(PL.Pallet, GHD.CodigoBarra) AS Barcode,
			CASE
				WHEN GHD.EstadoPieza = 'RECEIVED WH'
					THEN ISNULL(U.Codigo, U1.Codigo)
				WHEN GHD.EstadoPieza = 'DISPATCHED WH' AND PMN.Id IS NOT NULL AND PMN.Nota <> 'Escaner Picking'
					THEN ISNULL(U.Codigo, U1.Codigo)
				WHEN GHD.EstadoPieza = 'DISPATCHED WH' AND U.Codigo IS NULL AND U1.Codigo IS NULL
					THEN GHD.NroGuia
				WHEN GHD.EstadoPieza = 'DISPATCHED WH' AND PL.Id IS NOT NULL 
					THEN ISNULL(U.Codigo, '')
				WHEN GHD.EstadoPieza = 'DISPATCHED WH' AND ISNULL(U.Codigo, U1.Codigo) IS NOT NULL
					THEN ISNULL(U.Codigo, U1.Codigo)
				WHEN GHD.EstadoPieza = 'HOLD' AND (U.Codigo IS NOT NULL OR U1.Codigo IS NOT NULL)
					THEN ISNULL(U.Codigo, U1.Codigo)
				ELSE GHD.NroGuia 
			END AS [Location],
			ISNULL(ED.Puerta, GHD.Gate) AS Dock,
			ISNULL(MD.NroManifiesto, ''),
			CASE
				WHEN PMN.Id IS NOT NULL AND PMN.Nota = 'Escaner Picking'
					THEN 1
				ELSE 0
			END AS PiecesManifest,
			IIF(PL.Pallet IS NULL, 0, 1) AS IsPallet,
			ISNULL(GHD.Po, ''),
			GHD.IdEmpresa,
			GHD.ConsigneeId,
			CASE 
				WHEN @ValorEsDelivery = 'NO' THEN 0
				ELSE 1 
			END AS EsDelivery
		FROM #TMP_GUIAS GHD 
		LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON UP.IdGuiaHouseDetalle = GHD.Id 
		LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON PLD.IdGuiasHouseDetalle = GHD.Id
		LEFT JOIN Pallets PL WITH (NOLOCK) ON PL.Id = PLD.IdPallet
		LEFT JOIN Ubicaciones U ON U.Id =  PL.IdUbicacion
		LEFT JOIN Ubicaciones U1 ON U1.Id =  UP.IdUbicacion
		LEFT JOIN UbicacionesBodega UB1 ON UB1.Id = U1.IdUbicacionBodega
		LEFT JOIN DetalleDespacho DD WITH (NOLOCK) ON GHD.[Id] = DD.IdGuiaHouseDetalle
		LEFT JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.IdEncabezadoDespacho = ED.Id
		LEFT JOIN ProgramacionManifiesto PMN WITH (NOLOCK) ON PMN.IdProgramacionCarrier = GHD.IdProgramacionCarrier
		LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON MD.Id =  PMN.IdManifiestoDespacho
		WHERE (GHD.EstadoPieza NOT IN ('HOLD','LOST','SHORT','STANDBY')
				OR (GHD.EstadoPieza = 'HOLD'
						AND GHD.IdCatalogoAccion IN (SELECT Id FROM #CatalogosAccion)) 
			)
			AND GHD.EsPOD <> 1
			AND ISNULL(UB1.IdBodega, GHD.IdBodega) =  @IdBodega
			AND (@NroGuia IS NULL OR GHD.NroGuia = @NroGuia)
			AND (@NroManifiesto IS NULL OR MD.NroManifiesto = @NroManifiesto)
			AND (@NroPo IS NULL OR GHD.Po = @NroPo)

		SELECT TOP 1 @IdEmpresa = GHD.IdEmpresa 
		FROM #GuiasHouseDetalles GHD
		

		SELECT TOP 1 @BillToId = ER.EntityTypeId
		FROM EntityRelations ER WITH (NOLOCK)
		WHERE ER.Id = @BillToConsigneeId
		
		SELECT TOP 1 @ManifiestoDespacho = PC.Valor
		FROM ParametrosLista AS PL WITH (NOLOCK)
		JOIN ParametrosCatalogos AS PC WITH (NOLOCK) ON PC.IdParametroLista = PL.Id
		WHERE PL.Codigo = 'TipoManifiestoDespacho'
			AND PL.IdEmpresa = @IdEmpresa
			AND PC.IdEntidad IN (@BillToConsigneeId, @BillToId)
		ORDER BY PC.IdEntidad DESC
		
		SELECT 
			G.ShipToId,
			G.NroManifiesto,
			G.Total,
			G.Picked,
			G.TotalDispatched,
			G.EsDelivery,
			CASE 
				WHEN G.EsDelivery  = 0 
					AND G.Picked = G.Total 
					AND  G.NroManifiesto = ''
				THEN G.Picked
				ELSE G.HasManifest 
			END AS HasManifest
		INTO #GroupData
		FROM (
			SELECT 
				G.ShipToId,
				COUNT(1) AS Total, 
				SUM(G.PiecesManifest) AS HasManifest, 
				SUM(IIF(G.EstadoPieza = 'DISPATCHED WH',1,0)) TotalDispatched,
				SUM(G.PiecesPicked) AS Picked,
				G.EsDelivery,
				G.NroManifiesto
			FROM #GuiasHouseDetalles G
			GROUP BY G.ShipToId, 
				G.EsDelivery,
				G.NroManifiesto
		) G
	
		IF @ValorEsDelivery = 'NO'
		BEGIN
			
			IF (SELECT TOP 1 'SI' FROM #GroupData WHERE Picked = Total) = 'SI'
			BEGIN
				UPDATE #GuiasHouseDetalles
				SET PiecesManifest = 1
				WHERE NroManifiesto = ''
					AND PiecesPicked <> 0 
			END 
		END 
	
		IF @IsPending = 1
		BEGIN
			SELECT 
				ROW_NUMBER() OVER (ORDER BY GHD.BarCode) AS Id,
				BarCode,
				[Location],
				SUM(TotalPieces) AS Pieces,
				SUM(PiecesPicked) AS PiecesPicked,
				CONVERT(BIT,IIF(SUM(PiecesPicked) > 0, 1, 0)) AS IsPicked,
				Dock,
				NroManifiesto,
				IsPallet
			FROM #GuiasHouseDetalles GHD
			WHERE (
					( @NroPo IS NULL AND @ManifiestoDespacho = 'PO' AND  GHD.NroPo = '' )
					OR ( @NroPo IS NULL AND (@ManifiestoDespacho != 'PO' OR @ManifiestoDespacho IS NULL) )
				)
				OR GHD.NroPo = @NroPo 
			GROUP BY  BarCode,
				[Location],
				Dock,
				NroManifiesto,
				IsPallet
			HAVING  (SUM(GHD.TotalPieces) > SUM(GHD.PiecesPicked) 
				AND SUM(GHD.TotalPieces) >= SUM(GHD.PiecesManifest))
				OR (SUM(GHD.PiecesPicked)  = SUM(GHD.TotalPieces)
				AND SUM(GHD.PiecesPicked) <> SUM(GHD.PiecesManifest))
		END
		ELSE
		BEGIN 
			SELECT  
				@TotalPiecesByClient =COUNT(1),
				@TotalPiecesDispatched = SUM(IIF(EstadoPieza = 'DISPATCHED WH',1,0)) 
			FROM #GuiasHouseDetalles

			;WITH TempResp AS(
				SELECT 
					GHD.BarCode,
					[Location],
					TotalPieces,
					PiecesPicked,
					Dock,
					NroManifiesto,
					IsPallet,
					PiecesManifest
				FROM #GuiasHouseDetalles GHD
			)
			SELECT 
				ROW_NUMBER() OVER (ORDER BY GHD.BarCode) AS Id,
				ISNULL(BarCode, '') AS Barcode,
				[Location],
				SUM(TotalPieces) AS Pieces,
				SUM(PiecesPicked) AS PiecesPicked,
				CONVERT(BIT,IIF(SUM(PiecesPicked) > 0, 1, 0)) AS IsPicked,
				Dock,
				NroManifiesto,
				IsPallet
			FROM
				TempResp GHD
			GROUP BY 
				BarCode,
				[Location],
				Dock,
				NroManifiesto,
				IsPallet
			HAVING 
				SUM(GHD.TotalPieces) = SUM(GHD.PiecesPicked)
				AND SUM(GHD.TotalPieces) = SUM(GHD.PiecesManifest)
				AND @TotalPiecesDispatched <> @TotalPiecesByClient
		END
	
	END TRY
	BEGIN CATCH		
		EXEC [dbo].[pro_LogError] 
	END CATCH;	
	DROP TABLE #GuiasHouseDetalles
END
/*
exec [dbo].[AC_pro_GetOutboundOrderPickingByShipTo]
@IdBodega='LXgyot5M',
@IdCarrier='9Nlyxt0q6dGE',
@FechaDespacho='2026-05-02 00:00:00',
@IsPending=1,
@IdClienteFinal=NULL,
@BillToConsigneeId= NULL,
@NroManifiesto=NULL,
@NroPo=NULL,
@NroGuia=NULL
*/