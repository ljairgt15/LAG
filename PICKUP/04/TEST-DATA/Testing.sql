	EXEC [dbo].[AC_pro_GetPendingPickupDetails]
    @Pending         = 0,       
    @Consulta        = 2,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';

	EXEC [dbo].[AC_pro_GetPendingPickupDetails]
	@NroDocument     = null,
	@PO = null,
	@Consignee = 'A PERRI FARMS INC.',
	@NroManifiesto   =null,
	@Supplier = 'STARFLOWERS CIA. LTDA.',
	@PalletLabel = null,
    @Barcode = null,
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
	@NroDocument     = null,
	@PO = null,
	@Consignee = 'A PERRI FARMS INC.',
	@NroManifiesto   =null,
	@Supplier = 'STARFLOWERS CIA. LTDA.',
	@PalletLabel = null,
    @Barcode = null,
    @Pending         = 0,       
    @Consulta        = 2,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';