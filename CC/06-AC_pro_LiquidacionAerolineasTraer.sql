/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_LiquidacionAerolineasTraer
*/
CREATE ORALTER   PROCEDURE [dbo].[AC_pro_LiquidacionAerolineasTraer]
	@id varchar(13),
	@nroguia varchar(13),
	@transaccion varchar(25),
	@FechaDesde Datetime,
	@FechaHasta Datetime,
	@CodigoEmpresas char(3),
	@IdAerolinea char(4),	
	@Prepaid varchar(1),
	@Banderas char(30)
AS
BEGIN
BEGIN TRY
	IF @Banderas = 'TRANSACCION'
	BEGIN

		IF (@transaccion != '')
		BEGIN
			SELECT id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,valorprepaid
			  ,fletetotalcorte ,fletetotalreal ,pesobruto ,pesocargable ,fletenetoreal ,tarifareal
			  ,fletenetocorte  ,tarifacorte    ,fechacontable ,cca ,isnull(reclamo,0) as reclamo, descuento ,manejo ,costosmanejo
			  ,costootros ,utilidadmanejo ,comision ,overcomision ,diferenciatarifas ,cliente
			  ,origen ,codigoempresas ,transaccion ,fechatransaccion ,observaciones, cargosaerolinea, cierre, isnull(pagar,0.00) as pagar, isnull(cobrar,0.00) as cobrar, isnull(textopagarcobrar,0) as textopagarcobrar
			  ,tarifafsc, tarifassc, combustible, seguridad,
			  fechamanejo, fechacomision, fechadescuento, fechaovercomision, fechaovercomision2, fechadiferenciatarifas, fechareclamo
			FROM rentabilidad WHERE nroguia = @nroguia and transaccion=@transaccion
		
			RETURN
		END
	
		IF (@transaccion = '')
		BEGIN
			SELECT id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,valorprepaid
			  ,fletetotalcorte ,fletetotalreal ,pesobruto ,pesocargable ,fletenetoreal ,tarifareal
			  ,fletenetocorte  ,tarifacorte    ,fechacontable ,cca ,isnull(reclamo,0) as reclamo, descuento ,manejo ,costosmanejo
			  ,costootros ,utilidadmanejo ,comision ,overcomision ,diferenciatarifas ,cliente
			  ,origen ,codigoempresas ,transaccion ,fechatransaccion , observaciones, cargosaerolinea, cierre, isnull(pagar,0.00) as pagar, isnull(cobrar,0.00) as cobrar, isnull(textopagarcobrar,0) as textopagarcobrar
			  ,tarifafsc, tarifassc, combustible, seguridad,
		      fechamanejo, fechacomision, fechadescuento, fechaovercomision, fechaovercomision2, fechadiferenciatarifas, fechareclamo
			FROM rentabilidad WHERE nroguia = @nroguia and (transaccion='C' or transaccion = 'ND' or transaccion = 'NC' or transaccion='A')
		
			RETURN
		END
	END

	IF @Banderas = 'TODORENTABILIDADPRUEBA'
	BEGIN
		declare @SQL varchar(5000), @Empresa varchar (50), @Aerolinea varchar(50)

		if @CodigoEmpresas = ''
			set @Empresa = '' 
		else
			set @Empresa = 'AND rentabilidad.codigoempresas = ''' + @CodigoEmpresas + ''''
		
		if @IdAerolinea = ''
			set @Aerolinea = '' 
		else
			set @Aerolinea = 'AND idaerolinea = ''' + @IdAerolinea + ''''

		SET  @SQL = 'SELECT rentabilidad.*, ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, guias.detalles, mercancias.nombre, clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, guias.tarifafsc, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible, guias.seguridad, guias.awc, guias.cd1, guias.tarifassc, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc
					FROM RENTABILIDAD  LEFT JOIN GUIAS ON RENTABILIDAD.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id
					LEFT JOIN clientes on guias.codigo=clientes.codigo	
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia 
					LEFT JOIN consignatarios on guicon.idconsignatarios = consignatarios.id 								
					WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' and cntetiq=1 ORDER BY nroguia ASC '



		EXEC (@SQL)
		
		RETURN
		
	END

	IF @Banderas = 'TODORENTABILIDAD'
	BEGIN
		declare @SQL_PRUEBA varchar(8000), @Empresa_PRUEBA varchar (50), @Aerolinea_PRUEBA varchar(50)

		if @CodigoEmpresas = ''
			set @Empresa = '' 
		else
			set @Empresa = 'AND rentabilidad.codigoempresas = ''' + @CodigoEmpresas + ''''
		
		if @IdAerolinea = ''
			set @Aerolinea = '' 
		else
			set @Aerolinea = 'AND idaerolinea = ''' + @IdAerolinea + ''''

		SET  @SQL_PRUEBA = 'SELECT rentabilidad.*
					INTO ##TEMP_RENT_DH FROM RENTABILIDAD  								
					WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' and (transaccion=''S'' or transaccion=''A'' or transaccion=''ND'' ) ORDER BY nroguia ASC 

			UPDATE ##TEMP_RENT_DH
			SET ##TEMP_RENT_DH.id = correccion.id,
			##TEMP_RENT_DH.fletenetoreal = correccion.fletenetoreal,
			##TEMP_RENT_DH.tarifareal = correccion.tarifareal,
			##TEMP_RENT_DH.cargosaerolinea = correccion.cargosaerolinea,
			##TEMP_RENT_DH.comision = correccion.comision,
			##TEMP_RENT_DH.fechacontable = correccion.fechacontable,
			##TEMP_RENT_DH.diferenciatarifas = correccion.diferenciatarifas,
			##TEMP_RENT_DH.manejo = correccion.manejo,
			##TEMP_RENT_DH.descuento = correccion.descuento,
			##TEMP_RENT_DH.reclamo = correccion.reclamo,
			##TEMP_RENT_DH.overcomision = correccion.overcomision,
			##TEMP_RENT_DH.overcomision2 = correccion.overcomision2,
			##TEMP_RENT_DH.transaccion = correccion.transaccion,
			##TEMP_RENT_DH.fechacomision= correccion.fechacomision
			FROM ##TEMP_RENT_DH INNER JOIN (
										SELECT * from (
										SELECT row_number() over(partition by nroguia order by fechatransaccion desc) as contador, 
										id, nroguia, fechatransaccion, transaccion, fletenetoreal, tarifareal, cargosaerolinea, comision, diferenciatarifas, manejo, descuento, reclamo, fechacontable, overcomision, overcomision2, fechacomision
										FROM rentabilidad
										WHERE transaccion = ''C'') c
										WHERE contador=1 
										) correccion										
			on ##TEMP_RENT_DH.nroguia = correccion.nroguia and ##TEMP_RENT_DH.transaccion = ''S''			

			INSERT INTO ##TEMP_RENT_DH
					--(id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,valorprepaid ,fletetotalcorte ,fletetotalreal ,pesobruto ,pesocargable ,fletenetoreal ,tarifareal ,fletenetocorte ,tarifacorte ,fechacontable ,cca ,descuento ,manejo ,costosmanejo ,costootros ,utilidadmanejo ,comision ,overcomision ,diferenciatarifas ,cliente ,origen ,codigoempresas ,transaccion ,fechatransaccion ,cierre ,observaciones)
					SELECT b.* FROM ##TEMP_RENT_DH right join (				
						SELECT rentabilidad.* from rentabilidad inner join (
											SELECT id, row_number() over(partition by nroguia order by fechatransaccion desc) as contador, 
											nroguia, fechatransaccion, transaccion, comision, diferenciatarifas, manejo, descuento, reclamo, fechacontable
											FROM rentabilidad
											WHERE transaccion = ''C'' and fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''
										) c
										ON rentabilidad.id = c.id
										WHERE contador=1 												
					) b
					on ##TEMP_RENT_DH.id = b.id where  ##TEMP_RENT_DH.id is null and b.id is not null

			INSERT INTO ##TEMP_RENT_DH (id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,fletetotalreal, fletetotalcorte, pesobruto ,pesocargable ,
			   valorprepaid, fletenetoreal, tarifareal ,fletenetocorte ,tarifacorte ,fechacontable ,cca ,descuento , fechadescuento, reclamo, manejo , fechamanejo,
			   costosmanejo ,costootros ,utilidadmanejo ,comision , fechacomision, 
			   overcomision , fechaovercomision, overcomision2, fechaovercomision2, diferenciatarifas, fechadiferenciatarifas,
			   origen ,codigoempresas, transaccion)
			SELECT id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,0 as fletetotalreal, 0 as fletetotalcorte, 0 as pesobruto, 0 as pesocargable,
			   0 as valorprepaid, 0 AS fletenetoreal ,tarifareal ,0 as fletenetocorte ,tarifacorte ,fechacontable ,cca ,-1 * descuento ,fechadescuento, -1*reclamo, -1 * manejo , fechamanejo,
			   costosmanejo ,costootros ,utilidadmanejo , -1 * comision ,  fechacomision, 
			   overcomision , fechaovercomision, overcomision2, fechaovercomision2, -1 * diferenciatarifas, fechadiferenciatarifas,
			   origen ,codigoempresas, transaccion 
			   FROM rentabilidad WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' and (transaccion=''NC'' )


			SELECT ##TEMP_RENT_DH.id, ##TEMP_RENT_DH.nroguia, ##TEMP_RENT_DH.idaerolinea, ##TEMP_RENT_DH.cass, ##TEMP_RENT_DH.destino, ##TEMP_RENT_DH.fechaembarque, ##TEMP_RENT_DH.destino, ##TEMP_RENT_DH.prepaid, ##TEMP_RENT_DH.valorprepaid, 
					##TEMP_RENT_DH.fletetotalcorte, ##TEMP_RENT_DH.fletetotalreal, ##TEMP_RENT_DH.pesobruto, ##TEMP_RENT_DH.pesocargable, ##TEMP_RENT_DH.fletenetoreal, ##TEMP_RENT_DH.tarifareal, ##TEMP_RENT_DH.fletenetocorte, 
					##TEMP_RENT_DH.tarifacorte, ##TEMP_RENT_DH.fechacontable, ##TEMP_RENT_DH.cca, ##TEMP_RENT_DH.cargosaerolinea, ##TEMP_RENT_DH.costosmanejo, 
					##TEMP_RENT_DH.costootros, ##TEMP_RENT_DH.utilidadmanejo, ##TEMP_RENT_DH.comision, ##TEMP_RENT_DH.fechacomision, ##TEMP_RENT_DH.manejo, ##TEMP_RENT_DH.fechamanejo, ##TEMP_RENT_DH.reclamo, ##TEMP_RENT_DH.fechareclamo,##TEMP_RENT_DH.overcomision, ##TEMP_RENT_DH.fechaovercomision, ##TEMP_RENT_DH.diferenciatarifas, ##TEMP_RENT_DH.fechadiferenciatarifas,
					##TEMP_RENT_DH.overcomision2, ##TEMP_RENT_DH.fechaovercomision2, ##TEMP_RENT_DH.descuento, ##TEMP_RENT_DH.fechadescuento, ##TEMP_RENT_DH.TRANSACCION,
					ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, guias.detalles, mercancias.nombre, clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, guias.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, guias.seguridad as seguridadcorte, guias.awc, guias.cd1, guias.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, ##TEMP_RENT_DH.codigoempresas,
					totalapagar = case when ##TEMP_RENT_DH.prepaid = 1 then (fletenetoreal + isnull(guias.cargosaerolinea,0) + manejo) + round(((comision + descuento) * 0.02),2) - manejo - comision - descuento - round(((comision + descuento) * 0.12),2) else 0 end, 				  
				    totalacobrar = case when ##TEMP_RENT_DH.prepaid = 0 then comision + manejo + round(((comision + descuento) * 0.12),2) + descuento - round(((comision + descuento) * 0.02),2) else 0 end
					FROM ##TEMP_RENT_DH  LEFT JOIN GUIAS ON ##TEMP_RENT_DH.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id
					LEFT JOIN clientes on guias.codigo=clientes.codigo	
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN consignatarios on guicon.idconsignatarios = consignatarios.id 								
					WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC 

			DROP TABLE ##TEMP_RENT_DH
			'

		PRINT (@SQL_PRUEBA)
		EXEC (@SQL_PRUEBA)
		
		RETURN
		
	END


IF @Banderas = 'TODORENTABILIDADOVER'
	BEGIN
		declare @SQL_Over varchar(8000), @SQL_Over2 varchar(8000), @Empresa_Over varchar (50), @Aerolinea_Over varchar(50)

		if @CodigoEmpresas = ''
			set @Empresa_Over = '' 
		else
			set @Empresa_Over = 'AND rentabilidad.codigoempresas = ''' + @CodigoEmpresas + ''''
		
		if @IdAerolinea = ''
			set @Aerolinea_Over = '' 
		else
			set @Aerolinea_Over = 'AND idaerolinea = ''' + @IdAerolinea + ''''

		SET  @SQL_Over = 'SELECT rentabilidad.*
					INTO ##TEMP_RENT_DH FROM RENTABILIDAD  								
					WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa_Over	+	  
				  ' ' + @Aerolinea_Over + 		
			' and (transaccion=''S'' or transaccion=''A'' ) ORDER BY nroguia ASC 

			UPDATE ##TEMP_RENT_DH
			SET ##TEMP_RENT_DH.id = correccion.id,
			##TEMP_RENT_DH.fletenetoreal = correccion.fletenetoreal,
			##TEMP_RENT_DH.tarifareal = correccion.tarifareal,
			##TEMP_RENT_DH.cargosaerolinea = correccion.cargosaerolinea,
			##TEMP_RENT_DH.comision = correccion.comision,
			##TEMP_RENT_DH.fechacontable = correccion.fechacontable,
			##TEMP_RENT_DH.diferenciatarifas = correccion.diferenciatarifas,
			##TEMP_RENT_DH.manejo = correccion.manejo,
			##TEMP_RENT_DH.descuento = correccion.descuento,
			##TEMP_RENT_DH.reclamo = correccion.reclamo,
			##TEMP_RENT_DH.overcomision = correccion.overcomision,
			##TEMP_RENT_DH.overcomision2 = correccion.overcomision2,
			##TEMP_RENT_DH.transaccion = correccion.transaccion,
			##TEMP_RENT_DH.fechacomision= correccion.fechacomision,
			##TEMP_RENT_DH.fechadiferenciatarifas= correccion.fechadiferenciatarifas,
			##TEMP_RENT_DH.fechamanejo= correccion.fechamanejo,
			##TEMP_RENT_DH.fechadescuento= correccion.fechadescuento,
			##TEMP_RENT_DH.fechareclamo= correccion.fechareclamo,
			##TEMP_RENT_DH.fechaovercomision= correccion.fechaovercomision,
			##TEMP_RENT_DH.fechaovercomision2= correccion.fechaovercomision2
			FROM ##TEMP_RENT_DH INNER JOIN (
										SELECT * from (
										SELECT row_number() over(partition by nroguia order by fechatransaccion desc) as contador, 
										id, nroguia, fechatransaccion, transaccion, fletenetoreal, tarifareal, cargosaerolinea, comision, diferenciatarifas, manejo, descuento, reclamo, fechacontable, overcomision, overcomision2, 
										fechacomision, fechadiferenciatarifas, fechamanejo, fechadescuento, fechareclamo, fechaovercomision, fechaovercomision2
										FROM rentabilidad
										WHERE transaccion = ''C'') c
										WHERE contador=1 
										) correccion										
			on ##TEMP_RENT_DH.nroguia = correccion.nroguia and ##TEMP_RENT_DH.transaccion = ''S''			

			UPDATE ##TEMP_RENT_DH
			SET ##TEMP_RENT_DH.id = correccion.id,
--			##TEMP_RENT_DH.fletenetoreal = correccion.fletenetoreal,
--			##TEMP_RENT_DH.tarifareal = correccion.tarifareal,
--			##TEMP_RENT_DH.cargosaerolinea = correccion.cargosaerolinea,
--			##TEMP_RENT_DH.comision = correccion.comision,
--			##TEMP_RENT_DH.fechacontable = correccion.fechacontable,
--			##TEMP_RENT_DH.diferenciatarifas = correccion.diferenciatarifas,
--			##TEMP_RENT_DH.manejo = correccion.manejo,
--			##TEMP_RENT_DH.descuento = correccion.descuento,
--			##TEMP_RENT_DH.reclamo = correccion.reclamo,
			##TEMP_RENT_DH.overcomision = correccion.overcomision,
			##TEMP_RENT_DH.overcomision2 = correccion.overcomision2,
			##TEMP_RENT_DH.transaccion = correccion.transaccion,
--			##TEMP_RENT_DH.fechacomision= correccion.fechacomision
			##TEMP_RENT_DH.fechaovercomision= correccion.fechaovercomision,
			##TEMP_RENT_DH.fechaovercomision2= correccion.fechaovercomision2
			FROM ##TEMP_RENT_DH INNER JOIN (
										SELECT * from (
										SELECT row_number() over(partition by nroguia order by fechatransaccion desc) as contador, 
										id, nroguia, fechatransaccion, transaccion, fletenetoreal, tarifareal, cargosaerolinea, comision, diferenciatarifas, manejo, descuento, reclamo, fechacontable, overcomision, overcomision2, fechacomision, fechaovercomision, fechaovercomision2
										FROM rentabilidad
										WHERE transaccion = ''COC'') c
										WHERE contador=1 
										) correccion										
			on ##TEMP_RENT_DH.nroguia = correccion.nroguia and ##TEMP_RENT_DH.transaccion = ''C'' '

	set @SQL_Over2 = 'UPDATE ##TEMP_RENT_DH
			SET ##TEMP_RENT_DH.id = correccion.id,
--			##TEMP_RENT_DH.fletenetoreal = correccion.fletenetoreal,
--			##TEMP_RENT_DH.tarifareal = correccion.tarifareal,
--			##TEMP_RENT_DH.cargosaerolinea = correccion.cargosaerolinea,
--			##TEMP_RENT_DH.comision = correccion.comision,
--			##TEMP_RENT_DH.fechacontable = correccion.fechacontable,
--			##TEMP_RENT_DH.diferenciatarifas = correccion.diferenciatarifas,
--			##TEMP_RENT_DH.manejo = correccion.manejo,
--			##TEMP_RENT_DH.descuento = correccion.descuento,
--			##TEMP_RENT_DH.reclamo = correccion.reclamo,
			##TEMP_RENT_DH.overcomision = correccion.overcomision,
			##TEMP_RENT_DH.overcomision2 = correccion.overcomision2,
			##TEMP_RENT_DH.transaccion = correccion.transaccion,
--			##TEMP_RENT_DH.fechacomision= correccion.fechacomision,
			##TEMP_RENT_DH.fechaovercomision= correccion.fechaovercomision,
			##TEMP_RENT_DH.fechaovercomision2= correccion.fechaovercomision2
			FROM ##TEMP_RENT_DH INNER JOIN (
										SELECT * from (
										SELECT row_number() over(partition by nroguia order by fechatransaccion desc) as contador, 
										id, nroguia, fechatransaccion, transaccion, fletenetoreal, tarifareal, cargosaerolinea, comision, diferenciatarifas, manejo, descuento, reclamo, fechacontable, overcomision, overcomision2, fechacomision, fechaovercomision, fechaovercomision2
										FROM rentabilidad
										WHERE transaccion = ''COC'') c
										WHERE contador=1 
										) correccion										
			on ##TEMP_RENT_DH.nroguia = correccion.nroguia and ##TEMP_RENT_DH.transaccion = ''S''

			INSERT INTO ##TEMP_RENT_DH
					--(id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,valorprepaid ,fletetotalcorte ,fletetotalreal ,pesobruto ,pesocargable ,fletenetoreal ,tarifareal ,fletenetocorte ,tarifacorte ,fechacontable ,cca ,descuento ,manejo ,costosmanejo ,costootros ,utilidadmanejo ,comision ,overcomision ,diferenciatarifas ,cliente ,origen ,codigoempresas ,transaccion ,fechatransaccion ,cierre ,observaciones)
					SELECT b.* FROM ##TEMP_RENT_DH right join (				
						SELECT rentabilidad.* from rentabilidad inner join (
											SELECT id, row_number() over(partition by nroguia order by fechatransaccion desc) as contador, 
											nroguia, fechatransaccion, transaccion, comision, diferenciatarifas, manejo, descuento, reclamo, fechacontable, fechaovercomision
											FROM rentabilidad
											WHERE transaccion = ''COC'' and fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''
										) c
										ON rentabilidad.id = c.id
										WHERE contador=1 												
					) b
					on ##TEMP_RENT_DH.id = b.id where  ##TEMP_RENT_DH.id is null and b.id is not null

			INSERT INTO ##TEMP_RENT_DH (id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,fletetotalreal, fletetotalcorte, pesobruto ,pesocargable ,
			   valorprepaid, fletenetoreal, tarifareal ,fletenetocorte ,tarifacorte ,fechacontable ,cca ,descuento , fechadescuento, reclamo, manejo , fechamanejo,
			   costosmanejo ,costootros ,utilidadmanejo ,comision , fechacomision, 
			   overcomision , fechaovercomision, overcomision2, fechaovercomision2, diferenciatarifas, fechadiferenciatarifas,
			   origen ,codigoempresas, transaccion)
			SELECT id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,0 as fletetotalreal, 0 as fletetotalcorte, 0 as pesobruto, 0 as pesocargable,
			   0 as valorprepaid, 0 AS fletenetoreal ,tarifareal ,0 as fletenetocorte ,tarifacorte ,fechacontable ,cca ,-1 * descuento ,fechadescuento, -1*reclamo, -1 * manejo , fechamanejo,
			   costosmanejo ,costootros ,utilidadmanejo , -1 * comision ,  fechacomision, 
			   overcomision , fechaovercomision, overcomision2, fechaovercomision2, -1 * diferenciatarifas, fechadiferenciatarifas,
			   origen ,codigoempresas, transaccion 
			   FROM rentabilidad WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa_Over	+	  
				  ' ' + @Aerolinea_Over + 		
			' and (transaccion=''NCC'' )


			SELECT ##TEMP_RENT_DH.id, ##TEMP_RENT_DH.nroguia, ##TEMP_RENT_DH.idaerolinea, ##TEMP_RENT_DH.cass, ##TEMP_RENT_DH.destino, ##TEMP_RENT_DH.fechaembarque, ##TEMP_RENT_DH.destino, ##TEMP_RENT_DH.prepaid, ##TEMP_RENT_DH.valorprepaid, 
					##TEMP_RENT_DH.fletetotalcorte, ##TEMP_RENT_DH.fletetotalreal, ##TEMP_RENT_DH.pesobruto, ##TEMP_RENT_DH.pesocargable, ##TEMP_RENT_DH.fletenetoreal, ##TEMP_RENT_DH.tarifareal, ##TEMP_RENT_DH.fletenetocorte, 
					##TEMP_RENT_DH.tarifacorte, ##TEMP_RENT_DH.fechacontable, ##TEMP_RENT_DH.cca, ##TEMP_RENT_DH.cargosaerolinea, ##TEMP_RENT_DH.costosmanejo, 
					##TEMP_RENT_DH.costootros, ##TEMP_RENT_DH.utilidadmanejo, ##TEMP_RENT_DH.comision, ##TEMP_RENT_DH.fechacomision, ##TEMP_RENT_DH.manejo, ##TEMP_RENT_DH.fechamanejo, ##TEMP_RENT_DH.reclamo, ##TEMP_RENT_DH.fechareclamo,##TEMP_RENT_DH.overcomision, ##TEMP_RENT_DH.fechaovercomision, ##TEMP_RENT_DH.diferenciatarifas, ##TEMP_RENT_DH.fechadiferenciatarifas,
					##TEMP_RENT_DH.overcomision2, ##TEMP_RENT_DH.fechaovercomision2, ##TEMP_RENT_DH.descuento, ##TEMP_RENT_DH.fechadescuento, ##TEMP_RENT_DH.TRANSACCION,
					ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, guias.detalles, mercancias.nombre, clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, guias.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, guias.seguridad as seguridadcorte, guias.awc, guias.cd1, guias.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc
					FROM ##TEMP_RENT_DH  LEFT JOIN GUIAS ON ##TEMP_RENT_DH.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id
					LEFT JOIN clientes on guias.codigo=clientes.codigo	
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN consignatarios on guicon.idconsignatarios = consignatarios.id 								
					WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa_Over	+	  
				  ' ' + @Aerolinea_Over + 		
			' ORDER BY nroguia ASC 

			DROP TABLE ##TEMP_RENT_DH
			'

		PRINT (@SQL_Over + @SQL_Over2)
		EXEC (@SQL_Over + @SQL_Over2)
		
		RETURN
		
	END

	IF @Banderas = 'CORRECCIONES'
	BEGIN
		SELECT id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,valorprepaid
			  ,fletetotalcorte ,fletetotalreal ,pesobruto ,pesocargable ,fletenetoreal ,tarifareal
			  ,fletenetocorte  ,tarifacorte    ,fechacontable ,cca ,isnull(reclamo,0) as reclamo, descuento ,manejo ,costosmanejo
			  ,costootros ,utilidadmanejo ,comision ,overcomision ,diferenciatarifas ,cliente
			  ,origen ,codigoempresas ,transaccion ,fechatransaccion ,observaciones, cargosaerolinea, pagar, cobrar, textopagarcobrar, cierre
		FROM rentabilidad WHERE  LTRIM(RTRIM(transaccion)) != 'S' AND (fechacontable>=@FechaDesde and fechacontable <=@FechaHasta ) or (fechacontable = '12/31/2099')
		RETURN	
	END

	IF @Banderas = 'CORRECCIONESOCGUIA'
	BEGIN
		SELECT id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,valorprepaid
			  ,fletetotalcorte ,fletetotalreal ,pesobruto ,pesocargable ,fletenetoreal ,tarifareal
			  ,fletenetocorte  ,tarifacorte    ,fechacontable ,cca ,isnull(reclamo,0) as reclamo, descuento ,manejo ,costosmanejo
			  ,costootros ,utilidadmanejo ,comision ,overcomision ,diferenciatarifas ,cliente
			  ,origen ,codigoempresas ,transaccion ,fechatransaccion ,observaciones, cargosaerolinea, cierre, isnull(pagar,0.00) as pagar, isnull(cobrar,0.00) as cobrar, isnull(textopagarcobrar,0) as textopagarcobrar
			  ,tarifafsc, tarifassc, combustible, seguridad, fechaover
			FROM rentabilidad WHERE nroguia = @nroguia and (transaccion='COC' or transaccion = 'NDOC' or transaccion = 'NCOC' or transaccion='AOC')
		
			RETURN
	END

	IF @Banderas = 'CORRECCIONESOCTODO'
	BEGIN
		SELECT id ,nroguia ,idaerolinea ,cass ,destino ,fechaembarque ,prepaid ,valorprepaid
			  ,fletetotalcorte ,fletetotalreal ,pesobruto ,pesocargable ,fletenetoreal ,tarifareal
			  ,fletenetocorte  ,tarifacorte    ,fechacontable ,cca ,isnull(reclamo,0) as reclamo, descuento ,manejo ,costosmanejo
			  ,costootros ,utilidadmanejo ,comision ,overcomision ,diferenciatarifas ,cliente
			  ,origen ,codigoempresas ,transaccion ,fechatransaccion ,observaciones, cargosaerolinea, cierre, isnull(pagar,0.00) as pagar, isnull(cobrar,0.00) as cobrar, isnull(textopagarcobrar,0) as textopagarcobrar
			  ,tarifafsc, tarifassc, combustible, seguridad, fechaover
			FROM rentabilidad WHERE (fechaover>=@FechaDesde and fechaover <=@FechaHasta ) and (transaccion='COC' or transaccion = 'NDOC' or transaccion = 'NCOC' or transaccion='AOC') or (fechaover = '12/31/2099')
		
			RETURN
	END
	IF @Banderas = 'GUIA'
	BEGIN
		SELECT nroguia, cierre FROM rentabilidad WHERE nroguia = @nroguia
		RETURN
	END	

	IF @Banderas = 'CERRAR'
	BEGIN

			
		declare @SQLCerrar varchar(5000), @EmpresaCerrar varchar (50), @AerolineaCerrar varchar(50)

		if @CodigoEmpresas = ''
			set @EmpresaCerrar = '' 
		else
			set @EmpresaCerrar = 'AND codigoempresas = ''' + @CodigoEmpresas + ''''
		
		if @IdAerolinea = ''
			set @AerolineaCerrar = '' 
		else
			set @AerolineaCerrar = 'AND idaerolinea = ''' + @IdAerolinea + ''''

		SET @SQLCerrar = 'UPDATE rentabilidad SET cierre = ''CERRADA'' 
					WHERE fechacontable>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechacontable <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @EmpresaCerrar	+	  
				  ' ' + @AerolineaCerrar  
					
		print @SQLCerrar		
		exec ( @SQLCerrar)
		RETURN
	END

	IF @Banderas = 'GUIASFECHAEMBARQUE'
	BEGIN
		
		declare @SQL_Guias varchar(5000), @Empresa_Guias varchar (50), @Aerolinea_Guias varchar(50)

		if @CodigoEmpresas = ''
			set @Empresa_Guias = '' 
		else
			set @Empresa_Guias = 'AND rentabilidad.codigoempresas = ''' + @CodigoEmpresas + ''''
		
		if @IdAerolinea = ''
			set @Aerolinea_Guias = '' 
		else
			set @Aerolinea_Guias = 'AND idaerolinea = ''' + @IdAerolinea + ''''

		SET  @SQL_Guias = 'SELECT rentabilidad.*, ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, guias.detalles, mercancias.nombre, clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, guias.tarifafsc, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible, guias.seguridad, guias.awc, guias.cd1, guias.tarifassc, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc
					FROM RENTABILIDAD  LEFT JOIN GUIAS ON RENTABILIDAD.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id
					LEFT JOIN clientes on guias.codigo=clientes.codigo	
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia 
					LEFT JOIN consignatarios on guicon.idconsignatarios = consignatarios.id 								
					WHERE rentabilidad.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and rentabilidad.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa_Guias	+	  
				  ' ' + @Aerolinea_Guias + 		
			' and cntetiq=1 ORDER BY nroguia ASC '

		EXEC (@SQL_Guias)
		
		print @SQL_Guias

		RETURN
		
	END

	IF @Banderas = 'RENTABILIDADDIFERENCIASCAS'
	BEGIN

		--ELIMINAR TODAS LAS GUIAS QUE NO PERTENEZCAN AL STOCK DE G&G ANTES DE HACER EL CHEQUEO
		--PACAS 18/07/2014
		IF getdate() <= '08/15/2014'
		BEGIN
			DELETE FROM cas WHERE cas.nroguia IN (
			SELECT substring(cas.nroguia,1,11) FROM cas LEFT JOIN stockawb on cas.nroguia = stockawb.nroguia
			WHERE (substring(cas.nroguia,1,3) = '074' or substring(cas.nroguia,1,3) = '172') and stockawb.nroguia is null )
		END

		declare @SQL_DIFERENCIA_CAS varchar(8000)

		if @CodigoEmpresas = ''
			set @Empresa = '' 
		else
			set @Empresa = 'AND liquidacionaerolineas.codigoempresas = ''' + @CodigoEmpresas + ''''
		
		if @IdAerolinea = ''
			set @Aerolinea = '' 
		else
			set @Aerolinea = 'AND idaerolinea = ''' + @IdAerolinea + ''''
			--drop table  #TEMP_RENT_CAS
		SET  @SQL_DIFERENCIA_CAS = 'SELECT liquidacionaerolineas.*
					INTO #TEMP_RENT_CAS FROM liquidacionaerolineas  								
					WHERE fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' and (transaccion=''S'') ORDER BY nroguia ASC '
		--CREATE INDEX temp_rent_cas ON  #TEMP_RENT_CAS (nroguia)
		--exec (@SQL_DIFERENCIA_CAS)
		----select * from #TEMP_RENT_CAS
		--return

		IF @FechaHasta <= '01/15/2015'
		BEGIN
	
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, 
					consignatario as DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, guias.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, #TEMP_RENT_CAS.combustible, guias.seguridad as seguridadcorte, #TEMP_RENT_CAS.seguridad, guias.awc, guias.cd1, guias.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((comision + descuento) * 0.02),2) - manejo - comision - descuento - round(((comision + descuento) * 0.12),2) else 0 end, 				  
				    totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then comision + manejo + round(((comision + descuento) * 0.12),2) + descuento - round(((comision + descuento) * 0.02),2) else 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, mercancias.nombre as producto,	
					guias.cajasvoladas as cajasredondeadas,  #TEMP_RENT_CAS.cajasvoladas,	#TEMP_RENT_CAS.empresa, 
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.region, #TEMP_RENT_CAS.retencioniva,
					ciudades.nombre as ciudaddestino,												
					paises.nombre as paisdestino,
					0.0 as tarifaconvenio,
					0.0 as fletenetoconvenio,
					0.0 as biaconvenio,
					0.0 as feaconvenio,
					0.0 as fletetotalconvenio,
					#TEMP_RENT_CAS.tipoVuelo as tipoVuelo,
					#TEMP_RENT_CAS.codigoContable as codigoContable,
					#TEMP_RENT_CAS.idCliente as idCliente,
					#TEMP_RENT_CAS.idMercancia as idMercancia
					INTO ##TEMP_CAS
					FROM #TEMP_RENT_CAS  INNER JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					INNER JOIN mercancias on guias.idmercancia = mercancias.id						
					INNER JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1				
					left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino	
					left join paises on ciudades.idpaises=paises.id											
					WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END
--DROP TABLE ##TEMP_CAS
		IF @FechaHasta >= '01/16/2015' and @FechaHasta <= '05/31/2016'
		BEGIN
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, 
					consignatario as DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad as seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) else 0 end, 				  
				    --totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  else 0 end, cierre,
					totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) else 0 end, 				  
				    totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(isnull(retencioniva,0), 2)  else 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, mercancias.nombre as producto,	
					guias.cajasvoladas as cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
					ciudades.nombre as ciudaddestino,												
					paises.nombre as paisdestino,
					0.0 as tarifaconvenio,
					0.0 as fletenetoconvenio,
					0.0 as biaconvenio,
					0.0 as feaconvenio,
					0.0 as fletetotalconvenio,
					#TEMP_RENT_CAS.tipoVuelo as tipoVuelo,
					#TEMP_RENT_CAS.codigoContable as codigoContable,
					#TEMP_RENT_CAS.idCliente as idCliente,
					#TEMP_RENT_CAS.idMercancia as idMercancia
					INTO ##TEMP_CAS
					FROM #TEMP_RENT_CAS  LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
					--left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join paises on ciudades.idpaises=paises.id												
					WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
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
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, 
					consignatario as DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad as seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.14) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) else 0 end, 				  
				    --totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.14) * aerolineas.retencion ,2)  else 0 end, cierre,
					totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) else 0 end, 				  
				    totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.14),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(isnull(retencioniva,0), 2)  else 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, 
					producto = case when isnull(producto,'''')='''' then mercancias.nombre  else #TEMP_RENT_CAS.producto end,	
					guias.cajasvoladas as cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
					ciudades.nombre as ciudaddestino,												
					paises.nombre as paisdestino,
					isnull(#TEMP_RENT_CAS.tarifaconvenio,0) as tarifaconvenio,
					isnull(#TEMP_RENT_CAS.fletenetoconvenio,0) as fletenetoconvenio,
					isnull(#TEMP_RENT_CAS.biaconvenio,0) as biaconvenio,
					isnull(#TEMP_RENT_CAS.feaconvenio,0) as feaconvenio,
					isnull(#TEMP_RENT_CAS.fletetotalconvenio,0) as fletetotalconvenio,
					#TEMP_RENT_CAS.tipoVuelo as tipoVuelo,
					#TEMP_RENT_CAS.codigoContable as codigoContable,
					#TEMP_RENT_CAS.idCliente as idCliente,
					#TEMP_RENT_CAS.idMercancia as idMercancia
					INTO ##TEMP_CAS
					FROM #TEMP_RENT_CAS  LEFT JOIN GUIAS ON #TEMP_RENT_CAS.nroguia = guias.nroguia
					LEFT JOIN mercancias on guias.idmercancia = mercancias.id			
					LEFT JOIN guicon on guias.nroguia = guicon.nroguia and cntetiq=1
					LEFT JOIN aerolineas on #TEMP_RENT_CAS.idaerolinea = aerolineas.id	
					--left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join paises on ciudades.idpaises=paises.id												
					WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END
		/*
		IF @FechaHasta >= '06/01/2017' and @FechaHasta < '05/01/2020'
		BEGIN
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, 
					consignatario as DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad as seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) else 0 end, 				  
				    --totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  else 0 end, cierre,
					totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) else 0 end, 				  
				    totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.02),2) - round(isnull(retencioniva,0), 2)  else 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, 
					producto = case when isnull(producto,'''')='''' then mercancias.nombre  else #TEMP_RENT_CAS.producto end,	
					guias.cajasvoladas as cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
					ciudades.nombre as ciudaddestino,												
					paises.nombre as paisdestino,
					isnull(#TEMP_RENT_CAS.tarifaconvenio,0) as tarifaconvenio,
					isnull(#TEMP_RENT_CAS.fletenetoconvenio,0) as fletenetoconvenio,
					isnull(#TEMP_RENT_CAS.biaconvenio,0) as biaconvenio,
					isnull(#TEMP_RENT_CAS.feaconvenio,0) as feaconvenio,
					isnull(#TEMP_RENT_CAS.fletetotalconvenio,0) as fletetotalconvenio,
					#TEMP_RENT_CAS.tipoVuelo as tipoVuelo,
					#TEMP_RENT_CAS.codigoContable as codigoContable,
					#TEMP_RENT_CAS.idCliente as idCliente,
					#TEMP_RENT_CAS.idMercancia as idMercancia,
					#TEMP_RENT_CAS.maa as maa_alianza,
					#TEMP_RENT_CAS.paa as paa,
					#TEMP_RENT_CAS.tra as tra,
					#TEMP_RENT_CAS.bfa as bfa,
					#TEMP_RENT_CAS.acuerdoscomerciales as acuerdoscomerciales,
					#TEMP_RENT_CAS.descuentocliente as descuentocliente, #TEMP_RENT_CAS.comisioncliente, #TEMP_RENT_CAS.overcomisioncliente, 
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
					--left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join paises on ciudades.idpaises=paises.id												
					WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END
		*/
		IF @FechaHasta >= '06/01/2017' and @FechaHasta < '04/01/2024'
		BEGIN
			SET @SQL_DIFERENCIA_CAS = @SQL_DIFERENCIA_CAS + 'SELECT #TEMP_RENT_CAS.id, #TEMP_RENT_CAS.nroguia, #TEMP_RENT_CAS.idaerolinea, #TEMP_RENT_CAS.origen, #TEMP_RENT_CAS.destino, #TEMP_RENT_CAS.cass, #TEMP_RENT_CAS.fechaembarque, #TEMP_RENT_CAS.prepaid, #TEMP_RENT_CAS.valorprepaid, 
					#TEMP_RENT_CAS.fletetotalcorte, #TEMP_RENT_CAS.fletetotalreal, #TEMP_RENT_CAS.pesobruto, #TEMP_RENT_CAS.pesocargable, #TEMP_RENT_CAS.fletenetoreal, #TEMP_RENT_CAS.tarifareal, #TEMP_RENT_CAS.fletenetocorte, 
					#TEMP_RENT_CAS.tarifacorte, #TEMP_RENT_CAS.fechacontable, #TEMP_RENT_CAS.cca, #TEMP_RENT_CAS.cargosaerolinea, #TEMP_RENT_CAS.costosmanejo, 
					#TEMP_RENT_CAS.costootros, #TEMP_RENT_CAS.utilidadmanejo, #TEMP_RENT_CAS.comision, #TEMP_RENT_CAS.fechacomision, #TEMP_RENT_CAS.manejo, #TEMP_RENT_CAS.fechamanejo, #TEMP_RENT_CAS.reclamo, #TEMP_RENT_CAS.fechareclamo,#TEMP_RENT_CAS.overcomision, #TEMP_RENT_CAS.fechaovercomision, #TEMP_RENT_CAS.diferenciatarifas, #TEMP_RENT_CAS.fechadiferenciatarifas,
					#TEMP_RENT_CAS.overcomision2, #TEMP_RENT_CAS.fechaovercomision2, #TEMP_RENT_CAS.descuento, #TEMP_RENT_CAS.fechadescuento, #TEMP_RENT_CAS.TRANSACCION,
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, 
					consignatario as DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad as seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.0275),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) else 0 end, 				  
				    --totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12) * aerolineas.retencion ,2)  else 0 end, cierre,
					totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) else 0 end, 				  
				    totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.12),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(isnull(retencioniva,0), 2)  else 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, 
					producto = case when isnull(producto,'''')='''' then mercancias.nombre  else #TEMP_RENT_CAS.producto end,	
					guias.cajasvoladas as cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
					ciudades.nombre as ciudaddestino,												
					paises.nombre as paisdestino,
					isnull(#TEMP_RENT_CAS.tarifaconvenio,0) as tarifaconvenio,
					isnull(#TEMP_RENT_CAS.fletenetoconvenio,0) as fletenetoconvenio,
					isnull(#TEMP_RENT_CAS.biaconvenio,0) as biaconvenio,
					isnull(#TEMP_RENT_CAS.feaconvenio,0) as feaconvenio,
					isnull(#TEMP_RENT_CAS.fletetotalconvenio,0) as fletetotalconvenio,
					#TEMP_RENT_CAS.tipoVuelo as tipoVuelo,
					#TEMP_RENT_CAS.codigoContable as codigoContable,
					#TEMP_RENT_CAS.idCliente as idCliente,
					#TEMP_RENT_CAS.idMercancia as idMercancia,
					#TEMP_RENT_CAS.maa as maa_alianza,
					#TEMP_RENT_CAS.paa as paa,
					#TEMP_RENT_CAS.tra as tra,
					#TEMP_RENT_CAS.bfa as bfa,
					#TEMP_RENT_CAS.acuerdoscomerciales as acuerdoscomerciales,
					#TEMP_RENT_CAS.descuentocliente as descuentocliente, #TEMP_RENT_CAS.comisioncliente, #TEMP_RENT_CAS.overcomisioncliente, 
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
					left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join paises on ciudades.idpaises=paises.id												
					--WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
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
					--ltrim(rtrim(consignatarios.nombre1)) + '' '' + ltrim(rtrim(consignatarios.nombre2))  as DueñoCarga, 
					consignatario as DueñoCarga,
					guias.detalles, mercancias.nombre, cliente, --clientes.nombres,
					guias.transporte, guias.handling, guias.otroscargosagencia, guias.rp, guias.gye, guias.bodegaje, guias.documentos, guias.awa, guias.cargofitos, guias.tarifacf, #TEMP_RENT_CAS.tarifafsc as tarifafsccorte, guias.etiquetas,
					guias.cargosaerolinea as duecarrier, guias.combustible as combustiblecorte, #TEMP_RENT_CAS.combustible, #TEMP_RENT_CAS.seguridad, guias.seguridad as seguridadcorte, guias.awc, guias.cd1, #TEMP_RENT_CAS.tarifassc as tarifassccorte, guias.maa, guias.db, guias.mv, guias.mu,
					guias.dpf, guias.cc, #TEMP_RENT_CAS.codigoempresas,
					--totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.0275),2) + round(((#TEMP_RENT_CAS.comision + descuento) * 0.15) * aerolineas.retencion ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) else 0 end, 				  
				    --totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(((#TEMP_RENT_CAS.comision + descuento) * 0.15) * aerolineas.retencion ,2)  else 0 end, cierre,
					totalapagar = case when #TEMP_RENT_CAS.prepaid = 1 then (fletenetoreal + isnull(#TEMP_RENT_CAS.cargosaerolinea,0) + manejo) + round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) + round(isnull(retencioniva,0) ,2)  - manejo - #TEMP_RENT_CAS.comision - descuento - round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) else 0 end, 				  
				    totalacobrar = case when #TEMP_RENT_CAS.prepaid = 0 then #TEMP_RENT_CAS.comision + manejo + round(((#TEMP_RENT_CAS.comision + descuento) * 0.15),2) + descuento - round(((#TEMP_RENT_CAS.comision + descuento) * retencionfuente),2) - round(isnull(retencioniva,0), 2)  else 0 end, cierre,
					consignatario, #TEMP_RENT_CAS.observaciones, 
					producto = case when isnull(producto,'''')='''' then mercancias.nombre  else #TEMP_RENT_CAS.producto end,	
					guias.cajasvoladas as cajasredondeadas,  #TEMP_RENT_CAS.empresa,
					#TEMP_RENT_CAS.urn, #TEMP_RENT_CAS.cajasvoladas, #TEMP_RENT_CAS.region,	#TEMP_RENT_CAS.retencioniva,
					ciudades.nombre as ciudaddestino,												
					paises.nombre as paisdestino,
					isnull(#TEMP_RENT_CAS.tarifaconvenio,0) as tarifaconvenio,
					isnull(#TEMP_RENT_CAS.fletenetoconvenio,0) as fletenetoconvenio,
					isnull(#TEMP_RENT_CAS.biaconvenio,0) as biaconvenio,
					isnull(#TEMP_RENT_CAS.feaconvenio,0) as feaconvenio,
					isnull(#TEMP_RENT_CAS.fletetotalconvenio,0) as fletetotalconvenio,
					#TEMP_RENT_CAS.tipoVuelo as tipoVuelo,
					#TEMP_RENT_CAS.codigoContable as codigoContable,
					#TEMP_RENT_CAS.idCliente as idCliente,
					#TEMP_RENT_CAS.idMercancia as idMercancia,
					#TEMP_RENT_CAS.maa as maa_alianza,
					#TEMP_RENT_CAS.paa as paa,
					#TEMP_RENT_CAS.tra as tra,
					#TEMP_RENT_CAS.bfa as bfa,
					#TEMP_RENT_CAS.acuerdoscomerciales as acuerdoscomerciales,
					#TEMP_RENT_CAS.descuentocliente as descuentocliente, #TEMP_RENT_CAS.comisioncliente, #TEMP_RENT_CAS.overcomisioncliente, 
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
					left join ciudades on ciudades.codigociudad=#TEMP_RENT_CAS.destino
					left join paises on ciudades.idpaises=paises.id												
					--WHERE #TEMP_RENT_CAS.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and #TEMP_RENT_CAS.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' ORDER BY nroguia ASC '
		END

		
			EXEC (@SQL_DIFERENCIA_CAS)
				print getdate()
			--print @SQL_DIFERENCIA_CAS
			--return
	--DROP TABLE ##TEMP_cas		
			
			print 'PAso el Query string'

---- Find an existing index named IX_ProductVendor_VendorID and delete it if found. 
--IF EXISTS (SELECT name FROM sys.indexes
--            WHERE name = N'IX_temp_cass_fechaembarque') 
--    DROP INDEX IX_temp_cass_fechaembarque ON ##TEMP_CAS; 
--GO
---- Create a nonclustered index called IX_ProductVendor_VendorID 
---- on the Purchasing.ProductVendor table using the BusinessEntityID column. 
--CREATE NONCLUSTERED INDEX IX_temp_cass_fechaembarque 
--    ON ##TEMP_CAS(fechaembarque); 


		select convert(varchar(13), case when a.nroguia is null then b.id else a.id end) as id,  
        --convert(varchar(13), a.id ) as id,  				
		1 as status, convert(bit,0) as seleccionar, case when a.idaerolinea is null then b.idaerolinea else a.idaerolinea end as idaerolinea, isnull(a.prepaid,'') as prepaid, a.nroguia, b.nroguia as nroguiaCASS, 
		a.origen, a.destino, a.fechaembarque,		
		isnull(a.pesobruto,0) as pesobruto, isnull(a.pesocargable,0) as pesocargable, isnull(a.fletenetoreal,0) as fletenetoreal, isnull(a.tarifareal,0) as tarifareal, isnull(a.tarifacorte,0) as tarifacorte, 
		isnull(b.wgtchargeprepaid,0) as wgtchargeprepaid, isnull(b.wgtchargecollect,0) as wgtchargecollect,
	    convert(decimal(9,3),isnull(a.comision,0)) as comision, 
		convert(decimal(10,3),isnull(b.comission,0)) as comisioncass, 
		convert(decimal(9,3),isnull(a.manejo,0)) as manejo, 
		convert(decimal(10,3),isnull(b.dueagent,0)) as manejocass,
		convert(decimal(9,3),isnull(a.descuento,0)) as descuento, 
		convert(decimal(10,3),isnull(b.discount,0)) as descuentocass,   
		convert(decimal(9,3),isnull(a.diferenciatarifas,0)) as diferenciatarifas,
		convert(decimal(9,3),isnull(a.cargosaerolinea,0)) as cargosaerolinea, 
		convert(decimal(10,3), isnull(b.duecarrier,0)) as cargosaerolineacass, 
        isnull(totalapagar,0) as totalapagar, isnull(totalacobrar,0) as totalacobrar, isnull(payable,0) as payable, case when isnull(a.prepaid,'') = 1 then  isnull(payable,0) - isnull(totalapagar,0) else isnull(payable,0) - isnull(totalacobrar,0) end as diferenciapagarcobrar , cierre,
		observaciones, consignatario, cliente, cass, fechareportada, 		
		tarifacass = isnull (case when prepaid=1 and pesocargable>0 then wgtchargeprepaid / pesocargable when prepaid=0 and pesocargable>0 then wgtchargecollect / pesocargable else 0 end, 0),
		combustiblecorte, combustible, seguridad, 
		prepaidcass = convert(bit, isnull( case when (wgtchargeprepaid >0 and wgtchargecollect = 0) then 1 else 0 end ,0) ),isnull(urn,'') as urn, 
		producto,
		dueñocarga, handling, awa, documentos, transporte, etiquetas, cargofitos as fitos, tarifacf as certificadosorigen, otroscargosagencia, rp, tarifafsccorte, tarifassccorte, 
		periododesde, periodohasta, cajasredondeadas, cajasvoladas, empresa, b.taxcom as taxcomCASS, b.retencionfuente as retencionfuenteCASS, fletetotalcorte, region, 
		ciudaddestino, retencioniva, paisdestino,
		tarifaconvenio,
		fletenetoconvenio,
		biaconvenio,
		feaconvenio,
		fletetotalconvenio,
		tipoVuelo, -- = (select tipoVuelo from daesalianza.alliance.dbo.guias where nroguia=a.nroguia)
		------- rentabilidad bi
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
		from
			( select id, idaerolinea, nroguia, origen, destino, fechaembarque, isnull(pesobruto,0) as pesobruto, isnull(pesocargable,0) as pesocargable, isnull(fletenetoreal,0) as fletenetoreal, isnull(tarifareal,0) as tarifareal, isnull(tarifacorte,0) as tarifacorte,
			  convert(decimal(9,3),isnull(comision,0)) as comision, 
			  convert(decimal(9,3),isnull(manejo,0)) as manejo, 
			  convert(decimal(9,3),isnull(descuento,0)) as descuento, prepaid, 
			  convert(decimal(9,3),isnull(cargosaerolinea,0)) as cargosaerolinea, 
			  convert(decimal(9,3),isnull(totalapagar,0)) as totalapagar, 
			  -1 * convert(decimal(9,3),isnull(totalacobrar,0)) as totalacobrar, cierre, 
			  observaciones, consignatario, 
			  dueñocarga, cliente, 
			  cass, isnull(combustiblecorte,0) as combustiblecorte,isnull(combustible,0) as combustible, isnull(seguridad,0) as seguridad, isnull(diferenciatarifas,0) as diferenciatarifas,isnull(urn,'') as urn, 
			producto,
			  isnull(handling,0) as handling, isnull(awa,0) as awa, isnull(documentos,0) as documentos, isnull(transporte,0) as transporte, isnull(etiquetas,0) as etiquetas, isnull(cargofitos,0 ) as cargofitos, isnull(tarifacf,0) as tarifacf, isnull(otroscargosagencia,0) as otroscargosagencia, isnull(rp,0 ) as rp, isnull(tarifafsccorte,0) as tarifafsccorte, isnull(tarifassccorte,0) as tarifassccorte, isnull(cajasredondeadas,0) as cajasredondeadas, isnull(cajasvoladas,0) as cajasvoladas, empresa,
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
			  from ##TEMP_CAS	  
			  --where fechaembarque>=@FechaDesde and fechaembarque<=@FechaHasta 
			  
			) a
			left join 
			( select  min(convert(varchar(13),id)) as id,
				substring(cas.nroguia,1,3) as idaerolinea, cas.nroguia, 
				sum(convert(decimal(12,3),isnull(wgtchargeprepaid,0))) as wgtchargeprepaid, 
				sum(convert(decimal(9,3),isnull(taxawbprepaid,0))) as taxawbprepaid, 
			
				sum(convert(decimal(9,3),isnull(duecarrier,0))) as duecarrier, 
				sum(convert(decimal(9,3),isnull(wgtchargecollect,0))) as wgtchargecollect, 
				
				sum(convert(decimal(9,3),isnull(dueagent,0))) as dueagent, 
				
				sum(convert(decimal(9,3),isnull(comission,0))) as comission, 
				
				sum(convert(decimal(9,3),isnull(discount,0))) as discount, 

				sum(convert(decimal(9,3),isnull(retencionfuente,0))) as retencionfuente, 
				
				sum(convert(decimal(9,3),isnull(netsales,0))) as netsales, 
				
              sum(convert(decimal(9,3),isnull(taxcom,0))) as taxcom, 
			  
			  sum(convert(decimal(9,3),isnull(payable,0))) as payable, 
			  
			  min(invoicedate) as fechareportada, 
			  --periododesde, periodohasta 
				periododesde = (select top 1 casa.periododesde from cas casa inner join cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia order by casa.periododesde desc),
				periodohasta = (select top 1 casa.periodohasta from cas casa inner join cas casb ON cas.nroguia=casb.nroguia  WHERE casa.nroguia = cas.nroguia order by casa.periodohasta desc)
				from cas 
			  where periododesde>=@FechaDesde and periodohasta<=@FechaHasta  --and invoice like '%01.%'
			  --group by id, nroguia
			  group by nroguia--, periododesde, periodohasta
			) b
			on a.nroguia = b.nroguia 
					
		union

		select convert(varchar(13), case when a.nroguia is null then b.id else a.id end) as id, 
		1 as status, convert(bit,0) as seleccionar, case when a.idaerolinea is null then b.idaerolinea else a.idaerolinea end as idaerolinea,
		prepaid = isnull((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		a.nroguia, b.nroguia as nroguiaCASS, 
		origen = (SELECT origen FROM liquidacionaerolineas WHERE nroguia = b.nroguia), 
		destino = (SELECT destino FROM liquidacionaerolineas WHERE nroguia = b.nroguia), 
		fechaembarque = (SELECT fechaembarque FROM liquidacionaerolineas WHERE nroguia = b.nroguia),	
		pesobruto = isnull((SELECT pesobruto FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		pesocargable = isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		fletenetoreal = isnull((SELECT fletenetoreal FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		tarifareal = isnull((SELECT tarifareal FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),	
		tarifacorte = isnull((SELECT isnull(tarifacorte,0) FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),			
		isnull(b.wgtchargeprepaid,0) as wgtchargeprepaid, 
		isnull(b.wgtchargecollect,0) as wgtchargecollect,
		comision = isnull((SELECT isnull(tarifacorte,0) FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		convert(decimal(9,3),isnull(b.comission,0)) as comisioncass,  
		manejo = isnull((SELECT manejo FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		convert(decimal(9,3),isnull(b.dueagent,0)) as manejocass,
		descuento = isnull((SELECT descuento FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0), 
		convert(decimal(9,3),isnull(b.discount,0)) as descuentocass,   
		diferenciatarifas = isnull((SELECT diferenciatarifas FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		cargosaerolinea = isnull((SELECT cargosaerolinea FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0),
		convert(decimal(9,3), isnull(b.duecarrier,0)) as cargosaerolineacass, 
        isnull(totalapagar,0) as totalapagar, isnull(totalacobrar,0) as totalacobrar, 
		isnull(payable,0) as payable, 
		case when isnull(a.prepaid,'') = 1 then  isnull(payable,0) - isnull(totalapagar,0) else isnull(payable,0) - isnull(totalacobrar,0) end as diferenciapagarcobrar, 
		cierre,
		observaciones, 
		consignatario, 
		cliente, 
		cass, 
		fechareportada,		
		tarifacass = isnull (case when isnull((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)=1 and isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)>0 then wgtchargeprepaid / isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) when isnull((SELECT prepaid FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) = 0 and isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0)>0 then wgtchargecollect / isnull((SELECT pesocargable FROM liquidacionaerolineas WHERE nroguia = b.nroguia),0) else 0 end, 0),
		isnull(combustiblecorte,0) as combustiblecorte, isnull(combustible,0) as combustible, isnull(seguridad,0) as seguridad, 
		prepaidcass = convert(bit, isnull( case when (wgtchargeprepaid <>0 and wgtchargecollect = 0) then 1 else 0 end ,0) ),
		isnull(urn,'') as urn, producto,
		isnull(dueñocarga,0) as dueñocarga, isnull(handling,0) as handling , isnull(awa,0) as awa, isnull(documentos,0) as documentos, isnull(transporte,0) as transporte, isnull(etiquetas,0) as etiquetas, isnull(cargofitos,0) as fitos, isnull(tarifacf,0) as certificadosorigen, isnull(otroscargosagencia,0) as otroscargosagencia, isnull(rp,0) as rp, isnull(tarifafsccorte,0) as tarifafsccorte, isnull(tarifassccorte,0) as tarifassccorte,
		periododesde, periodohasta, isnull(cajasredondeadas,0) as cajasredondeadas, isnull(cajasvoladas,0) as cajasvoladas, empresa = (SELECT empresa FROM liquidacionaerolineas WHERE nroguia = b.nroguia) , isnull(b.taxcom,0) as taxcomCASS, isnull(b.retencionfuente,0) as retencionfuenteCASS,
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
		from
			( select id, idaerolinea, nroguia, destino, fechaembarque, isnull(pesobruto,0) as pesobruto, isnull(pesocargable,0) as pesocargable , isnull(fletenetoreal,0) as fletenetoreal, isnull(tarifareal,0) as tarifareal, isnull(tarifacorte,0) as tarifacorte,
			  convert(decimal(9,3),isnull(comision,0)) as comision, 
			  convert(decimal(9,3),isnull(manejo,0)) as manejo, 
			  convert(decimal(9,3),isnull(descuento,0)) as descuento, 
			  prepaid, 
			  convert(decimal(9,3),isnull(cargosaerolinea,0)) as cargosaerolinea, 
			  convert(decimal(9,3),isnull(totalapagar,0)) as totalapagar, 
			  1 * convert(decimal(9,3),isnull(totalacobrar,0)) as totalacobrar, 
			  cierre, 
              observaciones, cass, isnull(combustiblecorte,0) as combustiblecorte, isnull(combustible,0) as combustible, isnull(seguridad,0) as seguridad, isnull(diferenciatarifas,0) diferenciatarifas ,isnull(urn,'') as urn, 
				isnull(handling,0) as handling , isnull(awa,0) as awa, isnull(documentos,0) as documentos, isnull(transporte,0) as transporte , isnull(etiquetas,0) as etiquetas, isnull(cargofitos,0) as cargofitos, isnull(tarifacf,0) as tarifacf, isnull(otroscargosagencia,0 ) as otroscargosagencia, isnull(rp,0) as rp, isnull(tarifafsccorte,0) as tarifafsccorte, isnull(tarifassccorte,0) as tarifassccorte, isnull(cajasredondeadas,0) as cajasredondeadas , isnull(cajasvoladas,0) as cajasvoladas, empresa,
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

			  from ##TEMP_CAS	  
			  --where fechaembarque>=@FechaDesde and fechaembarque<=@FechaHasta 

             ) a
			right join 
			( 
		      select min(convert(varchar(13),id)) as id, 
			  substring(cas.nroguia,1,3) as idaerolinea,cas.nroguia, 
			  sum(convert(decimal(9,3),isnull(wgtchargeprepaid,0))) as wgtchargeprepaid,  
			  sum(convert(decimal(9,3),isnull(taxawbprepaid,0))) as taxawbprepaid, 
			  sum(convert(decimal(9,3),isnull(duecarrier,0))) as duecarrier, 
			  sum(convert(decimal(9,3),isnull(wgtchargecollect,0))) as wgtchargecollect, 
			  sum(convert(decimal(9,3),isnull(dueagent,0))) as dueagent, 
			  sum(convert(decimal(9,3),isnull(comission,0))) as comission, 
			  sum(convert(decimal(9,3),isnull(discount,0))) as discount, 
			  sum(convert(decimal(9,3),isnull(retencionfuente,0))) as retencionfuente, 
			  sum(convert(decimal(9,3),isnull(netsales,0))) as netsales, 
			  sum(convert(decimal(9,3),isnull(taxcom,0))) as taxcom, 
			  sum(convert(decimal(9,3),isnull(payable,0))) as payable, 
			  
			  execdate = (SELECT fechaembarque FROM guias where nroguia=cas.nroguia), 
			  consignatario = (SELECT consignatario FROM liquidacionaerolineas where nroguia=cas.nroguia), 
			  dueñocarga = (SELECT consignatarios.nombre1 FROM guicon inner join consignatarios on guicon.idconsignatarios = consignatarios.id where nroguia=cas.nroguia and cntetiq=1), 
			  cliente = (SELECT cliente FROM liquidacionaerolineas where nroguia=cas.nroguia), 
			  origen = (SELECT codigoempresas FROM guias where nroguia=cas.nroguia),
			  producto = (SELECT mercancias.nombre from guias inner join mercancias on guias.idmercancia=mercancias.id where nroguia = cas.nroguia),
			  min(invoicedate) as fechareportada, --periododesde, periodohasta
			  periododesde = (select top 1 casa.periododesde from cas casa inner join cas casb ON cas.nroguia=casb.nroguia WHERE casa.nroguia = cas.nroguia order by casa.periododesde desc),
			  periodohasta = (select top 1 casa.periodohasta from cas casa inner join cas casb ON cas.nroguia=casb.nroguia  WHERE casa.nroguia = cas.nroguia order by casa.periodohasta desc)
			  from cas 
			  where periododesde>=@FechaDesde and periodohasta<=@FechaHasta
			  group by cas.nroguia
			 ) b
			on a.nroguia = b.nroguia 		
		where a.nroguia is null
		print getdate()

		DROP TABLE ##TEMP_CAS
		
		
		RETURN
	END

	IF @Banderas = 'LISTAROVERCOMISION'
	BEGIN

		declare @SQL_DIFERENCIA_CAS1 varchar(8000)

		if @CodigoEmpresas = ''
			set @Empresa = '' 
		else
			set @Empresa = 'AND liquidacionaerolineas.codigoempresas = ''' + @CodigoEmpresas + ''''
		
		if @IdAerolinea = ''
			set @Aerolinea = '' 
		else
			set @Aerolinea = 'AND idaerolinea = ''' + @IdAerolinea + ''''

		SET  @SQL_DIFERENCIA_CAS1 = 'SELECT l.id,  
		statuscass, convert(bit,0) as seleccionar, l.idaerolinea, l.idaerolinea as idaerolineas, l.prepaid, l.nroguia, l.origen, l.destino, l.fechaembarque,
		isnull(l.pesobruto,0) as pesobruto, isnull(l.pesocargable,0) as pesocargable, 
		isnull(l.fletenetoreal,0) as fletenetoreal, 
	    convert(decimal(9,3),isnull(l.comision,0)) as comision, 	    
		convert(decimal(9,3),isnull(l.manejo,0)) as manejo, 
		convert(decimal(9,3),isnull(l.descuento,0)) as descuento,   
		convert(decimal(9,3),isnull(l.cargosaerolinea,0)) as cargosaerolinea,   
		convert(decimal(9,3),isnull(l.overcomision,0)) as overcomision,      
	    diferenciacass , cierre, guicon.idconsignatarios, guias.codigo as idpagador, guias.idmercancia, space('''') as prepaidtexto,
		guias.origen1,isnull(l.combustible,0) as combustible , guias.detalles as consignatario
		FROM liquidacionaerolineas l left join guias on  l.nroguia = guias.nroguia 
		left join guicon on l.nroguia = guicon.nroguia	and cntetiq=1							
					WHERE l.fechaembarque>= ''' + Convert(varchar(10),@FechaDesde,101) + ''' and l.fechaembarque <= ''' + Convert(Varchar(10),@FechaHasta,101)  + '''' +
				  ' ' + @Empresa	+	  
				  ' ' + @Aerolinea + 		
			' and (transaccion=''S'') ORDER BY nroguia ASC '

		
			EXEC (@SQL_DIFERENCIA_CAS1)
				
			print @SQL_DIFERENCIA_CAS1
		
		RETURN
	END

	IF @Banderas = 'PORGUIA'
	BEGIN
		--traer todas las guias de un rango de fechas por aerolinea
		SELECT nroguia FROM liquidacionaerolineas 
		WHERE fechaembarque >= @FechaDesde and fechaembarque <= @FechaHasta and idAerolinea=@IdAerolinea
		RETURN
	END	

	IF @Banderas = 'CERRARPORGUIA'
	BEGIN
		--cerrar una guia para que no sea modificada sus datos
		UPDATE liquidacionaerolineas
		SET cierre = 'CERRADA'
		WHERE nroguia = @nroguia and id=@id		
		RETURN
	END	
	
	IF @Banderas = 'LISTARLIQUIDACIONCLIENTES'
	BEGIN
		SELECT l.id,
		statuscass, convert(bit,0) as seleccionar, l.idaerolinea, l.idaerolinea as idaerolineas, 
        l.prepaid, l.nroguia, l.origen, l.destino, l.fechaembarque,
		isnull(l.tarifacorte,0) as tarifacorte, isnull(l.tarifafsc,0) as tarifafsc, isnull(l.tarifareal,0) as tarifareal,
		isnull(l.pesobruto,0) as pesobruto, isnull(l.pesocargable,0) as pesocargable, 
		isnull(l.fletenetoreal,0) as fletenetoreal, isnull(l.fletenetocorte,0) as fletenetocorte, 
	    convert(decimal(9,3),isnull(l.comision,0)) as comision, 	    
		convert(decimal(9,3),isnull(l.manejo,0)) as manejo, 
		convert(decimal(9,3),isnull(l.descuento,0)) as descuento,   
		convert(decimal(9,3),isnull(l.cargosaerolinea,0)) as cargosaerolinea,   
		convert(decimal(9,3),isnull(l.overcomision,0)) as overcomision,   
		isnull(guias.cargosagencia,0) as cargosagencia,      
	    diferenciacass , l.cierre, guicon.idconsignatarios, guias.codigo as idpagador, cliente = (select nombres from clientes where codigo=guias.codigo),
        guias.idmercancia,
		guias.origen1,isnull(l.combustible,0) as combustible, guias.detalles as consignatario,
	    '' as prepaidtexto, guias.anulado, guias.codigoempresas, isnull(comisioncliente,0) as comisioncliente,
		convert(decimal(9,3), isnull(cas.comisionCASS,0)) as comisioncass,
		convert(decimal(9,3), isnull(cas.descuentoCASS,0)) as descuentocass,
		isnull(descuentocliente,0) as descuentocliente, isnull(overcomisioncliente,0) overcomisioncliente, mercancias.nombre as producto,
		diferenciatarifascliente, 
		(isnull(transporte,0) + isnull(handling,0) + isnull(otroscargosagencia,0) + isnull(rp,0) + 
		 isnull(gye,0) +isnull(bodegaje,0)+isnull(documentos,0) +isnull(awa,0)+isnull(etiquetas,0)+
				isnull(cargofitos,0) + isnull(tarifacf,0) ) as cargosagencia,
		isnull(tarifacf,0) as certificadosorigen, 
		isnull(cargofitos,0) as fitos,
		isnull(transporte,0) as transporte, isnull(handling,0) as handling, isnull(otroscargosagencia,0) as otroscargosagencia,
	    isnull(rp,0) as rp, isnull(awa,0) as awa, isnull(etiquetas,0) as etiquetas,
		isnull(transporteacuerdogg,0) as transporteacuerdogg, isnull(oagg,0) as oagg, isnull(oacliente,0) as oacliente,
		isnull(devolucion,0) as devolucion, isnull(devolucioncliente,0) as devolucioncliente,
		cajasvoladas = ( CASE when guias.esmadre='S'  then (select sum(embarques.cajasvoladas) 
						FROM  guias inner join embarques on guias.nroguia=embarques.nroguia where guiamadre= l.nroguia )
						ELSE (select sum(embarques.cajasvoladas) 
						FROM  guias inner join embarques on guias.nroguia=embarques.nroguia where embarques.nroguia = l.nroguia )
						END
						),
		guias.cajasvoladas as cajasredondeadas,
		tarifacass = case when l.prepaid=1 then cas.wgtchargeprepaid / l.pesocargable else cas.wgtchargecollect / l.pesocargable end
		FROM liquidacionaerolineas l left join guias on  l.nroguia = guias.nroguia 
		LEFT JOIN mercancias on guias.idmercancia=mercancias.id
		LEFT JOIN guicon on l.nroguia = guicon.nroguia	and cntetiq=1	
		LEFT JOIN (select nroguia, sum(convert(decimal(9,3),isnull(comission,0))) as comisioncass, sum(convert(decimal(9,3),isnull(discount,0))) as descuentocass,
			sum(convert(decimal(9,3),isnull(wgtchargeprepaid,0))) as wgtchargeprepaid, sum(convert(decimal(9,3),isnull(wgtchargecollect,0))) as wgtchargecollect
			FROM cas  group by nroguia) cas on l.nroguia = cas.nroguia						
		WHERE l.fechaembarque>= @FechaDesde and l.fechaembarque <= @FechaHasta 			  	
		AND (transaccion='S') ORDER BY nroguia ASC 
		return
	END

	IF @Banderas = 'LISTARCUADREFLETES'
	BEGIN			
	/*
	if(@FechaDesde <='08/15/2014' )
	--begin
	SELECT a.* --, b.totalfacturado, (a.fletetotal - b.totalfacturado) as diferencia 
	FROM
	(SELECT guias.nroguia,guias.idaerolineas, isnull(ef.nomcli,'') as cliente, guias.fechaembarque, sum(isnull(rg.totren,0)) as reembolsofacturado, 
		isnull(cas.wgtchargeprepaid,0) + isnull(cas.duecarrier,0) as fletecass,
		isnull(cas.wgtchargeprepaid,0) + isnull(cas.duecarrier,0) - sum(isnull(rg.totren,0)) as diferenciafacturado,
		sum(isnull(ed.totfac,0)) as notasdecredito, isnull(fletetotal,0) as fletetotal, guias.codigoempresas
		FROM guias left join 
			(SELECT nroguia, sum(convert(decimal(9,3),isnull(wgtchargeprepaid,0))) as wgtchargeprepaid, sum(convert(decimal(9,3),isnull(duecarrier,0))) as duecarrier FROM cas GROUP BY nroguia) cas on  guias.nroguia = cas.nroguia 
					left join kdbs_ggcargo.dbo.encabezadofacturas ef on guias.nroguia=numtra
					left join kdbs_ggcargo.dbo.renglonesfacturas rg on 	ef.numfac=rg.numfac
					left join kdbs_ggcargo.dbo.encabezadodevoluciones ed on ef.numfac=ed.reffac
					left join kdbs_ggcargo.dbo.renglonesdevoluciones rd on ed.numfac=rd.numfac					
		WHERE guias.fechaembarque>= @FechaDesde and guias.fechaembarque <= @FechaHasta and guias.anulado=0 and rg.codart = '\1' 
				group by guias.nroguia	, guias.idaerolineas,guias.fechaembarque, guias.fletetotal, cas.wgtchargeprepaid, cas.duecarrier, ef.nomcli, guias.codigoempresas
	 ) a
	LEFT JOIN
	( SELECT nroguia, sum(rg.totren) as totalfacturado FROM guias
					left join kdbs_ggcargo.dbo.encabezadofacturas ef on guias.nroguia=numtra
					left join kdbs_ggcargo.dbo.renglonesfacturas rg on 	ef.numfac=rg.numfac
					--left join kdbs_ggcargo.dbo.encabezadodevoluciones ed on ef.numfac=ed.reffac
					--left join kdbs_ggcargo.dbo.renglonesdevoluciones rd on ed.numfac=rd.numfac					
		WHERE guias.fechaembarque>= @FechaDesde and guias.fechaembarque <= @FechaHasta and guias.anulado=0
				group by guias.nroguia  	  			
	 )b
	on a.nroguia = b.nroguia
	ORDER BY a.nroguia ASC
else
	SELECT empresa, idaerolineas, nroguia, fechaembarque, cliente,
	 isnull(reembolsofacturado,0) as reembolsofacturado, isnull(fletecass,0) as fletecass, 
	 (isnull(fletecass,0) - isnull(reembolsofacturado,0)) as diferencia, 
	 notasdecredito, guiacass, guianoreportada, periododesde, periodohasta
		FROM (
			SELECT liquidacionaerolineas.empresa, substring(liquidacionaerolineas.nroguia,1,3) as idaerolineas, liquidacionaerolineas.nroguia, liquidacionaerolineas.fechaembarque, facturas.nomcli as cliente,
			 reembolsofacturado = (SELECT sum(totren) FROM  contabilidadunificada.kdbs_unificada.dbo.encabezadofacturas ef1 INNER JOIN contabilidadunificada.kdbs_unificada.dbo.renglonesfacturas rf1 ON ef1.numfac=rf1.numfac AND  rf1.codart like '%\2.1.1.03.%' WHERE rf1.numtra= liquidacionaerolineas.nroguia),
			 cas.wgtchargeprepaid + cas.duecarrier as fletecass,	
			 notasdecredito = (SELECT sum(ed.totfac) FROM contabilidadunificada.kdbs_unificada.dbo.encabezadofacturas ef 
							left join contabilidadunificada.kdbs_unificada.dbo.renglonesfacturas rg on 	ef.numfac=rg.numfac
							left join contabilidadunificada.kdbs_unificada.dbo.encabezadodevoluciones ed on ef.numfac=ed.reffac
							left join contabilidadunificada.kdbs_unificada.dbo.renglonesdevoluciones rd on ed.numfac=rd.numfac
							WHERE ef.numtra=liquidacionaerolineas.nroguia),
			 isnull(cas.nroguia,'') as guiacass,
			 isnull(cas1.nroguia, '') as guianoreportada,
			 isnull(cas.periododesde,'') as periododesde,
			 isnull(cas.periodohasta,'') as periodohasta
			 FROM liquidacionaerolineas left join (SELECT rf.numtra, isnull(ef.nomcli,'') as nomcli, isnull(rf.totren,0) as totren FROM contabilidadunificada.kdbs_unificada.dbo.renglonesfacturas rf  
			 INNER JOIN contabilidadunificada.kdbs_unificada.dbo.encabezadofacturas ef ON ef.numfac=rf.numfac WHERE rf.codart like '%\2.1.1.03.%' ) facturas ON	liquidacionaerolineas.nroguia=facturas.numtra		 			 
			-- LEFT JOIN guias on liquidacionaerolineas.nroguia = guias.nroguia
			 LEFT JOIN (SELECT nroguia, sum(convert(decimal(9,3),wgtchargeprepaid)) as wgtchargeprepaid, sum(convert(decimal(9,3),duecarrier)) as duecarrier, periododesde, periodohasta FROM cas GROUP BY nroguia, periododesde, periodohasta) cas on  liquidacionaerolineas.nroguia = cas.nroguia 
			 LEFT JOIN (SELECT nroguia FROM cas WHERE periododesde>=@FechaDesde and periodohasta<=@FechaHasta GROUP BY nroguia, periododesde,periodohasta ) cas1 on  liquidacionaerolineas.nroguia = cas1.nroguia 
			 WHERE 
			 liquidacionaerolineas.fechaembarque>= @FechaDesde and liquidacionaerolineas.fechaembarque <= @FechaHasta 
			 --AND  rf1.codart like '%\2.1.1.03.%' 
	 ) a

	 */
	 print 'HOLA'
	END

	IF @Banderas = 'ABRIRGUIALIQUIDACION'
	BEGIN
		--delete from liquidacionaerolineasseguimientorespaldo where nroguia = @nroguia

		--delete from liquidacionaerolineasseguimiento where nroguia = @nroguia

		update liquidacionaerolineas set cierre = 'ABIERTA' where nroguia = @nroguia

		RETURN
	END

	IF @Banderas = 'DETALLEGUIACASS'
	BEGIN
		SELECT id, nroguia, estado, origen, destino, wgtchargeprepaid, taxawbprepaid, duecarrier, wgtchargecollect, dueagent, comission, discount, retencionfuente, netsales, 
               taxcom, payable, execdate, agentsinformation, invoice, invoicedate, periododesde, periodohasta
		FROM   cas WHERE nroguia = @nroguia		
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