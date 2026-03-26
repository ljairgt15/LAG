USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[AC_pro_GetCompletedDeliveredPickupShipTo]    Script Date: 26/03/2026 09:34:14 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  
VERSION		MODIFIEDBY			MODIFIEDDATE		HU				MODIFICATION
1			Juan Yanza			29-01-2026			WMS 57731		Based on pro_Despacho_PickUpShipToCompleteDelivered
*/  

ALTER   PROCEDURE [dbo].[AC_pro_GetCompletedDeliveredPickupShipTo]  
(  
    @FechaDesde                 DATE,  
    @FechaHasta                 DATE,  
    @NroDocumento               VARCHAR(32)  = NULL,  
    @Po                         VARCHAR(32)  = NULL,  
    @IdBillTo                   VARCHAR(16)  = NULL,
    @NombreBillTo               VARCHAR(512) = NULL,
    @IdConsignee                VARCHAR(16)  = NULL,  
    @NombreClienteConsignee     VARCHAR(512) = NULL,  
    @NroPOD                     VARCHAR(16)  = NULL,  
    @CodigoBarras               VARCHAR(32)  = NULL,  
    @NombreComercialExportador  VARCHAR(50)  = NULL,  
    @PalletLabel                VARCHAR(20)  = NULL,  
    @idEmpresa                  VARCHAR(16)  
)  
AS  
BEGIN  
    BEGIN TRY   
        DECLARE @idParametroDelivery VARCHAR(16);  
  
        CREATE TABLE #TablaAgrupacionGuiasHouse (  
            Id                    INT IDENTITY(1, 1) NOT NULL,  
            IdClienteFinal        VARCHAR(16),
            IdShipTo              VARCHAR(16),  
            nombreClienteFinal    VARCHAR(1024),    
            FechaPickUpProgramada DATETIME,  
            FechaPickUpEntrega    DATETIME,  
            TotalPending          INT,  
            TotalHold             INT,  
            TotalShort            INT,  
            TotalReceived         INT,  
            TotalStandBy          INT,  
            TotalDespachado       INT,  
            Total                 INT,  
            IdBodega              VARCHAR(16),  
            nombreBodega          VARCHAR(1024),    
            IdManifiesto          UNIQUEIDENTIFIER,  
            IdCarrier             VARCHAR(16),  
            NombreCarrier         VARCHAR(512),  
            EsPod                 BIT NOT NULL DEFAULT 0,   
            codigoCarrier         VARCHAR(32)  
        );  
         
        SELECT @idParametroDelivery = id
        FROM ParametrosLista parametroLista WITH(NOLOCK)   
        WHERE parametroLista.codigo = 'EsDelivery' 
            AND parametroLista.idEmpresa = @idEmpresa;  
  
        SELECT C.idEntidad, C.codigo  
        INTO #TMP_CodigosRelacionSistemas  
        FROM CodigosRelacionSistemas C WITH(NOLOCK)   
        WHERE C.tipoEntidad = 'CARRIER' 
            AND C.idSistemaEntidad = 100;  
    
        SELECT DISTINCT T.id, T.nombre  
        INTO #TMP_TRANS  
        FROM ParametrosLista PL   
        INNER JOIN ParametrosCatalogos PC WITH(NOLOCK) ON PC.idParametroLista = PL.id AND PC.valor = 'NO'  
        INNER JOIN Transportes T WITH(NOLOCK) ON T.idTransportePrincipal = PC.idEntidad  
        WHERE PL.codigo = 'EsDelivery' 
            AND PL.idEmpresa = @idEmpresa;  
  
        SELECT GHDH.idGuiaHouseDetalle, MAX(GHDH.fechaCambio) fechaCambio
        INTO #tmlGHH  
        FROM GuiasHouseDetallesHistorico GHDH WITH(NOLOCK)  
        WHERE GHDH.fechaCambio BETWEEN @FechaDesde AND @FechaHasta 
            AND GHDH.VALOR = 'DISPATCHED WH'  
        GROUP BY GHDH.idGuiaHouseDetalle;

		CREATE TABLE #TMP_ConsigneeByName (id VARCHAR(16))
		CREATE TABLE #TMP_BillToById     (id VARCHAR(16))
		CREATE TABLE #TMP_BillToByName   (id VARCHAR(16))

		IF @NombreClienteConsignee IS NOT NULL
			INSERT INTO #TMP_ConsigneeByName SELECT f.id FROM f_SearchEntities(@NombreClienteConsignee, 'Consignee') f

		IF @IdConsignee IS NULL AND @NombreClienteConsignee IS NULL
		BEGIN
			IF @IdBillTo IS NOT NULL
				INSERT INTO #TMP_BillToById SELECT f.id FROM f_SearchEntities(@IdBillTo, 'IdBillTo') f

			IF @NombreBillTo IS NOT NULL
				INSERT INTO #TMP_BillToByName SELECT f.id FROM f_SearchEntities(@NombreBillTo, 'BillTo') f
		END
  
        IF (     
            @NroDocumento              IS NULL AND 
            @Po                        IS NULL AND 
            @IdBillTo                  IS NULL AND
            @NombreBillTo              IS NULL AND
            @IdConsignee               IS NULL AND
            @NombreClienteConsignee    IS NULL AND
            @NroPOD                    IS NULL AND 
            @CodigoBarras              IS NULL AND 
            @NombreComercialExportador IS NULL AND
            @PalletLabel               IS NULL
        )  
        BEGIN     
            SELECT 
                GHD.id,  
                GHD.idGuiaHouse,  
                VCE.id      AS IdClienteFinal,  
                GHD.ShipToId,  
                GHD.ConsigneeId,  
                A.fechaCambio,  
                GHD.estadoPieza,  
                PC.ID       AS idProgramacionCarrier,  
                PC.fechaDespacho,  
                T.id        AS idSubCarrier,  
                T.nombre    AS nombreSubCarrier     
            INTO #TMP_GHD_MASIVO  
            FROM #tmlGHH A   
            INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON A.idGuiaHouseDetalle = GHD.id  
            INNER JOIN ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id   
            INNER JOIN v_ClientsEntities VCE WITH(NOLOCK) ON GHD.ShipToId = VCE.id     
            INNER JOIN #TMP_TRANS T ON PC.idCarrier = T.id;
  
            INSERT INTO #TablaAgrupacionGuiasHouse  
            SELECT      
                VCE.id                                          AS IdClienteFinal,
                GHD.ShipToId                                    AS IdShipTo,
                ISNULL(VCE.nombre, VCE.BillToName)              AS NombreClienteFinal,  
                MAX(GHD.fechaDespacho)                          AS FechaPickUpProgramada,   
                MAX(GHD.fechaCambio)                            AS FechaPickUpEntrega, 
                SUM(IIF(GHD.estadoPieza = 'PENDING',       1, 0)) AS TotalPending,  
                SUM(IIF(GHD.estadoPieza = 'HOLD',          1, 0)) AS TotalHold,  
                SUM(IIF(GHD.estadoPieza = 'SHORT',         1, 0)) AS TotalShort,  
                SUM(IIF(GHD.estadoPieza = 'RECEIVED WH',   1, 0)) AS TotalReceived,  
                SUM(IIF(GHD.estadoPieza = 'STANDBY',       1, 0)) AS TotalStandBy,  
                SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0)) AS TotalDespachado,  
                COUNT(1)                                        AS Total,     
                ISNULL(UB.idBodega, GH.idBodega)               AS idBodega,   
                ISNULL(BP.nombre, BG.nombre)                   AS nombreBodega,   
                MD.id                                          AS IdManifiesto,  
                GHD.idSubCarrier                               AS IdCarrier,  
                GHD.nombresubCarrier                           AS NombreCarrier,  
                CONVERT(BIT, 1)                                AS esPOD,  
                T1.codigo
            FROM #TMP_GHD_MASIVO GHD   
            INNER JOIN GuiasHouse GH WITH(NOLOCK) ON GHD.idGuiaHouse = GH.id  
            INNER JOIN v_ClientsEntities VCE WITH(NOLOCK) ON GHD.ShipToId = VCE.id     
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
            WHERE GH.idEmpresa = @idEmpresa 
                AND DCD.EsPod = 1  
            GROUP BY   
                VCE.id,
                GHD.ShipToId,  
                ISNULL(VCE.nombre, VCE.BillToName),
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
                GHD.ShipToId,  
                GHD.ConsigneeId,  
                GHD.po,  
                GHD.codigoBarra,  
                VCE.id      AS IdClienteFinal,  
                A.fechaCambio,  
                GHD.estadoPieza,  
                PC.ID       AS idProgramacionCarrier,  
                PC.fechaDespacho,  
                T.id        AS idSubCarrier,  
                T.nombre    AS nombreSubCarrier  
            INTO #TMP_GHD_FILTROS  
            FROM #tmlGHH A   
            INNER JOIN GuiasHouseDetalles GHD WITH(NOLOCK) ON A.idGuiaHouseDetalle = GHD.id
            INNER JOIN ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id   
            INNER JOIN v_ClientsEntities VCE WITH(NOLOCK) ON GHD.ShipToId = VCE.id     
            INNER JOIN #TMP_TRANS T ON PC.idCarrier = T.id;
  
            INSERT INTO #TablaAgrupacionGuiasHouse  
            SELECT      
                VCE.id                                                    AS IdClienteFinal,
                ghd.ShipToId                                              AS IdShipTo,     
                ISNULL(VCE.nombre, VCE.BillToName)                        AS NombreClienteFinal,  
                MAX(ghd.fechaDespacho)                                    AS FechaPickUpProgramada,  
                MAX(ghd.fechaCambio)                                      AS FechaPickUpEntrega,  
                SUM(IIF(ghd.estadoPieza = 'PENDING',       1, 0))         AS TotalPending,  
                SUM(IIF(ghd.estadoPieza = 'HOLD',          1, 0))         AS TotalHold,  
                SUM(IIF(ghd.estadoPieza = 'SHORT',         1, 0))         AS TotalShort,  
                SUM(IIF(ghd.estadoPieza = 'RECEIVED WH',   1, 0))         AS TotalReceived,  
                SUM(IIF(ghd.estadoPieza = 'STANDBY',       1, 0))         AS TotalStandBy,  
                SUM(IIF(ghd.estadoPieza = 'DISPATCHED WH', 1, 0))         AS TotalDespachado,  
                COUNT(1)                                                  AS Total,     
                ISNULL(ubicacionesBodega.idBodega, guiaHouse.idBodega)    AS idBodega,   
                ISNULL(bodegaPieza.nombre, bodegaGuia.nombre)             AS nombreBodega,   
                manifiestoDespacho.id                                     AS IdManifiesto,  
                ghd.idSubCarrier                                          AS IdCarrier,  
                ghd.nombresubCarrier                                      AS NombreCarrier,  
                CONVERT(BIT, 1)                                           AS esPOD,   
                T1.codigo    
            FROM #TMP_GHD_FILTROS ghd   
            INNER JOIN GuiasHouse guiaHouse WITH(NOLOCK) ON ghd.idGuiaHouse = guiaHouse.id  
            INNER JOIN v_ClientsEntities VCE WITH(NOLOCK) ON ghd.ShipToId = VCE.id     
            LEFT JOIN ProgramacionManifiesto programacionManifiesto WITH(NOLOCK) ON programacionManifiesto.idProgramacionCarrier = ghd.idProgramacionCarrier              
            LEFT JOIN ManifiestosDespacho manifiestoDespacho WITH(NOLOCK) ON manifiestoDespacho.id = programacionManifiesto.idManifiestoDespacho  
            OUTER APPLY (
                SELECT TOP 1 DD.EsPod
                FROM DocumentosDespacho DD WITH(NOLOCK)
                WHERE DD.idManifiesto = manifiestoDespacho.id 
                    AND DD.idDocumento = 'DOC052395'
                ORDER BY EsPod DESC
            ) dcd
            LEFT JOIN PalletsDetalles pld WITH(NOLOCK) ON ghd.id = pld.idGuiasHouseDetalle  
            LEFT JOIN Pallets pal WITH(NOLOCK) ON pld.idPallet = pal.id  
            INNER JOIN #TMP_CodigosRelacionSistemas T1 WITH(NOLOCK) ON ghd.idSubCarrier = T1.idEntidad  
            LEFT JOIN UbicacionPiezas AS ubicacionPiezas WITH(NOLOCK) ON ghd.id = ubicacionPiezas.idGuiaHouseDetalle  
            LEFT JOIN Ubicaciones AS ubicaciones WITH(NOLOCK) ON ubicacionPiezas.idUbicacion = ubicaciones.id  
            LEFT JOIN UbicacionesBodega AS ubicacionesBodega WITH(NOLOCK) ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id  
            LEFT JOIN Bodegas AS bodegaGuia WITH(NOLOCK) ON guiaHouse.idBodega = bodegaGuia.id  
            LEFT JOIN Bodegas AS bodegaPieza WITH(NOLOCK) ON ubicacionesBodega.idBodega = bodegaPieza.id 
            WHERE guiaHouse.idEmpresa = @idEmpresa 
                AND dcd.EsPod = 1  
                AND (@NroDocumento IS NULL OR guiaHouse.nroGuia LIKE '%' + @NroDocumento + '%')  
                AND (@Po IS NULL OR ghd.po LIKE '%' + @Po + '%')  
				AND (
					-- Prioridad Consignee (si llega cualquiera de los dos, ignorar BillTo)
					(@IdConsignee IS NOT NULL AND guiaHouse.ConsigneeId = @IdConsignee)
					OR
					(@NombreClienteConsignee IS NOT NULL AND guiaHouse.ConsigneeId IN (SELECT id FROM #TMP_ConsigneeByName))
					OR
					-- Prioridad BillTo (solo aplica si NO llegó ningún Consignee)
					(@IdConsignee IS NULL AND @NombreClienteConsignee IS NULL AND @IdBillTo IS NOT NULL AND guiaHouse.BillToConsigneeId IN (SELECT id FROM #TMP_BillToById))
					OR
					(@IdConsignee IS NULL AND @NombreClienteConsignee IS NULL AND @NombreBillTo IS NOT NULL AND guiaHouse.BillToConsigneeId IN (SELECT id FROM #TMP_BillToByName))
					OR
					-- Sin filtro
					(@IdConsignee IS NULL AND @NombreClienteConsignee IS NULL AND @IdBillTo IS NULL AND @NombreBillTo IS NULL)
				)
                AND (@NroPOD IS NULL OR manifiestoDespacho.nroManifiesto LIKE '%' + @NroPOD + '%')  
                AND (@CodigoBarras IS NULL OR ghd.codigoBarra LIKE '%' + @CodigoBarras + '%')  
                AND (@NombreComercialExportador IS NULL OR guiaHouse.idExportador IN (SELECT id FROM Exportadores WHERE nombre LIKE '%' + @NombreComercialExportador + '%'))  
                AND (@PalletLabel IS NULL OR pal.pallet LIKE '%' + @PalletLabel + '%')  
            GROUP BY   
                VCE.id,
                ghd.ShipToId,  
                ISNULL(VCE.nombre, VCE.BillToName),
                ISNULL(ubicacionesBodega.idBodega, guiaHouse.idBodega),   
                ISNULL(bodegaPieza.nombre, bodegaGuia.nombre),   
                manifiestoDespacho.id,  
                ghd.idSubCarrier,  
                ghd.nombresubCarrier,    
                T1.codigo  
            HAVING COUNT(1) = SUM(IIF(ghd.estadoPieza = 'DISPATCHED WH', 1, 0));
        END  
  
        SELECT        
            tmp.Id                                      AS Id,  
            tmp.IdClienteFinal,
            tmp.IdShipTo,  
            tmp.NombreClienteFinal,  
            tmp.IdBodega,  
            tmp.NombreBodega,  
            tmp.IdManifiesto,  
            tmp.IdCarrier,  
            tmp.NombreCarrier,  
            tmp.FechaPickUpProgramada,  
            tmp.FechaPickUpEntrega,  
            CONVERT(TIME, tmp.FechaPickUpEntrega)       AS HoraEntrega,  
            tmp.TotalPending                            AS PcsPending,  
            tmp.TotalHold                               AS PcsHold,  
            tmp.TotalShort                              AS PcsShort,  
            tmp.TotalReceived                           AS PcsReceivedWh,  
            tmp.TotalStandBy                            AS PcsStandby,  
            tmp.TotalDespachado                         AS TotalDespachado,  
            tmp.Total                                   AS Total,    
            CONVERT(BIT, 0)                             AS Enviado,  
            CONVERT(BIT, 0)                             AS Procesado,  
            NULL                                        AS TipoNubeDocs,  
            NULL                                        AS Estatus,  
            tmp.codigoCarrier  
        FROM #TablaAgrupacionGuiasHouse AS tmp;
		
    END TRY  
    BEGIN CATCH  
        EXEC [dbo].[pro_LogError];  
    END CATCH;  
END;