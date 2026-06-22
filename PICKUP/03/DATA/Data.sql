	EXEC [dbo].[pro_modulo_DespachoPickup]    
    @Consulta        = 1,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';
	EXEC [dbo].AC_pro_GetPendingPickup    
    @Consulta        = 1,
    @FechaDesde      = 3,
	@IdEmpresa       ='EMP014';