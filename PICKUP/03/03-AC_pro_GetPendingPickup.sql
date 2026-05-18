/*
VERSION     MODIFIEDBY          MODIFIEDDATE    HU      MODIFICATION
1           Ian Carlos Ortega   2026-01-26      57731   Based on dbo.pro_modulo_DespachoPickup
*/

CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetPendingPickup]
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
AS
BEGIN
    BEGIN TRY
        DECLARE 
            @VNroDocument VARCHAR(32) = @NroDocument,
            @VPo VARCHAR(64) = @Po,
            @VConsignee NVARCHAR(512) = @Consignee,
            @VBillTo NVARCHAR(512) = @BillTo,
            @VStatus VARCHAR(32) = @Status,
            @VNroManifiesto VARCHAR(32) = @NroManifiesto,
            @VBarcode VARCHAR(32) = @Barcode,
            @VSupplier NVARCHAR(512) = @Supplier,
            @VIdEmpresa VARCHAR(16) = @IdEmpresa,
            @VConsulta INT = @Consulta,     
            @VPalletLabel VARCHAR(16) = @PalletLabel,
            @FechaDespacho DATETIME = DATEADD(MM, -@FechaDesde, GETDATE()),
            @IdParametroDelivery VARCHAR(16),
            @IdParametroTipo VARCHAR(16)

        CREATE TABLE #TablaAgrupacionGuiasPickUp(
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
            esInventario BIT)

        SELECT @IdParametroDelivery = id
        FROM ParametrosLista PL WITH (NOLOCK)
        WHERE PL.codigo = 'EsDelivery'
            AND PL.idEmpresa = @VIdEmpresa;

        SELECT @IdParametroTipo = id
        FROM ParametrosLista PL WITH (NOLOCK)
        WHERE PL.codigo = 'TipoManifiestoDespacho'
            AND PL.idEmpresa = @VIdEmpresa;

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
            GHD.ShipToId,
            GHD.truckId,
            GHD.despachadoDestino,
            PC.idUsuarioLogPicking,
            TE.idTE
        INTO #TMP_PROGRAM
        FROM ProgramacionCarrier PC WITH (NOLOCK)
            INNER JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id
            INNER JOIN ParametrosCatalogos P WITH (NOLOCK) ON T.idTransportePrincipal = P.idEntidad 
                AND P.idParametroLista = @IdParametroDelivery 
                AND P.valor = 'NO'
            INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GHD.id = PC.idGuiaHouseDetalle
            LEFT JOIN ProgramacionTe TE WITH (NOLOCK) ON PC.id = TE.idProgramacionCarrier
        WHERE PC.fechaDespacho > @FechaDespacho
            AND (@VPo IS NULL OR GHD.po LIKE @VPo + '%')

        CREATE TABLE #TMP_BillToByName (
            id VARCHAR(16),
        );

        CREATE TABLE #TMP_ConsigneeByName (
            id VARCHAR(16)
        );

        IF @VBillTo IS NOT NULL
        BEGIN
            INSERT INTO #TMP_BillToByName
            SELECT Id FROM f_SearchEntities(@VBillTo, 'BillTo') 
        END

        IF @VConsignee IS NOT NULL
        BEGIN
            INSERT INTO #TMP_ConsigneeByName
            SELECT Id FROM f_SearchEntities(@VConsignee, 'Consignee') 
        END

        IF (@VNroDocument IS NULL AND @VPo IS NULL AND @VConsignee IS NULL AND @VNroManifiesto IS NULL AND @VSupplier IS NULL AND @VBarcode IS NULL AND @VPalletLabel IS NULL)
        BEGIN
            INSERT INTO #TablaAgrupacionGuiasPickUp
            SELECT
                MD.id,
                MD.nroManifiesto,
                VCE.nombre as ShipToName,
                PR.ShipToId,
                ISNULL(ub.idBodega, H.idBodega) idBodega,
                ISNULL(BP.nombre, BG.nombre) nombreBodega,
                PR.idCarrier,
                PR.truckId,
                PR.fechaDespacho,
                PCA.valor,
                COUNT(PR.estadoPieza),
                SUM(IIF(PR.estadoPieza = 'DISPATCHED WH', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'STANDBY', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'HOLD', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'PENDING', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'RECEIVED WH', 1, 0)),
                SUM(IIF(PR.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),
                ISNULL(DCD.esPOD, 0),
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
                    WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
                    ELSE 0
                END esInventario
            FROM #TMP_PROGRAM PR
                INNER JOIN #TMP_CodigosRelacionSistemas T1 ON PR.idCarrier = T1.idEntidad
                INNER JOIN GuiasHouse GH WITH (NOLOCK) ON PR.idGuiaHouse = GH.id
                INNER JOIN v_ClientsEntities VCE WITH (NOLOCK) ON VCE.id = PR.ShipToId
                INNER JOIN dbo.Paises PAC ON VCE.idPais = PAC.id
                CROSS APPLY
                (
                    SELECT G.ConsigneeId, idBodega
                    FROM GuiasHouse G WITH (NOLOCK)
                    WHERE PR.idGuiaHouse = G.id
                ) H
                LEFT JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON PCA.idEntidad = H.ConsigneeId 
                    AND PCA.idParametroLista = @IdParametroTipo
                LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PR.id = PM.idProgramacionCarrier
                LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
                OUTER APPLY (
                    SELECT TOP 1 DD.EsPod
                    FROM DocumentosDespacho DD WITH (NOLOCK)
                    WHERE DD.idManifiesto = MD.id
                    AND DD.idDocumento = 'DOC052395'
                    ORDER BY EsPod DESC
                ) DCD
                LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON PR.idGuiaHouseDetalle = UP.idGuiaHouseDetalle
                LEFT JOIN Ubicaciones U WITH (NOLOCK) ON UP.idUbicacion = U.id
                LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON U.idUbicacionBodega = UB.id
                LEFT JOIN Bodegas BG WITH (NOLOCK) ON H.idBodega = BG.id
                LEFT JOIN Bodegas BP WITH (NOLOCK) ON UB.idBodega = BP.id
                LEFT JOIN
                (
                    SELECT
                        PR.idGuiaHouseDetalle,
                        SV.id,
                        SV.nroOrden,
                        SVD.picking,
                        SV.fechaSolicitud,
                        ROW_NUMBER() OVER (PARTITION BY PR.idGuiaHouseDetalle ORDER BY SV.fechaSolicitud DESC) rown,
                        SV.tipoVenta,
                        SVD.tipoPieza
                    FROM #TMP_PROGRAM PR
                    INNER JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON PR.idGuiaHouseDetalle = SVD.idGuiaHouseDetalle
                    INNER JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud
                ) SVC ON PR.idGuiaHouseDetalle = SVC.idGuiaHouseDetalle AND SVC.rown = 1
                LEFT JOIN Paises PCF ON VCE.idPais = PCF.id
            WHERE @VIdEmpresa IS NULL OR GH.idEmpresa = @VIdEmpresa
            GROUP BY
                MD.id,
                MD.nroManifiesto,
                VCE.nombre,
                PR.ShipToId,
                ISNULL(UB.idBodega, H.idBodega),
                ISNULL(BP.nombre, BG.nombre),
                PR.idCarrier,
                PR.truckId,
                PR.fechaDespacho,
                PCA.valor,
                DCD.esPOD,
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
                    WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
                    ELSE 0
                END;
        END
        ELSE
        BEGIN
            INSERT INTO #TablaAgrupacionGuiasPickUp
            SELECT
                MD.id,
                MD.nroManifiesto,
                VCE.nombre AS ShipToName,
                PR.ShipToId ShipToId,
                ISNULL(UB.idBodega, H.idBodega) idBodega,
                ISNULL(BP.nombre, BG.nombre) nombreBodega,
                PR.idCarrier,
                PR.truckId,
                PR.fechaDespacho,
                PCA.valor,
                COUNT(PR.estadoPieza),
                SUM(IIF(PR.estadoPieza = 'DISPATCHED WH', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'STANDBY', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'HOLD', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'PENDING', 1, 0)),
                SUM(IIF(PR.estadoPieza = 'RECEIVED WH', 1, 0)),
                SUM(IIF(PR.estadoPieza IN ('SHORT', 'LOST'), 1, 0)),
                ISNULL(DCD.esPOD, 0),
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
                    WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
                    ELSE 0
                END esInventario
            FROM #TMP_PROGRAM PR
                INNER JOIN #TMP_CodigosRelacionSistemas T1 ON PR.idCarrier = T1.idEntidad
                INNER JOIN GuiasHouse GH WITH (NOLOCK) ON PR.idGuiaHouse = GH.id
                INNER JOIN v_ClientsEntities VCE WITH (NOLOCK) ON VCE.id = PR.ShipToId
                INNER JOIN dbo.Paises PAC ON VCE.idPais = PAC.id
                CROSS APPLY
                (
                    SELECT G.ConsigneeId, G.BillToConsigneeId, idBodega, idExportador, nroGuia
                    FROM GuiasHouse G WITH (NOLOCK)
                    WHERE PR.idGuiaHouse = G.id
                ) H
                LEFT JOIN dbo.PalletsDetalles pld WITH (NOLOCK) ON PR.idGuiaHouseDetalle = pld.idGuiasHouseDetalle
                LEFT JOIN dbo.Pallets pal WITH (NOLOCK) ON pld.idPallet = pal.id
                LEFT JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON PCA.idEntidad = H.ConsigneeId AND PCA.idParametroLista = @IdParametroTipo
                LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON PR.id = PM.idProgramacionCarrier
                LEFT JOIN manifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
                OUTER APPLY (
                    SELECT TOP 1 DD.EsPod
                    FROM DocumentosDespacho DD WITH (NOLOCK)
                    WHERE DD.idManifiesto = MD.id
                    AND DD.idDocumento = 'DOC052395'
                    ORDER BY EsPod DESC
                ) DCD
                LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON PR.idGuiaHouseDetalle = UP.idGuiaHouseDetalle
                LEFT JOIN Ubicaciones U WITH (NOLOCK) ON UP.idUbicacion = U.id
                LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON U.idUbicacionBodega = UB.id
                LEFT JOIN Bodegas BG WITH (NOLOCK) ON H.idBodega = BG.id
                LEFT JOIN Bodegas BP WITH (NOLOCK) ON UB.idBodega = BP.id
                LEFT JOIN
                (
                    SELECT
                        PR.idGuiaHouseDetalle,
                        SV.id,
                        SV.nroOrden,
                        SVD.picking,
                        SV.fechaSolicitud,
                        ROW_NUMBER() OVER (PARTITION BY PR.idGuiaHouseDetalle ORDER BY SV.fechaSolicitud DESC) AS rown,
                        SV.tipoVenta,
                        tipoPieza
                    FROM #TMP_PROGRAM PR
                    INNER JOIN SolicitudDeVentaDetalles SVD WITH (NOLOCK) ON PR.idGuiaHouseDetalle = SVD.idGuiaHouseDetalle
                    INNER JOIN SolicitudDeVenta SV WITH (NOLOCK) ON SV.id = SVD.idSolicitud
                ) SVC ON PR.idGuiaHouseDetalle = SVC.idGuiaHouseDetalle AND SVC.rown = 1
                LEFT JOIN dbo.Paises PCF ON VCE.idPais = PCF.id
            WHERE (@VIdEmpresa IS NULL OR GH.idEmpresa = @VIdEmpresa)
                AND (@VBarcode IS NULL OR PR.codigoBarra LIKE '%' + @VBarcode + '%')
                AND (@VNroDocument IS NULL OR H.nroGuia LIKE '%' + @VNroDocument + '%')
                AND (@VConsignee IS NULL OR (EXISTS(SELECT 1 FROM #TMP_ConsigneeByName) AND H.ConsigneeId IN (SELECT id FROM #TMP_ConsigneeByName)))
                AND (@VBillTo IS NULL OR (EXISTS(SELECT 1 FROM #TMP_BillToByName) AND H.BillToConsigneeId IN (SELECT id FROM #TMP_BillToByName)))
                AND (@VSupplier IS NULL OR H.idExportador IN (SELECT id FROM Exportadores WITH (NOLOCK) WHERE nombre LIKE '%' + @VSupplier + '%'))
                AND (@VPalletLabel IS NULL OR pal.pallet LIKE '%' + @VPalletLabel + '%')
                AND (@VNroManifiesto IS NULL OR MD.nroManifiesto LIKE '%' + @VNroManifiesto + '%')
            GROUP BY
                MD.id,
                MD.nroManifiesto,
                VCE.nombre,
                PR.ShipToId,
                ISNULL(UB.idBodega, H.idBodega),
                ISNULL(BP.nombre, BG.nombre),
                PR.idCarrier,
                PR.truckId,
                PR.fechaDespacho,
                PCA.valor,
                DCD.esPOD,
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
                    WHEN SVC.tipoVenta = 5 AND SVC.tipoPieza = 1 THEN 1
                    ELSE 0
                END;
        END

        SELECT
            NEWID() id,
            RES.idManifiesto,
            RES.nroManifiesto,
            RES.ShipToId,
            RES.fechaDespacho,
            RES.idBodega,
            RES.nombreBodega,
            RES.ShipToName,
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
            SUM(RES.totalPickingLoading) TotalPickingLoading,
            RES.idPaisCliente,
            RES.idPaisAlt,
            RES.idTEGuid,
            RES.esInventario
        FROM #TablaAgrupacionGuiasPickUp RES
        GROUP BY
            RES.idManifiesto,
            RES.nroManifiesto,
            RES.ShipToId,
            RES.fechaDespacho,
            RES.idBodega,
            RES.nombreBodega,
            RES.ShipToName,
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