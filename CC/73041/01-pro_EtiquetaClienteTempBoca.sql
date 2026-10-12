/*    
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Luis De Andrade     2019-07-06          ----            Creacion de sp pro_EtiquetaClienteTempBoca para etiqueta de cliente Boca  
2           Verónica Vicente    2020-09-25          ----            Se agreaga el Codigo de producto en la tabla CodigoBarraInfoAdicional, para que imprima de esta tabla cuando ingresa por XML  
3           Rogger Lindao       2021-08-06          ----            Modificacion para hacer inner join con codigosBarrasInfoAdicional ahora se lo hace con idPODEtalle  
4           Alex Rivera         2023-05-11          26555           Agregar campo nota de la tabla CodigosDeBarrasInfoAdicional
5           Jean Martillo       2024-09-04          43727           Modificacion de campo [itemNo], [shipTo], [tipoPieza], [codigoProducto] relacionados con la tabla CodigosDeBarrasInfoAdicional para que tengan los mismos valores 
6           Jair Gomez          2026-10-12          73041           Truncate the “note” (BoxCode / shipTo) field from 6 to 5 characters to prevent a break in the Telerik label layout.
*/  
  
CREATE OR ALTER PROCEDURE [dbo].[pro_EtiquetaClienteTempBoca]   
 (@codigos AS XML)  
AS  
BEGIN  
	DECLARE @query AS NVARCHAR(MAX);  
	
	DECLARE @tablaCodigos TABLE (
	idCodigo UNIQUEIDENTIFIER)  
  
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
		[codigoShipTo] [VARCHAR](512) NULL,  
		[sufijoCodigoBarra] [VARCHAR](6) NULL,  
		[ultimosTresDigitosCB] [VARCHAR](128) NULL  
	) ON [PRIMARY]  
  
	INSERT INTO @tablaCodigos (idCodigo)     
	SELECT codigosDeBarraXML.codigo.value('.','NVARCHAR(64)') AS idCodigoDeBarra   
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
	CASE WHEN G.tipoGuia = 'DISTRIBUCION' THEN (SELECT GC.nroGuia  
													FROM guias GC WITH (NOLOCK)  
													WHERE GC.id = G.idGuiaConsolidada)   
		ELSE G.nroGuia   
	END AS nroGuia,   
	PO.codigo,  
	PD.codigo,  
	NULL,
	COO.house,  
	CBI.itemNo,  
	IIF(CBI.codigoProducto IS NULL,IIF(CRB.codigo IS NULL,CRP.codigo,CRB.codigo),CBI.codigoProducto ) AS codigoProducto,
	IIF(CBI.tipoPiezaEntidad IS NULL, ITC.empaque,CBI.tipoPiezaEntidad),  
	ITC.unidades,  
	SUBSTRING(ITC.descripcionVariedad, 0, 42),  
	ITC.po,  
	ITC.codigoPieza,  
	NULL as totalPiezas,
	CLI.nombre,  
	CONCAT(CCE.nombre,ISNULL(', ' + ECE.codigoISO,' ') + ISNULL(CLE.codigozip, '')),  
	ITC.caja_transportador,  
	IIF(ITC.fecha_transportador IS NULL,'', '-' + UPPER(FORMAT(ITC.fecha_transportador,'ddd','en-us'))),  
	EX.mid,  
	LEFT(CBI.nota, 5) AS shipTo,  
	SUBSTRING(ITC.codigoPieza, 4, 6),  
	SUBSTRING(ITC.codigoPieza, 9, 4)  
	FROM InventarioTemporalCliente AS ITC WITH (NOLOCK)    
	INNER JOIN Coordinaciones AS COO WITH (NOLOCK) ON COO.id = ITC.idCoordinacion     
	INNER JOIN Guias AS G WITH (NOLOCK) ON G.id = COO.idGuia    
	INNER JOIN Puertos AS PO ON PO.id = G.idPuertoOrigen  
	INNER JOIN Puertos AS PD ON PD.id = G.idPuertoDestino  
	INNER JOIN Clientes AS CLI ON G.idCliente = CLI.id  
	INNER JOIN Exportadores AS EX ON COO.idExportador = EX.id  
	LEFT OUTER JOIN GrupoExportadores AS GE ON EX.idGrupo = GE.id     
	LEFT JOIN CoordinacionInventarioTemporal AS CI on ITC.id = CI.idInventarioTemporalCliente  
	LEFT JOIN CodigosDeBarrasInfoAdicional AS CBI WITH (NOLOCK) ON CI.idPoDetalle = CBI.idPoDetalle  
	LEFT OUTER JOIN CodigosRelacionSistemas AS CRP ON ( ITC.codigoProducto = CRP.codigo AND CRP.idSistemaEntidad = 100 AND CRP.tipoEntidad = 'MERCANCIAS')  
	LEFT OUTER JOIN CodigosRelacionSistemas AS CRB ON ( ITC.codigoProducto = CRB.codigo AND CRP.idEntidad = CRB.idEntidad AND CRB.idSistemaEntidad = 115 AND CRB.tipoEntidad = 'MERCANCIAS')  
	LEFT OUTER JOIN CodigosRelacionSistemas AS CRS ON ( ITC.codigoCliente = CRS.codigo AND CRS.idSistemaEntidad = 100 AND CRS.tipoEntidad = 'CLIENTE')      
	LEFT OUTER JOIN Clientes AS CLE ON CRS.idEntidad = CLE.id   
	LEFT OUTER JOIN Ciudades AS CCE ON CLE.idCiudad = CCE.id   
	LEFT OUTER JOIN Estados AS ECE ON CLE.idEstado = ECE.id  
	WHERE ITC.id IN (SELECT idCodigo FROM @tablaCodigos)  
  
	UPDATE  #Etiqueta  
	SET     totalPiezas = Cnt  
	FROM    #Etiqueta AS ss  
	INNER JOIN (SELECT nroPo,sufijoCodigoBarra, COUNT(1) AS Cnt   
				FROM #Etiqueta   
				GROUP BY nroPo,sufijoCodigoBarra) AS s  
				ON (ss.nroPo = s.nroPo OR ss.nroPo IS NULL AND s.nroPo IS NULL)  AND ss.sufijoCodigoBarra=s.sufijoCodigoBarra  
  
	SELECT   
	RIGHT(1000 + (ROW_NUMBER() OVER (PARTITION BY nroPo,sufijoCodigoBarra ORDER BY nroPo,sufijoCodigoBarra,ultimosTresDigitosCB ASC)), 3) AS pagina,
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
	ORDER BY nroPo,sufijoCodigoBarra,pagina,ultimosTresDigitosCB,codigoProducto,descripcionProducto,codigoBarra ASC
DROP TABLE #Etiqueta  
END  
  
/*  
declare @p1 xml  
set @p1=convert(xml,N'<codigos><c>DBFB3F69-7D62-46D1-8124-F87F16B028E9</c><c>21DFEBAF-822A-4130-88AB-F8ACE50B1DE8</c><c>8713B21F-F960-4AE0-B092-3C233D3B2A65</c></codigos>')  
exec pro_EtiquetaClienteTempBoca_pcg @codigos=@p1

set @p1=convert(xml,N'<codigos><c>1F5E2253-3CE1-44A0-A5BC-D67D285B4B08</c></codigos>')
exec pro_EtiquetaClienteTempBoca @codigos=@p1
*/