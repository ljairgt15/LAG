/*
VERSION     MODIFIEDBY       MODIFIEDDATE    HU          MODIFICATION
1           Paul Castillo    2012-03-19      N/A         Initial code - Save airline settlement data
2           Rogger Lindao    2026-08-31      AC 64492    Standardization according to database development guidelines
*/
CREATE OR ALTER   PROCEDURE [dbo].[AC_pro_LiquidacionAerolineasGuardar] 
	@id varchar(13)
   ,@nroguia varchar(13)
   ,@idaerolinea varchar(4)
   ,@cass varchar(1)
   ,@destino varchar(3)
   ,@fechaembarque datetime
   ,@prepaid bit
   ,@valorprepaid decimal(10,3)
   ,@fletetotalreal decimal(10,3)
   ,@fletetotalcorte decimal(10,3)
   ,@pesobruto decimal(10,3)
   ,@pesocargable decimal(10,3)
   ,@fletenetoreal decimal(10,3)
   ,@tarifareal varchar(10)
   ,@fletenetocorte decimal(10,3)
   ,@tarifacorte varchar(10)
   ,@fechacontable datetime
   ,@cca varchar(8)
   ,@reclamo decimal(10,3)
   ,@descuento decimal(10,3)
   ,@cargosaerolinea decimal(10,3)
   ,@manejo decimal(10,3)
   ,@costosmanejo decimal(10,3)
   ,@costootros decimal(10,3)
   ,@utilidadmanejo decimal(10,3)
   ,@comision decimal(10,3)
   ,@overcomision decimal(10,3)
   ,@overcomision2 decimal(10,3)
   ,@diferenciatarifas decimal(10,3)
   ,@cliente varchar(250)
   ,@consignatario varchar(100)
   ,@origen varchar(3)
   ,@codigoempresas varchar(3)
   ,@transaccion varchar(25)
   ,@observaciones varchar(500)
   ,@pagar decimal(10,3)
   ,@cobrar decimal(10,3)
   ,@textopagarcobrar varchar(250)
   ,@tarifafsc decimal(10,3)
   ,@tarifassc decimal(10,3)
   ,@combustible decimal(10,3)
   ,@seguridad decimal(10,3)
   ,@fechaover datetime --------desde aqui
   ,@versionfila int
   ,@fechamanejo datetime
   ,@fechacomision datetime
   ,@fechadescuento datetime
   ,@fechaovercomision datetime
   ,@fechaovercomision2 datetime
   ,@fechadiferenciatarifas datetime
   ,@fechareclamo datetime
   ,@cierre varchar(25) --desde aqui clientes
   ,@diferenciacass decimal(9,3)
   ,@statuscass int
   ,@comisioncliente decimal(10,3)
   ,@reclamocliente decimal(10,3)
   ,@descuentocliente decimal(10,3)
   ,@overcomisioncliente decimal(10,3)
   ,@overcomision2cliente decimal(10,3)
   ,@diferenciatarifascliente decimal(10,3)
   ,@devolucion decimal(10,3)
   ,@devolucioncliente decimal(10,3)
   ,@cargosagencia decimal(10,3)
   ,@transporteacuerdogg decimal(10,3)
   ,@oagg decimal(10,3)
   ,@oacliente decimal(10,3)
   ,@empresa char(3)
   ,@urn nvarchar(25)
   ,@cantidadfitos int
   ,@cantidadcertificadosorigen int
   ,@producto nvarchar(50)
   ,@cajasvoladas decimal(10,3)
   ,@region nvarchar(50)
   ,@retencioniva decimal(10,3)
   ,@tarifaconvenio decimal(10,3)
   ,@fletenetoconvenio decimal(10,3)
   ,@biaconvenio decimal(10,3)
   ,@feaconvenio decimal(10,3)   
   ,@fletetotalconvenio decimal(10,3)
   ,@tipoVuelo nvarchar(16)
   ,@codigoContable nvarchar(16)
   ,@idCliente nvarchar(16)
   ,@idMercancia nvarchar(16)
   ,@maa decimal(10,3)
   ,@paa decimal(10,3)
   ,@tra decimal(10,3) 
   ,@acuerdosComerciales decimal(10,3)
   ,@reclamos decimal(10,3)
   ,@bfa decimal(10,3)
   ,@tarifacompra decimal(10,3)  
   ,@tarifaventa decimal(10,3)
   ,@tarifamargen decimal(10,3)
   ,@ingresoxtarifa decimal(10,3)
   ,@ingresoxtarifaxkilo decimal(10,3)
   ,@ingresoneto decimal(10,3)		
   ,@margensinbia decimal(10,3)
   ,@ingresosinbia decimal(10,3)		
   ,@retencionfuente decimal(10,5)
   ,@banderas varchar(30)	
AS
BEGIN
	DECLARE @contarguia int
	set @contarguia = 0
	IF @banderas = 'SISTEMA'
	BEGIN
		
		SELECT @contarguia = count(*) FROM liquidacionaerolineas WHERE nroguia = @nroguia and transaccion = 'S'
		
		IF (@contarguia >0 ) 
		BEGIN
			
			--SOLO MODIFICA LAS transacciones que son del sistema (S) y que ademas esten abiertas
			UPDATE liquidacionaerolineas 
			SET 
			idaerolinea = @idaerolinea, cass = @cass, destino = @destino, fechaembarque = @fechaembarque, prepaid = @prepaid,
				valorprepaid = @valorprepaid , fletetotalreal = @fletetotalreal, fletetotalcorte = @fletetotalcorte,
				pesobruto = @pesobruto, pesocargable = @pesocargable, fletenetoreal = @fletenetoreal, tarifareal = @tarifareal, fletenetocorte = @fletenetocorte,
				tarifacorte = @tarifacorte, cca=@cca, reclamo=@reclamo, 
				descuento=@descuento, cargosaerolinea=@cargosaerolinea, manejo=@manejo, costosmanejo = @costosmanejo,costootros = @costootros,
				utilidadmanejo = @utilidadmanejo, comision = @comision, overcomision = @overcomision, 
				diferenciatarifas = @diferenciatarifas, cliente = @cliente, consignatario=@consignatario, origen = @origen,
				codigoempresas = @codigoempresas, fechacontable = @fechacontable, observaciones = @observaciones,
				fechatransaccion = getdate(), tarifafsc = @tarifafsc, tarifassc = @tarifassc, combustible = @combustible, seguridad = @seguridad,				
				empresa = @empresa,
				urn = @urn,
				cantidadfitos = @cantidadfitos,
				cantidadcertificadosorigen = @cantidadcertificadosorigen,
				producto  = @producto,
				cajasvoladas = @cajasvoladas,
				region=@region,
				retencioniva=@retencioniva,
				tarifaconvenio=@tarifaconvenio,
				fletenetoconvenio=@fletenetoconvenio,
				biaconvenio=@biaconvenio,
				feaconvenio=@feaconvenio,
				fletetotalconvenio=@fletetotalconvenio,
				tipoVuelo=@tipoVuelo,
				codigoContable=@codigoContable,
				idCliente=@idCliente,
				idMercancia=@idMercancia,
				maa=@maa,
				paa=@paa,
				tra=@tra,				
				reclamos=@reclamos,
				comisioncliente = @comisioncliente, 
				descuentocliente = @descuentocliente, 
				overcomisioncliente=@overcomisioncliente, 
				diferenciatarifascliente=@diferenciatarifascliente,
				devolucioncliente=@devolucioncliente,
				reclamocliente = @reclamocliente,				
				acuerdosComerciales=@acuerdosComerciales,		
				bfa=@bfa,
				tarifacompra=@tarifaCompra,
				tarifaventa = @tarifaventa,
				tarifamargen = @tarifamargen,
		    	ingresoxtarifa = @ingresoxtarifa,
				ingresoxtarifaxkilo = @ingresoxtarifaxkilo,
			    ingresoneto = @ingresoneto,
				margensinbia = @margensinbia,
				ingresosinbia = @ingresosinbia,
				oacliente=@oacliente,
				retencionfuente=@retencionfuente
				 
			WHERE nroguia = @nroguia and transaccion = 'S' and cierre='ABIERTA'
		END
		ELSE
		BEGIN			
			DECLARE @InicialCodigoEmpresas varchar(1), @idsucursal int, @IdUnico char(11)
			SET @InicialCodigoEmpresas = 'U'
			SET @idsucursal = 1
			EXECUTE pro_GeneraridUnicoIntOut  'liquidacionaerolineas',@InicialCodigoEmpresas, @idsucursal, @IdUnico OUT

			-- Insert statements for procedure here
			INSERT INTO liquidacionaerolineas           
		   (id, nroguia, idaerolinea, cass, destino, fechaembarque, prepaid,
			valorprepaid, fletetotalreal, fletetotalcorte,
			pesobruto, pesocargable, fletenetoreal, tarifareal, fletenetocorte, 
			tarifacorte, fechacontable, cca, reclamo, descuento, cargosaerolinea, manejo, costosmanejo,costootros,
			utilidadmanejo, comision, overcomision, overcomision2, diferenciatarifas, cliente, consignatario, origen,
			codigoempresas, transaccion, fechatransaccion, observaciones, cierre, tarifafsc, tarifassc, combustible, seguridad, fechaover,
			fechamanejo, fechacomision, fechadescuento, fechaovercomision, fechaovercomision2, fechadiferenciatarifas, fechareclamo, empresa, urn, cantidadfitos,
				cantidadcertificadosorigen, producto, cajasvoladas, region, retencioniva,
			tarifaconvenio, fletenetoconvenio, biaconvenio, feaconvenio, fletetotalconvenio, tipoVuelo, 
			codigoContable, idCliente, idMercancia, maa, paa, tra, acuerdosComerciales, reclamos,
			comisioncliente, descuentocliente, overcomisioncliente, diferenciatarifascliente, devolucioncliente, reclamocliente, bfa, tarifacompra, tarifaventa, tarifamargen, ingresoxtarifa, ingresoxtarifaxkilo, ingresoneto, margensinbia, ingresosinbia, oacliente, retencionfuente	)
			VALUES 
				   (@IdUnico, @nroguia, @idaerolinea, @cass, @destino, @fechaembarque, @prepaid,
					@valorprepaid, @fletetotalreal, @fletetotalcorte,
				   @pesobruto, @pesocargable, @fletenetoreal, @tarifareal, @fletenetocorte,
				   @tarifacorte, @fechacontable, @cca, @reclamo, @descuento, @cargosaerolinea, @manejo, @costosmanejo, @costootros,
				   @utilidadmanejo, @comision, @overcomision, @overcomision2, @diferenciatarifas, @cliente, @consignatario, @origen,
				   @codigoempresas, 'S', getdate(), @observaciones, 'ABIERTA', @tarifafsc, @tarifassc, @combustible, @seguridad, @fechaover,
				   @fechamanejo, @fechacomision, @fechadescuento, @fechaovercomision, @fechaovercomision2, @fechadiferenciatarifas, @fechareclamo, @empresa, @urn, @cantidadfitos ,
				   @cantidadcertificadosorigen, @producto, @cajasvoladas, @region, @retencioniva,
				   @tarifaconvenio, @fletenetoconvenio, @biaconvenio, @feaconvenio, @fletetotalconvenio, @tipoVuelo,
				   @codigoContable, @idCliente, @idMercancia, @maa, @paa, @tra, @acuerdosComerciales, @reclamos,
				   @comisioncliente, @descuentocliente, @overcomisioncliente, @diferenciatarifascliente, @devolucioncliente, @reclamocliente, @bfa, @tarifacompra, @tarifaventa, @tarifamargen, @ingresoxtarifa, @ingresoxtarifaxkilo, @ingresoneto, @margensinbia, @ingresosinbia,@oacliente, @retencionfuente 
			)
		END
	RETURN
	END

	if @banderas = 'CERRAR'
	BEGIN
		UPDATE liquidacionaerolineas 
			SET cierre = @cierre
			WHERE idaerolinea = @idaerolinea and transaccion = 'S' and cierre='ABIERTA' and empresa=@empresa
	END
--	IF @banderas = 'CORRECCION'
--	BEGIN
--
--		IF (ltrim(rtrim(@id)) != '')
--		BEGIN
--			--SOLO MODIFICA LAS transacciones que son del sistema (S) y que ademas esten abiertas
--			UPDATE rentabilidad 
--			SET idaerolinea = @idaerolinea, cass = @cass, destino = @destino, fechaembarque = @fechaembarque, prepaid = @prepaid,
--				valorprepaid = @valorprepaid , fletetotalreal = @fletetotalreal, fletetotalcorte = @fletetotalcorte,
--				pesobruto = @pesobruto, pesocargable = @pesocargable, fletenetoreal = @fletenetoreal, tarifareal = @tarifareal, fletenetocorte = @fletenetocorte,
--				tarifacorte = @tarifacorte, cca=@cca, reclamo=@reclamo, descuento=@descuento, cargosaerolinea=@cargosaerolinea, manejo=@manejo, costosmanejo = @costosmanejo,costootros = @costootros,
--				utilidadmanejo = @utilidadmanejo, comision = @comision, overcomision = @overcomision, overcomision2 = @overcomision2, diferenciatarifas = @diferenciatarifas, cliente = @cliente, origen = @origen,
--				codigoempresas = @codigoempresas,
--				transaccion = @transaccion, fechacontable = @fechacontable,
--				observaciones = @observaciones,
--			    pagar = @pagar,
--				cobrar = @cobrar,
--				textopagarcobrar = @textopagarcobrar,
--				fechatransaccion = getdate(),
--				tarifafsc = @tarifafsc,
--				tarifassc = @tarifassc,
--				combustible = @combustible,
--				seguridad = @seguridad,
--				fechaover = @fechaover,
--				fechamanejo = @fechamanejo, fechacomision = @fechacomision, fechadescuento = @fechadescuento, fechaovercomision = @fechaovercomision, 
--				fechaovercomision2 = @fechaovercomision2, fechadiferenciatarifas = @fechadiferenciatarifas, fechareclamo = @fechareclamo
--			WHERE id = @id and (transaccion='C' or transaccion='A' or  transaccion='ND' or transaccion='NC') and cierre='ABIERTA' --nroguia = @nroguia and transaccion = 'C' --and cierre='ABIERTA'
--		END
--		ELSE
--		BEGIN		
--
--			DECLARE @InicialCodigoEmpresasCorreccion varchar(1), @idsucursalCorreccion int, @IdUnicoCorreccion char(11)
--			SET @InicialCodigoEmpresasCorreccion = 'U'
--			SET @idsucursalCorreccion = 1
--			EXECUTE pro_GeneraridUnicoIntOut  'rentabilidad' ,@InicialCodigoEmpresasCorreccion, @idsucursalCorreccion, @IdUnicoCorreccion OUT
--
--			-- Insert statements for procedure here
--			INSERT INTO ggcargo.dbo.Rentabilidad           
--		   (id, nroguia, idaerolinea, cass, destino, fechaembarque, prepaid,
--			valorprepaid, fletetotalreal, fletetotalcorte,
--			pesobruto, pesocargable, fletenetoreal, tarifareal, fletenetocorte, 
--			tarifacorte, fechacontable, cca, reclamo, descuento, cargosaerolinea, manejo, costosmanejo,costootros,
--			utilidadmanejo, comision, overcomision, overcomision2, diferenciatarifas, cliente, origen,
--			codigoempresas, transaccion, fechatransaccion, observaciones, cierre, pagar, cobrar, textopagarcobrar, tarifafsc, tarifassc, combustible, seguridad, fechaover)
--			VALUES 
--				   (@IdUnicoCorreccion, @nroguia, @idaerolinea, @cass, @destino, @fechaembarque, @prepaid,
--					@valorprepaid, @fletetotalreal, @fletetotalcorte,
--				   @pesobruto, @pesocargable, @fletenetoreal, @tarifareal, @fletenetocorte,
--				   @tarifacorte, @fechacontable, @cca, @reclamo, @descuento, @cargosaerolinea, @manejo, @costosmanejo, @costootros,
--				   @utilidadmanejo, @comision, @overcomision, @overcomision2, @diferenciatarifas, @cliente, @origen,
--				   @codigoempresas, @transaccion, getdate(), @observaciones, '', @pagar, @cobrar, @textopagarcobrar, @tarifafsc, @tarifassc, @combustible, @seguridad, @fechaover)
--		END
--		RETURN
--	END

	IF @banderas = 'OVERCOMISION'
	BEGIN
		UPDATE liquidacionaerolineas SET overcomision = @overcomision, overcomision2=@overcomision2 where id =@id
		RETURN
	END	

	IF @banderas = 'ELIMINAR'
	BEGIN
		DELETE FROM liquidacionaerolineas WHERE id = @id
			
		
		RETURN
	END

	IF @banderas = 'LIQUIDACIONCLIENTES'
	BEGIN
		print @nroguia
		print @comisioncliente
		
		UPDATE liquidacionaerolineas SET comisioncliente = @comisioncliente, descuentocliente = @descuentocliente, overcomisioncliente=@overcomisioncliente, diferenciatarifascliente=@diferenciatarifascliente,
		devolucioncliente=@devolucioncliente, transporteacuerdogg=@transporteacuerdogg, oacliente=@oacliente, oagg=@oagg
		WHERE  nroguia=@nroguia and 
		(isnull(comisioncliente,0)<>@comisioncliente or isnull(descuentocliente,0)<>@descuentocliente or isnull(overcomisioncliente,0)<>@overcomisioncliente or isnull(diferenciatarifascliente,0)<>@diferenciatarifascliente
		 or isnull(devolucioncliente,0)<>@devolucioncliente or  isnull(transporteacuerdogg,0)<>@transporteacuerdogg or isnull(oacliente,0)<>@oacliente or isnull(oagg,0)<>@oagg)
		RETURN
	END

	IF @banderas = 'INGRESARDEVOLUCION'
	BEGIN
		print @nroguia
		print @comisioncliente
		
		UPDATE liquidacionaerolineas SET devolucion = @devolucion
		WHERE  nroguia=@nroguia and 
		isnull(devolucion,0) <> @devolucion
		RETURN
	END
END
