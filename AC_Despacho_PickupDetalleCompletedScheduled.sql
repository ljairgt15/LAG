CREATE OR ALTER     PROCEDURE [dbo].[AC_Despacho_PickupDetalleCompletedScheduled] (
@FechaDesde DATE,
@FechaHasta DATE,
@NroDocumento VARCHAR(32) = NULL,
@Po VARCHAR(32) = NULL,
@NombreClienteConsignee VARCHAR(512) = NULL,
@NroPOD VARCHAR(16) = NULL,
@CodigoBarras VARCHAR(32) = NULL,
@NombreComercialExportador VARCHAR(50) = NULL,
@IdManifiesto UNIQUEIDENTIFIER = NULL,
@IdCarrier VARCHAR(16) = NULL,
@IdClienteFinal VARCHAR(16) = NULL,
@IdBodega VARCHAR(16) = NULL,
@FechaPickUpProgramada DATE = NULL,
@FechaPickUpEntrega DATE = NULL,
@PalletLabel VARCHAR(20) = NULL,
@idEmpresa VARCHAR(16) = NULL,
@BillTo VARCHAR(128) = NULL -- <--- NUEVO PARÁMETRO
)
AS
BEGIN
    BEGIN TRY

        DECLARE @emptyUID UNIQUEIDENTIFIER = 0x0;

        CREATE TABLE #TablaAgrupacionGuiasHouse (Id INT IDENTITY(1, 1) NOT NULL,
                                                 IdClienteFinal VARCHAR(16) NOT NULL,
                                                 NombreClienteFinal VARCHAR(512) NULL, -- NUEVO
                                                 IdClienteConsignee VARCHAR(16) NOT NULL,
                                                 NombreClienteConsignee VARCHAR(512) NULL, -- NUEVO
                                                 FechaPickUpProgramada DATETIME NOT NULL,
                                                 FechaPickUpEntrega DATETIME NOT NULL,
                                                 idUsuarioLog VARCHAR(32) NULL,
												 TotalPending INT NOT NULL,
												 TotalHold INT NOT NULL,
												 TotalShort INT NOT NULL,
												 TotalReceived INT NOT NULL,
												 TotalStandBy INT NOT NULL,
                                                 TotalDespachado INT NOT NULL,
                                                 Total INT NOT NULL,
                                                 IdBodega VARCHAR(16) NULL,
                                                 NombreBodega NVARCHAR(512) NULL, -- NUEVO
                                                 IdManifiesto UNIQUEIDENTIFIER NULL,
                                                 IdCarrier VARCHAR(16) NOT NULL,
                                                 NombreCarrier VARCHAR(512) NOT NULL,
                                                 IdGuia VARCHAR(128) NOT NULL,
                                                 NroDocumento VARCHAR(32) NOT NULL,
                                                 IdOrdenVenta UNIQUEIDENTIFIER NULL,
                                                 NroOrdenVenta VARCHAR(32) NULL,
                                                 ConPOD INT NOT NULL,
                                                 Enviado INT NOT NULL,
                                                 Procesado INT NOT NULL);
		

        CREATE TABLE #TablaAgrupacionGuiasHouseFinal (Id INT IDENTITY(1, 1) NOT NULL,
                                                      IdClienteFinal VARCHAR(16) NOT NULL,
                                                      NombreClienteFinal VARCHAR(512) NULL, -- NUEVO
                                                      IdClienteConsignee VARCHAR(16) NOT NULL,
                                                      NombreClienteConsignee VARCHAR(512) NULL, -- NUEVO
                                                      FechaPickUpProgramada DATETIME NOT NULL,
                                                      FechaPickUpEntrega DATETIME NOT NULL,
                                                      idUsuarioLog VARCHAR(32) NULL,
													  TotalPending INT NOT NULL,
													  TotalHold INT NOT NULL,
													  TotalShort INT NOT NULL,
													  TotalReceived INT NOT NULL,
													  TotalStandBy INT NOT NULL,
                                                      TotalDespachado INT NOT NULL,
                                                      Total INT NOT NULL,
                                                      IdBodega VARCHAR(16) NULL,
                                                      NombreBodega NVARCHAR(512) NULL, -- NUEVO
                                                      IdManifiesto UNIQUEIDENTIFIER NULL,
                                                      IdCarrier VARCHAR(16) NOT NULL,
                                                      NombreCarrier VARCHAR(512) NOT NULL,
                                                      IdGuia VARCHAR(128) NOT NULL,
                                                      NroDocumento VARCHAR(32) NOT NULL,
                                                      IdOrdenVenta UNIQUEIDENTIFIER NULL,
                                                      NroOrdenVenta VARCHAR(32) NULL,
                                                      ConPOD INT NOT NULL,
                                                      Enviado INT NOT NULL,
                                                      Procesado INT NOT NULL);
									


        IF (   @NroDocumento IS NULL
           AND @Po IS NULL
           AND @NombreClienteConsignee IS NULL
           AND @NroPOD IS NULL
           AND @CodigoBarras IS NULL
           AND @NombreComercialExportador IS NULL
           AND @BillTo IS NULL) -- AGREGADO
        BEGIN
            INSERT INTO #TablaAgrupacionGuiasHouse (
                IdClienteFinal, NombreClienteFinal, 
                IdClienteConsignee, NombreClienteConsignee,
                FechaPickUpProgramada, FechaPickUpEntrega, idUsuarioLog, 
                TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
                IdBodega, NombreBodega,
                IdManifiesto, IdCarrier, NombreCarrier, IdGuia, NroDocumento, IdOrdenVenta, NroOrdenVenta, ConPOD, Enviado, Procesado
            )
            SELECT GHD.ShipToId
                 , VES.nombre   -- Nombre ShipTo (Vista)
                 , GH.ConsigneeId -- ID Físico (Integridad)
                 , VEC.nombre   -- Nombre Comercial (Vista)
                 , PC.fechaDespacho
                 , MAX(GHD.fechaCambio)
                 , GHD.idUsuarioLog
                 , SUM(IIF(GHD.estadoPieza = 'PENDING', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'HOLD', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'SHORT', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'RECEIVED WH', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'STANDBY', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0))
                 , COUNT(1)
                 , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                 , ISNULL(BUB.nombre, BGH.nombre) -- Nombre Bodega
                 , MD.id
                 , PC.idCarrier
                 , TRA.nombre -- Nombre Carrier (SubCarrier en tu query original)
                 , GH.idGuia
                 , GH.nroGuia
                 , SDV.id
                 , SDV.nroOrden
                 , MAX(IIF(DD.nombreArchivo LIKE 'POD%', 1, 0))
                 , MAX(IIF(DD.mailEnviado = 1, 1, 0))
                 , MAX(IIF(DD.podProcesado = 1, 1, 0))
            
            FROM dbo.GuiasHouseDetalles GHD WITH(NOLOCK) 
            INNER JOIN dbo.GuiasHouse GH WITH(NOLOCK) ON GHD.idGuiaHouse = GH.id
            
            -- BREAKING CHANGE: VISTAS
            INNER JOIN v_ClientsEntities VES WITH (NOLOCK) ON VES.id = GHD.ShipToId
            INNER JOIN v_ClientsEntities VEC WITH (NOLOCK) ON VEC.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)

            INNER JOIN dbo.ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
            INNER JOIN dbo.Transportes TRA ON PC.idCarrier = TRA.id -- SubCarrier
            INNER JOIN dbo.Transportes CARR ON TRA.idTransportePrincipal = CARR.id -- Carrier Principal
            
            INNER JOIN dbo.ParametrosCatalogos PCAT ON CARR.id = PCAT.idEntidad
            INNER JOIN dbo.ParametrosLista PL ON PCAT.idParametroLista = PL.id
                AND PL.codigo = 'EsDelivery'
                AND PL.idEmpresa = GH.idEmpresa

            LEFT JOIN dbo.ProgramacionManifiesto PM WITH(NOLOCK) ON PM.idProgramacionCarrier = PC.id
            LEFT JOIN dbo.DocumentosDespacho DD ON PM.idManifiestoDespacho = DD.idManifiesto AND DD.idDocumento = 'DOC052395'
            LEFT JOIN dbo.ManifiestosDespacho MD ON MD.id = PM.idManifiestoDespacho
            
            OUTER APPLY (SELECT TOP (1) S.id, S.nroOrden
             FROM      dbo.SolicitudDeVentaDetalles SLL
                               LEFT JOIN dbo.SolicitudDeVenta S
                                 ON S.id = SLL.idSolicitud
                              WHERE      SLL.idGuiaHouseDetalle = GHD.id
                              ORDER BY S.fechaSolicitud DESC ) AS SDV
            LEFT JOIN dbo.PalletsDetalles PD WITH(NOLOCK) ON GHD.id = PD.idGuiasHouseDetalle
            LEFT JOIN dbo.Pallets PAL WITH(NOLOCK) ON PD.idPallet = PAL.id
            LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
            LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
            LEFT JOIN UbicacionesBodega UB ON U.idUbicacionBodega = UB.id
            LEFT JOIN Bodegas BGH ON GH.idBodega = BGH.id
            LEFT JOIN Bodegas BUB ON UB.idBodega = BUB.id

            WHERE GH.idEmpresa = @idEmpresa
              AND PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
              AND PCAT.valor = 'NO' -- Filtro de Carrier No Delivery
              AND (@PalletLabel IS NULL OR PAL.pallet LIKE '%' + @PalletLabel + '%') 
              
            GROUP BY GHD.ShipToId
                   , VES.nombre
                   , GH.ConsigneeId
                   , VEC.nombre
                   , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                   , ISNULL(BUB.nombre, BGH.nombre)
                   , PC.fechaDespacho
                   , MD.id
                   , PC.idCarrier
                   , TRA.nombre
                   , GHD.idUsuarioLog
                   , GH.idGuia
                   , GH.nroGuia
                   , SDV.id
                   , SDV.nroOrden
            HAVING COUNT(1) = SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0));
        END;
        ELSE
        BEGIN
            INSERT INTO #TablaAgrupacionGuiasHouse (
                IdClienteFinal, NombreClienteFinal,
                IdClienteConsignee, NombreClienteConsignee,
                FechaPickUpProgramada, FechaPickUpEntrega, idUsuarioLog, 
                TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
                IdBodega, NombreBodega,
                IdManifiesto, IdCarrier, NombreCarrier, IdGuia, NroDocumento, IdOrdenVenta, NroOrdenVenta, ConPOD, Enviado, Procesado
            )
            SELECT GHD.ShipToId
                 , VES.nombre   -- Nombre ShipTo
                 , GH.ConsigneeId
                 , VEC.nombre   -- Nombre Consignee/BillTo
                 , PC.fechaDespacho
                 , MAX(GHD.fechaCambio)
                 , GHD.idUsuarioLog
                 , SUM(IIF(GHD.estadoPieza = 'PENDING', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'HOLD', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'SHORT', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'RECEIVED WH', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'STANDBY', 1, 0))
                 , SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0))
                 , COUNT(1)
                 , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                 , ISNULL(BUB.nombre, BGH.nombre) -- Nombre Bodega
                 , MD.id
                 , PC.idCarrier
                 , TRA.nombre -- Nombre SubCarrier
                 , GH.idGuia
                 , GH.nroGuia
                 , SDV.id
                 , SDV.nroOrden
                 , MAX(IIF(DD.nombreArchivo LIKE 'POD%', 1, 0))
                 , MAX(IIF(DD.mailEnviado = 1, 1, 0))
                 , MAX(IIF(DD.podProcesado = 1, 1, 0))

            FROM dbo.GuiasHouseDetalles GHD WITH(NOLOCK) 
            INNER JOIN dbo.GuiasHouse GH WITH(NOLOCK) ON GHD.idGuiaHouse = GH.id
            
            -- BREAKING CHANGE
            INNER JOIN v_ClientsEntities VES WITH (NOLOCK) ON VES.id = GHD.ShipToId
            INNER JOIN v_ClientsEntities VEC WITH (NOLOCK) ON VEC.id = ISNULL(GH.BillToConsigneeId, GH.ConsigneeId)
            
            INNER JOIN dbo.Exportadores EXP ON GH.idExportador = EXP.id

            INNER JOIN dbo.ProgramacionCarrier PC WITH(NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id
            INNER JOIN dbo.Transportes TRA ON PC.idCarrier = TRA.id
            INNER JOIN dbo.Transportes CARR ON TRA.idTransportePrincipal = CARR.id
            INNER JOIN dbo.ParametrosCatalogos PCAT ON CARR.id = PCAT.idEntidad
            INNER JOIN dbo.ParametrosLista PL ON PCAT.idParametroLista = PL.id
                AND PL.codigo = 'EsDelivery'
                AND PL.idEmpresa = GH.idEmpresa

            LEFT JOIN dbo.ProgramacionManifiesto PM WITH(NOLOCK) ON PM.idProgramacionCarrier = PC.id
            LEFT JOIN dbo.DocumentosDespacho DD ON PM.idManifiestoDespacho = DD.idManifiesto AND DD.idDocumento = 'DOC052395'
            LEFT JOIN dbo.ManifiestosDespacho MD ON MD.id = PM.idManifiestoDespacho
            OUTER APPLY (
                SELECT TOP (1) S.id, S.nroOrden
                FROM dbo.SolicitudDeVentaDetalles SLL
                LEFT JOIN dbo.SolicitudDeVenta S ON S.id = SLL.idSolicitud
                WHERE SLL.idGuiaHouseDetalle = GHD.id
                ORDER BY S.fechaSolicitud DESC
            ) AS SDV

            -- JOINS AUXILIARES
            LEFT JOIN dbo.PalletsDetalles PD WITH(NOLOCK) ON GHD.id = PD.idGuiasHouseDetalle
            LEFT JOIN dbo.Pallets PAL WITH(NOLOCK) ON PD.idPallet = PAL.id
            LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
            LEFT JOIN Ubicaciones U ON UP.idUbicacion = U.id
            LEFT JOIN UbicacionesBodega UB ON U.idUbicacionBodega = UB.id
            LEFT JOIN Bodegas BGH ON GH.idBodega = BGH.id
            LEFT JOIN Bodegas BUB ON UB.idBodega = BUB.id

            WHERE GH.idEmpresa = @idEmpresa
              AND PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
              AND PCAT.valor = 'NO' -- Carrier No Delivery
              -- FILTROS OPCIONALES
              AND (@NroDocumento IS NULL OR GH.nroGuia LIKE '%' + @NroDocumento + '%')
              AND (@Po IS NULL OR GHD.po LIKE '%' + @Po + '%')
              AND (@NombreClienteConsignee IS NULL OR VEC.nombre LIKE '%' + @NombreClienteConsignee + '%')
              AND (@NroPOD IS NULL OR MD.nroManifiesto LIKE '%' + @NroPOD + '%')
              AND (@CodigoBarras IS NULL OR GHD.codigoBarra LIKE '%' + @CodigoBarras + '%')
              AND (@NombreComercialExportador IS NULL OR EXP.nombreComercial LIKE '%' + @NombreComercialExportador + '%')
              AND (@PalletLabel IS NULL OR PAL.pallet LIKE '%' + @PalletLabel + '%') 
              -- FILTRO BILL TO (Aquí sí va)
              AND (@BillTo IS NULL OR (VEC.BillToId IS NOT NULL AND VEC.BillToName LIKE '%' + @BillTo + '%'))

            GROUP BY GHD.ShipToId
                   , VES.nombre
                   , GH.ConsigneeId
                   , VEC.nombre
                   , CASE WHEN (UB.idBodega IS NULL OR UB.idBodega = '') THEN GH.idBodega ELSE UB.idBodega END
                   , ISNULL(BUB.nombre, BGH.nombre)
                   , PC.fechaDespacho
                   , MD.id
                   , PC.idCarrier
                   , TRA.nombre
                   , GHD.idUsuarioLog
                   , GH.idGuia
                   , GH.nroGuia
                   , SDV.id
                   , SDV.nroOrden
            HAVING COUNT(1) = SUM(IIF(GHD.estadoPieza = 'DISPATCHED WH', 1, 0));
        END;	


								
        INSERT INTO #TablaAgrupacionGuiasHouseFinal (
            IdClienteFinal, NombreClienteFinal,
            IdClienteConsignee, NombreClienteConsignee,
            FechaPickUpProgramada, FechaPickUpEntrega, idUsuarioLog, 
            TotalPending, TotalHold, TotalShort, TotalReceived, TotalStandBy, TotalDespachado, Total, 
            IdBodega, NombreBodega,
            IdManifiesto, IdCarrier, NombreCarrier, IdGuia, NroDocumento, IdOrdenVenta, NroOrdenVenta, ConPOD, Enviado, Procesado
        )
        SELECT tbl.IdClienteFinal
             , tbl.NombreClienteFinal
             , tbl.IdClienteConsignee
             , tbl.NombreClienteConsignee
             , tbl.FechaPickUpProgramada
             , MAX(tbl.FechaPickUpEntrega) AS FechaPickUpEntrega
             
             , (SELECT TOP (1) sub.idUsuarioLog
                FROM #TablaAgrupacionGuiasHouse sub
                WHERE sub.IdGuia = tbl.IdGuia -- 1. Match por Guía (Llave maestra)
                  AND CONVERT(DATE, sub.FechaPickUpEntrega) = CONVERT(DATE, tbl.FechaPickUpEntrega) -- 2. Match por Fecha Agrupada
                ORDER BY sub.FechaPickUpEntrega DESC -- 3. El más reciente
               ) AS IdUsuarioLog

             , SUM(tbl.TotalPending)
             , SUM(tbl.TotalHold)
             , SUM(tbl.TotalShort)
             , SUM(tbl.TotalReceived)
             , SUM(tbl.TotalStandBy)
             , SUM(tbl.TotalDespachado)
             , SUM(tbl.Total)
             , tbl.IdBodega
             , tbl.NombreBodega
             , tbl.IdManifiesto
             , tbl.IdCarrier
             , tbl.NombreCarrier
             , tbl.IdGuia
             , tbl.NroDocumento
             , tbl.IdOrdenVenta
             , tbl.NroOrdenVenta
             , tbl.ConPOD
             , tbl.Enviado
             , tbl.Procesado

        FROM #TablaAgrupacionGuiasHouse tbl
        GROUP BY tbl.IdClienteFinal, tbl.NombreClienteFinal
               , tbl.IdClienteConsignee, tbl.NombreClienteConsignee
               , tbl.FechaPickUpProgramada
               , CONVERT(DATE, tbl.FechaPickUpEntrega) -- Agrupación por día
               , tbl.IdBodega, tbl.NombreBodega
               , tbl.IdManifiesto
               , tbl.IdCarrier
               , tbl.NombreCarrier
               , tbl.ConPOD, tbl.Enviado, tbl.Procesado
               , tbl.IdGuia, tbl.NroDocumento
               , tbl.IdOrdenVenta, tbl.NroOrdenVenta;
        
        IF @IdClienteFinal IS NULL
        BEGIN
            SELECT tmp.Id
                 , 'Entregada' AS Estatus
                 , 'dispatch-pick-up-delivered' AS ClaseCssEstatus       
                 , tmp.IdGuia
                 , tmp.NroDocumento
                 , tmp.IdOrdenVenta
                 , tmp.NroOrdenVenta                  
                 , tmp.IdClienteFinal
                 , tmp.NombreClienteFinal
                 , tmp.IdClienteConsignee
                 , tmp.NombreClienteConsignee
                 , tmp.FechaPickUpProgramada
                 , '' AS FechaPickUpProgramadaString
                 , tmp.FechaPickUpEntrega
                 , '' AS FechaPickUpEntregaString
                 , CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega
                 , tmp.TotalPending AS PcsPending
                 , tmp.TotalHold AS PcsHold
                 , tmp.TotalShort AS PcsShort
                 , tmp.TotalReceived AS PcsReceivedWh
                 , tmp.TotalStandBy AS PcsStandby
                 , tmp.TotalDespachado AS TotalDespachado
                 , tmp.Total
                 , tmp.IdBodega
                 , tmp.NombreBodega
                 , tmp.IdManifiesto
                 , tmp.IdCarrier
                 , tmp.NombreCarrier 
                 , ISNULL(usuario.nombre, '') + ' ' AS UsuarioFechaCambio
                 , CONVERT(BIT, tmp.Enviado) AS Enviado
                 , CONVERT(BIT, tmp.Procesado) AS Procesado
            FROM #TablaAgrupacionGuiasHouseFinal AS tmp
            INNER JOIN dbo.Usuarios usuario ON usuario.Id = tmp.idUsuarioLog
        END;
        ELSE
        BEGIN
            SELECT tmp.Id
                 , 'Entregada' AS Estatus
                 , 'dispatch-pick-up-delivered' AS ClaseCssEstatus       
                 , tmp.IdGuia
                 , tmp.NroDocumento
                 , tmp.IdOrdenVenta
                 , tmp.NroOrdenVenta                  
                 , tmp.IdClienteFinal
                 , tmp.NombreClienteFinal
                 , tmp.IdClienteConsignee
                 , tmp.NombreClienteConsignee
                 , tmp.FechaPickUpProgramada
                 , '' AS FechaPickUpProgramadaString
                 , tmp.FechaPickUpEntrega
                 , '' AS FechaPickUpEntregaString
                 , CONVERT(TIME, tmp.FechaPickUpEntrega) AS HoraEntrega
                 , tmp.TotalPending AS PcsPending
                 , tmp.TotalHold AS PcsHold
                 , tmp.TotalShort AS PcsShort
                 , tmp.TotalReceived AS PcsReceivedWh
                 , tmp.TotalStandBy AS PcsStandby
                 , tmp.TotalDespachado AS TotalDespachado
                 , tmp.Total
                 , tmp.IdBodega
                 , tmp.NombreBodega
                 , tmp.IdManifiesto
                 , tmp.IdCarrier
                 , tmp.NombreCarrier
                 , ISNULL(usuario.nombre, '') + ' ' AS UsuarioFechaCambio
                 , CONVERT(BIT, tmp.Enviado) AS Enviado
                 , CONVERT(BIT, tmp.Procesado) AS Procesado
            FROM #TablaAgrupacionGuiasHouseFinal AS tmp
            INNER JOIN dbo.Usuarios usuario ON usuario.Id = tmp.idUsuarioLog
            WHERE ISNULL(tmp.IdManifiesto, @emptyUID) = ISNULL(@IdManifiesto, @emptyUID)
              AND tmp.IdCarrier = @IdCarrier
              AND tmp.IdClienteFinal = @IdClienteFinal
              AND tmp.IdBodega = @IdBodega
              AND CONVERT(DATE, tmp.FechaPickUpEntrega) = @FechaPickUpEntrega
              AND tmp.FechaPickUpProgramada = @FechaPickUpProgramada
        END;
        DROP TABLE #TablaAgrupacionGuiasHouse;
        DROP TABLE #TablaAgrupacionGuiasHouseFinal;

    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH;
END;