/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_LiquidacionAerolineasGuardar
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
BEGIN TRY
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
	END TRY
		BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
GO

/*
-- EJEMPLO DE EJECUCI�N

EXEC [dbo].[AC_pro_LiquidacionAerolineasGuardar]
    @id = '',
    @nroguia = '12345678901',
    @idaerolinea = '1234',
    @cass = 'S',
    @destino = 'UIO',
    @fechaembarque = '20260801',
    @prepaid = 1,
    @valorprepaid = 0,
    @fletetotalreal = 100,
    @fletetotalcorte = 100,
    @pesobruto = 10,
    @pesocargable = 10,
    @fletenetoreal = 100,
    @tarifareal = '10',
    @fletenetocorte = 100,
    @tarifacorte = '10',
    @fechacontable = '20260801',
    @cca = '',
    @reclamo = 0,
    @descuento = 0,
    @cargosaerolinea = 0,
    @manejo = 0,
    @costosmanejo = 0,
    @costootros = 0,
    @utilidadmanejo = 0,
    @comision = 0,
    @overcomision = 0,
    @overcomision2 = 0,
    @diferenciatarifas = 0,
    @cliente = 'CLIENTE PRUEBA',
    @consignatario = 'CONSIGNATARIO PRUEBA',
    @origen = 'GYE',
    @codigoempresas = '001',
    @transaccion = 'S',
    @observaciones = 'PRUEBA ESTANDARIZACION',
    @pagar = 0,
    @cobrar = 0,
    @textopagarcobrar = '',
    @tarifafsc = 0,
    @tarifassc = 0,
    @combustible = 0,
    @seguridad = 0,
    @fechaover = NULL,
    @versionfila = 1,
    @fechamanejo = NULL,
    @fechacomision = NULL,
    @fechadescuento = NULL,
    @fechaovercomision = NULL,
    @fechaovercomision2 = NULL,
    @fechadiferenciatarifas = NULL,
    @fechareclamo = NULL,
    @cierre = 'ABIERTA',
    @diferenciacass = 0,
    @statuscass = 0,
    @comisioncliente = 0,
    @reclamocliente = 0,
    @descuentocliente = 0,
    @overcomisioncliente = 0,
    @overcomision2cliente = 0,
    @diferenciatarifascliente = 0,
    @devolucion = 0,
    @devolucioncliente = 0,
    @cargosagencia = 0,
    @transporteacuerdogg = 0,
    @oagg = 0,
    @oacliente = 0,
    @empresa = '001',
    @urn = '',
    @cantidadfitos = 0,
    @cantidadcertificadosorigen = 0,
    @producto = '',
    @cajasvoladas = 0,
    @region = '',
    @retencioniva = 0,
    @tarifaconvenio = 0,
    @fletenetoconvenio = 0,
    @biaconvenio = 0,
    @feaconvenio = 0,
    @fletetotalconvenio = 0,
    @tipoVuelo = '',
    @codigoContable = '',
    @idCliente = '',
    @idMercancia = '',
    @maa = 0,
    @paa = 0,
    @tra = 0,
    @acuerdosComerciales = 0,
    @reclamos = 0,
    @bfa = 0,
    @tarifacompra = 0,
    @tarifaventa = 0,
    @tarifamargen = 0,
    @ingresoxtarifa = 0,
    @ingresoxtarifaxkilo = 0,
    @ingresoneto = 0,
    @margensinbia = 0,
    @ingresosinbia = 0,
    @retencionfuente = 0,
    @banderas = 'SISTEMA'
*/