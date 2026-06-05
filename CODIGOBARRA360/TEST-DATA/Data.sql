exec dbo.AC_pro_GetBarCodeExternal
	@fechaDesde='20210713',
	@fechaHasta='20260714',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>  <ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">    <string>PENDING</string>  </ArrayOfString>',
	@idCarrier=N'9Nlyxt0q6dGE',
	@idBodega=N'LXgyot5M',
	@fechaDespacho='20260413',
	@isDispatchCarrier=0,
	@esInventario=0,
	@EntityId=N'CLI013680',
	@shipToId=N'ETY011729',
	@UserType=N'GRUPOCLIENTE'
exec dbo.AC_pro_GetBarCodeExternal_Test
	@fechaDesde='20210713',
	@fechaHasta='20260714',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>  <ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">    <string>PENDING</string>  </ArrayOfString>',
	@idCarrier=N'9Nlyxt0q6dGE',
	@idBodega=N'LXgyot5M',
	@fechaDespacho='20260413',
	@isDispatchCarrier=0,
	@esInventario=0,
	@EntityId=N'CLI013680',
	@shipToId=N'ETY011729',
	@UserType=N'GRUPOCLIENTE'
exec dbo.pro_ConsultarCodigoBarrasClientes 
	@fechaDesde='20210713',
	@fechaHasta='20260714',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>  <ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">    <string>PENDING</string>  </ArrayOfString>',
	@idCarrier=N'9Nlyxt0q6dGE',
	@idBodega=N'LXgyot5M',
	@fechaDespacho='20260413',
	@isDispatchCarrier=0,
	@esInventario=0,
	@IdCliente=N'CLI013680',
	@idClienteFinal=N'CLI0116411'



exec dbo.AC_pro_GetBarCodeExternal
	@fechaDesde='20220101',
	@fechaHasta='20260423',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>  <ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">    <string>PENDING</string>   <string>RECEIVED WH</string> </ArrayOfString>',
	@isDispatchCarrier=0,
	@EntityId=N'CLI013680',
	@consigneeName=N'BOTANICA WHOLESALE HOUSTON',
	@consigneeId=N'ETY011765',
	@UserType=N'GRUPOCLIENTE'
exec dbo.pro_ConsultarCodigoBarrasClientes 
	@fechaDesde='20220101',
	@fechaHasta='20260423',
	@estado=N'<?xml version="1.0" encoding="utf-16"?>  <ArrayOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">    <string>PENDING</string>   <string>RECEIVED WH</string> </ArrayOfString>',
	@isDispatchCarrier=0,
	@IdCliente=N'CLI013680',
	@nombreClienteDistribucion=N'BOTANICA WHOLESALE HOUSTON'


-- 06-04-2026 / RC: 222194 / T: 95
exec dbo.pro_ConsultarCodigoBarrasClientes 
	@fechaDesde='2024-11-01 00:00:00',
	@fechaHasta='2026-05-02 23:59:00',
	@IdCliente=N'CLI0116266',
	@codBarra=N'un',
	@isDispatchCarrier=0
exec dbo.AC_pro_GetBarCodeExternal
	@fechaDesde='2024-11-01 00:00:00',
	@fechaHasta='2026-05-02 23:59:00',
	@EntityId=N'CLI0116266',
	@codBarra=N'un',
	@isDispatchCarrier=0,
	@UserType = 'GRUPOCLIENTE'
exec dbo.AC_pro_GetBarCodeExternal
	@fechaDesde='2024-11-01 00:00:00',
	@fechaHasta='2026-05-02 23:59:00',
	@EntityId=N'CLI0116266',
	@codBarra=N'un',
	@isDispatchCarrier=0,
	@UserType = 'GRUPOCLIENTE'
-- 07-04-2026 / RC: 226001 / T: 85	
exec dbo.pro_ConsultarCodigoBarrasClientes 
	@fechaDesde='2024-10-01 00:00:00',
	@fechaHasta='2026-05-09 23:59:00',
	@IdCliente=N'CLI0116266',
	@codBarra=N'un',
	@isDispatchCarrier=0
exec dbo.AC_pro_GetBarCodeExternal 
	@fechaDesde='2024-10-01 00:00:00',
	@fechaHasta='2026-05-09 23:59:00',
	@EntityId=N'CLI0116266',
	@codBarra=N'un',
	@isDispatchCarrier=0,
	@UserType = 'GRUPOCLIENTE'
-- 31-03-2026 / RC: 140680 / T: 56	
exec dbo.pro_ConsultarCodigoBarrasClientes 
	@fechaDesde='2024-01-01 00:00:00',
	@fechaHasta='2026-04-02 23:59:00',
	@IdCliente=N'CLI0127475',
	@codBarra=N'gm',
	@isDispatchCarrier=0
exec dbo.AC_pro_GetBarCodeExternal 
	@fechaDesde='2024-01-01 00:00:00',
	@fechaHasta='2026-04-02 23:59:00',
	@EntityId=N'CLI0127475',
	@codBarra=N'gm',
	@isDispatchCarrier=0,
	@UserType = 'GRUPOCLIENTE'

