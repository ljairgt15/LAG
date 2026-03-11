/* VERSION     MODIFIEDBY        MODIFIEDDATE    HU     MODIFICATION
   1           Jair Gomez        2026-02-03      57731  Based on pro_Despacho_DespachoDetallePickUp
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_GetPendingPickupDetails]
(
    @NroDocument    VARCHAR(20) = NULL,
    @Po             VARCHAR(20) = NULL,
    @Consignee      VARCHAR(100)= NULL,
    @Status         VARCHAR(20) = NULL,
    @NroManifiesto  VARCHAR(50) = NULL,
    @Barcode        VARCHAR(20) = NULL,
    @Supplier       VARCHAR(100)= NULL,
    @Pending        INT,
    @Consulta       INT,
    @IdClienteFinal VARCHAR(30) = NULL,
    @IdCarrier      VARCHAR(30) = NULL,
    @FechaDespacho  DATETIME    = NULL,
    @FechaDesde     INT,
    @PalletLabel    VARCHAR(20) = NULL,
    @IdBodega       VARCHAR(32) = NULL,
    @IdEmpresa      VARCHAR(16) = NULL,
    @IdOrdenVenta   UNIQUEIDENTIFIER = NULL,
    @EsInventario   BIT = NULL,
    @BillTo         VARCHAR(128)= NULL
)
AS
BEGIN
    BEGIN TRY
        DECLARE @IdParametroDelivery VARCHAR(16)

        CREATE TABLE #TMP_AgrupacionGuiasPickUp
        (
            Id                    UNIQUEIDENTIFIER NOT NULL,
            IdGuiaHouse           UNIQUEIDENTIFIER NOT NULL,
            EstadoPieza           NVARCHAR(64)     NOT NULL,
            IdClienteFinal        VARCHAR(16)      NOT NULL,
            FechaDespacho         DATETIME         NOT NULL,
            NombreBodega          NVARCHAR(512)    NULL,
            IdBodega              VARCHAR(16)      NOT NULL,
            IdCarrier             VARCHAR(16)      NOT NULL,
            IdProgramacionCarrier UNIQUEIDENTIFIER NOT NULL,
            NombreClienteFinal    VARCHAR(256)     NOT NULL,
            NroGuia               VARCHAR(32)      NOT NULL,
            NroPo                 VARCHAR(50)      NULL,
            IdPaisCliente         VARCHAR(16)      NULL,
            TruckId               VARCHAR(10)      NULL,
            NombreConsignee       VARCHAR(512)     NULL,
            IdConsignee           VARCHAR(16)      NOT NULL,
            IdUsuarioLogEdi       VARCHAR(16)      NULL,
            IdUsuarioLogHouse     VARCHAR(16)      NULL,
            NombreUsuario         NVARCHAR(64)     NULL,
            TotalPiezas           INT,
            Valor                 VARCHAR(1024)    NULL,
            CodigoBarra           VARCHAR(16)      NULL,
            NroOrden              VARCHAR(16)      NULL,
            House                 VARCHAR(32)      NULL,
            FechaCambio           DATETIME         NULL,
            FechaCambioHouse      DATETIME         NOT NULL,
            IdExportador          VARCHAR(16)      NULL,
            Pallet                VARCHAR(16)      NULL,
            TotalPicking          INT,
            IdOrdenVenta          UNIQUEIDENTIFIER,
            Po                    VARCHAR(64),
            IdCliente             VARCHAR(16),
            DespachadoDestino     VARCHAR(16),
            TotalPickingLoading   INT,
            IdTEGuid              UNIQUEIDENTIFIER NULL,
            EsInventario          BIT
        );

        SELECT @IdParametroDelivery = PL.Id 
        FROM ParametrosLista PL 
        WHERE PL.Codigo = 'EsDelivery'
          AND PL.IdEmpresa = @IdEmpresa;

        -- Consulta 1: Consulta un cliente final
        IF (@Consulta = 1) 
        BEGIN
            INSERT INTO #TMP_AgrupacionGuiasPickUp
            SELECT 
                GHD.Id
               ,GH.Id
               ,GHD.EstadoPieza
               ,GHD.ShipToId
               ,PC.FechaDespacho
               ,ISNULL(B1.Nombre, B.Nombre)
               ,ISNULL(UB.IdBodega, GH.IdBodega)
               ,PC.IdCarrier
               ,PC.Id
               ,CLF.Nombre
               ,GH.NroGuia
               ,PE.NroPo
               ,CLF.IdPais
               ,GHD.TruckId
               ,CGN.Nombre
               ,CGN.Id
               ,EDI.IdUsuarioLog
               ,GH.IdUsuarioLog
               ,US.Nombre
               ,0
               ,PCAT.Valor
               ,NULL
               ,V.NroOrden
               ,GH.House
               ,EDI.FechaCambio
               ,GH.FechaCambio
               ,GH.IdExportador
               ,PAL.Pallet
               ,SUM(CASE WHEN V.Picking = 1 THEN 1 ELSE 0 END)
               ,V.Id
               ,GHD.Po
               ,GH.ConsigneeId
               ,GHD.DespachadoDestino
               ,SUM(CASE WHEN PC.IdUsuarioLogPicking IS NOT NULL THEN 1 ELSE 0 END)
               ,TE.IdTE
               ,CI.ValorEsInventario
            FROM ProgramacionCarrier PC WITH (NOLOCK)
            INNER JOIN Transportes T ON PC.IdCarrier = T.Id
            INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
                                              AND PCA.IdParametroLista = @IdParametroDelivery 
                                              AND PCA.Valor = 'NO'
            INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id
            INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id
            INNER JOIN ParametrosLista PLC ON PLC.Codigo = 'TipoManifiestoDespacho' AND PLC.IdEmpresa = GH.IdEmpresa
            INNER JOIN v_ClientsEntities CLF ON CLF.Id = GHD.ShipToId
            INNER JOIN v_ClientsEntities CGN ON CGN.Id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
            LEFT JOIN ParametrosCatalogos PCAT ON PCAT.EntityTypeId = CGN.ConsigneeId AND PCAT.IdParametroLista = PLC.Id
            LEFT JOIN ProgramacionTe TE ON PC.Id = TE.IdProgramacionCarrier  
            LEFT JOIN EDI ON PC.IdCarrier = EDI.IdCarrier AND PC.FechaDespacho = EDI.FechaDespacho
            LEFT JOIN Usuarios US ON EDI.IdUsuarioLog = US.Id
            LEFT JOIN PoDetalles PD WITH (NOLOCK) ON GHD.IdPoDetalle = PD.Id
            LEFT JOIN PoEncabezado PE ON PD.IdPo = PE.Id
            OUTER APPLY (
                SELECT TOP (1) SV.Id, SV.NroOrden, SVD.Picking, SV.TipoVenta, SVD.TipoPieza
                FROM SolicitudDeVentaDetalles SVD
                LEFT JOIN SolicitudDeVenta SV ON SV.Id = SVD.IdSolicitud
                WHERE SVD.IdGuiaHouseDetalle = GHD.Id
                ORDER BY SV.FechaSolicitud DESC
            ) V
            LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON GHD.Id = PLD.IdGuiasHouseDetalle
            LEFT JOIN Pallets PAL WITH (NOLOCK) ON PLD.IdPallet = PAL.Id
            LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle
            LEFT JOIN Ubicaciones U ON UP.IdUbicacion = U.Id
            LEFT JOIN UbicacionesBodega UB ON U.IdUbicacionBodega = UB.Id
            LEFT JOIN Bodegas B ON GH.IdBodega = B.Id
            LEFT JOIN Bodegas B1 ON UB.IdBodega = B1.Id
            CROSS APPLY (
                SELECT CASE 
                    WHEN V.TipoVenta < 4 THEN 1 
                    WHEN V.TipoVenta = 5 AND V.TipoPieza = 1 THEN 1 
                    ELSE 0 
                END AS ValorEsInventario
            ) AS CI
            WHERE PC.FechaDespacho = @FechaDespacho
              AND GH.IdEmpresa = @IdEmpresa              
              AND (@IdOrdenVenta IS NULL OR V.Id = @IdOrdenVenta)
              AND GHD.ShipToId = @IdClienteFinal
              AND (@IdCarrier IS NULL OR PC.IdCarrier = @IdCarrier)
              AND (@PalletLabel IS NULL OR PAL.Pallet LIKE '%' + @PalletLabel + '%')
              AND (@IdBodega IS NULL OR ISNULL(UB.IdBodega, GH.IdBodega) = @IdBodega)
              AND (@EsInventario IS NULL OR CI.ValorEsInventario = @EsInventario)
            GROUP BY 
                GHD.Id, GH.Id, GHD.EstadoPieza, GHD.ShipToId, PC.FechaDespacho,
                ISNULL(B1.Nombre, B.Nombre), ISNULL(UB.IdBodega, GH.IdBodega),
                PC.IdCarrier, PC.Id, CLF.Nombre, GH.NroGuia, PE.NroPo, CLF.IdPais,
                GHD.TruckId, CGN.Nombre, CGN.Id, EDI.IdUsuarioLog, GH.IdUsuarioLog,
                US.Nombre, PCAT.Valor, V.NroOrden, V.Id, GH.House, EDI.FechaCambio,
                GH.FechaCambio, GH.IdExportador, PAL.Pallet, GHD.Po, GH.ConsigneeId,
                GHD.DespachadoDestino, TE.IdTE, CI.ValorEsInventario;

            IF (@NroManifiesto IS NULL)
            BEGIN
                SELECT 
                    APU.Id
                   ,APU.IdGuiaHouse
                   ,MD.Id AS IdManifiesto
                   ,DD.MailEnviado
                   ,APU.EstadoPieza
                   ,APU.IdClienteFinal
                   ,APU.FechaDespacho
                   ,APU.NombreBodega
                   ,APU.IdBodega
                   ,ISNULL(ISNULL(APU.IdUsuarioLogEdi, MD.IdUsuarioLog), APU.IdUsuarioLogHouse) AS IdUsuarioLog
                   ,CASE
                       WHEN APU.IdUsuarioLogEdi IS NOT NULL THEN APU.NombreUsuario
                       WHEN MD.IdUsuarioLog IS NOT NULL THEN U.Nombre
                       ELSE USH.Nombre
                    END AS NombreUsuario
                   ,APU.NombreClienteFinal
                   ,APU.IdCarrier
                   ,APU.NroGuia
                   ,MD.NroManifiesto
                   ,APU.NroPo
                   ,APU.IdPaisCliente
                   ,DD.NombreArchivo AS TipoNubeDocs
                   ,ISNULL(ISNULL(APU.FechaCambio, MD.FechaCambio), APU.FechaCambioHouse) AS UsuarioFechaCambio
                   ,APU.TruckId
                   ,APU.NombreConsignee
                   ,APU.IdConsignee
                   ,APU.TotalPiezas
                   ,APU.Valor
                   ,APU.CodigoBarra
                   ,APU.NroOrden
                   ,APU.House
                   ,APU.TotalPicking
                   ,APU.IdOrdenVenta
                   ,APU.DespachadoDestino
                   ,APU.TotalPickingLoading
                   ,APU.IdTEGuid
                   ,APU.EsInventario
                FROM #TMP_AgrupacionGuiasPickUp APU
                LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.IdProgramacionCarrier = PM.IdProgramacionCarrier
                LEFT JOIN ManifiestosDespacho MD ON PM.IdManifiestoDespacho = MD.Id
                OUTER APPLY (
                    SELECT TOP 1 DD.EsPod, DD.NombreArchivo, DD.MailEnviado
                    FROM DocumentosDespacho DD 
                    WHERE DD.IdManifiesto = MD.Id
                      AND DD.IdDocumento = 'DOC052395'
                    ORDER BY DD.EsPod DESC
                ) DD
                LEFT JOIN Usuarios U ON MD.IdUsuarioLog = U.Id
                LEFT JOIN Usuarios USH ON APU.IdUsuarioLogHouse = USH.Id
                WHERE MD.NroManifiesto IS NULL;
            END;
            ELSE
            BEGIN
                SELECT 
                    APU.Id
                   ,APU.IdGuiaHouse
                   ,MD.Id AS IdManifiesto
                   ,DD.MailEnviado
                   ,APU.EstadoPieza
                   ,APU.IdClienteFinal
                   ,APU.FechaDespacho
                   ,APU.NombreBodega
                   ,APU.IdBodega
                   ,ISNULL(ISNULL(APU.IdUsuarioLogEdi, MD.IdUsuarioLog), APU.IdUsuarioLogHouse) AS IdUsuarioLog
                   ,CASE
                       WHEN APU.IdUsuarioLogEdi IS NOT NULL THEN APU.NombreUsuario
                       WHEN MD.IdUsuarioLog IS NOT NULL THEN U.Nombre
                       ELSE USH.Nombre
                    END AS NombreUsuario
                   ,APU.NombreClienteFinal
                   ,APU.IdCarrier
                   ,APU.NroGuia
                   ,MD.NroManifiesto
                   ,APU.NroPo
                   ,APU.IdPaisCliente
                   ,DD.NombreArchivo AS TipoNubeDocs
                   ,ISNULL(ISNULL(APU.FechaCambio, MD.FechaCambio), APU.FechaCambioHouse) AS UsuarioFechaCambio
                   ,APU.TruckId
                   ,APU.NombreConsignee
                   ,APU.IdConsignee
                   ,APU.TotalPiezas
                   ,APU.Valor
                   ,APU.CodigoBarra
                   ,APU.NroOrden
                   ,APU.House
                   ,APU.TotalPicking
                   ,APU.IdOrdenVenta
                   ,APU.DespachadoDestino
                   ,APU.TotalPickingLoading
                   ,APU.IdTEGuid
                   ,APU.EsInventario
                FROM #TMP_AgrupacionGuiasPickUp APU
                INNER JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.IdProgramacionCarrier = PM.IdProgramacionCarrier
                INNER JOIN ManifiestosDespacho MD ON PM.IdManifiestoDespacho = MD.Id
                OUTER APPLY (
                    SELECT TOP 1 DD.EsPod, DD.NombreArchivo, DD.MailEnviado
                    FROM DocumentosDespacho DD
                    WHERE DD.IdManifiesto = MD.Id
                      AND DD.IdDocumento = 'DOC052395'
                    ORDER BY DD.EsPod DESC
                ) DD
                LEFT JOIN Usuarios U ON MD.IdUsuarioLog = U.Id
                LEFT JOIN Usuarios USH ON APU.IdUsuarioLogHouse = USH.Id
                WHERE MD.NroManifiesto = @NroManifiesto
                  AND ISNULL(DD.EsPod, 0) = 0;
            END;
        END;
        ELSE IF (@Consulta = 2)
        BEGIN
            INSERT INTO #TMP_AgrupacionGuiasPickUp
            SELECT 
                GHD.Id
               ,GH.Id
               ,GHD.EstadoPieza
               ,GHD.ShipToId
               ,PC.FechaDespacho
               ,ISNULL(B1.Nombre, B.Nombre)
               ,ISNULL(UB.IdBodega, GH.IdBodega)
               ,PC.IdCarrier
               ,PC.Id
               ,CLF.Nombre
               ,GH.NroGuia
               ,PE.NroPo
               ,CLF.IdPais
               ,GHD.TruckId
               ,CGN.Nombre
               ,CGN.Id
               ,EDI.IdUsuarioLog
               ,GH.IdUsuarioLog
               ,US.Nombre
               ,0
               ,PCAT.Valor
               ,GHD.CodigoBarra
               ,V.NroOrden
               ,GH.House
               ,EDI.FechaCambio
               ,GH.FechaCambio
               ,GH.IdExportador
               ,PAL.Pallet
               ,SUM(CASE WHEN V.Picking = 1 THEN 1 ELSE 0 END)
               ,V.Id
               ,GHD.Po
               ,GH.ConsigneeId
               ,GHD.DespachadoDestino
               ,SUM(CASE WHEN PC.IdUsuarioLogPicking IS NOT NULL THEN 1 ELSE 0 END)
               ,TE.IdTE
               ,CI.ValorEsInventario
            FROM ProgramacionCarrier PC WITH (NOLOCK) 
            INNER JOIN Transportes T ON PC.IdCarrier = T.Id
            INNER JOIN ParametrosCatalogos PCA ON T.IdTransportePrincipal = PCA.IdEntidad 
                                              AND PCA.IdParametroLista = @IdParametroDelivery 
                                              AND PCA.Valor = 'NO'
            INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.IdGuiaHouseDetalle = GHD.Id 
            INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.IdGuiaHouse = GH.Id 
            INNER JOIN ParametrosLista PLC ON PLC.Codigo = 'TipoManifiestoDespacho' AND PLC.IdEmpresa = GH.IdEmpresa
            INNER JOIN v_ClientsEntities CLF ON CLF.Id = GHD.ShipToId
            INNER JOIN v_ClientsEntities CGN ON CGN.Id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
            LEFT JOIN ParametrosCatalogos PCAT ON PCAT.EntityTypeId = GH.ConsigneeId AND PCAT.IdParametroLista = PLC.Id
            LEFT JOIN ProgramacionTe TE ON PC.Id = TE.IdProgramacionCarrier  
            LEFT JOIN EDI ON PC.IdCarrier = EDI.IdCarrier AND PC.FechaDespacho = EDI.FechaDespacho
            LEFT JOIN Usuarios US ON EDI.IdUsuarioLog = US.Id
            LEFT JOIN PoDetalles PD WITH (NOLOCK) ON GHD.IdPoDetalle = PD.Id -- Transaccional en lista
            LEFT JOIN PoEncabezado PE ON PD.IdPo = PE.Id
            OUTER APPLY (
                SELECT TOP (1) SV.Id, SV.NroOrden, SVD.Picking, SV.TipoVenta, SVD.TipoPieza
                FROM SolicitudDeVentaDetalles SVD
                LEFT JOIN SolicitudDeVenta SV ON SV.Id = SVD.IdSolicitud
                WHERE SVD.IdGuiaHouseDetalle = GHD.Id
                ORDER BY SV.FechaSolicitud DESC
            ) AS V
            LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON GHD.Id = PLD.IdGuiasHouseDetalle 
            LEFT JOIN Pallets PAL WITH (NOLOCK) ON PLD.IdPallet = PAL.Id 
            LEFT JOIN UbicacionPiezas AS UP WITH (NOLOCK) ON GHD.Id = UP.IdGuiaHouseDetalle 
            LEFT JOIN Ubicaciones U ON UP.IdUbicacion = U.Id
            LEFT JOIN UbicacionesBodega UB ON U.IdUbicacionBodega = UB.Id
            LEFT JOIN Bodegas B ON GH.IdBodega = B.Id
            LEFT JOIN Bodegas B1 ON UB.IdBodega = B1.Id
            CROSS APPLY (
                SELECT CASE 
                    WHEN V.TipoVenta < 4 THEN 1 
                    WHEN V.TipoVenta = 5 AND V.TipoPieza = 1 THEN 1 
                    ELSE 0 
                END AS ValorEsInventario
            ) AS CI
            WHERE PC.FechaDespacho > DATEADD(MM, -@FechaDesde, GETDATE())
            AND GH.IdEmpresa = @IdEmpresa                     
            AND GHD.EsPod = 0
            AND (@Consignee IS NULL OR @Consignee = ''
                OR CGN.Id IN (SELECT Id FROM dbo.f_SearchEntities(@Consignee, 'Consignee')))    
            AND (@BillTo IS NULL OR @BillTo = '' 
                OR CGN.Id IN (SELECT Id FROM dbo.f_SearchEntities(@BillTo, 'BillTo')))
            AND (@IdCarrier IS NULL OR PC.IdCarrier = @IdCarrier)
            AND (@IdBodega IS NULL OR ISNULL(UB.IdBodega, GH.IdBodega) = @IdBodega)
            AND (@NroDocument IS NULL OR GH.NroGuia LIKE '%' + @NroDocument + '%')
            AND (@Po IS NULL OR GHD.Po LIKE '%' + @Po + '%')
            AND (@Barcode IS NULL OR GHD.CodigoBarra LIKE '%' + @Barcode + '%')
            AND (@Supplier IS NULL OR GH.IdExportador IN (SELECT Id FROM Exportadores WHERE Nombre LIKE '%' + @Supplier + '%'))
            AND (@PalletLabel IS NULL OR PAL.Pallet LIKE '%' + @PalletLabel + '%')
            AND (@EsInventario IS NULL OR CI.ValorEsInventario = @EsInventario)
            GROUP BY 
                GHD.Id, GH.Id, GHD.EstadoPieza, GHD.ShipToId, PC.FechaDespacho,
                ISNULL(B1.Nombre, B.Nombre), ISNULL(UB.IdBodega, GH.IdBodega),
                PC.IdCarrier, PC.Id, CLF.Nombre, GH.NroGuia, PE.NroPo, CLF.IdPais,
                GHD.TruckId, CGN.Nombre, CGN.Id, EDI.IdUsuarioLog, GH.IdUsuarioLog,
                US.Nombre, PCAT.Valor, V.NroOrden, V.Id, GH.House, EDI.FechaCambio,
                GH.FechaCambio, GH.IdExportador, PAL.Pallet, GHD.Po, GH.ConsigneeId,
                GH.IdExportador, GHD.DespachadoDestino, GHD.CodigoBarra, TE.IdTE, CI.ValorEsInventario;

            SELECT 
                APU.Id
               ,APU.IdGuiaHouse
               ,MD.Id AS IdManifiesto
               ,DD.MailEnviado
               ,APU.EstadoPieza
               ,APU.IdClienteFinal
               ,APU.FechaDespacho
               ,APU.NombreBodega
               ,APU.IdBodega
               ,ISNULL(ISNULL(APU.IdUsuarioLogEdi, MD.IdUsuarioLog), APU.IdUsuarioLogHouse) AS IdUsuarioLog
               ,CASE
                   WHEN APU.IdUsuarioLogEdi IS NOT NULL THEN APU.NombreUsuario
                   WHEN MD.IdUsuarioLog IS NOT NULL THEN U.Nombre
                   ELSE USH.Nombre
                END AS NombreUsuario
               ,APU.NombreClienteFinal
               ,APU.IdCarrier
               ,APU.NroGuia
               ,MD.NroManifiesto
               ,APU.NroPo
               ,APU.IdPaisCliente
               ,DD.NombreArchivo AS TipoNubeDocs
               ,ISNULL(ISNULL(APU.FechaCambio, MD.FechaCambio), APU.FechaCambioHouse) AS UsuarioFechaCambio
               ,APU.TruckId
               ,APU.NombreConsignee
               ,APU.IdConsignee
               ,APU.TotalPiezas
               ,APU.Valor
               ,APU.CodigoBarra
               ,APU.NroOrden
               ,APU.House
               ,APU.TotalPicking
               ,APU.IdOrdenVenta
               ,APU.DespachadoDestino
               ,APU.TotalPickingLoading
               ,APU.IdTEGuid
               ,APU.EsInventario
            FROM #TMP_AgrupacionGuiasPickUp APU
            LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.IdProgramacionCarrier = PM.IdProgramacionCarrier 
            LEFT JOIN ManifiestosDespacho MD ON PM.IdManifiestoDespacho = MD.Id
            OUTER APPLY (
                SELECT TOP 1 DD.EsPod, DD.NombreArchivo, DD.MailEnviado
                FROM DocumentosDespacho DD
                WHERE DD.IdManifiesto = MD.Id
                  AND DD.IdDocumento = 'DOC052395'
                ORDER BY DD.EsPod DESC
            ) DD
            LEFT JOIN Usuarios U ON MD.IdUsuarioLog = U.Id
            LEFT JOIN Usuarios USH ON APU.IdUsuarioLogHouse = USH.Id
            WHERE (@NroManifiesto IS NULL OR MD.NroManifiesto LIKE '%' + @NroManifiesto + '%')
              AND ISNULL(DD.EsPod, 0) = 0;
        END;

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError]
    END CATCH;
END;
/*
EXEC [dbo].[AC_pro_GetPendingPickupDetails]
    @Pending         = 0,       
    @Consulta        = 2,
    @FechaDesde      = 1,
	@IdEmpresa       ='EMP014',
	@BillTo=NULL;
EXEC [dbo].[AC_pro_GetPendingPickupDetails]
    @NroDocument     = NULL,
    @Po              = NULL,
    @Consignee       = NULL,
    @Status          = 'PENDING',
    @NroManifiesto   = NULL,
    @Barcode         = NULL,
    @Supplier        = NULL,
    @Pending         = 0,       
    @Consulta        = 2,
    @IdClienteFinal  = 'ETY00053007',
    @IdCarrier       = 'ybOy4oex7F5E',
    @FechaDespacho   = '2026-01-10',
    @FechaDesde      = 1,
    @PalletLabel     = NULL,
    @IdBodega        = 'LXgyot5M',
	@IdEmpresa       ='EMP014',
    @IdOrdenVenta    = NULL,
    @EsInventario    = 0,
	@BillTo=NULL;
*/