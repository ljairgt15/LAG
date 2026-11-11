/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_LiquidacionAerolineasTraer
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_LiquidacionAerolineasTraer]
	@Id VARCHAR(13),
	@NroGuia VARCHAR(13),
	@Transaccion VARCHAR(25),
	@FechaDesde DATETIME,
	@FechaHasta DATETIME,
	@CodigoEmpresas CHAR(3),
	@IdAerolinea CHAR(4),	
	@Prepaid VARCHAR(1),
	@Banderas CHAR(30)
AS
BEGIN
	BEGIN TRY
		IF @Banderas = 'RENTABILIDADDIFERENCIASCAS'
		BEGIN
			DECLARE @SQL_DIFERENCIA_CAS VARCHAR(8000),
					@Empresa VARCHAR(50),
					@Aerolinea VARCHAR(50)

			IF @CodigoEmpresas = ''
				SELECT @Empresa = '' 
			ELSE
				SELECT @Empresa = 'AND liquidacionaerolineas.codigoempresas = ''' + @CodigoEmpresas + ''''
			
			IF @IdAerolinea = ''
				SELECT @Aerolinea = '' 
			ELSE
				SELECT @Aerolinea = 'AND idaerolinea = ''' + @IdAerolinea + ''''

			-- Estilo 112 (YYYYMMDD) en lugar de 101 (MM/DD/YYYY)
			SELECT @SQL_DIFERENCIA_CAS = 'SELECT liquidacionaerolineas.*
						INTO #TEMP_RENT_CAS FROM liquidacionaerolineas 								
						WHERE fechaembarque>= ''' + CONVERT(VARCHAR(8),@FechaDesde,112) + ''' and fechaembarque <= ''' + CONVERT(VARCHAR(8),@FechaHasta,112) + '''' +
					  ' ' + @Empresa + 
					  ' ' + @Aerolinea + 		
				' and (transaccion=''S'') ORDER BY nroguia ASC '

			IF @FechaHasta <= '20150115'
			BEGIN
				SELECT @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
						#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
						#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
						#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
						#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
						consignatario AS DueñoCarga,
						guias.detalles, mercancias.nombre, cliente,
						guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, guias.tarifafsc AS tarifafsccorte, guias.etiquetas,
						guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, guias.seguridad AS seguridadcorte, #TEMP_RENT_CAS.seguridad, guias.awc, guias.cd1, guias.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
						guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
						totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((comision + descuento) * 0.02),2) - manejo - comision - descuento - round(((comision + descuento) * 0.12),2) ELSE 0 end, 				  
						totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then comision + manejo + round(((comision + descuento) * 0.12),2) + descuento - round(((comision + descuento) * 0.02),2) ELSE 0 end, cierre,
						consignatario, #TEMP_RENT_CAS.observaciones, mercancias.nombre AS producto,	
						guias.cajasvoladas AS cajasredondeadas, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.empresa, 
						#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.region, #TEMP_RENT_CAS.retencioniva,
						ciudades.nombre AS ciudaddestino,												
						paises.nombre AS paisdestino,
						0.0 AS tarifaconvenio,
						0.0 AS fletenetoconvenio,
						0.0 AS biaconvenio,
						0.0 AS feaconvenio,
						0.0 AS fletetotalconvenio,
						#TEMP_RENT_CAS.tipoVuelo AS tipoVuelo,
						#TEMP_RENT_CAS.codigoContable AS codigoContable,
						#TEMP_RENT_CAS.idCliente AS idCliente,
						#TEMP_RENT_CAS.idMercancia AS idMercancia
						INTO ##TEMP_CAS
						FROM #TEMP_RENT_CAS 
						INNER JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
						INNER JOIN mercancias on guias.idmercancia = mercancias.id						
						INNER JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1				
						LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino	
						LEFT JOIN paises on ciudades.idpaises=paises.id											
						WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + CONVERT(VARCHAR(8),@FechaDesde,112) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + CONVERT(VARCHAR(8),@FechaHasta,112) + '''' +
					  ' ' + @Empresa + 
					  ' ' + @Aerolinea + 		
				' ORDER BY nroguia ASC '
			END

			IF @FechaHasta >= '20150116' AND @FechaHasta <= '20160531'
			BEGIN
				SELECT @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
						#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
						#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
						#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
						#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
						consignatario AS DueñoCarga,
						guias.detalles, mercancias.nombre, cliente,
						guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
						guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
						guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
						totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(isnull(retencioniva,0) ,2) - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) ELSE 0 end, 				  
						totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(isnull(retencioniva,0), 2) ELSE 0 end, cierre,
						consignatario, #TEMP_RENT_CAS.observaciones, mercancias.nombre AS producto,	
						guias.cajasvoladas AS cajasredondeadas, #TEMP_RENT_CAS.empresa,
						#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region, #TEMP_RENT_CAS.retencioniva,
						ciudades.nombre AS ciudaddestino,												
						paises.nombre AS paisdestino,
						0.0 AS tarifaconvenio,
						0.0 AS fletenetoconvenio,
						0.0 AS biaconvenio,
						0.0 AS feaconvenio,
						0.0 AS fletetotalconvenio,
						#TEMP_RENT_CAS.tipoVuelo AS tipoVuelo,
						#TEMP_RENT_CAS.codigoContable AS codigoContable,
						#TEMP_RENT_CAS.idCliente AS idCliente,
						#TEMP_RENT_CAS.idMercancia AS idMercancia
						INTO ##TEMP_CAS
						FROM #TEMP_RENT_CAS LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
						LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
						LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
						LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
						LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
						LEFT JOIN paises on ciudades.idpaises=paises.id												
						WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + CONVERT(VARCHAR(8),@FechaDesde,112) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + CONVERT(VARCHAR(8),@FechaHasta,112) + '''' +
					  ' ' + @Empresa + 
					  ' ' + @Aerolinea + 		
				' ORDER BY nroguia ASC '
			END

			IF @FechaHasta >= '20160601' AND @FechaHasta <= '20170531'
			BEGIN
				SELECT @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
						#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
						#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
						#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
						#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
						consignatario AS DueñoCarga,
						guias.detalles, mercancias.nombre, cliente,
						guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
						guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
						guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
						totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(isnull(retencioniva,0) ,2) - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) ELSE 0 end, 				  
						totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(isnull(retencioniva,0), 2) ELSE 0 end, cierre,
						consignatario, #TEMP_RENT_CAS.observaciones, 
						producto = CASE WHEN isnull(producto,'''')='''' then mercancias.nombre ELSE #TEMP_RENT_CAS.producto end,	
						guias.cajasvoladas AS cajasredondeadas, #TEMP_RENT_CAS.empresa,
						#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region, #TEMP_RENT_CAS.retencioniva,
						ciudades.nombre AS ciudaddestino,												
						paises.nombre AS paisdestino,
						isnull(#TEMP_RENT_CAS.tarifaconvenio,0) AS tarifaconvenio,
						isnull(#TEMP_RENT_CAS.fletenetoconvenio,0) AS fletenetoconvenio,
						isnull(#TEMP_RENT_CAS.biaconvenio,0) AS biaconvenio,
						isnull(#TEMP_RENT_CAS.feaconvenio,0) AS feaconvenio,
						isnull(#TEMP_RENT_CAS.fletetotalconvenio,0) AS fletetotalconvenio,
						#TEMP_RENT_CAS.tipoVuelo AS tipoVuelo,
						#TEMP_RENT_CAS.codigoContable AS codigoContable,
						#TEMP_RENT_CAS.idCliente AS idCliente,
						#TEMP_RENT_CAS.idMercancia AS idMercancia
						INTO ##TEMP_CAS
						FROM #TEMP_RENT_CAS LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
						LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
						LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
						LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
						LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
						LEFT JOIN paises on ciudades.idpaises=paises.id												
						WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + CONVERT(VARCHAR(8),@FechaDesde,112) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + CONVERT(VARCHAR(8),@FechaHasta,112) + '''' +
					  ' ' + @Empresa + 
					  ' ' + @Aerolinea + 		
				' ORDER BY nroguia ASC '
			END
			
			IF @FechaHasta >= '20170601' AND @FechaHasta < '20240401'
			BEGIN
				SELECT @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
						#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
						#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
						#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
						#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
						consignatario AS DueñoCarga,
						guias.detalles, mercancias.nombre, cliente,
						guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
						guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
						guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
						totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) + round(isnull(retencioniva,0) ,2) - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) ELSE 0 end, 				  
						totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(isnull(retencioniva,0), 2) ELSE 0 end, cierre,
						consignatario, #TEMP_RENT_CAS.observaciones, 
						producto = CASE WHEN isnull(producto,'''')='''' then mercancias.nombre ELSE #TEMP_RENT_CAS.producto end,	
						guias.cajasvoladas AS cajasredondeadas, #TEMP_RENT_CAS.empresa,
						#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region, #TEMP_RENT_CAS.retencioniva,
						ciudades.nombre AS ciudaddestino,												
						paises.nombre AS paisdestino,
						isnull(#TEMP_RENT_CAS.tarifaconvenio,0) AS tarifaconvenio,
						isnull(#TEMP_RENT_CAS.fletenetoconvenio,0) AS fletenetoconvenio,
						isnull(#TEMP_RENT_CAS.biaconvenio,0) AS biaconvenio,
						isnull(#TEMP_RENT_CAS.feaconvenio,0) AS feaconvenio,
						isnull(#TEMP_RENT_CAS.fletetotalconvenio,0) AS fletetotalconvenio,
						#TEMP_RENT_CAS.tipoVuelo AS tipoVuelo,
						#TEMP_RENT_CAS.codigoContable AS codigoContable,
						#TEMP_RENT_CAS.idCliente AS idCliente,
						#TEMP_RENT_CAS.idMercancia AS idMercancia,
						#TEMP_RENT_CAS.maa AS maa_alianza,
						#TEMP_RENT_CAS.paa AS paa,
						#TEMP_RENT_CAS.tra AS tra,
						#TEMP_RENT_CAS.bfa AS bfa,
						#TEMP_RENT_CAS.acuerdoscomerciales AS acuerdoscomerciales,
						#TEMP_RENT_CAS.descuentocliente AS descuentocliente, #TEMP_RENT_CAS.comisioncliente, #TEMP_RENT_CAS.overcomisioncliente, 
						#TEMP_RENT_CAS.diferenciatarifascliente, 
						#TEMP_RENT_CAS.devolucioncliente, 
						#TEMP_RENT_CAS.reclamocliente, 
						#TEMP_RENT_CAS.reclamos,
						#TEMP_RENT_CAS.numeroVuelo,
						#TEMP_RENT_CAS.totalFacturado,
						#TEMP_RENT_CAS.tarifaCompra,
						#TEMP_RENT_CAS.tarifaventa,
						#TEMP_RENT_CAS.tarifamargen,
						#TEMP_RENT_CAS.ingresoxtarifa,
						#TEMP_RENT_CAS.ingresoxtarifaxkilo,
						#TEMP_RENT_CAS.ingresoneto,
						#TEMP_RENT_CAS.margensinbia,
						#TEMP_RENT_CAS.ingresosinbia,
						#TEMP_RENT_CAS.oacliente
						INTO ##TEMP_CAS
						FROM #TEMP_RENT_CAS LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
						LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
						LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
						LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
						LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
						LEFT JOIN paises on ciudades.idpaises=paises.id												
						--WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + CONVERT(VARCHAR(8),@FechaDesde,112) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + CONVERT(VARCHAR(8),@FechaHasta,112) + '''' +
					  ' ' + @Empresa + 
					  ' ' + @Aerolinea + 		
				' ORDER BY nroguia ASC '
			END

			IF @FechaHasta >= '20240401'
			BEGIN
				SELECT @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
						#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
						#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
						#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
						#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
						consignatario AS DueñoCarga,
						guias.detalles, mercancias.nombre, cliente,
						guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
						guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
						guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
						totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) + round(isnull(retencioniva,0) ,2) - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) ELSE 0 end, 				  
						totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(isnull(retencioniva,0), 2) ELSE 0 end, cierre,
						consignatario, #TEMP_RENT_CAS.observaciones, 
						producto = CASE WHEN isnull(producto,'''')='''' then mercancias.nombre ELSE #TEMP_RENT_CAS.producto end,	
						guias.cajasvoladas AS cajasredondeadas, #TEMP_RENT_CAS.empresa,
						#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region, #TEMP_RENT_CAS.retencioniva,
						ciudades.nombre AS ciudaddestino,												
						paises.nombre AS paisdestino,
						isnull(#TEMP_RENT_CAS.tarifaconvenio,0) AS tarifaconvenio,
						isnull(#TEMP_RENT_CAS.fletenetoconvenio,0) AS fletenetoconvenio,
						isnull(#TEMP_RENT_CAS.biaconvenio,0) AS biaconvenio,
						isnull(#TEMP_RENT_CAS.feaconvenio,0) AS feaconvenio,
						isnull(#TEMP_RENT_CAS.fletetotalconvenio,0) AS fletetotalconvenio,
						#TEMP_RENT_CAS.tipoVuelo AS tipoVuelo,
						#TEMP_RENT_CAS.codigoContable AS codigoContable,
						#TEMP_RENT_CAS.idCliente AS idCliente,
						#TEMP_RENT_CAS.idMercancia AS idMercancia,
						#TEMP_RENT_CAS.maa AS maa_alianza,
						#TEMP_RENT_CAS.paa AS paa,
						#TEMP_RENT_CAS.tra AS tra,
						#TEMP_RENT_CAS.bfa AS bfa,
						#TEMP_RENT_CAS.acuerdoscomerciales AS acuerdoscomerciales,
						#TEMP_RENT_CAS.descuentocliente AS descuentocliente, #TEMP_RENT_CAS.comisioncliente, #TEMP_RENT_CAS.overcomisioncliente, 
						#TEMP_RENT_CAS.diferenciatarifascliente, 
						#TEMP_RENT_CAS.devolucioncliente, 
						#TEMP_RENT_CAS.reclamocliente, 
						#TEMP_RENT_CAS.reclamos,
						#TEMP_RENT_CAS.numeroVuelo,
						#TEMP_RENT_CAS.totalFacturado,
						#TEMP_RENT_CAS.tarifaCompra,
						#TEMP_RENT_CAS.tarifaventa,
						#TEMP_RENT_CAS.tarifamargen,
						#TEMP_RENT_CAS.ingresoxtarifa,
						#TEMP_RENT_CAS.ingresoxtarifaxkilo,
						#TEMP_RENT_CAS.ingresoneto,
						#TEMP_RENT_CAS.margensinbia,
						#TEMP_RENT_CAS.ingresosinbia,
						#TEMP_RENT_CAS.oacliente
						INTO ##TEMP_CAS
						FROM #TEMP_RENT_CAS LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
						LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
						LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
						LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
						LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
						LEFT JOIN paises on ciudades.idpaises=paises.id												
						--WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + CONVERT(VARCHAR(8),@FechaDesde,112) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + CONVERT(VARCHAR(8),@FechaHasta,112) + '''' +
					  ' ' + @Empresa + 
					  ' ' + @Aerolinea + 		
				' ORDER BY nroguia ASC '
			END

			EXEC (@SQL_DIFERENCIA_CAS)
			PRINT GETDATE()
			PRINT 'PAso el Query string'

			SELECT CONVERT(VARCHAR(13), CASE WHEN a.nroguia IS NULL THEN b.id ELSE a.id END) AS id,  
				1 AS status, CONVERT(BIT,0) AS seleccionar, CASE WHEN a.idaerolinea IS NULL THEN b.idaerolinea ELSE a.idaerolinea END AS idaerolinea, ISNULL(a.prepaid,'') AS prepaid, a.nroguia, b.nroguia AS nroguiaCASS, 
				a.origen, a.destino, a.fechaembarque,		
				ISNULL(a.pesobruto,0) AS pesobruto, ISNULL(a.pesocargable,0) AS pesocargable, ISNULL(a.fletenetoreal,0) AS fletenetoreal, ISNULL(a.tarifareal,0) AS tarifareal, ISNULL(a.tarifacorte,0) AS tarifacorte, 
				ISNULL(b.wgtchargeprepaid,0) AS wgtchargeprepaid, ISNULL(b.wgtchargecollect,0) AS wgtchargecollect,
				CONVERT(DECIMAL(9,3),ISNULL(a.comision,0)) AS comision, 
				CONVERT(DECIMAL(10,3),ISNULL(b.comission,0)) AS comisioncass, 
				CONVERT(DECIMAL(9,3),ISNULL(a.manejo,0)) AS manejo, 
				CONVERT(DECIMAL(10,3),ISNULL(b.dueagent,0)) AS manejocass,
				CONVERT(DECIMAL(9,3),ISNULL(a.descuento,0)) AS descuento, 
				CONVERT(DECIMAL(10,3),ISNULL(b.discount,0)) AS descuentocass,   
				CONVERT(DECIMAL(9,3),ISNULL(a.diferenciatarifas,0)) AS diferenciatarifas,
				CONVERT(DECIMAL(9,3),ISNULL(a.cargosaerolinea,0)) AS cargosaerolinea, 
				CONVERT(DECIMAL(10,3), ISNULL(b.duecarrier,0)) AS cargosaerolineacass, 
				ISNULL(totalapagar,0) AS totalapagar, ISNULL(totalacobrar,0) AS totalacobrar, ISNULL(payable,0) AS payable, CASE WHEN ISNULL(a.prepaid,'') = 1 THEN ISNULL(payable,0) - ISNULL(totalapagar,0) ELSE ISNULL(payable,0) - ISNULL(totalacobrar,0) END AS diferenciapagarcobrar , cierre,
				observaciones, consignatario, cliente, cass, fechareportada, 		
				tarifacass = ISNULL(CASE WHEN prepaid=1 AND pesocargable>0 THEN wgtchargeprepaid / pesocargable WHEN prepaid=0 AND pesocargable>0 THEN wgtchargecollect / pesocargable ELSE 0 END, 0),
				combustiblecorte, combustible, seguridad, 
				prepaidcass = CONVERT(BIT, ISNULL(CASE WHEN (wgtchargeprepaid >0 AND wgtchargecollect = 0) THEN 1 ELSE 0 END, 0)), ISNULL(urn,'') AS urn, 
				producto,
				dueñocarga, handling, awa, documentos, transporte, etiquetas, cargofitos AS fitos, tarifacf AS certificadosorigen, otroscargosagencia, rp, tarifafsccorte, tarifassccorte, 
				periododesde, periodohasta, cajasredondeadas, cajasvoladas, empresa, b.taxcom AS taxcomCASS, b.retencionfuente AS retencionfuenteCASS, fletetotalcorte, region, 
				ciudaddestino, retencioniva, paisdestino,
				tarifaconvenio,
				fletenetoconvenio,
				biaconvenio,
				feaconvenio,
				fletetotalconvenio,
				tipoVuelo, 
				codigocontable,				
				idcliente,
				idmercancia,
				bia = biaconvenio,
				fea = feaconvenio,
				maa,
				paa,
				tra,
				reclamos,
				acuerdoscomerciales,
				descuentocliente, comisioncliente, overcomisioncliente, diferenciatarifascliente, devolucioncliente, reclamocliente,
				sucursal = 'UIO',
				bfa, 
				numeroVuelo, 
				totalFacturado, 
				tarifacompra,
				tarifaventa,
				tarifamargen,
				ingresoxtarifa,
				ingresoxtarifaxkilo,
				ingresoneto,	
				margensinbia,
				ingresosinbia,
				oacliente
			FROM
				( SELECT id, idaerolinea, nroguia, origen, destino, fechaembarque, ISNULL(pesobruto,0) AS pesobruto, ISNULL(pesocargable,0) AS pesocargable, ISNULL(fletenetoreal,0) AS fletenetoreal, ISNULL(tarifareal,0) AS tarifareal, ISNULL(tarifacorte,0) AS tarifacorte,
				  CONVERT(DECIMAL(9,3),ISNULL(comision,0)) AS comision, 
				  CONVERT(DECIMAL(9,3),ISNULL(manejo,0)) AS manejo, 
				  CONVERT(DECIMAL(9,3),ISNULL(descuento,0)) AS descuento, prepaid, 
				  CONVERT(DECIMAL(9,3),ISNULL(cargosaerolinea,0)) AS cargosaerolinea, 
				  CONVERT(DECIMAL(9,3),ISNULL(totalapagar,0)) AS totalapagar, 
				  -1 * CONVERT(DECIMAL(9,3),ISNULL(totalacobrar,0)) AS totalacobrar, cierre, 
				  observaciones, consignatario, 
				  dueñocarga, cliente, 
				  cass, ISNULL(combustiblecorte,0) AS combustiblecorte, ISNULL(combustible,0) AS combustible, ISNULL(seguridad,0) AS seguridad, ISNULL(diferenciatarifas,0) AS diferenciatarifas, ISNULL(urn,'') AS urn, 
				  producto,
				  ISNULL(handling,0) AS handling, ISNULL(awa,0) AS awa, ISNULL(documentos,0) AS documentos, ISNULL(transporte,0) AS transporte, ISNULL(etiquetas,0) AS etiquetas, ISNULL(cargofitos,0) AS cargofitos, ISNULL(tarifacf,0) AS tarifacf, ISNULL(otroscargosagencia,0) AS otroscargosagencia, ISNULL(rp,0) AS rp, ISNULL(tarifafsccorte,0) AS tarifafsccorte, ISNULL(tarifassccorte,0) AS tarifassccorte, ISNULL(cajasredondeadas,0) AS cajasredondeadas, ISNULL(cajasvoladas,0) AS cajasvoladas, empresa,
				  fletetotalcorte, region, ciudaddestino, retencioniva, paisdestino,
				  tarifaconvenio,
				  fletenetoconvenio,
				  biaconvenio,
				  feaconvenio,
				  fletetotalconvenio,
				  tipoVuelo,
				  codigocontable,
				  codigoempresas,
				  idcliente,
				  idmercancia,
				  maa = maa_alianza,
				  paa,
				  tra,
				  bfa,
				  reclamos,
				  acuerdoscomerciales,
				  descuentocliente, comisioncliente, overcomisioncliente, diferenciatarifascliente, devolucioncliente, reclamocliente,
				  numeroVuelo, 
				  totalFacturado,
				  tarifacompra,
				  tarifaventa,
				  tarifamargen,
				  ingresoxtarifa,
				  ingresoxtarifaxkilo,
				  ingresoneto,
				  margensinbia,
				  ingresosinbia,
				  oacliente
				  FROM ##TEMP_CAS	  
				) a
				LEFT JOIN 
				( SELECT MIN(CONVERT(VARCHAR(13),id)) AS id,
					SUBSTRING(cas.nroguia,1,3) AS idaerolinea, cas.nroguia, 
					SUM(CONVERT(DECIMAL(12,3),ISNULL(wgtchargeprepaid,0))) AS wgtchargeprepaid, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(taxawbprepaid,0))) AS taxawbprepaid, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(duecarrier,0))) AS duecarrier, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(wgtchargecollect,0))) AS wgtchargecollect, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(dueagent,0))) AS dueagent, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(comission,0))) AS comission, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(discount,0))) AS discount, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(retencionfuente,0))) AS retencionfuente, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(netsales,0))) AS netsales, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(taxcom,0))) AS taxcom, 
					SUM(CONVERT(DECIMAL(9,3),ISNULL(payable,0))) AS payable, 
					MIN(invoicedate) AS fechareportada, 
					periododesde = (SELECT TOP 1 casa.periododesde FROM cas casa INNER JOIN cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia ORDER BY casa.periododesde DESC),
					periodohasta = (SELECT TOP 1 casa.periodohasta FROM cas casa INNER JOIN cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia ORDER BY casa.periodohasta DESC)
				  FROM cas 
				  WHERE periododesde>=@FechaDesde AND periodohasta<=@FechaHasta 
				  GROUP BY nroguia
				) b
				ON a.nroguia = b.nroguia 
						
			UNION

			SELECT CONVERT(VARCHAR(13), CASE WHEN a.nroguia IS NULL THEN b.id ELSE a.id END) AS id, 
				1 AS [status], CONVERT(BIT,0) AS seleccionar, CASE WHEN a.idaerolinea IS NULL THEN b.idaerolinea ELSE a.idaerolinea END AS idaerolinea,
				prepaid = ISNULL((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
				a.nroguia, b.nroguia AS nroguiaCASS, 
				origen = (SELECT origen FROM liquidacionaerolineas WHERE nroguia = b.nroguia), 
				destino = (SELECT destino FROM liquidacionaerolineas WHERE nroguia = b.nroguia), 
				fechaembarque = (SELECT fechaembarque FROM liquidacionaerolineas WHERE nroguia = b.nroguia),	
				pesobruto = ISNULL((SELECT pesobruto FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
				pesocargable = ISNULL((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
				fletenetoreal = ISNULL((SELECT fletenetoreal FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
				tarifareal = ISNULL((SELECT tarifareal FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
				tarifacorte = ISNULL((SELECT ISNULL(tarifacorte,0) FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),			
				ISNULL(b.wgtchargeprepaid,0) AS wgtchargeprepaid, 
				ISNULL(b.wgtchargecollect,0) AS wgtchargecollect,
				comision = ISNULL((SELECT ISNULL(tarifacorte,0) FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
				CONVERT(DECIMAL(9,3),ISNULL(b.comission,0)) AS comisioncass,  
				manejo = ISNULL((SELECT manejo FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
				CONVERT(DECIMAL(9,3),ISNULL(b.dueagent,0)) AS manejocass,
				descuento = ISNULL((SELECT descuento FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0), 
				CONVERT(DECIMAL(9,3),ISNULL(b.discount,0)) AS descuentocass,   
				diferenciatarifas = ISNULL((SELECT diferenciatarifas FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
				cargosaerolinea = ISNULL((SELECT cargosaerolinea FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
				CONVERT(DECIMAL(9,3), ISNULL(b.duecarrier,0)) AS cargosaerolineacass, 
				ISNULL(totalapagar,0) AS totalapagar, ISNULL(totalacobrar,0) AS totalacobrar, 
				ISNULL(payable,0) AS payable, 
				CASE WHEN ISNULL(a.prepaid,'') = 1 THEN ISNULL(payable,0) - ISNULL(totalapagar,0) ELSE ISNULL(payable,0) - ISNULL(totalacobrar,0) END AS diferenciapagarcobrar, 
				cierre,
				observaciones, 
				consignatario, 
				cliente, 
				cass, 
				fechareportada,		
				tarifacass = ISNULL(CASE WHEN ISNULL((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)=1 AND ISNULL((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)>0 THEN wgtchargeprepaid / ISNULL((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) WHEN ISNULL((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) = 0 AND ISNULL((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)>0 THEN wgtchargecollect / ISNULL((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) ELSE 0 END, 0),
				ISNULL(combustiblecorte,0) AS combustiblecorte, ISNULL(combustible,0) AS combustible, ISNULL(seguridad,0) AS seguridad, 
				prepaidcass = CONVERT(BIT, ISNULL(CASE WHEN (wgtchargeprepaid <>0 AND wgtchargecollect = 0) THEN 1 ELSE 0 END, 0)),
				ISNULL(urn,'') AS urn, producto,
				ISNULL(dueñocarga,0) AS dueñocarga, ISNULL(handling,0) AS handling, ISNULL(awa,0) AS awa, ISNULL(documentos,0) AS documentos, ISNULL(transporte,0) AS transporte, ISNULL(etiquetas,0) AS etiquetas, ISNULL(cargofitos,0) AS fitos, ISNULL(tarifacf,0) AS certificadosorigen, ISNULL(otroscargosagencia,0) AS otroscargosagencia, ISNULL(rp,0) AS rp, ISNULL(tarifafsccorte,0) AS tarifafsccorte, ISNULL(tarifassccorte,0) AS tarifassccorte,
				periododesde, periodohasta, ISNULL(cajasredondeadas,0) AS cajasredondeadas, ISNULL(cajasvoladas,0) AS cajasvoladas, empresa = (SELECT empresa FROM liquidacionaerolineas WHERE nroguia = b.nroguia), ISNULL(b.taxcom,0) AS taxcomCASS, ISNULL(b.retencionfuente,0) AS retencionfuenteCASS,
				fletetotalcorte, region, ciudaddestino, retencioniva, paisdestino,
				tarifaconvenio,
				fletenetoconvenio,
				biaconvenio,
				feaconvenio,
				fletetotalconvenio,
				tipoVuelo, 
				codigocontable,				
				idcliente,
				idmercancia,
				bia = biaconvenio,
				fea = feaconvenio,
				maa,
				paa,
				tra,
				reclamos,
				acuerdoscomerciales,
				descuentocliente, comisioncliente, overcomisioncliente, diferenciatarifascliente, devolucioncliente, reclamocliente,
				sucursal = 'UIO',
				bfa,
				numeroVuelo,
				totalFacturado,
				tarifacompra,
				tarifaventa,
				tarifamargen,
				ingresoxtarifa,
				ingresoxtarifaxkilo,
				ingresoneto,
				margensinbia,
				ingresosinbia,
				oacliente
			FROM
				( SELECT id, idaerolinea, nroguia, destino, fechaembarque, ISNULL(pesobruto,0) AS pesobruto, ISNULL(pesocargable,0) AS pesocargable, ISNULL(fletenetoreal,0) AS fletenetoreal, ISNULL(tarifareal,0) AS tarifareal, ISNULL(tarifacorte,0) AS tarifacorte,
				  CONVERT(DECIMAL(9,3),ISNULL(comision,0)) AS comision, 
				  CONVERT(DECIMAL(9,3),ISNULL(manejo,0)) AS manejo, 
				  CONVERT(DECIMAL(9,3),ISNULL(descuento,0)) AS descuento, 
				  prepaid, 
				  CONVERT(DECIMAL(9,3),ISNULL(cargosaerolinea,0)) AS cargosaerolinea, 
				  CONVERT(DECIMAL(9,3),ISNULL(totalapagar,0)) AS totalapagar, 
				  1 * CONVERT(DECIMAL(9,3),ISNULL(totalacobrar,0)) AS totalacobrar, 
				  cierre, 
				  observaciones, cass, ISNULL(combustiblecorte,0) AS combustiblecorte, ISNULL(combustible,0) AS combustible, ISNULL(seguridad,0) AS seguridad, ISNULL(diferenciatarifas,0) diferenciatarifas, ISNULL(urn,'') AS urn, 
				  ISNULL(handling,0) AS handling, ISNULL(awa,0) AS awa, ISNULL(documentos,0) AS documentos, ISNULL(transporte,0) AS transporte, ISNULL(etiquetas,0) AS etiquetas, ISNULL(cargofitos,0) AS cargofitos, ISNULL(tarifacf,0) AS tarifacf, ISNULL(otroscargosagencia,0) AS otroscargosagencia, ISNULL(rp,0) AS rp, ISNULL(tarifafsccorte,0) AS tarifafsccorte, ISNULL(tarifassccorte,0) AS tarifassccorte, ISNULL(cajasredondeadas,0) AS cajasredondeadas, ISNULL(cajasvoladas,0) AS cajasvoladas, empresa,
				  fletetotalcorte, region, ciudaddestino, retencioniva, paisdestino,
				  tarifaconvenio,
				  fletenetoconvenio,
				  biaconvenio,
				  feaconvenio,
				  fletetotalconvenio,
				  tipoVuelo,
				  codigocontable,
				  codigoempresas,
				  idCliente,
				  idMercancia,
				  maa = maa_alianza,
				  paa,
				  tra,
				  bfa,
				  acuerdoscomerciales, 
				  descuentocliente, comisioncliente, overcomisioncliente, diferenciatarifascliente, devolucioncliente, reclamos, reclamocliente,
				  numeroVuelo, 
				  totalFacturado = 0,
				  tarifacompra,
				  tarifaventa,
				  tarifamargen,
				  ingresoxtarifa,
				  ingresoxtarifaxkilo,
				  ingresoneto,
				  margensinbia,
				  ingresosinbia,
				  oacliente	
				  FROM ##TEMP_CAS	  
				) a
				RIGHT JOIN 
				( 
				  SELECT MIN(CONVERT(VARCHAR(13),id)) AS id, 
				  SUBSTRING(cas.nroguia,1,3) AS idaerolinea, cas.nroguia, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(wgtchargeprepaid,0))) AS wgtchargeprepaid,  
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(taxawbprepaid,0))) AS taxawbprepaid, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(duecarrier,0))) AS duecarrier, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(wgtchargecollect,0))) AS wgtchargecollect, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(dueagent,0))) AS dueagent, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(comission,0))) AS comission, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(discount,0))) AS discount, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(retencionfuente,0))) AS retencionfuente, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(netsales,0))) AS netsales, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(taxcom,0))) AS taxcom, 
				  SUM(CONVERT(DECIMAL(9,3),ISNULL(payable,0))) AS payable, 
				  execdate = (SELECT fechaembarque FROM guias WHERE nroguia=cas.nroguia), 
				  consignatario = (SELECT consignatario FROM liquidacionaerolineas WHERE nroguia=cas.nroguia), 
				  dueñocarga = (SELECT consignatarios.nombre1 FROM guicon INNER JOIN consignatarios ON guicon.idconsignatarios = consignatarios.id WHERE nroguia=cas.nroguia AND cntetiq=1), 
				  cliente = (SELECT cliente FROM liquidacionaerolineas WHERE nroguia=cas.nroguia), 
				  origen = (SELECT codigoempresas FROM guias WHERE nroguia=cas.nroguia),
				  producto = (SELECT mercancias.nombre FROM guias INNER JOIN mercancias ON guias.idmercancia=mercancias.id WHERE nroguia = cas.nroguia),
				  MIN(invoicedate) AS fechareportada,
				  periododesde = (SELECT TOP 1 casa.periododesde FROM cas casa INNER JOIN cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia ORDER BY casa.periododesde DESC),
				  periodohasta = (SELECT TOP 1 casa.periodohasta FROM cas casa INNER JOIN cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia ORDER BY casa.periodohasta DESC)
				  FROM cas 
				  WHERE periododesde>=@FechaDesde AND periodohasta<=@FechaHasta
				  GROUP BY cas.nroguia
				) b
				ON a.nroguia = b.nroguia 		
			WHERE a.nroguia IS NULL

			PRINT GETDATE()

			DROP TABLE ##TEMP_CAS
			
			RETURN
		END

		IF @Banderas = 'DETALLEGUIACASS'
		BEGIN
			SELECT id, nroguia, estado, origen, destino, wgtchargeprepaid, taxawbprepaid, duecarrier, wgtchargecollect, dueagent, comission, discount, retencionfuente, netsales, 
				   taxcom, payable, execdate, agentsinformation, invoice, invoicedate, periododesde, periodohasta
			FROM CAS 
			WHERE nroguia = @NroGuia		
			RETURN
		END

	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
GO
/*
	exec AC_pro_LiquidacionAerolineasTraer 
	@id='',
	@nroguia='',
	@transaccion='',
	@FechaDesde='2026-09-01 00:00:00',
	@FechaHasta='2026-09-15 00:00:00',
	@CodigoEmpresas='   ',
	@IdAerolinea='    ',
	@Prepaid='',
	@Banderas='RENTABILIDADDIFERENCIASCAS    '
*/