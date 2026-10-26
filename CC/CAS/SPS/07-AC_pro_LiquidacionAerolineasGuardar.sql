/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_LiquidacionAerolineasGuardar
*/
CREATE OR ALTER   PROCEDURE [dbo].[AC_pro_LiquidacionAerolineasGuardar] 
	@Id varchar(13)
   @NroGuia varchar(13),
   @IdAerolinea varchar(4),
   @Cass varchar(1),
   @Destino varchar(3),
   @FechaEmbarque datetime,
   @Prepaid bit,
   @ValorPrepaid decimal(10,3),
   @FleteTotalReal decimal(10,3),
   @FleteTotalCorte decimal(10,3),
   @PesoBruto decimal(10,3),
   @PesoCargable decimal(10,3),
   @FleteNetoReal decimal(10,3),
   @TarifaReal varchar(10),
   @FleteNetoCorte decimal(10,3),
   @TarifaCorte varchar(10),
   @FechaContable datetime,
   @Cca varchar(8),
   @Reclamo decimal(10,3),
   @Descuento decimal(10,3),
   @CargoAerolinea decimal(10,3),
   @Manejo decimal(10,3),
   @CostosManejo decimal(10,3),
   @CostoOtros decimal(10,3),
   @UtilidadManejo decimal(10,3),
   @Comision decimal(10,3),
   @OverComision decimal(10,3),
   @OverComision2 decimal(10,3),
   @DiferenciaTarifas decimal(10,3),
   @Cliente varchar(250),
   @Consignatario varchar(100),
   @Origen varchar(3),
   @CodigoEmpresas varchar(3),
   @Transaccion varchar(25),
   @Observaciones varchar(500),
   @Pagar decimal(10,3),
   @Cobrar decimal(10,3),
   @TextoPagarCobrar varchar(250),
   @TarifaFsc decimal(10,3),
   @TarifaSsc decimal(10,3),
   @Combustible decimal(10,3),
   @Seguridad decimal(10,3),
   @FechaOver datetime, --------desde aqui
   @VersionFila int,
   @FechaManejo datetime,
   @FechaComision datetime,
   @FechaDescuento datetime,
   @FechaOverComision datetime,
   @FechaOverComision2 datetime,
   @FechaDiferenciaTarifas datetime,
   @FechaReclamo datetime,
   @Cierre varchar(25), --desde aqui clientes
   @DiferenciaCass decimal(9,3),
   @StatusCass int,
   @ComisionCliente decimal(10,3),
   @ReclamoCliente decimal(10,3),
   @DescuentoCliente decimal(10,3),
   @OverComisionCliente decimal(10,3),
   @OverComision2Cliente decimal(10,3),
   @DiferenciaTarifasCliente decimal(10,3),
   @Devolucion decimal(10,3),
   @DevolucionCliente decimal(10,3),
   @CargosAgencia decimal(10,3),
   @TransporteAcuerdoGg decimal(10,3),
   @Oagg decimal(10,3),
   @OaCliente decimal(10,3),
   @Empresa char(3),
   @Urn nvarchar(25),
   @CantidadFitos int,
   @CantidadCertificadosOrigen int,
   @Producto nvarchar(50),
   @CajasVoladas decimal(10,3),
   @Region nvarchar(50),
   @RetencionIva decimal(10,3),
   @TarifaConvenio decimal(10,3),
   @FleteNetoConvenio decimal(10,3),
   @BiaConvenio decimal(10,3),
   @FeaConvenio decimal(10,3), 
   @FleteTotalConvenio decimal(10,3),
   @TipoVuelo nvarchar(16),
   @CodigoContable nvarchar(16),
   @IdCliente nvarchar(16),
   @IdMercancia nvarchar(16),
   @Maa decimal(10,3),
   @Paa decimal(10,3),
   @Tra decimal(10,3) ,
   @AcuerdosComerciales decimal(10,3),
   @Reclamos decimal(10,3),
   @Bfa decimal(10,3),
   @TarifaCompra decimal(10,3),
   @TarifaVenta decimal(10,3),
   @TarifaMargen decimal(10,3),
   @IngresoXTarifa decimal(10,3),
   @IngresoXTarifaXKilo decimal(10,3),
   @IngresoNeto decimal(10,3),	
   @MargenSinBia decimal(10,3),
   @IngresoSinBia decimal(10,3),
   @RetencionFuente decimal(10,5),
   @Banderas varchar(30)
AS
BEGIN
BEGIN TRY
	DECLARE @ContarGuia INT
	SET @ContarGuia = 0
	IF @Banderas = 'SISTEMA'
	BEGIN
		
		SELECT @ContarGuia = count(*) 
      FROM liquidacionaerolineas 
      WHERE nroguia = @NroGuia AND transaccion = 'S'
		
		IF (@ContarGuia >0 ) 
		BEGIN
			
			--SOLO MODIFICA LAS transacciones que son del sistema (S) y que ademas esten abiertas
			UPDATE liquidacionaerolineas 
			SET 
			idaerolinea = @IdAerolinea, 
         cass = @Cass, destino = @Destino, 
         fechaembarque = @FechaEmbarque, 
         prepaid = @Prepaid,
         valorprepaid = @ValorPrepaid , 
         fletetotalreal = @FleteTotalReal, 
         fletetotalcorte = @FleteTotalCorte,
         pesobruto = @PesoBruto, pesocargable = @PesoCargable, fletenetoreal = @FleteNetoReal, tarifareal = @TarifaReal, fletenetocorte = @FleteNetoCorte,
         tarifacorte = @TarifaCorte, cca=@Cca, reclamo=@Reclamo, 
         descuento=@Descuento, cargosaerolinea=@CargoAerolinea, manejo=@Manejo, costosmanejo = @CostosManejo,costootros = @CostoOtros,
         utilidadmanejo = @UtilidadManejo, comision = @Comision, overcomision = @OverComision, 
         diferenciatarifas = @DiferenciaTarifas, cliente = @Cliente, consignatario=@Consignatario, origen = @Origen,
         codigoempresas = @CodigoEmpresas, fechacontable = @FechaContable, observaciones = @Observaciones,
         fechatransaccion = getdate(), tarifafsc = @TarifaFsc, tarifassc = @TarifaSsc, combustible = @Combustible, seguridad = @Seguridad,				
         empresa = @Empresa,
         urn = @Urn,
         cantidadfitos = @CantidadFitos,
         cantidadcertificadosorigen = @CantidadCertificadosOrigen,
         producto  = @Producto,
         cajasvoladas = @CajasVoladas,
         region=@Region,
         retencioniva=@RetencionIva,
         tarifaconvenio=@TarifaConvenio,
         fletenetoconvenio=@FleteNetoConvenio,
         biaconvenio=@BiaConvenio,
         feaconvenio=@FeaConvenio,
         fletetotalconvenio=@FleteTotalConvenio,
         tipoVuelo=@TipoVuelo,
         codigoContable=@CodigoContable,
         idCliente=@IdCliente,
         idMercancia=@IdMercancia,
         maa=@Maa,
         paa=@Paa,
         tra=@Tra,				
         reclamos=@Reclamos,
         comisioncliente = @ComisionCliente, 
         descuentocliente = @DescuentoCliente, 
         overcomisioncliente=@OverComisionCliente, 
         diferenciatarifascliente=@DiferenciaTarifasCliente,
         devolucioncliente=@DevolucionCliente,
         reclamocliente = @ReclamoCliente,				
         acuerdosComerciales=@AcuerdosComerciales,		
         bfa=@Bfa,
         tarifacompra=@TarifaCompra,
         tarifaventa = @TarifaVenta,
         tarifamargen = @TarifaMargen,
         ingresoxtarifa = @IngresoXTarifa,
         ingresoxtarifaxkilo = @IngresoXTarifaXKilo,
            ingresoneto = @IngresoNeto,
         margensinbia = @MargenSinBia,
         ingresosinbia = @IngresoSinBia,
         oacliente=@OaCliente,
         retencionfuente=@RetencionFuente
			WHERE nroguia = @NroGuia AND transaccion = 'S' AND cierre='ABIERTA'
		END
		ELSE
		BEGIN			
			DECLARE 
         @InicialCodigoEmpresas VARCHAR(1), 
         @IdSucursal INT, 
         @IdUnico CHAR(11)

			SET @InicialCodigoEmpresas = 'U'
			SET @IdSucursal = 1
			EXECUTE pro_GeneraridUnicoIntOut  'liquidacionaerolineas',@InicialCodigoEmpresas, @IdSucursal, @IdUnico OUT

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
         (@IdUnico, @NroGuia, @IdAerolinea, @Cass, @Destino, @FechaEmbarque, @Prepaid,
         @ValorPrepaid, @FleteTotalReal, @FleteTotalCorte,
         @PesoBruto, @PesoCargable, @FleteNetoReal, @TarifaReal, @FleteNetoCorte,
         @TarifaCorte, @FechaContable, @Cca, @Reclamo, @Descuento, @CargoAerolinea, @Manejo, @CostosManejo, @CostoOtros,
         @UtilidadManejo, @Comision, @OverComision, @OverComision2, @DiferenciaTarifas, @Cliente, @Consignatario, @Origen,
         @CodigoEmpresas, 'S', getdate(), @Observaciones, 'ABIERTA', @TarifaFsc, @TarifaSsc, @Combustible, @Seguridad, @FechaOver,
         @FechaManejo, @FechaComision, @FechaDescuento, @FechaOverComision, @FechaOverComision2, @FechaDiferenciaTarifas, @FechaReclamo, @Empresa, @Urn, @CantidadFitos ,
         @CantidadCertificadosOrigen, @Producto, @CajasVoladas, @Region, @RetencionIva,
         @TarifaConvenio, @FleteNetoConvenio, @BiaConvenio, @FeaConvenio, @FleteTotalConvenio, @TipoVuelo,
         @CodigoContable, @IdCliente, @IdMercancia, @Maa, @Paa, @Tra, @AcuerdosComerciales, @Reclamos,
         @ComisionCliente, @DescuentoCliente, @OverComisionCliente, @DiferenciaTarifasCliente, @DevolucionCliente, @ReclamoCliente, @Bfa, @TarifaCompra, @TarifaVenta, @TarifaMargen, @IngresoXTarifa, @IngresoXTarifaXKilo, @IngresoNeto, @MargenSinBia, @IngresoSinBia,@OaCliente, @RetencionFuente 
			)
		END
	RETURN
	END

	IF @Banderas = 'CERRAR'
	BEGIN
		UPDATE liquidacionaerolineas 
      SET cierre = @Cierre
      WHERE idaerolinea = @IdAerolinea AND transaccion = 'S' AND cierre='ABIERTA' AND empresa=@Empresa
	END

	IF @Banderas = 'OVERCOMISION'
	BEGIN
		UPDATE liquidacionaerolineas 
      SET overcomision = @OverComision, overcomision2=@OverComision2 
      WHERE id =@Id
		RETURN
	END	

	IF @Banderas = 'ELIMINAR'
	BEGIN
		DELETE FROM liquidacionaerolineas WHERE id = @Id
		RETURN
	END

	IF @Banderas = 'LIQUIDACIONCLIENTES'
	BEGIN
		print @NroGuia
		print @ComisionCliente
		
		UPDATE liquidacionaerolineas 
      SET comisioncliente = @ComisionCliente, descuentocliente = @DescuentoCliente, overcomisioncliente=@OverComisionCliente, diferenciatarifascliente=@DiferenciaTarifasCliente,
		devolucioncliente=@DevolucionCliente, transporteacuerdogg=@TransporteAcuerdoGg, oacliente=@OaCliente, oagg=@Oagg
		WHERE  nroguia=@NroGuia AND 
		(isnull(comisioncliente,0)<>@ComisionCliente OR isnull(descuentocliente,0)<>@DescuentoCliente OR isnull(overcomisioncliente,0)<>@OverComisionCliente OR isnull(diferenciatarifascliente,0)<>@DiferenciaTarifasCliente
		 OR isnull(devolucioncliente,0)<>@DevolucionCliente OR  isnull(transporteacuerdogg,0)<>@TransporteAcuerdoGg OR isnull(oacliente,0)<>@OaCliente OR isnull(oagg,0)<>@Oagg)
		RETURN
	END

	IF @Banderas = 'INGRESARDEVOLUCION'
	BEGIN
		print @NroGuia
		print @ComisionCliente
		
		UPDATE liquidacionaerolineas SET devolucion = @Devolucion
		WHERE  nroguia=@NroGuia AND 
		isnull(devolucion,0) <> @Devolucion
		RETURN
	END
	END TRY
		BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
GO

/*
EXEC [dbo].[AC_pro_LiquidacionAerolineasGuardar]
    @Id = '',
    @NroGuia = '12345678901',
    @IdAerolinea = '1234',
    @Cass = 'S',
    @Destino = 'UIO',
    @FechaEmbarque = '20260801',
    @Prepaid = 1,
    @ValorPrepaid = 0,
    @FleteTotalReal = 100,
    @FleteTotalCorte = 100,
    @PesoBruto = 10,
    @PesoCargable = 10,
    @FleteNetoReal = 100,
    @TarifaReal = '10',
    @FleteNetoCorte = 100,
    @TarifaCorte = '10',
    @FechaContable = '20260801',
    @Cca = '',
    @Reclamo = 0,
    @Descuento = 0,
    @CargoAerolinea = 0,
    @Manejo = 0,
    @CostosManejo = 0,
    @CostoOtros = 0,
    @UtilidadManejo = 0,
    @Comision = 0,
    @OverComision = 0,
    @OverComision2 = 0,
    @DiferenciaTarifas = 0,
    @Cliente = 'CLIENTE PRUEBA',
    @Consignatario = 'CONSIGNATARIO PRUEBA',
    @Origen = 'GYE',
    @CodigoEmpresas = '001',
    @Transaccion = 'S',
    @Observaciones = 'PRUEBA ESTANDARIZACION',
    @Pagar = 0,
    @Cobrar = 0,
    @TextoPagarCobrar = '',
    @TarifaFsc = 0,
    @TarifaSsc = 0,
    @Combustible = 0,
    @Seguridad = 0,
    @FechaOver = NULL,
    @VersionFila = 1,
    @FechaManejo = NULL,
    @FechaComision = NULL,
    @FechaDescuento = NULL,
    @FechaOverComision = NULL,
    @FechaOverComision2 = NULL,
    @FechaDiferenciaTarifas = NULL,
    @FechaReclamo = NULL,
    @Cierre = 'ABIERTA',
    @DiferenciaCass = 0,
    @StatusCass = 0,
    @ComisionCliente = 0,
    @ReclamoCliente = 0,
    @DescuentoCliente = 0,
    @OverComisionCliente = 0,
    @OverComision2Cliente = 0,
    @DiferenciaTarifasCliente = 0,
    @Devolucion = 0,
    @DevolucionCliente = 0,
    @CargosAgencia = 0,
    @TransporteAcuerdoGg = 0,
    @Oagg = 0,
    @OaCliente = 0,
    @Empresa = '001',
    @Urn = '',
    @CantidadFitos = 0,
    @CantidadCertificadosOrigen = 0,
    @Producto = '',
    @CajasVoladas = 0,
    @Region = '',
    @RetencionIva = 0,
    @TarifaConvenio = 0,
    @FleteNetoConvenio = 0,
    @BiaConvenio = 0,
    @FeaConvenio = 0,
    @FleteTotalConvenio = 0,
    @TipoVuelo = '',
    @CodigoContable = '',
    @IdCliente = '',
    @IdMercancia = '',
    @Maa = 0,
    @Paa = 0,
    @Tra = 0,
    @AcuerdosComerciales = 0,
    @Reclamos = 0,
    @Bfa = 0,
    @TarifaCompra = 0,
    @TarifaVenta = 0,
    @TarifaMargen = 0,
    @IngresoXTarifa = 0,
    @IngresoXTarifaXKilo = 0,
    @IngresoNeto = 0,
    @MargenSinBia = 0,
    @IngresoSinBia = 0,
    @RetencionFuente = 0,
    @Banderas = 'SISTEMA'
*/