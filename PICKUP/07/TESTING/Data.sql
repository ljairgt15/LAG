    Use alliance_desa
	EXEC [dbo].AC_pro_GetCompletedDeliveredPickupDetail
    @FechaDesde                 = '2026-01-03',
    @FechaHasta                 = '2026-01-05',
    @idEmpresa                  = 'EMP014';
    
	EXEC [dbo].pro_Despacho_PickUpDetalleCompleteDelivered
    @FechaDesde                 = '2026-01-03',
    @FechaHasta                 = '2026-01-05',
    @idEmpresa                  = 'EMP014';

    EXEC [dbo].AC_pro_GetCompletedDeliveredPickupDetail
    @FechaDesde                 = '2026-01-01',
    @FechaHasta                 = '2026-01-03',
    @NroDocumento               = NULL,
    @Po                         = NULL,
    @NombreClienteConsignee     = NULL,
    @NroPod                     = NULL,
    @CodigoBarras               = NULL,
    @NombreComercialExportador  = NULL,
    @IdManifiesto               = '8c03f16f-17bb-4606-b24a-49f1a1ec531d',
    @IdCarrier                  = 'ybOy4oex7F5E',
    @IdClienteFinal             = 'ETY0000000032873',
    @IdBodega                   = 'QK6s23du',
    @FechaPickUpProgramada      = '2026-01-02',
    @FechaPickUpEntrega         = '2026-01-02',
    @PalletLabel                = NULL,
    @IdEmpresa                  = 'EMP014',
    @BillTo                     = NULL;

	
	EXEC [dbo].[pro_Despacho_PickUpDetalleCompleteDelivered]
    @FechaDesde                 = '2026-01-01',
    @FechaHasta                 = '2026-01-03',
    @NroDocumento               = NULL,
    @Po                         = NULL,
    @NombreClienteConsignee     = NULL,
    @NroPod                     = NULL,
    @CodigoBarras               = NULL,
    @NombreComercialExportador  = NULL,
    @IdManifiesto               = '8c03f16f-17bb-4606-b24a-49f1a1ec531d',
    @IdCarrier                  = 'ybOy4oex7F5E',
    @IdClienteFinal             = 'CLI0515731',
    @IdBodega                   = 'QK6s23du',
    @FechaPickUpProgramada      = '2026-01-02',
    @FechaPickUpEntrega         = '2026-01-02',
    @PalletLabel                = NULL,
    @IdEmpresa                  = 'EMP014';
