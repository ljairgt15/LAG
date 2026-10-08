/*    
VERSION  AUTOR             FECHA        HU        CAMBIO  
1        Luis De Andrade   06/07/2019   ----      Creacion de sp pro_EtiquetaClienteBoca para etiqueta de cliente Boca  
2        Verónica Vicente  25/09/2020   ----      Se agreaga el Codigo de producto en la tabla CodigoBarraInfoAdicional, para que imprima de esta tabla cuando ingresa por XML  
3        Rogger Lindao     16/10/20220  ----      Se cambia el orden como se generan los CB ahora lo hace por sufijo de codigo barra y pagina de forma ascendente  
4        Alex Rivera       11/05/2023   26555     Agregar campo nota de la tabla CodigosDeBarrasInfoAdicional  
5        Jean Martillo     04/09/2024   43727     Modificacion de campos [itemNo],[codigoProducto],[tipoPieza],[codigoShipTo] relacionados con la tabla CodigosDeBarrasInfoAdicional para que tengan los mismos valores  
6        Jair Gomez        08/10/2026   73041     Se modifica la longitud del campo nota (BoxCode / shipTo) de 6 a 5 caracteres para evitar ruptura en el diseño de la etiqueta Telerik.
*/  
  
CREATE OR ALTER PROCEDURE [dbo].[pro_EtiquetaClienteBoca]   
	(@codigos AS XML)  
AS  
BEGIN  
	DECLARE @query AS NVARCHAR(MAX);  
	DECLARE @tablaCodigos TABLE 
	(idCodigo VARCHAR(50));  
  
	CREATE TABLE [dbo].[#Etiqueta](  
		[nroGuia] [VARCHAR](21) NULL,  
		[codigoPuertoOrigen] [VARCHAR](16) NULL,  
		[codigoPuertoDestino] [VARCHAR](16) NULL,  
		[codigoExportador] [NVARCHAR](256) NULL,  
		[house] [VARCHAR](16) NULL,  
		[itemNo] [VARCHAR](512) NULL,  
		[codigoProducto] [VARCHAR](512) NULL,  
		[tipoPieza] [VARCHAR](512) NULL,  
		[unidadesPiezas] [INT] null,  
		[descripcionProducto] [VARCHAR](256) NULL,  
		[nroPo] [VARCHAR](64) NULL,  
		[codigoBarra] [VARCHAR](16)  NULL,  
		[totalPiezas][VARCHAR](16) NULL,  
		[nombreCliente] [NVARCHAR](512) NULL,  
		[direccionShipTo] [NVARCHAR](512) NULL,  
		[nombreSubCarrierDestino] [VARCHAR](32) NULL,  
		[fechaDespacho][VARCHAR](16) NULL,  
		[codigoMidExportador] [NVARCHAR](64) NULL,  
		[codigoShipTo] [VARCHAR](256) NULL,  
		[sufijoCodigoBarra] [VARCHAR](128) NULL,  
		[ultimosTresDigitosCB] [VARCHAR](128) NULL  
	) ON [PRIMARY]  
  
	INSERT INTO @tablaCodigos (idCodigo)     
	SELECT codigosDeBarraXML.codigo.value('.','NVARCHAR(16)') AS idCodigoDeBarra   
	FROM @codigos.nodes('//c') AS codigosDeBarraXML(codigo);  
  
	INSERT INTO #Etiqueta (  
	[nroGuia],  
	[codigoPuertoOrigen],  
	[codigoPuertoDestino],  
	[codigoExportador],  
	[house],  
	[itemNo],  
	[codigoProducto],  
	[tipoPieza],  
	[unidadesPiezas],  
	[descripcionProducto],  
	[nroPo],  
	[codigoBarra],  
	[totalPiezas],  
	[nombreCliente],  
	[direccionShipTo],  
	[nombreSubCarrierDestino],  
	[fechaDespacho],  
	[codigoMidExportador],  
	[codigoShipTo],  
	[sufijoCodigoBarra],  
	[ultimosTresDigitosCB])  
	SELECT   
	CASE WHEN guia.tipoGuia = 'DISTRIBUCION' THEN  
		(SELECT guiaConsolidada.nroGuia  
		FROM guias guiaConsolidada  
		WHERE guiaConsolidada.id = guia.idGuiaConsolidada)   
		ELSE guia.nroGuia   
	END AS nroGuia,   
	PO.codigo,  
	PD.codigo,  
	NULL, --YA NO SE USA EL CODIGO DE EXPORTADOR  
	CO.house,  
	CBI.itemNo,  
	IIF(CBI.codigoProducto IS NULL,IIF(CRB.codigo IS NULL,CRP.codigo,CRB.codigo),CBI.codigoProducto),--[codigoProducto]  
	CBI.tipoPiezaEntidad,  
	CONVERT(INT, CB.unidades),  
	SUBSTRING(CB.descripcionVariedad, 0, 42),  
	CB.po,  
	CB.codigoBarra,  
	NULL, --[totalPiezas]  
	CL.nombre,  
	CONCAT(CCE.nombre,ISNULL(', ' + ECE.codigoISO,' ') + CLE.codigozip),  
	CB.caja_transportador,  
	IIF(CB.caja_fecha_transportador IS NULL,'', UPPER(FORMAT(CB.caja_fecha_transportador,'ddd','en-us'))),  
	EX.mid,  
	LEFT(CBI.nota, 5) AS shipTo,  
	SUBSTRING(CB.codigoBarra, 4, 6),  
	SUBSTRING(CB.codigoBarra, 9, 4)  
	FROM dbo.CodigosDeBarra CB WITH (NOLOCK)  
	INNER JOIN dbo.Coordinaciones AS CO  WITH (NOLOCK) ON CO.id = CB.idCoordinacion  
	INNER JOIN  dbo.Guias AS guia WITH (NOLOCK) ON guia.id = CO.idGuia  
	INNER JOIN dbo.Puertos AS PO ON PO.id = guia.idPuertoOrigen  
	INNER JOIN dbo.Puertos AS PD ON PD.id = guia.idPuertoDestino  
	INNER JOIN dbo.Clientes AS CL  ON guia.idCliente = CL.id  
	INNER JOIN dbo.Exportadores AS EX ON CO.idExportador = EX.id  
	LEFT OUTER JOIN GrupoExportadores AS GE ON EX.idGrupo = GE.id     
	LEFT OUTER JOIN (SELECT CBI.codigoBarra, 
						CBI.codigoBarraEntidad, 
						CBI.itemNo, 
						CBI.codigoCientificoProducto, 
						CBI.codigoProducto, 
						CBI.fechaEntregaSupermercado, 
						CBI.tipoPiezaEntidad, 
						CBI.shipTo, 
						CBI.nota, 
						CBI.fechaCambio, ROW_NUMBER() OVER ( partition BY codigoBarra ORDER BY fechaCambio DESC ) AS idRow   
						FROM dbo.CodigosDeBarrasInfoAdicional CBI WITH (NOLOCK)
						) AS CBI  ON CB.codigoBarra = CBI.codigoBarra AND idRow = 1  
	LEFT OUTER JOIN dbo.CodigosRelacionSistemas CRP ON ( CB.codigoProducto = CRP.codigo AND CRP.idSistemaEntidad = 100 AND CRP.tipoEntidad = 'MERCANCIAS')  
	LEFT OUTER JOIN dbo.CodigosRelacionSistemas CRB ON ( CRP.idEntidad = CRB.idEntidad AND CRB.idSistemaEntidad = 115 AND CRB.tipoEntidad = 'MERCANCIAS')  
	LEFT OUTER JOIN dbo.CodigosRelacionSistemas crs ON ( CB.codigoCliente = crs.codigo AND crs.idSistemaEntidad = 100 AND crs.tipoEntidad = 'CLIENTE')  
	LEFT OUTER JOIN dbo.Clientes AS CLE ON crs.idEntidad = CLE.id   
	LEFT OUTER JOIN dbo.Ciudades AS CCE ON CLE.idCiudad = CCE.id   
	LEFT OUTER JOIN dbo.Estados AS ECE ON CLE.idEstado = ECE.id  
	WHERE CB.id IN (SELECT idCodigo FROM @tablaCodigos)  
  
	UPDATE  #Etiqueta  
	SET     totalPiezas = Cnt  
	FROM    #Etiqueta AS ss  
	INNER JOIN (SELECT nroPo,sufijoCodigoBarra, COUNT(1) AS Cnt   
	FROM #Etiqueta GROUP BY nroPo,sufijoCodigoBarra) AS s  
	ON (ss.nroPo = s.nroPo OR ss.nroPo IS NULL AND s.nroPo IS NULL) AND ss.sufijoCodigoBarra=s.sufijoCodigoBarra  
  
	SELECT   
	RIGHT(1000 + (ROW_NUMBER() OVER (PARTITION BY nroPo,sufijoCodigoBarra ORDER BY nroPo,sufijoCodigoBarra,ultimosTresDigitosCB ASC)), 3) AS pagina,--CONTADOR DE ETIQUETAS  
	[nroGuia],  
	[codigoPuertoOrigen] + '-' + [codigoPuertoDestino] AS [codigoPuertoOrigen],  
	NULL,  
	[codigoExportador],  
	[house],  
	[itemNo],  
	[codigoProducto],  
	[tipoPieza],  
	[unidadesPiezas],  
	[descripcionProducto],  
	[nroPo],  
	[codigoBarra],  
	RIGHT(1000 + [totalPiezas], 3) AS [totalPiezas],  
	SUBSTRING([nombreCliente], 0, 25) AS nombreCliente,  
	[direccionShipTo],  
	[nombreSubCarrierDestino] + [fechaDespacho] AS [nombreSubCarrierDestino],  
	NULL,  
	[codigoMidExportador],  
	[codigoShipTo] AS codigoShipTo  
	FROM #Etiqueta  
	ORDER BY nroPo,sufijoCodigoBarra,pagina,ultimosTresDigitosCB,codigoProducto,descripcionProducto,codigoBarra ASC --RL 16/10/2020 se agrupa y ordena por PO y sufijoy pagina generada  
  
DROP TABLE #Etiqueta  
END
  
/*  
declare @p1 xml  
set @p1=convert(xml,N'<codigos><c>CDB12121452</c></codigos>')  
exec dbo.pro_EtiquetaClienteBoca @codigos=@p1  
*/  