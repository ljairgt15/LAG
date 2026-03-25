	EXEC [dbo].[AC_pro_GetCompletedScheduledPickupDetail] 
    @FechaDesde = '2026-01-04',
    @FechaHasta = '2026-01-05',
    @IdEmpresa  = 'EMP014';

	EXEC [dbo].[pro_Despacho_PickUpDetalleCompleteScheduled]
    @FechaDesde = '2026-01-04',
    @FechaHasta = '2026-01-05',
    @IdEmpresa  = 'EMP014';



	    EXEC [dbo].[AC_pro_GetCompletedScheduledPickupDetail]
    @FechaDesde                 = '2026-01-03',
    @FechaHasta                 = '2026-01-05',
    @NroDocumento               = NULL,
    @Po                          = NULL,
    @NombreClienteConsignee     = NULL,
    @NroPod                     = NULL,
    @CodigoBarras               = NULL,
    @NombreComercialExportador  = NULL,
    @IdManifiesto               = 'BFB80C7A-AF03-415A-8517-2A2121F13D7B',
    @IdCarrier                  = 'ZWYOb294',
    @IdClienteFinal             = 'ETY000121625',
    @IdBodega                   = 'QK6s23du',
    @FechaPickUpProgramada      = '2026-01-03',
    @FechaPickUpEntrega         = '2026-01-02',
    @PalletLabel                = NULL,
    @IdEmpresa                  = 'EMP014',
    @BillTo                     = NULL;

	EXEC [dbo].[AC_pro_GetCompletedScheduledPickupDetail]
    @FechaDesde                 = '2026-01-04',
    @FechaHasta                 = '2026-01-05',
    @NroDocumento               = NULL,
    @Po                         = NULL,
    @NombreClienteConsignee     = NULL,
    @NroPod                     = NULL,
    @CodigoBarras               = NULL,
    @NombreComercialExportador  = NULL,
    @IdManifiesto               = 'cc6e1877-4e65-455a-bad8-7bcc5c79a12a',
    @IdCarrier                  = 'znfINmvW',
    @IdClienteFinal             = 'ETY0000000036142',
    @IdBodega                   = 'QK6s23du',
    @FechaPickUpProgramada      = '2026-01-05',
    @FechaPickUpEntrega         = '2026-03-24',
    @PalletLabel                = NULL,
    @IdEmpresa                  = 'EMP014',
    @BillTo                     = NULL;

	EXEC [dbo].[pro_Despacho_PickUpDetalleCompleteScheduled]
    @FechaDesde                 = '2026-01-04',
    @FechaHasta                 = '2026-01-05',
    @NroDocumento               = NULL,
    @Po                         = NULL,
    @NombreClienteConsignee     = NULL,
    @NroPod                     = NULL,
    @CodigoBarras               = NULL,
    @NombreComercialExportador  = NULL,
    @IdManifiesto               = 'cc6e1877-4e65-455a-bad8-7bcc5c79a12a',
    @IdCarrier                  = 'znfINmvW',
    @IdClienteFinal             = 'CLI0519087',
    @IdBodega                   = 'QK6s23du',
    @FechaPickUpProgramada      = '2026-01-05',
    @FechaPickUpEntrega         = '2026-03-24',
    @PalletLabel                = NULL,
    @IdEmpresa                  = 'EMP014';
