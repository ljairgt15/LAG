/*
VERSION		MODIFIEDBY			MODIFIEDDATE	HU			MODIFICATION
1			Jordan Chango       2026-02-02		57730		Initial Code - Based on pro_ObtenerPiezasClientesPorSubCarrier
*/
ALTER   PROCEDURE [dbo].[AC_pro_GetClientsPiecesBySubCarrier] 
	@idSistema INT,
	@idDocumentoManifiesto VARCHAR(16),
	@parametroLista VARCHAR(32),
	@tipoEntidad VARCHAR(16),
	@idCarrier VARCHAR(16) = NULL,
	@fechaDespacho DATETIME = NULL,
	@idBodega VARCHAR(16) = NULL,
	@fechaDesde DATETIME = NULL,
	@fechaHasta DATETIME = NULL,
	@truckId VARCHAR(16) = NULL,
	@nombreExportador VARCHAR(512) = NULL,
	@po VARCHAR(64) = NULL,
	@ConsigneeName VARCHAR(512) = NULL,
	@ShipToName VARCHAR(512) = NULL,
	@palletLabel VARCHAR(16) = NULL,
	@nroDocumento VARCHAR(32) = NULL,
	@nroDespacho VARCHAR(32) = NULL,
	@camion VARCHAR(32) = NULL,
	@puerta VARCHAR(64) = NULL,
	@chofer VARCHAR(128) = NULL,
	@idEmpresa VARCHAR(16),
	@esInventario BIT = NULL,
	@ShipToId VARCHAR(16) = NULL,
	@ConsigneeId VARCHAR(16) = NULL,
	@idTransporte VARCHAR(16) = NULL,
	@BillToId VARCHAR(16) = NULL,
	@BillToName VARCHAR(512) = NULL
AS
BEGIN
	BEGIN TRY
		DECLARE @sql_script NVARCHAR(MAX),
			@param NVARCHAR(MAX)

		CREATE TABLE #TMP_ShipTo (id VARCHAR(16))

		CREATE TABLE #TMP_Consignee (id VARCHAR(16))

		CREATE TABLE #TMP_BillTo (id VARCHAR(16))

		CREATE TABLE #TMP_Exportadores (id VARCHAR(16))

		CREATE TABLE #TMP_CarrierNoDelivery (
			id VARCHAR(16),
			valor VARCHAR(16)
			)

		INSERT INTO #TMP_CarrierNoDelivery
		SELECT T.id,
			PC.Valor
		FROM Transportes T
			INNER JOIN ParametrosCatalogos PC ON T.idTransportePrincipal = PC.IdEntidad
			INNER JOIN ParametrosLista PL ON PC.IdParametroLista = PL.Id
				AND PL.codigo = 'EsDelivery'
		WHERE PC.valor = 'NO'
			AND PL.Actor IN (
				'CARRIER',
				'TERRESTRE'
				)
			AND PL.idEmpresa = @idEmpresa

		IF (@fechaDespacho IS NOT NULL)
		BEGIN
			SELECT @fechaDesde = @fechaDespacho,
				@fechaHasta = @fechaDespacho;
		END;

		IF (@chofer IS NOT NULL)
		BEGIN
			SELECT @chofer = '%' + @chofer + '%'
		END

		IF (@nombreExportador IS NOT NULL)
		BEGIN
			IF @idTransporte IS NOT NULL
			BEGIN
				INSERT INTO #TMP_Exportadores
				VALUES (@idTransporte)
			END
			ELSE
			BEGIN
				SELECT @nombreExportador = '%' + @nombreExportador + '%'

				INSERT INTO #TMP_Exportadores
				SELECT EX.id
				FROM Exportadores EX
				WHERE EX.nombreComercial LIKE @nombreExportador
			END
		END

		SELECT @ConsigneeName = dbo.fnPrevenirInyeccion(@ConsigneeName)

		IF (@ConsigneeName IS NOT NULL)
		BEGIN
			IF @ConsigneeId IS NOT NULL
			BEGIN
				INSERT INTO #TMP_Consignee
				VALUES (@ConsigneeId)
			END
			ELSE
			BEGIN
				INSERT INTO #TMP_Consignee
				SELECT id
				FROM f_SearchEntities(@ConsigneeName, 'Consignee');
			END
		END

		SELECT @BillToName = dbo.fnPrevenirInyeccion(@BillToName)

		IF (@BillToName IS NOT NULL)
		BEGIN
			IF @BillToId IS NOT NULL
			BEGIN
				INSERT INTO #TMP_BillTo
				SELECT id
				FROM f_SearchEntities(@BillToId, 'IdBillTo')
			END
			ELSE
			BEGIN
				INSERT INTO #TMP_BillTo
				SELECT id
				FROM f_SearchEntities(@BillToName, 'BillTo')
			END
		END

		SELECT @ShipToName = dbo.fnPrevenirInyeccion(@ShipToName)

		IF (@ShipToName IS NOT NULL)
		BEGIN
			IF @ShipToId IS NOT NULL
			BEGIN
				INSERT INTO #TMP_ShipTo
				VALUES (@ShipToId)
			END
			ELSE
			BEGIN
				INSERT INTO #TMP_ShipTo
				SELECT id
				FROM f_SearchEntities(@ShipToName, 'ShipTo')
			END
		END

		SELECT @sql_script = CONCAT (
				N'
			;WITH CTE_SubCarrier as
			(
				SELECT
					NEWID() id,
					guiasHouseDetalle.Id IdGuiaHouseDetalle,
					guiaHouse.Id IdGuiaHouse,
					guiaHouse.NroGuia NroGuia,
					programacion.FechaDespacho FechaDespacho,
					ISNULL(ubicacionesBodega.idBodega, guiaHouse.idBodega) AS IdBodega,
					transporte.Id IdCarrier,
					transporte.Nombre NombreCarrier,
					codigoRelacion.Codigo CodigoCarrier,
					paisClientes.Id IdPaisAlt,
					paisClientes.Nombre NombrePaisAlt,
					paisClientes.CodigoIso CodigoIsoPaisAlt,
					estadoClientes.Id IdEstadoAlt,
					estadoClientes.CodigoIso CodigoIsoEstadoAlt,
					estadoClientes.nombre EstadoAlt,
					SHI.Id ShipToId,
					SHI.nombre NombreClienteFinalAlt,
					SHI.nombre NombreClienteFinal,
					CON.Id ConsigneeId,
					CON.nombre NombreClienteConsignee,
					SHI.IdPais IdPais,
					paisClientesFinal.Nombre NombrePais,
					paisClientesFinal.CodigoIso CodigoIsoPais,
					estadoClientesFinal.Id IdEstado,
					estadoClientesFinal.CodigoIso CodigoIsoEstado,
					estadoClientesFinal.nombre Estado,
					manifiesto.Id IdManifiesto,
					manifiesto.NroManifiesto NroManifiesto,
					puertoTE.CodigoAduana DescripcionPuertoFronterizo,
					guiasHouseDetalle.EstadoPieza Status,
					ubicaciones.CargaTransito CargaTransitoNull,
					documentos.NombreArchivo TipoNubeDocs,
					documentos.Id IdDocumentosDespacho,
					ISNULL(documentos.mailEnviado, 0) EmailEnviado,
					ISNULL(transportacionExportacion.enviado, 0) TransportExportEnviado,
					guiasHouseDetalle.TruckId,
					exportador.Id IdExportador,
					exportador.Nombre NombreExportador,
					documentos.NombreArchivo NombreDocumentoDespacho,
					guiasHouseDetalle.AltoIn,
					guiasHouseDetalle.LargoIn,
					guiasHouseDetalle.AnchoIn,
					ISNULL(documentos.modificado, 0) Modificado,
					pallet.Pallet Pallet,
					solicitudDeVenta.Id IdOrdenVenta,
					ed.Puerta,
					ve.Placa,
					ed.truckId NroDespacho,
					transportacionExportacion.id TransportacionExportacionId,
					transportacionExportacion.fechaEnvio FechaEnvio,
					transportacionExportacion.enviado Enviado,
					empleado.Nombres NombresEmpleado,
					empleado.Apellidos ApellidosEmpleado,
					usuariocliente.Nombre NombreUsuarioCliente,
					solicitudDeVenta.fechaSolicitud FechaOrdenVenta,
					guiasHouseDetalle.PO,
					CAST(CASE WHEN solicitudDeVenta.tipoVenta = 5 AND solicitudDeVentaDetalles.tipoPieza = 1 THEN 1
					WHEN solicitudDeVenta.tipoVenta < 4 THEN 1 ELSE 0
					END AS BIT) esInventario,
					CASE WHEN programacion.idUsuarioLogPicking IS NOT NULL THEN 1
					WHEN solicitudDeVentaDetalles.picking = 1 THEN 1
					ELSE 0 END AS Picking,
					CASE WHEN programacionManifiesto.nota = ''Escaner Picking'' THEN 1
					ELSE 0 END AS EscanerDespacho
				FROM ProgramacionCarrier programacion WITH (NOLOCK)
					INNER JOIN GuiasHouseDetalles guiasHouseDetalle WITH (NOLOCK, INDEX = PK_GuiasHouseDetalles) ON guiasHouseDetalle.Id = programacion.IdGuiaHouseDetalle
					INNER JOIN GuiasHouse guiaHouse WITH (NOLOCK) ON guiasHouseDetalle.IdGuiaHouse = guiaHouse.Id
					INNER JOIN Transportes transporte WITH (NOLOCK) ON programacion.IdCarrier = transporte.Id
					INNER JOIN v_ClientsEntities SHI WITH (NOLOCK) ON guiasHouseDetalle.shipToId = SHI.Id
					INNER JOIN v_ClientsEntities CON WITH (NOLOCK) ON guiaHouse.ConsigneeId  = CON.Id
					INNER JOIN Exportadores exportador WITH (NOLOCK) ON guiaHouse.IdExportador = exportador.Id
					INNER JOIN Paises paisClientes WITH (NOLOCK) ON CON.idPais = paisClientes.id
					INNER JOIN Estados estadoClientes WITH (NOLOCK) ON CON.idEstado = estadoClientes.id
					LEFT JOIN CodigosRelacionSistemas codigoRelacion WITH (NOLOCK) ON ((transporte.id = codigoRelacion.idEntidad) AND (@idSistema = codigoRelacion.idSistemaEntidad)) AND (@tipoEntidad = codigoRelacion.tipoEntidad)
					LEFT JOIN Paises paisClientesFinal WITH (NOLOCK) ON SHI.idPais = paisClientesFinal.id
					LEFT JOIN Estados estadoClientesFinal WITH (NOLOCK) ON SHI.idEstado = estadoClientesFinal.id
					LEFT JOIN ProgramacionManifiesto programacionManifiesto WITH (NOLOCK) ON programacion.id = programacionManifiesto.idProgramacionCarrier
					LEFT JOIN ManifiestosDespacho manifiesto WITH (NOLOCK) ON programacionManifiesto.idManifiestoDespacho = manifiesto.id
					OUTER APPLY(
						SELECT TOP 1 nombreArchivo, mailEnviado, id, modificado
						FROM DocumentosDespacho
						WHERE manifiesto.id = idManifiesto AND idDocumento = @idDocumentoManifiesto
						ORDER BY EsPod desc 
					) documentos
					LEFT JOIN ProgramacionTE programacionTe WITH (NOLOCK) ON programacion.id = programacionTe.idProgramacionCarrier
					LEFT JOIN TransportacionExportacion transportacionExportacion WITH (NOLOCK) ON programacionTe.idTE = transportacionExportacion.id
					LEFT JOIN Puertos puertoTE WITH (NOLOCK) ON transportacionExportacion.idPuerto = puertoTE.id
					LEFT JOIN Usuarios usuario WITH (NOLOCK) ON transportacionExportacion.idUsuarioEnvio = usuario.id
					LEFT JOIN Empleados empleado WITH (NOLOCK) ON usuario.idEntidad = empleado.id
					LEFT JOIN v_ClientsEntities usuariocliente WITH (NOLOCK) ON usuario.EntityTypeId = usuariocliente.id
					LEFT JOIN PalletsDetalles palletsDetalle WITH (NOLOCK) ON guiasHouseDetalle.id = palletsDetalle.idGuiasHouseDetalle
					LEFT JOIN Pallets pallet WITH (NOLOCK) ON palletsDetalle.idPallet = pallet.id
					LEFT JOIN SolicitudDeVentaDetalles solicitudDeVentaDetalles WITH (NOLOCK) ON guiasHouseDetalle.id = solicitudDeVentaDetalles.idGuiaHouseDetalle
					LEFT JOIN SolicitudDeVenta solicitudDeVenta WITH (NOLOCK) ON solicitudDeVentaDetalles.idSolicitud = solicitudDeVenta.id
					LEFT JOIN DetalleDespacho dd WITH (NOLOCK) ON guiasHouseDetalle.id = dd.idGuiaHouseDetalle
					LEFT JOIN EncabezadoDespacho ed WITH (NOLOCK) ON dd.idEncabezadoDespacho = ed.id
					LEFT JOIN VehiculosExportadores ve WITH (NOLOCK) ON ed.idVehiculo = ve.id
					LEFT JOIN UbicacionPiezas AS ubicacionPiezas WITH (NOLOCK) ON guiasHouseDetalle.id = ubicacionPiezas.idGuiaHouseDetalle
					LEFT JOIN Ubicaciones AS ubicaciones WITH (NOLOCK) ON ubicacionPiezas.idUbicacion = ubicaciones.id
					LEFT JOIN UbicacionesBodega AS ubicacionesBodega WITH (NOLOCK) ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id'
				,
				CASE 
					WHEN (@chofer IS NOT NULL)
						THEN ' INNER JOIN Empleados emp WITH (NOLOCK) ON ed.idEmpleado = emp.id
					  INNER JOIN FuncionesDepartamento fd WITH (NOLOCK) ON (emp.idFuncionDepartamento = fd.id AND fd.funcion = ''CHOFER'')'
					END,
				' WHERE programacion.idCarrier NOT IN (SELECT id FROM #TMP_CarrierNoDelivery) 
				AND programacion.fechaDespacho BETWEEN @fechaDesde AND @fechaHasta
				AND guiaHouse.IdEmpresa = @IdEmpresa',
				CASE 
					WHEN (@nombreExportador IS NOT NULL)
						THEN ' AND guiaHouse.idExportador IN (SELECT id FROM #TMP_Exportadores)'
					END,
				CASE 
					WHEN (@ShipToName IS NOT NULL)
						THEN ' AND guiasHouseDetalle.ShipToId IN (SELECT id FROM #TMP_ShipTo)'
					END,
				CASE 
					WHEN (@ConsigneeName IS NOT NULL)
						THEN ' AND guiaHouse.ConsigneeId IN (SELECT id FROM #TMP_Consignee)'
					END,
				CASE 
					WHEN (@BillToName IS NOT NULL)
						THEN ' AND CON.id IN (SELECT id FROM #TMP_BillTo)'
					END,
				CASE 
					WHEN (@chofer IS NOT NULL)
						THEN 'AND CONCAT(emp.nombres, '' '', emp.apellidos) LIKE @chofer'
					END,
				')
			SELECT * FROM CTE_SubCarrier
			WHERE  (@IdBodega is null or idBodega = @IdBodega )',
				CASE 
					WHEN (@esInventario IS NOT NULL)
						THEN ' AND esInventario = @esInventario'
					END
				);

		SELECT @param = N'@idSistema INT, @idDocumentoManifiesto VARCHAR(16), @parametroLista VARCHAR(32), @tipoEntidad VARCHAR(16), @fechaDespacho DATETIME
							, @idCarrier VARCHAR(16), @idBodega VARCHAR(16), @fechaDesde DATETIME, @fechaHasta DATETIME, @truckId VARCHAR(16), @nombreExportador VARCHAR(512)
							, @po VARCHAR(64), @ConsigneeName VARCHAR(512), @ShipToName VARCHAR(512), @palletLabel VARCHAR(16)
							, @nroDocumento VARCHAR(32), @nroDespacho VARCHAR(32), @camion VARCHAR(32), @puerta VARCHAR(64), @chofer VARCHAR(128), @IdEmpresa VARCHAR(16), @esInventario BIT
							, @BillToId VARCHAR(16), @BillToName VARCHAR(512)'

		IF (@idCarrier IS NOT NULL)
		BEGIN
			SELECT @sql_script = @sql_script + ' AND IdCarrier = @idCarrier'
		END

		IF (@truckId IS NOT NULL)
		BEGIN
			SELECT @truckId = '%' + @truckId + '%'

			SELECT @sql_script = @sql_script + ' AND TruckId LIKE @truckId'
		END

		IF (@po IS NOT NULL)
		BEGIN
			SELECT @po = '%' + @po + '%'

			SELECT @sql_script = @sql_script + ' AND PO LIKE @po'
		END

		IF (@palletLabel IS NOT NULL)
		BEGIN
			SELECT @palletLabel = '%' + @palletLabel + '%'

			SELECT @sql_script = @sql_script + ' AND Pallet LIKE @palletLabel'
		END

		IF (@nroDocumento IS NOT NULL)
		BEGIN
			SELECT @nroDocumento = '%' + @nroDocumento + '%'

			SELECT @sql_script = @sql_script + ' AND NroGuia LIKE @nroDocumento'
		END

		IF (@nroDespacho IS NOT NULL)
		BEGIN
			SELECT @nroDespacho = '%' + @nroDespacho + '%'

			SELECT @sql_script = @sql_script + ' AND NroDespacho LIKE @nroDespacho'
		END

		IF (@camion IS NOT NULL)
		BEGIN
			SELECT @camion = '%' + @camion + '%'

			SELECT @sql_script = @sql_script + ' AND Placa LIKE @camion'
		END

		IF (@puerta IS NOT NULL)
		BEGIN
			SELECT @puerta = '%' + @puerta + '%'

			SELECT @sql_script = @sql_script + ' AND Puerta LIKE @puerta'
		END

		EXEC SP_EXECUTESQL @sql_script,
			@param,
			@idSistema,
			@idDocumentoManifiesto = @idDocumentoManifiesto,
			@parametroLista = @parametroLista,
			@tipoEntidad = @tipoEntidad,
			@fechaDespacho = @fechaDespacho,
			@idCarrier = @idCarrier,
			@idBodega = @idBodega,
			@fechaDesde = @fechaDesde,
			@fechaHasta = @fechaHasta,
			@truckId = @truckId,
			@po = @po,
			@ConsigneeName = @ConsigneeName,
			@ShipToName = @ShipToName,
			@nombreExportador = @nombreExportador,
			@palletLabel = @palletLabel,
			@nroDocumento = @nroDocumento,
			@nroDespacho = @nroDespacho,
			@camion = @camion,
			@puerta = @puerta,
			@chofer = @chofer,
			@IdEmpresa = @IdEmpresa,
			@esInventario = @esInventario,
			@BillToId = @BillToId,
			@BillToName = @BillToName
	END TRY

	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH;
END
	/*

EXEC dbo.pro_ObtenerPiezasClientesPorSubCarrier       @idSistema = 100,      @idDocumentoManifiesto = N'DOC052395',      @parametroLista = N'PLI0110391',      @tipoEntidad = N'CARRIER',      @idCarrier = NULL,                    @fechaDespacho = NULL,                @idBodega = NULL,                     @fechaDesde = '20251212',       @fechaHasta = '20251216',       @truckId = NULL,      @nombreExportador = NULL,      @po = NULL,      @nombreClienteConsignee = NULL,      @nombreClienteFinal = NULL,      @palletLabel = NULL,      @nroDocumento = NULL,      @nroDespacho = NULL,      @camion = NULL,      @puerta = NULL,      @chofer = NULL,      @IdEmpresa = N'EMP014',      @esInventario = NULL;           
EXEC dbo.AC_pro_GetClientsPiecesBySubCarrier      @idSistema = 100,      @idDocumentoManifiesto = N'DOC052395',      @parametroLista = N'PLI0110391',      @tipoEntidad = N'CARRIER',      @idCarrier = NULL,                    @fechaDespacho = NULL,                @idBodega = NULL,                     @fechaDesde = '20251212',       @fechaHasta = '20251216',       @truckId = NULL,      @nombreExportador = NULL,      @po = NULL,      @ConsigneeName = NULL,      @ShipToName = NULL,      @palletLabel = NULL,      @nroDocumento = NULL,      @nroDespacho = NULL,      @camion = NULL,      @puerta = NULL,      @chofer = NULL,      @IdEmpresa = N'EMP014',      @esInventario = NULL,   @BillToId=NULL,    @BillToName = NULL;  
*/