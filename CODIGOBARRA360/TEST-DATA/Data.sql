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