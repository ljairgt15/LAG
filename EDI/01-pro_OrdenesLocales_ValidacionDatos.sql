 ALTER   Procedure [dbo].[pro_OrdenesLocales_ValidacionDatos](
 	@listaOrdenLocal VARCHAR(MAX))
 as
 
 DECLARE @DatosEntradaOrdenLocal table (id int, unitId varchar(16),  shipDate DateTime, shipper varchar(16), 
  Consignee varchar(32), accion varchar(12)  )

  DECLARE @tableTemp table 
( 
	id int  IDENTITY(1,1),
	codigoBarraEntrada varchar(16),
	codigoBarraBase varchar(16) ,
	shipperEntrada varchar(16),
	shipperBase varchar(16),
	consigneeEntrada varchar(32),
	consigneeBase varchar(32),
	shipdateEntrada DateTime,
	shipdateBase DateTime , 
	idOrdenLocal uniqueidentifier,
	idGHDetalle uniqueidentifier,
	idGuiaHouse uniqueidentifier,
	idPoDetalle uniqueidentifier,
	idPoEncabezado uniqueidentifier,
	estadoPieza varchar(16),
	accion varchar(12)  
   )
 begin 

INSERT INTO @DatosEntradaOrdenLocal
  (unitId , Shipper, Shipdate, Consignee)

	SELECT unitId , Shipper ,Shipdate , Consignee
	FROM OPENJSON(@listaOrdenLocal)
	WITH (unitId varchar(16)'$.UnitID', 
	Shipper varchar(16)'$.Shipper',
	Shipdate Datetime'$.Shipdate',
	Consignee varchar(32)'$.Consignee')

insert into @tableTemp 
	(
	codigoBarraEntrada,
	codigoBarraBase, 
	shipperEntrada,
	shipperBase, 
	consigneeEntrada,
	consigneeBase, 
	shipdateEntrada,
	shipdateBase, 
	idOrdenLocal,
	idGHDetalle,
	idGuiaHouse,
	idPoDetalle,
	idPoEncabezado,
	estadoPieza,
	accion
	)
 select 
	temp.unitId,
	pd.codigoBarra,  
	temp.shipper ,
	ol.idExportador,
	temp.Consignee,
	ol.idCliente ,
	temp.shipDate,
	ol.fechaEntrega, 
	ol.Id,
	ghd.id,
	ghd.idGuiaHouse, 
	pd.id,
	poe.id,
	ghd.estadoPieza,
    temp.accion 
	from @DatosEntradaOrdenLocal temp 
 left join PoDetalles pd on temp.unitId = pd.codigoBarra
 left join PoEncabezado poe on pd.idPo =  poe.id
 left join OrdenesLocales ol on poe.idOrdenLocal = ol.id
 left join GuiasHouseDetalles ghd on  temp.unitId = ghd.codigoBarra

update temp set temp.accion=  
CASE when  codigoBarraBase is  null and consigneeBase  is null and shipperBase is null and shipdateBase is null then  'i'
else CASE when consigneeBase = consigneeEntrada and shipperBase = shipperEntrada and shipdateEntrada = shipdateBase and estadoPieza = 'PENDING'  then 'u'
else CASE when consigneeBase = consigneeEntrada and shipperBase = shipperEntrada and shipdateEntrada = shipdateBase and estadoPieza <> 'PENDING' then  'es'
else 'e' end end end
 
from @tableTemp temp

select id, codigoBarraEntrada,codigoBarraBase,shipperEntrada,shipperBase, consigneeEntrada,
	 consigneeBase, shipdateEntrada, shipdateBase, idOrdenLocal, idGHDetalle,
	 idGuiaHouse,	idPoDetalle, idPoEncabezado, estadoPieza, accion 
	 from @tableTemp	

 end