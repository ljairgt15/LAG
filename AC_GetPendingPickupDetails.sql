CREATE OR ALTER PROCEDURE [dbo].[AC_GetPendingPickupDetails]
(
	@nroDocument	VARCHAR(20) = NULL,
	@po				VARCHAR(20) = NULL,
	@Consignee		VARCHAR(100) = NULL,
	@status			VARCHAR(20) = NULL,
	@nroManifiesto	VARCHAR(50) = NULL,
	@barcode		VARCHAR(20) = NULL,
	@supplier		VARCHAR(100) = NULL,
	@pending		INT,
	@consulta		INT,
	@idClienteFinal VARCHAR(30) = NULL,
	@idCarrier		VARCHAR(30) = NULL,
	@fechaDespacho	DATETIME = NULL,
	@fechaDesde		INT,
	@palletLabel	VARCHAR(20) = NULL,
	@idBodega		VARCHAR(32) = NULL,
	@idEmpresa		VARCHAR(16) = NULL,
	@idOrdenVenta	UNIQUEIDENTIFIER = NULL,
	@esInventario   BIT = NULL,
    @BillTo         VARCHAR(128) = NULL
)
AS
BEGIN
    BEGIN TRY
		DECLARE @idParametroDelivery VARCHAR(16)

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
            IdOrdenventa          UNIQUEIDENTIFIER,
            Po                    VARCHAR(64),
            IdCliente             VARCHAR(16),
            DespachadoDestino     VARCHAR(16),
			TotalPickingLoading   INT,
			IdTEGuid			  UNIQUEIDENTIFIER NULL,
			EsInventario		  BIT
        );

		SELECT @idParametroDelivery = id 
		FROM ParametrosLista parametroLista WITH (NOLOCK) 
		WHERE parametroLista.codigo = 'EsDelivery'
			AND parametroLista.idEmpresa = @idEmpresa;

        IF (@consulta = 1) -- Consulta un cliente final
            BEGIN
                INSERT INTO #TMP_AgrupacionGuiasPickUp
                SELECT GHD.id
                     , GH.id
                     , GHD.estadoPieza
                     , GHD.ShipToId
                     , PC.fechaDespacho
                     , ISNULL(B1.nombre, B.nombre)
                     , ISNULL(UB.idBodega, GH.idBodega)
                     , PC.idCarrier
                     , PC.id
                     , CLF.nombre
                     , GH.nroGuia
                     , PE.nroPo
                     , CLF.idPais
                     , GHD.truckId
                     , CGN.nombre
                     , CGN.id
                     , EDI.idUsuarioLog
                     , GH.idUsuarioLog
                     , US.nombre
                     , 0
                     , PCAT.valor
                     , NULL
                     , V.nroOrden
                     , GH.house
                     , EDI.fechaCambio
                     , GH.fechaCambio
                     , GH.idExportador
                     , PAL.pallet
                     , SUM(CASE WHEN V.picking = 1 THEN 1 ELSE 0 END)
                     , V.id
                     , GHD.po
                     , GH.ConsigneeId
                     , GHD.despachadoDestino
                     , SUM(CASE WHEN PC.idUsuarioLogPicking IS NOT NULL THEN 1 ELSE 0 END)
                     , TE.idTE
                     , CI.ValorEsInventario
                FROM  ProgramacionCarrier PC  WITH (NOLOCK)
                     INNER JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id
                     INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON T.idTransportePrincipal = PCA.idEntidad 
                                                                     AND PCA.idParametroLista = @idParametroDelivery 
                                                                     AND PCA.valor = 'NO'
                     INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
                     INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
                     INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
                     INNER JOIN v_ClientsEntities CLF WITH (NOLOCK) ON CLF.id = GHD.ShipToId
                     INNER JOIN v_ClientsEntities CGN WITH (NOLOCK) ON CGN.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
                     LEFT JOIN ParametrosCatalogos PCAT WITH (NOLOCK) ON PCAT.EntityTypeId = CGN.ConsigneeId AND PCAT.idParametroLista = PLC.id
                     LEFT JOIN ProgramacionTe TE WITH (NOLOCK) ON PC.id = TE.idProgramacionCarrier  
                     LEFT JOIN EDI ON PC.idCarrier = EDI.idCarrier AND PC.fechaDespacho = EDI.fechaDespacho
                     LEFT JOIN Usuarios US WITH (NOLOCK) ON EDI.idUsuarioLog = US.id
                     LEFT JOIN PoDetalles PD WITH (NOLOCK) ON GHD.idPoDetalle = PD.id
                     LEFT JOIN PoEncabezado PE ON PD.idPo = PE.id
                     OUTER APPLY (SELECT TOP (1) SV.id, SV.nroOrden, SVD.picking, SV.tipoVenta, SVD.tipoPieza
                                  FROM SolicitudDeVentaDetalles SVD
                                       LEFT JOIN SolicitudDeVenta SV ON SV.id = SVD.idSolicitud
                                  WHERE SVD.idGuiaHouseDetalle = GHD.id
                                  ORDER BY SV.fechaSolicitud DESC) V
                     LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON GHD.id = PLD.idGuiasHouseDetalle
                     LEFT JOIN Pallets PAL WITH (NOLOCK) ON PLD.idPallet = PAL.id
                     LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
                     LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
                     LEFT JOIN UbicacionesBodega UB ON U.idUbicacionBodega = UB.id
                     LEFT JOIN Bodegas B ON GH.idBodega = B.id
                     LEFT JOIN Bodegas B1 ON UB.idBodega = B1.id
                     CROSS APPLY (
                        SELECT CASE 
                            WHEN V.tipoVenta < 4 THEN 1 
                            WHEN V.tipoVenta = 5 AND V.tipoPieza = 1 THEN 1 
                            ELSE 0 
                        END AS ValorEsInventario
                     ) AS CI
                WHERE PC.fechaDespacho = @fechaDespacho
                  AND GH.idEmpresa = @idEmpresa              
                  AND (@idOrdenVenta IS NULL OR V.id = @idOrdenVenta)
                  AND GHD.ShipToId = @idClienteFinal
                  AND (@idCarrier IS NULL OR PC.idCarrier = @idCarrier)
                  AND (@palletLabel IS NULL OR PAL.pallet LIKE '%' + @palletLabel + '%')
                  AND (@idBodega IS NULL OR ISNULL(UB.idBodega, GH.idBodega) = @idBodega)
                  AND (@esInventario IS NULL OR CI.ValorEsInventario = @esInventario)

                GROUP BY GHD.id
                       , GH.id
                       , GHD.estadoPieza
                       , GHD.ShipToId
                       , PC.fechaDespacho
                       , ISNULL(B1.nombre, B.nombre)
                       , ISNULL(UB.idBodega, GH.idBodega)
                       , PC.idCarrier
                       , PC.id
                       , CLF.nombre
                       , GH.nroGuia
                       , PE.nroPo
                       , CLF.idPais
                       , GHD.truckId
                       , CGN.nombre
                       , CGN.id
                       , EDI.idUsuarioLog
                       , GH.idUsuarioLog
                       , US.nombre
                       , PCAT.valor
                       , V.nroOrden
                       , V.id
                       , GH.house
                       , EDI.fechaCambio
                       , GH.fechaCambio
                       , GH.idExportador
                       , PAL.pallet
                       , GHD.po
                       , GH.ConsigneeId
                       , GHD.despachadoDestino
                       , TE.idTE
                       , CI.ValorEsInventario

                IF (@nroManifiesto IS NULL)
                    BEGIN
                        SELECT APU.Id
                             , APU.IdGuiaHouse
                             , MD.id AS IdManifiesto
                             , DD.mailEnviado AS MailEnviado
                             , APU.EstadoPieza
                             , APU.IdClienteFinal
                             , APU.FechaDespacho
                             , APU.NombreBodega
                             , APU.IdBodega
                             , ISNULL(ISNULL(APU.IdUsuarioLogEdi, MD.idUsuarioLog), APU.IdUsuarioLogHouse) AS IdUsuarioLog
                             , CASE
                                   WHEN APU.IdUsuarioLogEdi IS NOT NULL THEN APU.NombreUsuario
                                   WHEN MD.idUsuarioLog IS NOT NULL THEN U.nombre
                                   ELSE USH.nombre
                               END AS NombreUsuario
                             , APU.NombreClienteFinal
                             , APU.IdCarrier
                             , APU.NroGuia
                             , MD.nroManifiesto AS NroManifiesto
                             , APU.NroPo
                             , APU.IdPaisCliente
                             , DD.nombreArchivo AS TipoNubeDocs
                             , ISNULL(ISNULL(APU.FechaCambio, MD.fechaCambio), APU.FechaCambioHouse) AS UsuarioFechaCambio
                             , APU.TruckId
                             , APU.NombreConsignee
                             , APU.IdConsignee
                             , APU.TotalPiezas
                             , APU.Valor
                             , APU.CodigoBarra
                             , APU.NroOrden
                             , APU.House
                             , APU.TotalPicking
                             , APU.IdOrdenventa
                             , APU.DespachadoDestino
                             , APU.TotalPickingLoading
                             , APU.IdTEGuid
                             , APU.EsInventario
                        FROM #TMP_AgrupacionGuiasPickUp APU
                             LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.IdProgramacionCarrier = PM.idProgramacionCarrier
                             LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
                             OUTER APPLY (
                                SELECT TOP 1 DD.EsPod, DD.nombreArchivo, DD.mailEnviado
                                FROM DocumentosDespacho DD WITH (NOLOCK)
                                WHERE DD.idManifiesto = MD.id
                                AND DD.idDocumento = 'DOC052395'
                                ORDER BY DD.EsPod DESC
                            ) DD
                             LEFT JOIN Usuarios U ON MD.idUsuarioLog = U.id
                             LEFT JOIN Usuarios USH ON APU.IdUsuarioLogHouse = USH.id
                        WHERE MD.nroManifiesto IS NULL
                    END;
                ELSE
                    BEGIN
                        SELECT APU.Id
                             , APU.IdGuiaHouse
                             , MD.id AS IdManifiesto
                             , DD.mailEnviado AS MailEnviado
                             , APU.EstadoPieza
                             , APU.IdClienteFinal
                             , APU.FechaDespacho
                             , APU.NombreBodega
                             , APU.IdBodega
                             , ISNULL(ISNULL(APU.IdUsuarioLogEdi, MD.idUsuarioLog), APU.IdUsuarioLogHouse) AS IdUsuarioLog
                             , CASE
                                   WHEN APU.IdUsuarioLogEdi IS NOT NULL THEN APU.NombreUsuario
                                   WHEN MD.idUsuarioLog IS NOT NULL THEN U.nombre
                                   ELSE USH.nombre
                               END AS NombreUsuario
                             , APU.NombreClienteFinal
                             , APU.IdCarrier
                             , APU.NroGuia
                             , MD.nroManifiesto AS NroManifiesto
                             , APU.NroPo
                             , APU.IdPaisCliente
                             , DD.nombreArchivo AS TipoNubeDocs
                             , ISNULL(ISNULL(APU.FechaCambio, MD.fechaCambio), APU.FechaCambioHouse) AS UsuarioFechaCambio
                             , APU.TruckId
                             , APU.NombreConsignee
                             , APU.IdConsignee
                             , APU.TotalPiezas
                             , APU.Valor
                             , APU.CodigoBarra
                             , APU.NroOrden
                             , APU.House
                             , APU.TotalPicking
                             , APU.IdOrdenventa
                             , APU.DespachadoDestino
                             , APU.TotalPickingLoading
                             , APU.IdTEGuid
                             , APU.EsInventario
                        FROM #TMP_AgrupacionGuiasPickUp APU
                             INNER JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.IdProgramacionCarrier = PM.idProgramacionCarrier
                             INNER JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
                             OUTER APPLY (
                                SELECT TOP 1 DD.EsPod, DD.nombreArchivo, DD.mailEnviado
                                FROM DocumentosDespacho DD WITH (NOLOCK)
                                WHERE DD.idManifiesto = MD.id
                                AND DD.idDocumento = 'DOC052395'
                                ORDER BY DD.EsPod DESC
                            ) DD
                             LEFT JOIN Usuarios U ON MD.idUsuarioLog = U.id
                             LEFT JOIN Usuarios USH ON APU.IdUsuarioLogHouse = USH.id
                        WHERE MD.nroManifiesto = @nroManifiesto
                          AND ISNULL(DD.esPOD, 0) = 0
                    END;
            END;
        ELSE
            IF (@consulta = 2)
                BEGIN
                    INSERT INTO #TMP_AgrupacionGuiasPickUp
                    SELECT GHD.id
                         , GH.id
                         , GHD.estadoPieza
                         , GHD.ShipToId
                         , PC.fechaDespacho
                         , ISNULL(B1.nombre, B.nombre)
						 , ISNULL(UB.idBodega, GH.idBodega)
                         , PC.idCarrier
                         , PC.id
                         , CLF.nombre
                         , GH.nroGuia
                         , PE.nroPo
                         , CLF.idPais
                         , GHD.truckId
                         , CGN.nombre
                         , CGN.id
                         , EDI.idUsuarioLog
                         , GH.idUsuarioLog
                         , US.nombre
                         , 0
                         , PCAT.valor
                         , GHD.codigoBarra
                         , V.nroOrden
                         , GH.house
                         , EDI.fechaCambio
                         , GH.fechaCambio
                         , GH.idExportador
                         , PAL.pallet
                         , SUM(CASE WHEN V.picking = 1 THEN 1 ELSE 0 END)
                         , V.id
                         , GHD.po
                         , GH.ConsigneeId
                         , GHD.despachadoDestino
						 , SUM(CASE WHEN PC.idUsuarioLogPicking IS NOT NULL THEN 1 ELSE 0 END)
						 , TE.idTE
						 , CI.ValorEsInventario
                    FROM ProgramacionCarrier PC  WITH (NOLOCK)
                         INNER JOIN Transportes T ON PC.idCarrier = T.id
                         INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON T.idTransportePrincipal = PCA.idEntidad 
																	 AND PCA.idParametroLista = @idParametroDelivery 
																	 AND PCA.valor = 'NO'
                         INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
                         INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
                         INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
                         INNER JOIN v_ClientsEntities CLF WITH (NOLOCK) ON CLF.id = GHD.ShipToId
                         INNER JOIN v_ClientsEntities CGN WITH (NOLOCK) ON CGN.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
                         LEFT JOIN ParametrosCatalogos PCAT WITH (NOLOCK) ON PCAT.EntityTypeId = CGN.ConsigneeId AND PCAT.idParametroLista = PLC.id
						 LEFT JOIN ProgramacionTe TE WITH (NOLOCK) ON PC.id = TE.idProgramacionCarrier  
                         LEFT JOIN EDI ON PC.idCarrier = EDI.idCarrier AND PC.fechaDespacho = EDI.fechaDespacho
                         LEFT JOIN Usuarios US ON EDI.idUsuarioLog = US.id
                         LEFT JOIN PoDetalles PD ON GHD.idPoDetalle = PD.id
                         LEFT JOIN PoEncabezado PE ON PD.idPo = PE.id
                         OUTER APPLY (SELECT TOP (1) SV.id, SV.nroOrden, SVD.picking, SV.tipoVenta, SVD.tipoPieza
                                      FROM SolicitudDeVentaDetalles SVD
                                           LEFT JOIN SolicitudDeVenta SV ON SV.id = SVD.idSolicitud
                                      WHERE SVD.idGuiaHouseDetalle = GHD.id
                                      ORDER BY SV.fechaSolicitud DESC) AS V
                         LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON GHD.id = PLD.idGuiasHouseDetalle
                         LEFT JOIN Pallets PAL WITH (NOLOCK) ON PLD.idPallet = PAL.id
                         LEFT JOIN UbicacionPiezas AS UP WITH (NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
                         LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
                         LEFT JOIN UbicacionesBodega UB ON U.idUbicacionBodega = UB.id
                         LEFT JOIN Bodegas B ON GH.idBodega = B.id
                         LEFT JOIN Bodegas B1 ON UB.idBodega = B1.id
                         CROSS APPLY (
                                SELECT CASE 
                                    WHEN V.tipoVenta < 4 THEN 1 
                                    WHEN V.tipoVenta = 5 AND V.tipoPieza = 1 THEN 1 
                                    ELSE 0 
                                END AS ValorEsInventario
                        ) AS CI
                    WHERE PC.fechaDespacho > DATEADD(MM, -@fechaDesde, GETDATE())            
                    AND GH.idEmpresa = @idEmpresa                     
                    AND GHD.esPOD = 0
                    AND (@Consignee IS NULL OR CGN.nombre LIKE '%' + @Consignee + '%')
                    AND (@BillTo IS NULL OR (CGN.BillToId IS NOT NULL AND CGN.BillToName LIKE '%' + @BillTo + '%'))
                    AND (@idCarrier IS NULL OR PC.idCarrier = @idCarrier)
                    AND (@idBodega IS NULL OR ISNULL(UB.idBodega, GH.idBodega) = @idBodega)
                    AND (@nroDocument IS NULL OR GH.nroGuia LIKE '%' + @nroDocument + '%')
                    AND (@po IS NULL OR GHD.po LIKE '%' + @po + '%')
                    AND (@barcode IS NULL OR GHD.codigoBarra LIKE '%' + @barcode + '%')
                    AND (@supplier IS NULL OR GH.idExportador IN (SELECT id FROM Exportadores WITH (NOLOCK) WHERE nombre LIKE '%' + @supplier + '%'))
                    AND (@palletLabel IS NULL OR PAL.pallet LIKE '%' + @palletLabel + '%')
                    AND (@esInventario IS NULL OR CI.ValorEsInventario = @esInventario)
                    GROUP BY GHD.id
                           , GH.id
                           , GHD.estadoPieza
                           , GHD.ShipToId
                           , PC.fechaDespacho
                           , ISNULL(B1.nombre, B.nombre) 
						   , ISNULL(UB.idBodega, GH.idBodega)
                           , PC.idCarrier
                           , PC.id
                           , CLF.nombre
                           , GH.nroGuia
                           , PE.nroPo
                           , CLF.idPais
                           , GHD.truckId
                           , CGN.nombre
                           , CGN.id
                           , EDI.idUsuarioLog
                           , GH.idUsuarioLog
                           , US.nombre
						   , PCAT.valor
                           , V.nroOrden
                           , V.id
                           , GH.house
                           , EDI.fechaCambio
                           , GH.fechaCambio
                           , GH.idExportador
                           , PAL.pallet
                           , GHD.po
                           , GH.ConsigneeId
                           , GH.idExportador
                           , GHD.despachadoDestino
						   , GHD.codigoBarra 
						   , TE.idTE
						   , CI.ValorEsInventario
						   
                    SELECT APU.Id
                         , APU.IdGuiaHouse
                         , MD.id AS IdManifiesto
                         , DD.mailEnviado AS MailEnviado
                         , APU.EstadoPieza
                         , APU.IdClienteFinal
                         , APU.FechaDespacho
                         , APU.NombreBodega
                         , APU.IdBodega
                         , ISNULL(ISNULL(APU.IdUsuarioLogEdi, MD.idUsuarioLog), APU.IdUsuarioLogHouse) AS IdUsuarioLog
                         , CASE
                               WHEN APU.IdUsuarioLogEdi IS NOT NULL THEN APU.NombreUsuario
                               WHEN MD.idUsuarioLog IS NOT NULL THEN U.nombre
                               ELSE USH.nombre
                           END AS NombreUsuario
                         , APU.NombreClienteFinal
                         , APU.IdCarrier
                         , APU.NroGuia
                         , MD.nroManifiesto AS NroManifiesto
                         , APU.NroPo
                         , APU.IdPaisCliente
                         , DD.nombreArchivo AS TipoNubeDocs
						 , ISNULL(ISNULL(APU.FechaCambio, MD.fechaCambio), APU.FechaCambioHouse) AS UsuarioFechaCambio
                         , APU.TruckId
                         , APU.NombreConsignee
                         , APU.IdConsignee
                         , APU.TotalPiezas
                         , APU.Valor
                         , APU.CodigoBarra
                         , APU.NroOrden
                         , APU.House
                         , APU.TotalPicking
                         , APU.IdOrdenventa
                         , APU.DespachadoDestino
                         , APU.TotalPickingLoading
						 , APU.IdTEGuid
						 , APU.EsInventario
                    FROM #TMP_AgrupacionGuiasPickUp APU
                         LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.IdProgramacionCarrier = PM.idProgramacionCarrier
                         LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
                         OUTER APPLY (
								SELECT TOP 1 DD.EsPod, DD.nombreArchivo, DD.mailEnviado
								FROM DocumentosDespacho DD WITH (NOLOCK)
								WHERE DD.idManifiesto = MD.id
								AND DD.idDocumento = 'DOC052395'
								ORDER BY DD.EsPod DESC
							) DD
                         LEFT JOIN Usuarios U ON MD.idUsuarioLog = U.id
                         LEFT JOIN Usuarios USH ON APU.IdUsuarioLogHouse = USH.id
                    WHERE 
						(@nroManifiesto IS NULL
                        OR MD.nroManifiesto LIKE '%' + @nroManifiesto + '%')
                        AND ISNULL(DD.esPOD, 0) = 0
                END;
    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError]
    END CATCH;
END;