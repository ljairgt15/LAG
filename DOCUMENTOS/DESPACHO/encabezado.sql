/*
VERSION		MODIFIEDBY			MODIFIEDDATE	HU			MODIFICATION
1			Jordan Chango       2026-02-02		57730		Initial Code - Based on pro_Despacho_DespachoPorCarrier
*/
ALTER   PROCEDURE [dbo].[AC_pro_GetDispatchesByCarrier] (
	@idEmpresa VARCHAR(16),
	@FechaDesde DATETIME,
	@FechaHasta DATETIME,
	@ConsigneeName VARCHAR(512) = NULL,
	@ShipToName VARCHAR(512) = NULL,
	@NombreExportador VARCHAR(512) = NULL,
	@TruckId VARCHAR(16) = NULL,
	@PO VARCHAR(64) = NULL,
	@IdBodega VARCHAR(16) = NULL,
	@NroDocumento VARCHAR(32) = NULL,
	@EsDelivery BIT = 1,
	@Pendientes BIT = 1,
	@PalletLabel VARCHAR(16) = NULL,
	@NroDespacho VARCHAR(32) = NULL,
	@Camion VARCHAR(32) = NULL,
	@Puerta VARCHAR(64) = NULL,
	@Chofer VARCHAR(128) = NULL,
	@ShipToId VARCHAR(16) = NULL,
	@ConsigneeId VARCHAR(16) = NULL,
	@idTransporte VARCHAR(16) = NULL,
	@BillToId VARCHAR(16) = NULL,
	@BillToName VARCHAR(512) = NULL
	)
AS
BEGIN
	BEGIN TRY
		DECLARE @idParametroLista VARCHAR(16),
			@sql_script NVARCHAR(MAX),
			@parametros NVARCHAR(MAX) = N'@FechaDesde DATETIME, @FechaHasta DATETIME, @ConsigneeName VARCHAR(512), @ShipToName VARCHAR(512),
			@NombreExportador VARCHAR(512), @TruckId VARCHAR(16), @PO VARCHAR(64), @IdBodega VARCHAR(16), @NroDocumento VARCHAR(32),
			@PalletLabel VARCHAR(16), @NroDespacho VARCHAR(32), @Camion VARCHAR(32), @Puerta VARCHAR(64), @Chofer VARCHAR(128), @idEmpresa VARCHAR(16), @BillToId VARCHAR(16), @BillToName VARCHAR(512)'

		CREATE TABLE #TMP_TablaAgrupacionGuiasHouse (
			id INT IDENTITY(1, 1),
			idBodega VARCHAR(16) NULL,
			idBroker VARCHAR(16) NULL,
			estadoPieza NVARCHAR(64) NULL,
			idCarrier VARCHAR(16) NOT NULL,
			fechaDespacho DATETIME NOT NULL,
			totalPiezas INT NOT NULL,
			idTE UNIQUEIDENTIFIER NULL,
			piezasManifiesto INT NOT NULL,
			conPodEnviado INT NOT NULL,
			esInventario BIT
			);

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

		SELECT @sql_script = 
			N'INSERT INTO #TMP_TablaAgrupacionGuiasHouse
			SELECT 
				CASE
					WHEN (UB.idBodega IS NULL OR UB.idBodega = '''')
					THEN GH.idBodega ELSE UB.idBodega
				END AS idBodega,
				GH.idBroker,
				GHD.estadoPieza, 
				PC.idCarrier,
				PC.fechaDespacho,
				COUNT(1) AS totalPiezas,
				PT.idTE, 
				SUM(IIF(PM.id IS NOT NULL, 1, 0)) piezasManifiesto,
				SUM(IIF(documentosDespacho.nombreArchivo LIKE ''POD%'' 
					AND documentosDespacho.mailEnviado = 1, 1, 0)) conPodEnviado,
				CASE WHEN svc.tipoVenta = 5 AND svd.tipoPieza = 1 THEN 1
					WHEN svc.tipoVenta < 4 THEN 1 ELSE 0 
				END esInventario
			FROM ProgramacionCarrier PC WITH (NOLOCK) 
				INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON PC.idGuiaHouseDetalle = GHD.id  
				INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id	
				LEFT JOIN dbo.ProgramacionTe PT WITH (NOLOCK) ON PC.id = PT.idProgramacionCarrier  
				LEFT JOIN dbo.ProgramacionManifiesto PM WITH (NOLOCK) ON PM.idProgramacionCarrier = PC.id 
				OUTER APPLY(
					SELECT TOP 1 DD.nombreArchivo, DD.mailEnviado
					FROM DocumentosDespacho DD WITH (NOLOCK)
					WHERE DD.idManifiesto = PM.idManifiestoDespacho
						AND DD.idDocumento = ''DOC052395''
						AND DD.mailEnviado = 1
				) AS documentosDespacho
				OUTER APPLY (
					SELECT TOP (1) solicitud.id, solicitud.tipoVenta
					FROM SolicitudDeVentaDetalles solicitudDetalle WITH (NOLOCK)
						LEFT JOIN dbo.SolicitudDeVenta solicitud WITH (NOLOCK) ON solicitud.id = solicitudDetalle.idSolicitud
					WHERE solicitudDetalle.idGuiaHouseDetalle = GHD.id
					ORDER BY solicitud.fechaSolicitud DESC) AS svc
				LEFT JOIN SolicitudDeVentaDetalles svd  WITH (NOLOCK) ON GHD.id = svd.idGuiaHouseDetalle AND svd.idSolicitud = svc.id
				LEFT JOIN UbicacionPiezas UP WITH (NOLOCK) ON GHD.id = UP.idGuiaHouseDetalle
				LEFT JOIN Ubicaciones U WITH (NOLOCK) ON UP.idUbicacion = U.id
				LEFT JOIN UbicacionesBodega UB WITH (NOLOCK) ON U.idUbicacionBodega = UB.id
				#FILTROS#
			WHERE  PC.idCarrier NOT IN (SELECT id FROM #TMP_CarrierNoDelivery) 
				AND PC.fechaDespacho BETWEEN @FechaDesde AND @FechaHasta 
				AND GH.idEmpresa = @idEmpresa
				#CONDICION#
			GROUP BY 
			CASE
				WHEN (UB.idBodega IS NULL OR UB.idBodega = '''')
				THEN GH.idBodega ELSE UB.idBodega
			END, 
			GH.idBroker, GHD.estadoPieza, 
			PC.idCarrier, PC.fechaDespacho, PT.idTE, 
			CASE WHEN svc.tipoVenta = 5 AND svd.tipoPieza = 1 THEN 1
				WHEN svc.tipoVenta < 4 THEN 1 ELSE 0 
				END'

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
				FROM f_SearchEntities(@ConsigneeName, 'Consignee')
			END

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND GH.ConsigneeId IN (SELECT id FROM #TMP_Consignee)
				#CONDICION#')
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

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND GHD.ShipToId IN (SELECT id FROM #TMP_ShipTo)
				#CONDICION#')
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

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND GH.BillToConsigneeId IN (SELECT id FROM #TMP_BillTo)
				#CONDICION#')
		END

		SELECT @NombreExportador = dbo.fnPrevenirInyeccion(@NombreExportador)

		IF (@NombreExportador IS NOT NULL)
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

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND GH.idExportador IN (SELECT id FROM #TMP_Exportadores)
				#CONDICION#')
		END

		SELECT @TruckId = dbo.fnPrevenirInyeccion(@TruckId)

		IF (@TruckId IS NOT NULL)
		BEGIN
			SELECT @TruckId = '%' + @TruckId + '%'

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND GHD.truckId LIKE @TruckId
				#CONDICION#')
		END

		SELECT @PO = dbo.fnPrevenirInyeccion(@PO)

		IF (@PO IS NOT NULL)
		BEGIN
			SELECT @PO = '%' + @PO + '%'

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND GHD.po LIKE @PO
				#CONDICION#')
		END

		SELECT @NroDocumento = dbo.fnPrevenirInyeccion(@NroDocumento)

		IF (@NroDocumento IS NOT NULL)
		BEGIN
			SELECT @NroDocumento = '%' + @NroDocumento + '%'

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND GH.nroGuia LIKE @NroDocumento
				#CONDICION#')
		END

		SELECT @PalletLabel = dbo.fnPrevenirInyeccion(@PalletLabel)

		IF (@PalletLabel IS NOT NULL)
		BEGIN
			SELECT @PalletLabel = '%' + @PalletLabel + '%'

			SELECT @sql_script = REPLACE(@sql_script, '#FILTROS#', 'INNER JOIN PalletsDetalles PLD WITH (NOLOCK) ON GHD.id = PLD.idGuiasHouseDetalle
				INNER JOIN Pallets PAL WITH (NOLOCK) ON PLD.idPallet = PAL.id
				#FILTROS#')

			SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND PAL.pallet LIKE @PalletLabel
				#CONDICION#')
		END

		SELECT @Camion = dbo.fnPrevenirInyeccion(@Camion)

		SELECT @Puerta = dbo.fnPrevenirInyeccion(@Puerta)

		SELECT @NroDespacho = dbo.fnPrevenirInyeccion(@NroDespacho)

		SELECT @Chofer = dbo.fnPrevenirInyeccion(@Chofer)

		IF (
				@Camion IS NOT NULL
				OR @Puerta IS NOT NULL
				OR @NroDespacho IS NOT NULL
				OR @Chofer IS NOT NULL
				)
		BEGIN
			SELECT @sql_script = REPLACE(@sql_script, '#FILTROS#', 'INNER JOIN DetalleDespacho DD WITH (NOLOCK) ON GHD.id = DD.idGuiaHouseDetalle
				INNER JOIN EncabezadoDespacho ED WITH (NOLOCK) ON DD.idEncabezadoDespacho = ED.id
				INNER JOIN VehiculosExportadores VE WITH (NOLOCK) ON ED.idVehiculo = VE.id
				#FILTROS#')

			IF (@Camion IS NOT NULL)
			BEGIN
				SELECT @Camion = '%' + @Camion + '%'

				SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND VE.placa LIKE @Camion
					#CONDICION#')
			END

			IF (@Puerta IS NOT NULL)
			BEGIN
				SELECT @Puerta = '%' + @Puerta + '%'

				SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND ED.puerta LIKE @Puerta
					#CONDICION#')
			END

			IF (@NroDespacho IS NOT NULL)
			BEGIN
				SELECT @NroDespacho = '%' + @NroDespacho + '%'

				SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND ED.truckId LIKE @NroDespacho
					#CONDICION#')
			END

			IF (@Chofer IS NOT NULL)
			BEGIN
				SELECT @sql_script = REPLACE(@sql_script, '#FILTROS#', 'INNER JOIN Empleados EMP WITH (NOLOCK) ON ED.idEmpleado = EMP.id
				INNER JOIN FuncionesDepartamento FD WITH (NOLOCK) ON EMP.idFuncionDepartamento = FD.id
				#FILTROS#')

				SELECT @Chofer = '%' + @Chofer + '%'

				SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', 'AND CONCAT(EMP.nombres, '' '', EMP.apellidos) LIKE @Chofer 
					#CONDICION#')
			END
		END

		SELECT @sql_script = REPLACE(@sql_script, '#FILTROS#', '')

		SELECT @sql_script = REPLACE(@sql_script, '#CONDICION#', '')

		EXEC SP_EXECUTESQL @sql_script,
			@parametros,
			@FechaDesde = @FechaDesde,
			@FechaHasta = @FechaHasta,
			@ConsigneeName = @ConsigneeName,
			@ShipToName = @ShipToName,
			@NombreExportador = @NombreExportador,
			@TruckId = @TruckId,
			@PO = @PO,
			@IdBodega = @IdBodega,
			@NroDocumento = @NroDocumento,
			@PalletLabel = @PalletLabel,
			@NroDespacho = @NroDespacho,
			@Camion = @Camion,
			@Puerta = @Puerta,
			@Chofer = @Chofer,
			@idEmpresa = @idEmpresa,
			@BillToId = @BillToId,
			@BillToName = @BillToName

		SELECT @idParametroLista = id
		FROM ParametrosLista parametroLista
		WHERE parametroLista.codigo = 'EsDelivery'
			AND parametroLista.idEmpresa = @idEmpresa;

		SELECT tmp.id Id,
			TMP.idBroker,
			TMP.idBodega IdBodega,
			B.nombre NombreBodega,
			TMP.idCarrier IdCarrier,
			T.nombre NombreCarrier,
			TMP.fechaDespacho FechaDespacho,
			TMP.estadoPieza [Status],
			TMP.totalPiezas TotalPiezas,
			TMP.idTE,
			CONVERT(BIT, (IIF(TE.enviado = 1, 1, 0))) StatusEnvioTE,
			E.nombres + ' ' + E.apellidos UsuarioEnvioTE,
			TE.fechaEnvio FechaEnvioTE,
			TMP.piezasManifiesto PiezasManifiesto,
			TMP.conPodEnviado PiezasConPodEnviado,
			PC.valor,
			TMP.esInventario
		FROM #TMP_TablaAgrupacionGuiasHouse TMP
			INNER JOIN dbo.Bodegas B WITH (NOLOCK) ON TMP.idBodega = B.id
			INNER JOIN dbo.Transportes T WITH (NOLOCK) ON TMP.idCarrier = T.id
			INNER JOIN dbo.Transportes C WITH (NOLOCK) ON T.idTransportePrincipal = C.id
			LEFT JOIN dbo.TransportacionExportacion TE WITH (NOLOCK) ON TMP.idTE = TE.id
			LEFT JOIN dbo.Usuarios U WITH (NOLOCK) ON TE.idUsuarioEnvio = U.id
			LEFT JOIN dbo.Empleados E WITH (NOLOCK) ON U.idEntidad = E.id
			LEFT JOIN dbo.ParametrosCatalogos PC WITH (NOLOCK) ON C.id = PC.idEntidad
				AND PC.idParametroLista = @idParametroLista
		WHERE (
				PC.valor IS NULL
				OR PC.valor = 'SI'
				)
			AND (
				@IdBodega IS NULL
				OR tmp.idBodega = @IdBodega
				)

		DROP TABLE #TMP_TablaAgrupacionGuiasHouse
	END TRY

	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH;
END
	/*  

  exec dbo.pro_Despacho_DespachoPorCarrier @idEmpresa=N'EMP014',@FechaDesde='2025-12-03 00:00:00',    @FechaHasta='2025-12-07 00:00:00',@NombreClienteConsignee=NULL,@NombreClienteFinal=NULL,@NombreExportador=NULL,@TruckId=NULL,@PO=NULL,@IdBodega=NULL,@NroDocumento=NULL,@EsDelivery=1,@Pendientes=1,@PalletLabel=NULL,@NroDespacho=NULL,@Camion=NULL,@Puerta=NULL,@Chofer=NULL     
  exec dbo.AC_pro_GetDispatchesByCarrier @idEmpresa=N'EMP014',@FechaDesde='2025-12-03 00:00:00',    @FechaHasta='2025-12-07 00:00:00',@ConsigneeName=NULL,@ShipToName=NULL,@NombreExportador=NULL,@TruckId=NULL,@PO=NULL,@IdBodega=NULL,@NroDocumento=NULL,@EsDelivery=1,@Pendientes=1,@PalletLabel=NULL,@NroDespacho=NULL,@Camion=NULL,@Puerta=NULL,@Chofer=NULL,     @BillToId=NULL, @BillToName = null


*/