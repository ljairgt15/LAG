USE [alliance_desa]
GO
/****** Object:  StoredProcedure [dbo].[pro_Despacho_DespachoDetallePickUp]    Script Date: 28/01/2026 12:21:18 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
VERSION		AUTOR				FECHA		HU				CAMBIO
1			Jesus Yandun        11-01-2021                  Codigo Inicial -Extrae información para detalle de modulo de pickup
2			Jonathan Merino     09-04-2021                  se modifica listado para devolver TipoManifiesto en base al parametro del cliente Consignee
3			Jonathan Merino     01-10-2021                  se modifica listado para filtrar por pallet
4			Jonathan Merino     05-11-2021                  se modifica listado para agregar total picking y asi manejar el estado sold
5			Luchin Campos       15-04-2022                  Mostrar Bodega de acuerdo con la ubicación de la pieza
6			Jorge Ortiz         21-03-2022  25211           Muestra todos los detalles(consulta = 2) pickup con esPod=0 y con fecha de hace 3 meses, refactorizaicon de codigo, correcion de campos declarados. Correccion de las tablas temporales y la asignacion de campos.
7 			Jose Ganchozo		12-06-2023	25674			Agregar columnas despachadoDestino y totalPickingLoading
8			Jean Martillo       01-09-2023  29121           Agregar parametro IdEmpresa y colocarlo dentro del where si la consulta es 2 (usuario interno), se agrega en el select codigo de barra
9			Jean Martillo       24-11-2023  29121           Quitar el filtro que discrimina las piezas Lost
10			Damian Briones		07-02-2024	35758			Agregar id T&E y cambio encabezado
11			Fernando Ordoñez	07-10-2024	41334			Agrega EsInventario
12			Jose Ganchozo		29-11-2024	Bug-46654	    Se corrige la logica para las piezas que son de inventario
13			Edwin Casa			20-01-2024	WMS-47594	    Optimizacion de querys, se agrega outeraplly para documentos despacho y se hace una preconsulta de los carriers no delivery
*/
ALTER     PROCEDURE [dbo].[pro_Despacho_DespachoDetallePickUp]
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
	@esInventario	BIT = NULL
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
                     , GH.id idGuiaHouse
                     , GHD.estadoPieza
                     , GHD.idClienteFinal
                     , PC.fechaDespacho
                     , ISNULL(B1.nombre, B.nombre) AS nombreBodega
                     , ISNULL(ub.idBodega, GH.idBodega) AS idBodega
                     , PC.idCarrier
                     , PC.id idProgramacionCarrier
                     ,ISNULL(CLF.nombreClienteFinal, CLF.nombre) AS nombreClienteFinal
                     , GH.nroGuia
                     , PE.nroPo
                     , CLF.idPais idPaisCliente
                     , GHD.truckId
                     , CLI.nombre nombreConsignee
                     , CLI.id idConsignee
                     , edi.idUsuarioLog idUsuarioLogEdi
                     , GH.idUsuarioLog idUsuarioLogHouse
                     , US.nombre nombreUsuario
                     , 0 totalPiezas
                     , PCAT.valor
                     , NULL codigoBarra
                     , V.nroOrden
                     , GH.house
                     , edi.fechaCambio
                     , GH.fechaCambio
                     , GH.idExportador
                     , pal.pallet
                     , SUM(IIF(V.picking = 1, 1, 0)) totalPicking
                     , V.id
                     , GHD.po
                     , GH.idCliente
                     , GHD.despachadoDestino
                     , SUM(IIF(PC.idUsuarioLogPicking IS NOT NULL, 1, 0)) idUsuarioLogPicking
					 , TE.idTE idTEGuid
					 , CASE 
							WHEN V.tipoVenta < 4 THEN 1 
							WHEN V.tipoVenta = 5 AND V.tipoPieza = 1  THEN 1 
							ELSE 0
						END esInventario
                FROM  ProgramacionCarrier PC  WITH (NOLOCK)
                     INNER JOIN Transportes T WITH (NOLOCK) ON PC.idCarrier = T.id
					 INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON t.idTransportePrincipal = PCA.idEntidad 
																	 AND PCA.idParametroLista = @idParametroDelivery 
																	 AND PCA.valor = 'NO'
                     INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
                     INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
                     INNER JOIN ParametrosLista PLC WITH (NOLOCK) ON PLC.codigo = 'TipoManifiestoDespacho'
                                    AND PLC.idEmpresa = GH.idEmpresa
                     INNER JOIN Clientes CLF ON GHD.idClienteFinal = CLF.id
                     INNER JOIN Clientes cli ON GH.idCliente = CLI.id
                     LEFT JOIN ParametrosCatalogos PCAT WITH (NOLOCK) ON PCAT.idEntidad = GH.idCliente
                                   AND PCAT.idParametroLista = PLC.id
					 LEFT JOIN ProgramacionTe te WITH (NOLOCK) ON PC.id = TE.idProgramacionCarrier  
					 LEFT JOIN EDI ON PC.idCarrier = edi.idCarrier AND PC.fechaDespacho = edi.fechaDespacho
                     LEFT JOIN Usuarios US WITH (NOLOCK) ON edi.idUsuarioLog = US.id
                     LEFT JOIN PoDetalles PD WITH (NOLOCK) ON GHD.idPoDetalle = PD.id
                     LEFT JOIN PoEncabezado PE ON PD.idPo = PE.id
                     OUTER APPLY (SELECT TOP (1) SV.id, SV.nroOrden, SVD.picking, SV.tipoVenta, SVD.tipoPieza
                                  FROM SolicitudDeVentaDetalles SVD
                                       LEFT JOIN SolicitudDeVenta SV ON SV.id = SVD.idSolicitud
                                  WHERE SVD.idGuiaHouseDetalle = GHD.id
                                  ORDER BY SV.fechaSolicitud DESC) V
                     LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON GHD.id = PLD.idGuiasHouseDetalle
                     LEFT JOIN Pallets PAL WITH (NOLOCK) ON PLD.idPallet = pal.id
                     LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
                     LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
                     LEFT JOIN UbicacionesBodega UB ON U.idUbicacionBodega = ub.id
                     LEFT JOIN Bodegas B ON GH.idBodega = B.id
                     LEFT JOIN Bodegas B1 ON ub.idBodega = B1.id
                WHERE PC.fechaDespacho = @fechaDespacho
				  AND GH.idEmpresa = @idEmpresa              
                  AND (@idOrdenVenta IS NULL OR V.id = @idOrdenVenta)
                GROUP BY GHD.id
                       , GH.id
                       , GHD.estadoPieza
                       , GHD.idClienteFinal
                       , PC.fechaDespacho
                       , ISNULL(B1.nombre, B.nombre)
                       , ISNULL(ub.idBodega, GH.idBodega)
                       , PC.idCarrier
                       , PC.id
                       , ISNULL(CLF.nombreClienteFinal, CLF.nombre)
                       , GH.nroGuia
                       , PE.nroPo
                       , CLF.idPais
                       , GHD.truckId
                       , CLI.nombre
                       , CLI.id
                       , edi.idUsuarioLog
                       , GH.idUsuarioLog
                       , US.nombre
                       , PCAT.valor
                       , V.nroOrden
                       , V.id
                       , GH.house
                       , edi.fechaCambio
                       , GH.fechaCambio
                       , GH.idExportador
                       , pal.pallet
                       , GHD.po
                       , GH.idCliente
                       , GH.idExportador
                       , GHD.despachadoDestino  
					   , TE.idTE
					   , CASE WHEN V.tipoVenta < 4 THEN 1 
							WHEN V.tipoVenta = 5 AND V.tipoPieza = 1  THEN 1 
							ELSE 0 
						END

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
							 ,ISNULL(ISNULL(APU.idUsuarioLogEdi, MD.idUsuarioLog), APU.idUsuarioLogHouse) AS idUsuarioLog
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
                             LEFT JOIN Pallets pal WITH (NOLOCK) ON PLD.idPallet = pal.id
                        WHERE MD.nroManifiesto IS NULL
                          AND APU.idClienteFinal = @idClienteFinal
                          AND APU.idCarrier = @idCarrier
                          AND (@palletLabel IS NULL OR pal.pallet LIKE '%' + @palletLabel + '%') 
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
                             LEFT JOIN Pallets pal WITH (NOLOCK) ON PLD.idPallet = pal.id
                        WHERE APU.idClienteFinal = @idClienteFinal
                        AND MD.nroManifiesto = @nroManifiesto
                        AND APU.idCarrier = @idCarrier
                        AND (@palletLabel IS NULL OR pal.pallet LIKE '%' + @palletLabel + '%')
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
                         , GHD.idClienteFinal
                         , PC.fechaDespacho
                         , ISNULL(B1.nombre, B.nombre) AS nombreBodega
						 , ISNULL(ub.idBodega, GH.idBodega) AS idBodega
                         , PC.idCarrier
                         , PC.id idProgramacionCarrier
                         , ISNULL(CLF.nombreClienteFinal, CLF.nombre) AS nombreClienteFinal
                         , GH.nroGuia
                         , PE.nroPo
                         , CLF.idPais idPaisCliente
                         , GHD.truckId
                         , CLI.nombre nombreConsignee
                         , CLI.id idConsignee
                         , edi.idUsuarioLog idUsuarioLogEdi
                         , GH.idUsuarioLog idUsuarioLogHouse
                         , US.nombre nombreUsuario
                         , 0 totalPiezas
                         , PCAT.valor
                         , GHD.codigoBarra codigoBarra
                         , V.nroOrden
                         , GH.house
                         , edi.fechaCambio
                         , GH.fechaCambio
                         , GH.idExportador
                         , pal.pallet
                         , SUM(IIF(V.picking = 1, 1, 0)) totalPicking
                         , V.id
                         , GHD.po
                         , GH.idCliente
                         , GHD.despachadoDestino
						 , SUM(IIF(PC.idUsuarioLogPicking IS NOT NULL, 1, 0)) idUsuarioLogPicking
						 , TE.idTE idTEGuid
						 , CASE 
								WHEN V.tipoVenta < 4 THEN 1 
								WHEN V.tipoVenta = 5 AND V.tipoPieza = 1  THEN 1 
								ELSE 0
						   END esInventario
                    FROM ProgramacionCarrier PC  WITH (NOLOCK)
                         INNER JOIN Transportes T ON PC.idCarrier = T.id
                         INNER JOIN ParametrosCatalogos PCA WITH (NOLOCK) ON t.idTransportePrincipal = PCA.idEntidad 
																	 AND PCA.idParametroLista = @idParametroDelivery 
																	 AND PCA.valor = 'NO'
                         INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
                         INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
                         INNER JOIN ParametrosLista PLC ON PLC.codigo = 'TipoManifiestoDespacho' AND PLC.idEmpresa = GH.idEmpresa
                         INNER JOIN Clientes CLF ON GHD.idClienteFinal = CLF.id
                         INNER JOIN Clientes CLI ON GH.idCliente = CLI.id
                         LEFT JOIN ParametrosCatalogos PCAT ON PCAT.idEntidad = GH.idCliente AND PCAT.idParametroLista = PLC.id
						 LEFT JOIN ProgramacionTe TE WITH (NOLOCK) ON PC.id = TE.idProgramacionCarrier  
                         LEFT JOIN edi ON PC.idCarrier = edi.idCarrier AND PC.fechaDespacho = edi.fechaDespacho
                         LEFT JOIN Usuarios US ON edi.idUsuarioLog = US.id
                         LEFT JOIN PoDetalles PD ON GHD.idPoDetalle = PD.id
                         LEFT JOIN PoEncabezado PE ON PD.idPo = PE.id
                         OUTER APPLY (SELECT TOP (1) SV.id, SV.nroOrden, SVD.picking, SV.tipoVenta, SVD.tipoPieza
                                      FROM SolicitudDeVentaDetalles SVD
                                           LEFT JOIN SolicitudDeVenta SV ON SV.id = SVD.idSolicitud
                                      WHERE SVD.idGuiaHouseDetalle = GHD.id
                                      ORDER BY SV.fechaSolicitud DESC) AS V
                         LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON GHD.id = PLD.idGuiasHouseDetalle
                         LEFT JOIN Pallets pal WITH (NOLOCK) ON PLD.idPallet = pal.id
                         LEFT JOIN UbicacionPiezas AS UP WITH (NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
                         LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
                         LEFT JOIN UbicacionesBodega ub ON U.idUbicacionBodega = ub.id
                         LEFT JOIN Bodegas B ON GH.idBodega = B.id
                         LEFT JOIN Bodegas B1 ON ub.idBodega = B1.id
                    WHERE PC.fechaDespacho > DATEADD(MM, -@fechaDesde, GETDATE()) 				  
                      AND GH.idEmpresa = @idEmpresa					 
                      AND GHD.esPOD = 0
                    GROUP BY GHD.id
                           , GH.id
                           , GHD.estadoPieza
                           , GHD.idClienteFinal
                           , PC.fechaDespacho
                           , ISNULL(B1.nombre, B.nombre) 
						   , ISNULL(ub.idBodega, GH.idBodega)
                           , PC.idCarrier
                           , PC.id
                           , ISNULL(CLF.nombreClienteFinal, CLF.nombre)
                           , GH.nroGuia
                           , PE.nroPo
                           , CLF.idPais
                           , GHD.truckId
                           , CLI.nombre
                           , CLI.id
                           , edi.idUsuarioLog
                           , GH.idUsuarioLog
                           , US.nombre
						   , PCAT.valor
                           , V.nroOrden
                           , V.id
                           , GH.house
                           , edi.fechaCambio
                           , GH.fechaCambio
                           , GH.idExportador
                           , pal.pallet
                           , GHD.po
                           , GH.idCliente
                           , GH.idExportador
                           , GHD.despachadoDestino
						   , GHD.codigoBarra 
						   , TE.idTE
						   , CASE WHEN V.tipoVenta < 4 THEN 1 
							WHEN V.tipoVenta = 5 AND V.tipoPieza = 1  THEN 1 
							ELSE 0 END
						   
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
                         LEFT JOIN Usuarios U ON MD.idUsuarioLog = U.id
                         LEFT JOIN Usuarios USH ON APU.idUsuarioLogHouse = USH.id
                         LEFT JOIN PalletsDetalles PLD WITH (NOLOCK) ON APU.id = PLD.idGuiasHouseDetalle
                         LEFT JOIN Pallets pal WITH (NOLOCK) ON PLD.idPallet = pal.id
                    WHERE CASE 
							WHEN @esInventario IS NULL THEN 1
							WHEN APU.esInventario = @esInventario THEN 1
							ELSE 0
						END = 1
						AND ISNULL(DD.esPOD, 0) = 0
						AND (@barcode IS NULL OR APU.codigoBarra LIKE '%' + @barcode + '%')
						AND APU.idCarrier =  ISNULL(@idCarrier, APU.idCarrier)
						AND (@barcode IS NULL
                        OR APU.codigoBarra LIKE '%' + @barcode + '%')
						AND (@nroDocument IS NULL
                        OR APU.nroGuia LIKE '%' + @nroDocument + '%')
						AND (@po IS NULL
                        OR APU.po LIKE '%' + @po + '%')
						AND (@nroManifiesto IS NULL
                        OR MD.nroManifiesto LIKE '%' + @nroManifiesto + '%')
						AND (@Consignee IS NULL
                        OR APU.idCliente IN (SELECT id FROM Clientes WHERE nombre LIKE '%' + @Consignee + '%'))
                        AND (@supplier IS NULL
                        OR APU.idExportador IN (SELECT id FROM Exportadores WHERE nombre LIKE '%' + @supplier + '%'))
						AND (@palletLabel IS NULL OR pal.pallet LIKE '%' + @palletLabel + '%')
                END;
    END TRY
    BEGIN CATCH
        EXEC [pro_LogError]
    END CATCH;
END;
/*===========================================\======================================================
exec sp_executesql N'pro_Despacho_DespachoDetallePickUp @nroDocument, @po, @Consignee, @status, @nroManifiesto, @barcode, @supplier, @pending, @consulta, @idClienteFinal, @idCarrier,@fechaDespacho, @fechaDesde, @palletLabel, @idBodega
',N'@nroDocument varchar(32),@po varchar(32),@Consignee varchar(100),@status nvarchar(7),@nroManifiesto varchar(50),@barcode varchar(20),@supplier varchar(100),@pending int,@consulta int,@idClienteFinal varchar(32),@idCarrier varchar(20),@fechaDespacho da
tetime,@fechaDesde int,@palletLabel varchar(20),@idBodega varchar(8000)'
    ,@nroDocument=NULL,@po=NULL,@Consignee=NULL,@status=N'PENDING',@nroManifiesto=NULL,@barcode=NULL,@supplier=NULL,@pending=0,@consulta=2,@idClienteFinal=NULL,@idCarrier=NULL,@fechaDespacho=NULL,@fechaDesde=3,@palletLabel=NULL,@idBodega=NULL


Prueba 1 idEmpresa = MIA, idCliente = null
exec pro_Despacho_DespachoDetallePickUp @nroDocument=NULL,@po=NULL,@Consignee=NULL,@status=NULL,@nroManifiesto=NULL,@barcode=NULL,@supplier=NULL,@pending=0,@consulta=2,@idClienteFinal=NULL,@idCarrier=NULL,@fechaDespacho=NULL,@fechaDesde=3,@palletLabel=NUL
L,@idBodega=NULL,@idOrdenVenta=NULL,@idEmpresa=N'EMP014'

Prueba 2 idEmpresa = AMS, idCliente = null
exec pro_Despacho_DespachoDetallePickUp @nroDocument=NULL,@po=NULL,@Consignee=NULL,@status=NULL,@nroManifiesto=NULL,@barcode=NULL,@supplier=NULL,@pending=0,@consulta=2,@idClienteFinal=NULL,@idCarrier=NULL,@fechaDespacho=NULL,@fechaDesde=3,@palletLabel=NULL,@idBodega=NULL,@idOrdenVenta=NULL,@idEmpresa=N'EMP015'

exec sp_executesql N'pro_Despacho_DespachoDetallePickUp @nroDocument, @po, @Consignee, @status, @nroManifiesto, @barcode, @supplier, @pending, @consulta, @idClienteFinal, @idCarrier,@fechaDespacho, @fechaDesde, @palletLabel, @idBodega, @idEmpresa
',N'@nroDocument varchar(32),@po varchar(32),@Consignee varchar(100),@status nvarchar(7),@nroManifiesto varchar(50),@barcode varchar(20),@supplier varchar(100),@pending int,@consulta int,@idClienteFinal nvarchar(10),@idCarrier nvarchar(12),@fechaDespacho 
nvarchar(10),@fechaDesde int,@palletLabel varchar(20),@idBodega varchar(8),@idOrdenVenta uniqueidentifier,@idEmpresa nvarchar(6)',@nroDocument=NULL,@po=NULL,@Consignee=NULL,@status=N'PENDING',@nroManifiesto=NULL,@barcode=NULL,@supplier=NULL,@pending=0,@co
nsulta=1,@idClienteFinal=N'CLI0114374',@idCarrier=N'ybOy4oex7F5E',@fechaDespacho=N'02-02-2024',@fechaDesde=3,@palletLabel=NULL,@idBodega='LXgyot5M',@idOrdenVenta=NULL,@idEmpresa=N'EMP014'
 */