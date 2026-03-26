	EXEC [dbo].[AC_pro_GetPendingPickupDetails]
    @Pending         = 0,       
    @Consulta        = 2,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';

	EXEC [dbo].[AC_pro_GetPendingPickupDetails]
	--@NroDocument     = '36998315604',
	--@PO = 'LUNES',
	--@Consignee = 'A PERRI FARMS INC.',
	--@NroManifiesto   ='H584299',
	--@Supplier = 'STARFLOWERS CIA. LTDA.',
	--@PalletLabel = 'H4P0219260034',
    @Barcode = 'PM12756434',
    @Pending         = 0,       
    @Consulta        = 2,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';

	EXEC [dbo].[pro_Despacho_DespachoDetallePickUp]
    @Pending         = 0,       
    @Consulta        = 2,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';


	EXEC [dbo].[pro_Despacho_DespachoDetallePickUp]
	@NroDocument     = '36998315604',
	@PO = 'LUNES',
	@Consignee = 'A PERRI FARMS INC.',
	@NroManifiesto   = 'H584299',
	@Supplier = 'STARFLOWERS CIA. LTDA.',
	@PalletLabel = 'H4P0219260034',
    @Barcode = 'PM12756434',
    @Pending         = 0,       
    @Consulta        = 2,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';