USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_Despacho_PickUpShipToCompleteDelivered]    Script Date: 26/03/2026 09:34:56 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  
VERSION		MODIFIEDBY			MODIFIEDDATE		HU							MODIFICATION
1			Juan Domínguez      2021-02-12							SP para obtener los datos de la pestaña ShipTo del despacho pickup completados   
2			Jonathan            2021-08-25							Modificación para mostrar en completados solo las piezas con Manifiesto POD  
3			Luchin              2021-08-05							No agrupar por totales, house, idGuiaHouse. No hacer join con DocumentoDespacho. No hacer join con Usuarios. Remover campos no usados  
4			Jonathan            2021-10-01							Modificación para filtrar por pallet  
5			Jonathan            2021-11-08							Modificación para agrupar por orden de venta  
6			Saul Mendez         2021-12-27							Se agregan los campos de carrier  
7			Luchin              2022-04-15							Mostrar Bodega de acuerdo con la ubicación de la pieza  
8			Luchin / Paty       2022-12-27			15337			Mejoras SP  
9			Jorge / Paty        2023-05-05			24025			ENTREGA: Antes: guiaHouseDetalle.fechaCambio, ahora: guiaHouseDetalleHistorico.fechaCambio. Ahora filtra por la fecha de despacho real o ejecutada al momento de despachar la pieza en destino MIA. Mejora de rendimiento  
10			Jean                2023-11-25							Se agrega filtro por idEmpresa de guías house  
11			Joel Cedeno			2024-11-01			CC: 45993		Modificacion para obtener el primer documento activo en documento despacho
12			Juan Ordoñez		2025-03-25			N/A				Eliminar comentario de indice line 194 INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON A.idGuiaHouseDetalle = GHD.id -- INDEX(idx_GuiasHouseDetalles_idGuiaHouseIdCliente)
13		    Jairo Gonzalez		2025-09-24			53983			Delete join with sales orders and regruop fields.
*/  
ALTER     PROCEDURE [dbo].[pro_Despacho_PickUpShipToCompleteDelivered]  
(  
	@FechaDesde					DATE,  
	@FechaHasta					DATE,  
	@NroDocumento				VARCHAR(32)	= NULL,  
	@Po							VARCHAR(32) = NULL,  
	@NombreClienteConsignee		VARCHAR(512) = NULL,  
	@NroPOD						VARCHAR(16) = NULL,  
	@CodigoBarras				VARCHAR(32) = NULL,  
	@NombreComercialExportador	VARCHAR(50) = NULL,  
	@PalletLabel				VARCHAR(20) = NULL,  
	@idEmpresa					VARCHAR(16)  
)  
AS  
BEGIN  

    BEGIN TRY   
		DECLARE @idParametroDelivery VARCHAR(16);  
  
        CREATE TABLE #TablaAgrupacionGuiasHouse	(  
			Id						INT IDENTITY(1, 1) NOT NULL,  
			IdClienteFinal			VARCHAR(16),  
			nombreClienteFinal		VARCHAR(1024),    
			FechaPickUpProgramada	DATETIME,  
			FechaPickUpEntrega		DATETIME,  
			TotalPending			INT,  
			TotalHold				INT,  
			TotalShort				INT,  
			TotalReceived			INT,  
			TotalStandBy			INT,  
			TotalDespachado			INT,  
			Total					INT,  
			IdBodega				VARCHAR(16),  
			nombreBodega			VARCHAR(1024),    
			IdManifiesto			UNIQUEIDENTIFIER,  
			IdCarrier				VARCHAR(16),  
			NombreCarrier			VARCHAR(512),  
			EsPod					BIT NOT NULL DEFAULT 0,   
			codigoCarrier			VARCHAR(32)  
		);  
         
		SELECT @idParametroDelivery = id
		FROM ParametrosLista parametroLista WITH(NOLOCK)   
		WHERE parametroLista.codigo = 'EsDelivery' AND parametroLista.idEmpresa = @idEmpresa;  
  
		SELECT C.idEntidad, C.codigo  
		INTO #TMP_CodigosRelacionSistemas  
		FROM CodigosRelacionSistemas C WITH(NOLOCK)   
		WHERE C.tipoEntidad = 'CARRIER' AND C.idSistemaEntidad = 100;  
    
		SELECT DISTINCT T.id, T.nombre  
		INTO #TMP_TRANS  
		FROM ParametrosLista PL   
		INNER JOIN ParametrosCatalogos PC WITH(NOLOCK) ON PC.idParametroLista = PL.id AND PC.valor = 'NO'  
		INNER JOIN Transportes T WITH(NOLOCK) ON T.idTransportePrincipal = PC.idEntidad  
		WHERE PL.codigo = 'EsDelivery' AND PL.idEmpresa = @idEmpresa;  
  
		SELECT GHDH.idGuiaHouseDetalle, MAX(GHDH.fechaCambio) fechaCambio
		INTO #tmlGHH  
		FROM GuiasHouseDetallesHistorico GHDH WITH(NOLOCK)  
		WHERE GHDH.fechaCambio BETWEEN @FechaDesde AND @FechaHasta AND GHDH.VALOR = 'DISPATCHED WH'  
		GROUP BY GHDH.idGuiaHouseDetalle  
  
        IF   
		(     
			@NroDocumento IS NULL AND 
			@Po IS NULL AND 
			@NombreClienteConsignee IS NULL AND
			@NroPOD IS NULL AND 
			@CodigoBarras IS NULL AND 
			@NombreComercialExportador IS NULL AND
			@PalletLabel IS NULL
		)  
        BEGIN     
			SELECT 
				GHD.id,  
				GHD.idGuiaHouse,  
				GHD.idClienteFinal,  
				A.fechaCambio,  
				GHD.estadoPieza,  
				PC.ID AS idProgramacionCarrier,  
				PC.fechaDespacho,  
				T.id AS idSubCarrier,  
				T.nombre AS nombreSubCarrier     
			INTO #TMP_GHD_MASIVO  
			FROM #tmlGHH A   
			INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON A.idGuiaHouseDetalle = GHD.id  
			INNER JOIN ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id   
			INNER JOIN #TMP_TRANS T ON PC.idCarrier = T.id  
  
			INSERT INTO #TablaAgrupacionGuiasHouse  
			SELECT      
				GHD.idClienteFinal AS IdClienteFinal,     
				ISNULL(CF.nombreClienteFinal,CF.nombre) AS NombreClienteFinal,  
				MAX(GHD.fechaDespacho) AS FechaPickUpProgramada,   
				MAX(GHD.fechaCambio) AS FechaPickUpEntrega, 
				SUM(IIF(GHD.estadoPieza = 'PENDING', 1, 0)) AS TotalPending,  
				SUM(IIF(GHD.estadoPieza = 'HOLD', 1, 0)) AS TotalHold,  
				SUM(IIF(GHD.estadoPieza = 'SHORT', 1, 0)) AS TotalShort,  
				SUM(IIF(GHD.estadoPieza = 'RECEIVED WH', 1, 0)) AS TotalReceived,  
				SUM(IIF(GHD.estadoPieza = 'STANDBY', 1, 0)) AS TotalStandBy,  
				SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0)) AS TotalDespachado,  
				COUNT(1) AS Total,     
				ISNULL(UB.idBodega, GH.idBodega) AS idBodega,   
				ISNULL(BP.nombre, BG.nombre) AS nombreBodega,   
				MD.id AS IdManifiesto,  
				GHD.idSubCarrier AS IdCarrier,  
				GHD.nombresubCarrier AS NombreCarrier,  
				CONVERT(BIT, 1) AS esPOD,  
				T1.codigo
			FROM #TMP_GHD_MASIVO GHD   
			INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GHD.idGuiaHouse = GH.id  
			INNER JOIN Clientes CF WITH(NOLOCK) ON GHD.IdClienteFinal = CF.Id     
			LEFT JOIN ProgramacionManifiesto PM WITH(NOLOCK) ON PM.idProgramacionCarrier = GHD.idProgramacionCarrier              
			LEFT JOIN ManifiestosDespacho MD WITH(NOLOCK) ON MD.id = PM.idManifiestoDespacho  
			OUTER APPLY (
				SELECT TOP 1 DD.EsPod
				FROM DocumentosDespacho DD WITH(NOLOCK)
				WHERE DD.idManifiesto = MD.id 
				AND DD.idDocumento = 'DOC052395'
				ORDER BY EsPod DESC
			) DCD
			LEFT JOIN PalletsDetalles pld WITH(NOLOCK) ON GHD.id = pld.idGuiasHouseDetalle  
			LEFT JOIN Pallets pal WITH(NOLOCK) ON pld.idPallet = pal.id  
			INNER JOIN #TMP_CodigosRelacionSistemas T1 WITH(NOLOCK) ON GHD.idSubCarrier = T1.idEntidad  
			LEFT JOIN UbicacionPiezas AS UP WITH(NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle  
			LEFT JOIN Ubicaciones AS U WITH(NOLOCK) ON UP.idUbicacion = U.id  
			LEFT JOIN UbicacionesBodega AS UB WITH(NOLOCK) ON U.idUbicacionBodega = UB.id  
			LEFT JOIN Bodegas AS BG WITH(NOLOCK) ON GH.idBodega = BG.id  
			LEFT JOIN Bodegas AS BP WITH(NOLOCK) ON UB.idBodega = BP.id    
			WHERE GH.idEmpresa = @idEmpresa AND dcd.EsPod = 1  
			GROUP BY   
				GHD.idClienteFinal,  
				ISNULL(CF.nombreClienteFinal,CF.nombre),  
				ISNULL(UB.idBodega, GH.idBodega),   
				ISNULL(BP.nombre, BG.nombre),   
				MD.id,  
				GHD.idSubCarrier,  
				GHD.nombresubCarrier,   
				T1.codigo  
			HAVING COUNT(1) = SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0));  
		END  
		ELSE  
		BEGIN  
			SELECT   
				GHD.id,  
				GHD.idGuiaHouse,  
				GHD.po,  
				GHD.codigoBarra,  
				GHD.idClienteFinal,  
				A.fechaCambio,  
				GHD.estadoPieza,  
				PC.ID AS idProgramacionCarrier,  
				PC.fechaDespacho,  
				T.id AS idSubCarrier,  
				T.nombre AS nombreSubCarrier  
			INTO #TMP_GHD_FILTROS  
			FROM #tmlGHH A   
			INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON A.idGuiaHouseDetalle = GHD.id
			INNER JOIN ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id   
			INNER JOIN #TMP_TRANS T ON PC.idCarrier = T.id  
  
			INSERT INTO #TablaAgrupacionGuiasHouse  
			SELECT      
				guiaHouseDetalle.idClienteFinal AS IdClienteFinal,     
				ISNULL(clienteFinal.nombreClienteFinal,clienteFinal.nombre) AS NombreClienteFinal,  
				MAX(guiaHouseDetalle.fechaDespacho) AS FechaPickUpProgramada,  
				MAX(guiaHouseDetalle.fechaCambio) AS FechaPickUpEntrega,  
				SUM(IIF(guiaHouseDetalle.estadoPieza = 'PENDING', 1, 0)) AS TotalPending,  
				SUM(IIF(guiaHouseDetalle.estadoPieza = 'HOLD', 1, 0)) AS TotalHold,  
				SUM(IIF(guiaHouseDetalle.estadoPieza = 'SHORT', 1, 0)) AS TotalShort,  
				SUM(IIF(guiaHouseDetalle.estadoPieza = 'RECEIVED WH', 1, 0)) AS TotalReceived,  
				SUM(IIF(guiaHouseDetalle.estadoPieza = 'STANDBY', 1, 0)) AS TotalStandBy,  
				SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0)) AS TotalDespachado,  
				COUNT(1) AS Total,     
				ISNULL(ubicacionesBodega.idBodega, guiaHouse.idBodega) AS idBodega,   
				ISNULL(bodegaPieza.nombre, bodegaGuia.nombre) AS nombreBodega,   
				manifiestoDespacho.id AS IdManifiesto,  
				guiaHouseDetalle.idSubCarrier AS IdCarrier,  
				guiaHouseDetalle.nombresubCarrier AS NombreCarrier,  
				CONVERT(BIT, 1) AS esPOD,   
				T1.codigo    
			FROM #TMP_GHD_FILTROS guiaHouseDetalle   
			INNER JOIN GuiasHouse guiaHouse  WITH(NOLOCK) ON guiaHouseDetalle.idGuiaHouse = guiaHouse.id  
			INNER JOIN Clientes clienteFinal WITH(NOLOCK) ON guiaHouseDetalle.IdClienteFinal = clienteFinal.Id     
			LEFT JOIN ProgramacionManifiesto programacionManifiesto WITH(NOLOCK) ON programacionManifiesto.idProgramacionCarrier = guiaHouseDetalle.idProgramacionCarrier              
			LEFT JOIN ManifiestosDespacho manifiestoDespacho WITH(NOLOCK) ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho  
			OUTER APPLY (
				SELECT TOP 1 DD.EsPod
				FROM DocumentosDespacho DD WITH (NOLOCK)
				WHERE DD.idManifiesto = manifiestoDespacho.id 
				AND DD.idDocumento = 'DOC052395'
				ORDER BY EsPod DESC
			) dcd
			LEFT JOIN PalletsDetalles pld WITH(NOLOCK) ON guiaHouseDetalle.id = pld.idGuiasHouseDetalle  
			LEFT JOIN Pallets pal WITH(NOLOCK) ON pld.idPallet = pal.id  
			INNER JOIN #TMP_CodigosRelacionSistemas T1 WITH (NOLOCK) ON guiaHouseDetalle.idSubCarrier = T1.idEntidad  
			LEFT JOIN UbicacionPiezas AS ubicacionPiezas WITH (NOLOCK) ON guiaHouseDetalle.id = ubicacionPiezas.idGuiaHouseDetalle  
			LEFT JOIN Ubicaciones AS ubicaciones WITH (NOLOCK)  ON ubicacionPiezas.idUbicacion = ubicaciones.id  
			LEFT JOIN UbicacionesBodega AS ubicacionesBodega WITH (NOLOCK) ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id  
			LEFT JOIN Bodegas AS bodegaGuia WITH (NOLOCK) ON guiaHouse.idBodega = bodegaGuia.id  
			LEFT JOIN Bodegas AS bodegaPieza WITH (NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 
			WHERE guiaHouse.idEmpresa = @idEmpresa 
				AND  dcd.EsPod = 1  
				AND (@NroDocumento IS NULL OR guiaHouse.nroGuia LIKE '%' + @NroDocumento + '%')  
				AND (@Po IS NULL OR guiaHouseDetalle.po LIKE '%' + @Po + '%')  
				AND (@NombreClienteConsignee IS NULL OR guiaHouse.idCliente IN ( SELECT id FROM Clientes WHERE nombre LIKE '%' + @NombreClienteConsignee + '%' ))  
				AND (@NroPOD IS NULL OR manifiestoDespacho.nroManifiesto LIKE '%' + @NroPOD + '%')  
				AND (@CodigoBarras IS NULL OR guiaHouseDetalle.codigoBarra LIKE '%' + @CodigoBarras + '%')  
				AND (@NombreComercialExportador IS NULL OR guiaHouse.idExportador IN ( SELECT id FROM Exportadores WHERE nombre LIKE '%' + @NombreComercialExportador + '%' ))  
				AND (@PalletLabel IS NULL OR   pal.pallet LIKE '%' + @PalletLabel + '%')  
		   GROUP BY   
			   guiaHouseDetalle.idClienteFinal,  
			   ISNULL(clienteFinal.nombreClienteFinal,clienteFinal.nombre),  
			   ISNULL(ubicacionesBodega.idBodega, guiaHouse.idBodega),   
			   ISNULL(bodegaPieza.nombre, bodegaGuia.nombre),   
			   manifiestoDespacho.id,  
			   guiaHouseDetalle.idSubCarrier,  
			   guiaHouseDetalle.nombresubCarrier,    
				T1.codigo  
			   HAVING COUNT(1) = SUM(IIF(guiaHouseDetalle.estadoPieza = 'DISPATCHED WH', 1, 0));  
        END  
  
        SELECT        
			tmp.Id AS Id,  
			tmp.IdClienteFinal,  
			tmp.NombreClienteFinal,  
			tmp.IdBodega,  
			tmp.NombreBodega,  
			tmp.IdManifiesto,  
			tmp.IdCarrier,  
			tmp.NombreCarrier,  
			tmp.FechaPickUpProgramada,  
			tmp.FechaPickUpEntrega,  
			CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega,  
			tmp.TotalPending AS PcsPending,  
			tmp.TotalHold AS PcsHold,  
			tmp.TotalShort AS PcsShort,  
			tmp.TotalReceived AS PcsReceivedWh,  
			tmp.TotalStandBy AS PcsStandby,  
			tmp.TotalDespachado AS TotalDespachado,  
			tmp.Total AS Total,    
			CONVERT(BIT, 0) AS Enviado,  
			CONVERT(BIT, 0) AS Procesado,  
			NULL AS TipoNubeDocs,  
			NULL AS Estatus,  
			tmp.codigoCarrier  
		FROM #TablaAgrupacionGuiasHouse AS tmp  		
    END TRY  
    BEGIN CATCH  
        EXEC [dbo].[pro_LogError];  
    END CATCH;  
END;    
/*  
exec pro_Despacho_PickUpShipToCompleteDelivered '20241101', '20241201', null, null, null, null, '52203886535', null, null, 'EMP014'  
exec pro_Despacho_PickUpShipToCompleteDelivered '20241101', '20241201', null, null, null, null, null, null, null, 'EMP014'  

exec sp_executesql N'pro_Despacho_PickUpShipToCompleteDelivered @FechaDesde, @FechaHasta, @NroDocumento, @Po, @NombreClienteConsignee, @NroPOD, @CodigoBarras, @NombreComercialExportador, @PalletLabel, @idEmpresa  
',N'@FechaDesde date,@FechaHasta date,@NroDocumento varchar(32),@Po varchar(32),@NombreClienteConsignee varchar(512),@NroPOD varchar(16),@CodigoBarras varchar(32),@NombreComercialExportador varchar(256),@PalletLabel varchar(256),@idEmpresa varchar(16)'  
,@FechaDesde='25-8-2025',@FechaHasta='24-9-2025',@NroDocumento=NULL,@Po=NULL,@NombreClienteConsignee=NULL,@NroPOD=NULL,@CodigoBarras=NULL,@NombreComercialExportador=NULL,@PalletLabel=NULL,@idEmpresa='EMP014' 
  
  */