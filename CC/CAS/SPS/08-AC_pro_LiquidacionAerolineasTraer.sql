/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_LiquidacionAerolineasTraer
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_LiquidacionAerolineasTraer]
	@Id VARCHAR(13),
	@NroGuia VARCHAR(13),
	@Transaccion VARCHAR(25),
	@FechaDesde Datetime,
	@FechaHasta Datetime,
	@CodigoEmpresas char(3),
	@IdAerolinea char(4),	
	@Prepaid VARCHAR(1),
	@Banderas char(30)
AS
BEGIN
BEGIN TRY
IF @Banderas = 'RENTABILIDADDIFERENCIASCAS'
	BEGIN

		--ELIMINAR TODAS LAS GUIAS QUE NO PERTENEZCAN AL STOCK DE G&G ANTES DE HACER EL CHEQUEO
		--PACAS 18/07/2014
		IF getdate() <= '08/15/2014'
		BEGIN
			DELETE FROM CAS WHERE CAS.nroguia IN (
			SELECT substring(CAS.nroguia,1,11) FROM CAS LEFT JOIN stockawb on CAS.nroguia = stockawb.nroguia
			WHERE (substring(CAS.nroguia,1,3) = '074' or substring(CAS.nroguia,1,3) = '172') and stockawb.nroguia is null )
		END

		DECLARE @SQL_DIFERENCIA_CAS VARCHAR(8000)

		IF @CodigoEmpresas = ''
			SET @Empresa = '' 
		ELSE
			SET @Empresa = 'AND liquidacionaerolineas.codigoempresas = ''' + @CodigoEmpresas + ''''
		
		IF @IdAerolinea = ''
			SET @Aerolinea = '' 
		ELSE
			SET @Aerolinea = 'AND idaerolinea = ''' + @IdAerolinea + ''''
			--drop table  #TEMP_RENT_CAS
		SET  @SQL_DIFERENCIA_CAS = 'SELECT liquidacionaerolineas.*
					INTO #TEMP_RENT_CAS FROM liquidacionaerolineas  								
					WHERE fechaembarque>= ''' + Convert(VARCHAR(10),@FechaDesde,101) + ''' and fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' and (transaccion=''S'') ORDER BY nroguia ASC '

		IF @FechaHasta <= '01/15/2015'
		BEGIN
	
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  AS DueñoCarga, 
					consignatario AS DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, guias.tarifafsc AS tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, guias.seguridad AS seguridadcorte, #TEMP_RENT_CAS.seguridad, guias.awc, guias.cd1, guias.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((comision + descuento) * 0.02),2) - manejo - comision - descuento - round(((comision + descuento) * 0.12),2) ELSE 0 end, 				  
				    totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then comision + manejo + round(((comision + descuento) * 0.12),2) + descuento - round(((comision + descuento) * 0.02),2) ELSE 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, mercancias.nombre AS producto,	
					guias.cajasvoladas AS cajasredondeadas,  #TEMP_RENT_CAS.cajasvoladas,	#TEMP_RENT_CAS.empresa, 
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
					FROM #TEMP_RENT_CAS  INNER JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					INNER JOIN mercancias on guias.idmercancia = mercancias.id						
					INNER JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1				
					LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino	
					LEFT JOIN paises on ciudades.idpaises=paises.id											
					WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(VARCHAR(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END
		IF @FechaHasta >= '01/16/2015' and @FechaHasta <= '05/31/2016'
		BEGIN
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  AS DueñoCarga, 
					consignatario AS DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) ELSE 0 end, 				  
				    --totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  ELSE 0 end, cierre,
					totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) ELSE 0 end, 				  
				    totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(isnull(retencioniva,0), 2)  ELSE 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, mercancias.nombre AS producto,	
					guias.cajasvoladas AS cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
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
					FROM #TEMP_RENT_CAS  LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
					--LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					LEFT JOIN paises on ciudades.idpaises=paises.id												
					WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(VARCHAR(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END
		IF @FechaHasta >= '06/01/2016' and @FechaHasta <= '05/31/2017'
		BEGIN
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  AS DueñoCarga, 
					consignatario AS DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.14) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) ELSE 0 end, 				  
				    --totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.14) * aerolineas.retencion ,2)  ELSE 0 end, cierre,
					totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) ELSE 0 end, 				  
				    totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(isnull(retencioniva,0), 2)  ELSE 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, 
					producto = CASE WHEN isnull(producto,'''')='''' then mercancias.nombre  ELSE #TEMP_RENT_CAS.producto end,	
					guias.cajasvoladas AS cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
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
					FROM #TEMP_RENT_CAS  LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
					--LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					LEFT JOIN paises on ciudades.idpaises=paises.id												
					WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(VARCHAR(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END
		
		IF @FechaHasta >= '06/01/2017' and @FechaHasta < '04/01/2024'
		BEGIN
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  AS DueñoCarga, 
					consignatario AS DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.0275),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) ELSE 0 end, 				  
				    --totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  ELSE 0 end, cierre,
					totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) ELSE 0 end, 				  
				    totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(isnull(retencioniva,0), 2)  ELSE 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, 
					producto = CASE WHEN isnull(producto,'''')='''' then mercancias.nombre  ELSE #TEMP_RENT_CAS.producto end,	
					guias.cajasvoladas AS cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
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
					FROM #TEMP_RENT_CAS  LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
					LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					LEFT JOIN paises on ciudades.idpaises=paises.id												
					--WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(VARCHAR(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END

		IF @FechaHasta >= '04/01/2024'
		BEGIN
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  AS DueñoCarga, 
					consignatario AS DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc AS tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea AS duecarrier, guias.combustible AS combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad AS seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc AS tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.0275),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.15) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) ELSE 0 end, 				  
				    --totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.15) * aerolineas.retencion ,2)  ELSE 0 end, cierre,
					totalapagar = CASE WHEN #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) ELSE 0 end, 				  
				    totalacobrar = CASE WHEN #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(isnull(retencioniva,0), 2)  ELSE 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, 
					producto = CASE WHEN isnull(producto,'''')='''' then mercancias.nombre  ELSE #TEMP_RENT_CAS.producto end,	
					guias.cajasvoladas AS cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
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
					FROM #TEMP_RENT_CAS  LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
					LEFT JOIN ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					LEFT JOIN paises on ciudades.idpaises=paises.id												
					--WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(VARCHAR(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END

		
			EXEC (@SQL_DIFERENCIA_CAS)
			PRINT GETDATE()
			PRINT 'PAso el Query string'


		SELECT convert(VARCHAR(13), CASE WHEN a.nroguia IS NULL THEN b.id ELSE a.id end) AS id,  
        --convert(VARCHAR(13), a.id ) AS id,  				
		1 AS status, convert(bit,0) AS seleccionar, CASE WHEN a.idaerolinea IS NULL THEN b.idaerolinea ELSE a.idaerolinea end AS idaerolinea, isnull(a.prepaid,'') AS prepaid, a.nroguia, b.nroguia AS nroguiaCASS, 
		a.origen, a.destino, a.fechaembarque,		
		isnull(a.pesobruto,0) AS pesobruto, isnull(a.pesocargable,0) AS pesocargable, isnull(a.fletenetoreal,0) AS fletenetoreal, isnull(a.tarifareal,0) AS tarifareal, isnull(a.tarifacorte,0) AS tarifacorte, 
		isnull(b.wgtchargeprepaid,0) AS wgtchargeprepaid, isnull(b.wgtchargecollect,0) AS wgtchargecollect,
	    convert(decimal(9,3),isnull(a.comision,0)) AS comision, 
		convert(decimal(10,3),isnull(b.comission,0)) AS comisioncass, 
		convert(decimal(9,3),isnull(a.manejo,0)) AS manejo, 
		convert(decimal(10,3),isnull(b.dueagent,0)) AS manejocass,
		convert(decimal(9,3),isnull(a.descuento,0)) AS descuento, 
		convert(decimal(10,3),isnull(b.discount,0)) AS descuentocass,   
		convert(decimal(9,3),isnull(a.diferenciatarifas,0)) AS diferenciatarifas,
		convert(decimal(9,3),isnull(a.cargosaerolinea,0)) AS cargosaerolinea, 
		convert(decimal(10,3), isnull(b.duecarrier,0)) AS cargosaerolineacass, 
        isnull(totalapagar,0) AS totalapagar, isnull(totalacobrar,0) AS totalacobrar, isnull(payable,0) AS payable, CASE WHEN isnull(a.prepaid,'') = 1 then  isnull(payable,0) - isnull(totalapagar,0) ELSE isnull(payable,0) - isnull(totalacobrar,0) end AS diferenciapagarcobrar , cierre,
		observaciones, consignatario, cliente, cass, fechareportada, 		
		tarifacass = isnull (CASE WHEN prepaid=1 and pesocargable>0 then wgtchargeprepaid / pesocargable when prepaid=0 and pesocargable>0 then wgtchargecollect / pesocargable ELSE 0 end, 0),
		combustiblecorte, combustible, seguridad, 
		prepaidcass = convert(bit, isnull( CASE WHEN (wgtchargeprepaid >0 and wgtchargecollect = 0) then 1 ELSE 0 end ,0) ),isnull(urn,'') AS urn, 
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
		maa ,
		paa ,
		tra ,
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
			( SELECT id, idaerolinea, nroguia, origen, destino, fechaembarque, isnull(pesobruto,0) AS pesobruto, isnull(pesocargable,0) AS pesocargable, isnull(fletenetoreal,0) AS fletenetoreal, isnull(tarifareal,0) AS tarifareal, isnull(tarifacorte,0) AS tarifacorte,
			  convert(decimal(9,3),isnull(comision,0)) AS comision, 
			  convert(decimal(9,3),isnull(manejo,0)) AS manejo, 
			  convert(decimal(9,3),isnull(descuento,0)) AS descuento, prepaid, 
			  convert(decimal(9,3),isnull(cargosaerolinea,0)) AS cargosaerolinea, 
			  convert(decimal(9,3),isnull(totalapagar,0)) AS totalapagar, 
			  -1 * convert(decimal(9,3),isnull(totalacobrar,0)) AS totalacobrar, cierre, 
			  observaciones, consignatario, 
			  dueñocarga, cliente, 
			  cass, isnull(combustiblecorte,0) AS combustiblecorte,isnull(combustible,0) AS combustible, isnull(seguridad,0) AS seguridad, isnull(diferenciatarifas,0) AS diferenciatarifas,isnull(urn,'') AS urn, 
			producto,
			  isnull(handling,0) AS handling, isnull(awa,0) AS awa, isnull(documentos,0) AS documentos, isnull(transporte,0) AS transporte, isnull(etiquetas,0) AS etiquetas, isnull(cargofitos,0 ) AS cargofitos, isnull(tarifacf,0) AS tarifacf, isnull(otroscargosagencia,0) AS otroscargosagencia, isnull(rp,0 ) AS rp, isnull(tarifafsccorte,0) AS tarifafsccorte, isnull(tarifassccorte,0) AS tarifassccorte, isnull(cajasredondeadas,0) AS cajasredondeadas, isnull(cajasvoladas,0) AS cajasvoladas, empresa,
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
			( SELECT  min(convert(VARCHAR(13),id)) AS id,
				substring(cas.nroguia,1,3) AS idaerolinea, cas.nroguia, 
				sum(convert(decimal(12,3),isnull(wgtchargeprepaid,0))) AS wgtchargeprepaid, 
				sum(convert(decimal(9,3),isnull(taxawbprepaid,0))) AS taxawbprepaid, 
			
				sum(convert(decimal(9,3),isnull(duecarrier,0))) AS duecarrier, 
				sum(convert(decimal(9,3),isnull(wgtchargecollect,0))) AS wgtchargecollect, 
				
				sum(convert(decimal(9,3),isnull(dueagent,0))) AS dueagent, 
				
				sum(convert(decimal(9,3),isnull(comission,0))) AS comission, 
				
				sum(convert(decimal(9,3),isnull(discount,0))) AS discount, 

				sum(convert(decimal(9,3),isnull(retencionfuente,0))) AS retencionfuente, 
				
				sum(convert(decimal(9,3),isnull(netsales,0))) AS netsales, 
				
              sum(convert(decimal(9,3),isnull(taxcom,0))) AS taxcom, 
			  
			  sum(convert(decimal(9,3),isnull(payable,0))) AS payable, 
			  
			  min(invoicedate) AS fechareportada, 
				periododesde = (SELECT top 1 casa.periododesde FROM cas casa inner join cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia order by casa.periododesde desc),
				periodohasta = (SELECT top 1 casa.periodohasta FROM cas casa inner join cas casb ON cas.nroguia=casb.nroguia  WHERE casa.nroguia = cas.nroguia order by casa.periodohasta desc)
				FROM cas 
			  WHERE periododesde>=@FechaDesde and periodohasta<=@FechaHasta 
			  GROUP BY nroguia
			) b
			on a.nroguia = b.nroguia 
					
		UNION

		SELECT convert(VARCHAR(13), CASE WHEN a.nroguia IS NULL THEN b.id ELSE a.id end) AS id, 
		1 AS [status], convert(bit,0) AS seleccionar, CASE WHEN a.idaerolinea IS NULL THEN b.idaerolinea ELSE a.idaerolinea end AS idaerolinea,
		prepaid = isnull((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		a.nroguia, b.nroguia AS nroguiaCASS, 
		origen = (SELECT origen FROM liquidacionaerolineas WHERE nroguia = b.nroguia), 
		destino = (SELECT destino FROM liquidacionaerolineas WHERE nroguia = b.nroguia), 
		fechaembarque = (SELECT fechaembarque FROM liquidacionaerolineas WHERE nroguia = b.nroguia),	
		pesobruto = isnull((SELECT pesobruto FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		pesocargable = isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		fletenetoreal = isnull((SELECT fletenetoreal FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		tarifareal = isnull((SELECT tarifareal FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		tarifacorte = isnull((SELECT isnull(tarifacorte,0) FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),			
		isnull(b.wgtchargeprepaid,0) AS wgtchargeprepaid, 
		isnull(b.wgtchargecollect,0) AS wgtchargecollect,
		comision = isnull((SELECT isnull(tarifacorte,0) FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		convert(decimal(9,3),isnull(b.comission,0)) AS comisioncass,  
		manejo = isnull((SELECT manejo FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		convert(decimal(9,3),isnull(b.dueagent,0)) AS manejocass,
		descuento = isnull((SELECT descuento FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0), 
		convert(decimal(9,3),isnull(b.discount,0)) AS descuentocass,   
		diferenciatarifas = isnull((SELECT diferenciatarifas FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		cargosaerolinea = isnull((SELECT cargosaerolinea FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		convert(decimal(9,3), isnull(b.duecarrier,0)) AS cargosaerolineacass, 
        isnull(totalapagar,0) AS totalapagar, isnull(totalacobrar,0) AS totalacobrar, 
		isnull(payable,0) AS payable, 
		CASE WHEN isnull(a.prepaid,'') = 1 then  isnull(payable,0) - isnull(totalapagar,0) ELSE isnull(payable,0) - isnull(totalacobrar,0) end AS diferenciapagarcobrar, 
		cierre,
		observaciones, 
		consignatario, 
		cliente, 
		cass, 
		fechareportada,		
		tarifacass = isnull (CASE WHEN isnull((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)=1 and isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)>0 then wgtchargeprepaid / isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) when isnull((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) = 0 and isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)>0 then wgtchargecollect / isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) ELSE 0 end, 0),
		isnull(combustiblecorte,0) AS combustiblecorte, isnull(combustible,0) AS combustible, isnull(seguridad,0) AS seguridad, 
		prepaidcass = convert(bit, isnull( CASE WHEN (wgtchargeprepaid <>0 and wgtchargecollect = 0) then 1 ELSE 0 end ,0) ),
		isnull(urn,'') AS urn, producto,
		isnull(dueñocarga,0) AS dueñocarga, isnull(handling,0) AS handling , isnull(awa,0) AS awa, isnull(documentos,0) AS documentos, isnull(transporte,0) AS transporte, isnull(etiquetas,0) AS etiquetas, isnull(cargofitos,0) AS fitos, isnull(tarifacf,0) AS certificadosorigen, isnull(otroscargosagencia,0) AS otroscargosagencia, isnull(rp,0) AS rp, isnull(tarifafsccorte,0) AS tarifafsccorte, isnull(tarifassccorte,0) AS tarifassccorte,
		periododesde, periodohasta, isnull(cajasredondeadas,0) AS cajasredondeadas, isnull(cajasvoladas,0) AS cajasvoladas, empresa = (SELECT empresa FROM liquidacionaerolineas WHERE nroguia = b.nroguia) , isnull(b.taxcom,0) AS taxcomCASS, isnull(b.retencionfuente,0) AS retencionfuenteCASS,
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
			( SELECT id, idaerolinea, nroguia, destino, fechaembarque, isnull(pesobruto,0) AS pesobruto, isnull(pesocargable,0) AS pesocargable , isnull(fletenetoreal,0) AS fletenetoreal, isnull(tarifareal,0) AS tarifareal, isnull(tarifacorte,0) AS tarifacorte,
			  convert(decimal(9,3),isnull(comision,0)) AS comision, 
			  convert(decimal(9,3),isnull(manejo,0)) AS manejo, 
			  convert(decimal(9,3),isnull(descuento,0)) AS descuento, 
			  prepaid, 
			  convert(decimal(9,3),isnull(cargosaerolinea,0)) AS cargosaerolinea, 
			  convert(decimal(9,3),isnull(totalapagar,0)) AS totalapagar, 
			  1 * convert(decimal(9,3),isnull(totalacobrar,0)) AS totalacobrar, 
			  cierre, 
              observaciones, cass, isnull(combustiblecorte,0) AS combustiblecorte, isnull(combustible,0) AS combustible, isnull(seguridad,0) AS seguridad, isnull(diferenciatarifas,0) diferenciatarifas ,isnull(urn,'') AS urn, 
				isnull(handling,0) AS handling , isnull(awa,0) AS awa, isnull(documentos,0) AS documentos, isnull(transporte,0) AS transporte , isnull(etiquetas,0) AS etiquetas, isnull(cargofitos,0) AS cargofitos, isnull(tarifacf,0) AS tarifacf, isnull(otroscargosagencia,0 ) AS otroscargosagencia, isnull(rp,0) AS rp, isnull(tarifafsccorte,0) AS tarifafsccorte, isnull(tarifassccorte,0) AS tarifassccorte, isnull(cajasredondeadas,0) AS cajasredondeadas , isnull(cajasvoladas,0) AS cajasvoladas, empresa,
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
			right join 
			( 
		      SELECT min(convert(VARCHAR(13),id)) AS id, 
			  substring(cas.nroguia,1,3) AS idaerolinea,cas.nroguia, 
			  sum(convert(decimal(9,3),isnull(wgtchargeprepaid,0))) AS wgtchargeprepaid,  
			  sum(convert(decimal(9,3),isnull(taxawbprepaid,0))) AS taxawbprepaid, 
			  sum(convert(decimal(9,3),isnull(duecarrier,0))) AS duecarrier, 
			  sum(convert(decimal(9,3),isnull(wgtchargecollect,0))) AS wgtchargecollect, 
			  sum(convert(decimal(9,3),isnull(dueagent,0))) AS dueagent, 
			  sum(convert(decimal(9,3),isnull(comission,0))) AS comission, 
			  sum(convert(decimal(9,3),isnull(discount,0))) AS discount, 
			  sum(convert(decimal(9,3),isnull(retencionfuente,0))) AS retencionfuente, 
			  sum(convert(decimal(9,3),isnull(netsales,0))) AS netsales, 
			  sum(convert(decimal(9,3),isnull(taxcom,0))) AS taxcom, 
			  sum(convert(decimal(9,3),isnull(payable,0))) AS payable, 
			  
			  execdate = (SELECT fechaembarque FROM guias WHERE nroguia=cas.nroguia), 
			  consignatario = (SELECT consignatario FROM liquidacionaerolineas WHERE nroguia=cas.nroguia), 
			  dueñocarga = (SELECT consignatarios.nombre1 FROM guicon inner join consignatarios on guicon.idconsignatarios = consignatarios.id WHERE nroguia=cas.nroguia and cntetiq=1), 
			  cliente = (SELECT cliente FROM liquidacionaerolineas WHERE nroguia=cas.nroguia), 
			  origen = (SELECT codigoempresas FROM guias WHERE nroguia=cas.nroguia),
			  producto = (SELECT mercancias.nombre FROM guias inner join mercancias on guias.idmercancia=mercancias.id WHERE nroguia = cas.nroguia),
			  min(invoicedate) AS fechareportada, --periododesde, periodohasta
			  periododesde = (SELECT top 1 casa.periododesde FROM cas casa inner join cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia order by casa.periododesde desc),
			  periodohasta = (SELECT top 1 casa.periodohasta FROM cas casa inner join cas casb ON cas.nroguia=casb.nroguia  WHERE casa.nroguia = cas.nroguia order by casa.periodohasta desc)
			  FROM cas 
			  WHERE periododesde>=@FechaDesde and periodohasta<=@FechaHasta
			  GROUP BY cas.nroguia
			 ) b
			on a.nroguia = b.nroguia 		
		WHERE a.nroguia is null
		PRINT getdate()

		DROP TABLE ##TEMP_CAS
		
		
		RETURN
	END
	
	IF @Banderas = 'DETALLEGUIACASS'
	BEGIN
		SELECT id, nroguia, estado, origen, destino, wgtchargeprepaid, taxawbprepaid, duecarrier, wgtchargecollect, dueagent, comission, discount, retencionfuente, netsales, 
               taxcom, payable, execdate, agentsinformation, invoice, invoicedate, periododesde, periodohasta
		FROM CAS WHERE nroguia = @NroGuia		
		RETURN
	END
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
GO
/*
EXEC [dbo].[AC_pro_LiquidacionAerolineasTraer]
    @Id = '',
    @NroGuia = '12345678901',
    @Transaccion = 'S',
    @FechaDesde = '20260801',
    @FechaHasta = '20260831',
    @CodigoEmpresas = '001',
    @IdAerolinea = '1234',
    @Prepaid = '',
    @Banderas = 'TRANSACCION'
*/