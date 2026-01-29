USE [alliance_desa]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER     PROCEDURE [dbo].[AC_pro_GetPendingPickupDetails]
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
    @BillTo         VARCHAR(100) = NULL -- NUEVO PARÁMETRO
)
AS
BEGIN
    BEGIN TRY
		DECLARE @idParametroDelivery VARCHAR(16)

        CREATE TABLE #TablaAgrupacionGuiasPickUp
        (
            id                    UNIQUEIDENTIFIER NOT NULL,
            idGuiaHouse           UNIQUEIDENTIFIER NOT NULL,
            estadoPieza           NVARCHAR(64)     NOT NULL,
            idClienteFinal        VARCHAR(16)      NOT NULL,
            fechaDespacho         DATETIME         NOT NULL,
            nombreBodega          NVARCHAR(512)    NULL,
            idBodega              VARCHAR(16)      NOT NULL,
            idCarrier             VARCHAR(16)      NOT NULL,
            idProgramacionCarrier UNIQUEIDENTIFIER NOT NULL,
            nombreClienteFinal    VARCHAR(256)     NOT NULL,
            nroGuia               VARCHAR(32)      NOT NULL,
            nroPo                 VARCHAR(50)      NULL,
            idPaisCliente         VARCHAR(16)      NULL,
            truckId               VARCHAR(10)      NULL,
            nombreConsignee       NVARCHAR(512)    NULL,
            idConsignee           VARCHAR(16)      NOT NULL,
            idUsuarioLogEdi       VARCHAR(16)      NULL,
            idUsuarioLogHouse     VARCHAR(16)      NULL,
            nombreUsuario         NVARCHAR(64)     NULL,
            totalPiezas           INT,
            valor                 VARCHAR(1024)    NULL,
            codigoBarra           VARCHAR(16)      NULL,
            nroOrden              VARCHAR(16)      NULL,
            house                 VARCHAR(32)      NULL,
            fechaCambio           DATETIME         NULL,
            fechaCambioHouse      DATETIME         NOT NULL,
            idExportador          VARCHAR(16)      NULL,
            pallet                VARCHAR(16)      NULL,
            totalPicking          INT,
            idOrdenventa          UNIQUEIDENTIFIER,
            po                    VARCHAR(64),
            idCliente             VARCHAR(16),
            despachadoDestino     VARCHAR(16),
			totalPickingLoading   INT,
			idTEGuid			  UNIQUEIDENTIFIER NULL,
			esInventario		  BIT
        );

		SELECT @idParametroDelivery = id 
		FROM ParametrosLista parametroLista WITH (NOLOCK) 
		WHERE parametroLista.codigo = 'EsDelivery'
			AND parametroLista.idEmpresa = @idEmpresa;

        IF (@consulta = 1) -- Consulta un cliente final
            BEGIN
                INSERT INTO #TablaAgrupacionGuiasPickUp
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
                     , 0 -- TotalPiezas
                     , PCAT.valor
                     , NULL -- CodigoBarra (En consulta 1 suele ir nulo según tu original)
                     , V.nroOrden
                     , GH.house
                     , EDI.fechaCambio
                     , GH.fechaCambio
                     , GH.idExportador
                     , PAL.pallet
                     , SUM(IIF(V.picking = 1, 1, 0))
                     , V.id
                     , GHD.po
                     , ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
                     , GHD.despachadoDestino
                     , SUM(IIF(PC.idUsuarioLogPicking IS NOT NULL, 1, 0))
                     , TE.idTE
                     , CalcInventario.ValorEsInventario -- Usando Cross Apply
                FROM  ProgramacionCarrier PC  WITH (NOLOCK)
                     INNER JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id
					 INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON t.idTransportePrincipal = PCA.idEntidad 
																	 AND PCA.idParametroLista = @idParametroDelivery 
																	 AND PCA.valor = 'NO'
                     INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
                     INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
					 INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
                     INNER JOIN v_ClientsEntities CLF WITH (NOLOCK) ON CLF.id = GHD.ShipToId
                     INNER JOIN v_ClientsEntities CGN WITH (NOLOCK) ON CGN.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
					 LEFT JOIN ParametrosCatalogos PCAT WITH (NOLOCK) ON PCAT.EntityTypeId = CGN.ConsigneeId AND PCAT.idParametroLista = PLC.id
					 LEFT JOIN ProgramacionTe te WITH (NOLOCK) ON PC.id = TE.idProgramacionCarrier  
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
                     -- CROSS APPLY para cálculo de inventario
                     CROSS APPLY (
                        SELECT CASE 
                            WHEN V.tipoVenta < 4 THEN 1 
                            WHEN V.tipoVenta = 5 AND V.tipoPieza = 1 THEN 1 
                            ELSE 0 
                        END AS ValorEsInventario
                     ) AS CalcInventario
                WHERE PC.fechaDespacho = @fechaDespacho
				  AND GH.idEmpresa = @idEmpresa              
                  AND (@idOrdenVenta IS NULL OR V.id = @idOrdenVenta)
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
                       , ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
                       , GHD.despachadoDestino  
					   , TE.idTE
                       , CalcInventario.ValorEsInventario

                IF (@nroManifiesto IS NULL)
                    BEGIN
                        SELECT APU.id
                             , APU.idGuiaHouse
                             , MD.id idManifiesto
                             , DD.mailEnviado
                             , APU.estadoPieza
                             , APU.idClienteFinal
                             , APU.fechaDespacho
                             , APU.nombreBodega
                             , APU.idBodega
                             , ISNULL(ISNULL(APU.idUsuarioLogEdi, MD.idUsuarioLog), APU.idUsuarioLogHouse) AS idUsuarioLog
                             , CASE
                                   WHEN APU.idUsuarioLogEdi IS NOT NULL THEN APU.nombreUsuario
                                   WHEN MD.idUsuarioLog IS NOT NULL THEN U.nombre
                                   ELSE USH.nombre
                               END AS nombreUsuario
                             , APU.nombreClienteFinal
                             , APU.idCarrier
                             , APU.nroGuia
                             , MD.nroManifiesto
                             , APU.nroPo
                             , APU.idPaisCliente
                             , DD.nombreArchivo tipoNubeDocs
							 , ISNULL(ISNULL(APU.fechaCambio, MD.fechaCambio), APU.fechaCambioHouse) AS usuarioFechaCambio
                             , APU.truckId
                             , APU.nombreConsignee
                             , APU.idConsignee
                             , APU.totalPiezas
                             , APU.valor
                             , APU.codigoBarra
                             , APU.nroOrden
                             , APU.house
                             , APU.totalPicking
                             , APU.idOrdenventa
                             , APU.despachadoDestino
                             , APU.totalPickingLoading TotalPickingLoading
							 , APU.idTEGuid
							 , APU.esInventario
                        FROM #TablaAgrupacionGuiasPickUp APU
                             LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.idProgramacionCarrier = PM.idProgramacionCarrier
                             LEFT JOIN manifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
							 OUTER APPLY (
								SELECT TOP 1 DD.EsPod, DD.nombreArchivo, DD.mailEnviado
								FROM DocumentosDespacho DD WITH (NOLOCK)
								WHERE DD.idManifiesto = MD.id
								AND DD.idDocumento = 'DOC052395'
								ORDER BY EsPod DESC
							) DD
                             LEFT JOIN Usuarios U ON MD.idUsuarioLog = U.id
                             LEFT JOIN Usuarios USH ON APU.idUsuarioLogHouse = USH.id
                             LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON APU.id = PLD.idGuiasHouseDetalle 
                             LEFT JOIN Pallets PAL WITH (NOLOCK) ON PLD.idPallet = PAL.id
                        WHERE MD.nroManifiesto IS NULL
                          AND APU.idClienteFinal = @idClienteFinal
                          AND APU.idCarrier = @idCarrier
                          AND (@palletLabel IS NULL OR PAL.pallet LIKE '%' + @palletLabel + '%') 
                          AND APU.idBodega = @IdBodega
						  AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN APU.esInventario = @esInventario THEN 1
								ELSE 0
							END = 1
                    END;
                ELSE -- Consulta todos los detalles pickup pendientes de hace 3 meses
                    BEGIN
                        SELECT APU.id
                             , APU.idGuiaHouse
                             , MD.id idManifiesto
                             , DD.mailEnviado
                             , APU.estadoPieza
                             , APU.idClienteFinal
                             , APU.fechaDespacho
                             , APU.nombreBodega
                             , APU.idBodega
                             ,ISNULL(ISNULL(APU.idUsuarioLogEdi, MD.idUsuarioLog), APU.idUsuarioLogHouse) AS idUsuarioLog
                             , CASE
                                   WHEN APU.idUsuarioLogEdi IS NOT NULL THEN APU.nombreUsuario
                                   WHEN MD.idUsuarioLog IS NOT NULL THEN U.nombre
                                   ELSE USH.nombre
                               END nombreUsuario
                             , APU.nombreClienteFinal
                             , APU.idCarrier
                             , APU.nroGuia
                             , MD.nroManifiesto
                             , APU.nroPo
                             , APU.idPaisCliente
                             , DD.nombreArchivo tipoNubeDocs
                             , ISNULL(ISNULL(APU.fechaCambio, MD.fechaCambio), APU.fechaCambioHouse) AS usuarioFechaCambio
                             , APU.truckId
                             , APU.nombreConsignee
                             , APU.idConsignee
                             , APU.totalPiezas
                             , APU.valor
                             , APU.codigoBarra
                             , APU.nroOrden
                             , APU.house
                             , APU.totalPicking
                             , APU.idOrdenventa
                             , APU.despachadoDestino
                             , APU.totalPickingLoading TotalPickingLoading
							 , APU.idTEGuid
							 , APU.esInventario
                        FROM #TablaAgrupacionGuiasPickUp APU
                             LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.idProgramacionCarrier = PM.idProgramacionCarrier
                             LEFT JOIN ManifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
							 OUTER APPLY (
								SELECT TOP 1 DD.EsPod, DD.nombreArchivo, DD.mailEnviado
								FROM DocumentosDespacho DD WITH (NOLOCK)
								WHERE DD.idManifiesto = MD.id
								AND DD.idDocumento = 'DOC052395'
								ORDER BY EsPod DESC
							) DD
                             LEFT JOIN Usuarios U ON MD.idUsuarioLog = U.id
                             LEFT JOIN Usuarios USH ON APU.idUsuarioLogHouse = USH.id
                             LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON APU.id = PLD.idGuiasHouseDetalle
                             LEFT JOIN Pallets PAL WITH (NOLOCK) ON PLD.idPallet = PAL.id
                        WHERE APU.idClienteFinal = @idClienteFinal
                        AND MD.nroManifiesto = @nroManifiesto
                        AND APU.idCarrier = @idCarrier
                        AND (@palletLabel IS NULL OR PAL.pallet LIKE '%' + @palletLabel + '%')
                        AND APU.idBodega = @IdBodega
						AND CASE 
								WHEN @esInventario IS NULL THEN 1
								WHEN APU.esInventario = @esInventario THEN 1
								ELSE 0
							END = 1
                    END;
            END;
        ELSE
            IF (@consulta = 2)
                BEGIN
                    INSERT INTO #TablaAgrupacionGuiasPickUp
                    SELECT GHD.id
                         , GH.id idGuiaHouse
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
                         , 0 totalPiezas
                         , PCAT.valor
                         , GHD.codigoBarra
                         , V.nroOrden
                         , GH.house
                         , EDI.fechaCambio
                         , GH.fechaCambio
                         , GH.idExportador
                         , PAL.pallet
                         , SUM(IIF(V.picking = 1, 1, 0))
                         , V.id
                         , GHD.po
                         , ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
                         , GHD.despachadoDestino
						 , SUM(IIF(PC.idUsuarioLogPicking IS NOT NULL, 1, 0))
						 , TE.idTE
						 , CalcInventario.ValorEsInventario
                    FROM ProgramacionCarrier PC  WITH (NOLOCK)
                         INNER JOIN Transportes T ON PC.idCarrier = T.id
                         INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON t.idTransportePrincipal = PCA.idEntidad 
																	 AND PCA.idParametroLista = @idParametroDelivery 
																	 AND PCA.valor = 'NO'
                         INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
                         INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
                         INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
                         -- CAMBIO: Vista ShipTo
                         INNER JOIN v_ClientsEntities CLF WITH (NOLOCK) ON CLF.id = GHD.ShipToId
                         -- CAMBIO: Vista Header Híbrida
                         INNER JOIN v_ClientsEntities CGN WITH (NOLOCK) ON CGN.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
                         -- CAMBIO: ParametrosCatalogos con ID Normalizado
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
                        ) AS CalcInventario
                    WHERE PC.fechaDespacho > DATEADD(MM, -@fechaDesde, GETDATE())            
                    AND GH.idEmpresa = @idEmpresa                     
                    AND GHD.esPOD = 0
                    -- 1. FILTROS NUEVOS (CONSIGNEE / BILLTO)
                    AND (@Consignee IS NULL OR CGN.nombre LIKE '%' + @Consignee + '%')
                    AND (@BillTo IS NULL OR (CGN.BillToId IS NOT NULL AND CGN.EntityName LIKE '%' + @BillTo + '%'))
                    -- 2. FILTROS OPTIMIZADOS (MOVIDOS DEL FINAL AL PRINCIPIO) --------------------
                    AND (@idCarrier IS NULL OR PC.idCarrier = @idCarrier)
                    -- Bodega (Replica la lógica del SELECT: ISNULL(Ubicacion, Header))
                    AND (@idBodega IS NULL OR ISNULL(UB.idBodega, GH.idBodega) = @idBodega)
                    -- Nro Documento (Guía)
                    AND (@nroDocument IS NULL OR GH.nroGuia LIKE '%' + @nroDocument + '%')
                    -- PO
                    AND (@po IS NULL OR GHD.po LIKE '%' + @po + '%')
                    -- Barcode
                    AND (@barcode IS NULL OR GHD.codigoBarra LIKE '%' + @barcode + '%')
                    -- Supplier (Exportador)
                    AND (@supplier IS NULL OR GH.idExportador IN (SELECT id FROM Exportadores WITH (NOLOCK) WHERE nombre LIKE '%' + @supplier + '%'))
                    -- Pallet Label
                    AND (@palletLabel IS NULL OR PAL.pallet LIKE '%' + @palletLabel + '%')
                    -- Es Inventario (Replica la lógica del CASE del SELECT)
                    AND (@esInventario IS NULL OR CalcInventario.ValorEsInventario = @esInventario)
                    ------------------------------------------------------------------------------
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
                           , ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
                           , GH.idExportador
                           , GHD.despachadoDestino
						   , GHD.codigoBarra 
						   , TE.idTE
						   , CalcInventario.ValorEsInventario
						   
                    SELECT APU.id
                         , APU.idGuiaHouse
                         , MD.id idManifiesto
                         , DD.mailEnviado
                         , APU.estadoPieza
                         , APU.idClienteFinal
                         , APU.fechaDespacho
                         , APU.nombreBodega
                         , APU.idBodega
                         , ISNULL(ISNULL(APU.idUsuarioLogEdi, MD.idUsuarioLog), APU.idUsuarioLogHouse) AS idUsuarioLog
                         , CASE
                               WHEN APU.idUsuarioLogEdi IS NOT NULL THEN APU.nombreUsuario
                               WHEN MD.idUsuarioLog IS NOT NULL THEN U.nombre
                               ELSE USH.nombre
                           END nombreUsuario
                         , APU.nombreClienteFinal
                         , APU.idCarrier
                         , APU.nroGuia
                         , MD.nroManifiesto
                         , APU.nroPo
                         , APU.idPaisCliente
                         , DD.nombreArchivo tipoNubeDocs
						 ,ISNULL(ISNULL(APU.fechaCambio, MD.fechaCambio), APU.fechaCambioHouse) AS usuarioFechaCambio
                         , APU.truckId
                         , APU.nombreConsignee
                         , APU.idConsignee
                         , APU.totalPiezas
                         , APU.valor
                         , APU.codigoBarra
                         , APU.nroOrden
                         , APU.house
                         , APU.totalPicking
                         , APU.idOrdenventa
                         , APU.despachadoDestino
                         , APU.totalPickingLoading TotalPickingLoading
						 , APU.idTEGuid
						 , APU.esInventario
                    FROM #TablaAgrupacionGuiasPickUp APU
                         LEFT JOIN ProgramacionManifiesto PM WITH (NOLOCK) ON APU.idProgramacionCarrier = PM.idProgramacionCarrier
                         LEFT JOIN manifiestosDespacho MD WITH (NOLOCK) ON PM.idManifiestoDespacho = MD.id
                         OUTER APPLY (
								SELECT TOP 1 DD.EsPod, DD.nombreArchivo, DD.mailEnviado
								FROM DocumentosDespacho DD WITH (NOLOCK)
								WHERE DD.idManifiesto = MD.id
								AND DD.idDocumento = 'DOC052395'
								ORDER BY EsPod DESC
							) DD
                            ---usados para traer informacion de usuario, aunque no se use en where
                         LEFT JOIN Usuarios U ON MD.idUsuarioLog = U.id
                         LEFT JOIN Usuarios USH ON APU.idUsuarioLogHouse = USH.id
                    WHERE 
						(@nroManifiesto IS NULL
                        OR MD.nroManifiesto LIKE '%' + @nroManifiesto + '%')
                        AND ISNULL(DD.esPOD, 0) = 0
                END;
    END TRY
    BEGIN CATCH
        EXEC [pro_LogError]
    END CATCH;
END;