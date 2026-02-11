-------------------------------------------------------------------------
--  [pro_reportes_analiticadespachoconsolidado]
--               
--  Sp para actualizar house sin transaccion para el nuevo sp de coordinacion
--
--  VERSION		AUTOR					FECHA			HU			CAMBIO
--  1			Jesus Yandun			12-10-2020		-       	Codigo Inicial
--  2           Rogger Lindao           27-04-2022      18196       Se agregan los noLock a tbalas concurrentes
--  3			Jorge					22-08-2022		20206		Cambio @clientesSelecciondos a Tabla Temporal. Causaba una gran cantidad de lecturas fisicas. Se realizo en conjunto con DBA. 
--																	Add execute test y se aplico estandares de base de datos
-------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[pro_reportes_analiticadespachoconsolidado]
(
	@clientes			VARCHAR(MAX),
	@fechaDesde			DATETIME,
	@fechaHasta			DATETIME
)
AS
BEGIN
	-- Tabla de Clientes Seleccionados
	 CREATE TABLE #ClientesSeleccionados(
		id					VARCHAR(16) PRIMARY KEY,
		nombre				NVARCHAR(1024),
		alias				NVARCHAR(1024)
	)

	-- Tabla de resultados preliminares
	DECLARE @Preliminar TABLE(
		idConsignatario		VARCHAR(16),
		consignatario		NVARCHAR(1024),
		shipper				NVARCHAR(1024),
		[status]			VARCHAR(64),
		awb					VARCHAR(32),
		origin				NVARCHAR(128),
		poNumber			VARCHAR(64),
		[type]				VARCHAR(8),
		equivalencia		DECIMAL(18,5),
		alto				DECIMAL(18,3),
		largo				DECIMAL(18,3),
		ancho				DECIMAL(18,3),
		boxes				INT,
		totalPcsHouse		INT,
		totalFullHouse		DECIMAL(18,3),
		fechaDespacho		datetime,
		idGuiaHouse			uniqueidentifier,
		idGuiaHouseDetalle	uniqueidentifier,
		idPo				uniqueidentifier,
		idPoDetalle			uniqueidentifier,
		carrier				NVARCHAR(1024),
		shipTo				NVARCHAR(1024)
	)

	-- Separar la lista de clientes en una tabla
	INSERT INTO #ClientesSeleccionados (id)
	SELECT VALUE FROM STRING_SPLIT(@clientes, ',')

	-- Obtener los nombres de los clientes enviados
	UPDATE	#ClientesSeleccionados
	SET		nombre	= C.nombre,
			alias	= C.alias
	FROM	#ClientesSeleccionados		 CS
		INNER JOIN	Clientes	C	ON C.id = CS.id

	-- Informaci�n preliminar para el reporte (Guias House)
	INSERT INTO @Preliminar 
	SELECT
			idConsignatario		= CS.id,
			consignatario		= CS.nombre,
			shipper				= EX.nombre,
			[status]			= HD.estadoPieza,
			awb					= HE.nroGuia,
			origin				= CD.nombre,
			poNumber			= HD.po,
			[type]				= TP.tipoPieza,
			equivalencia		= TP.equivalencia,
			alto				= HD.altoIn,
			largo				= HD.largoIn,
			ancho				= HD.anchoIn,
			boxes				= 1,
			totalPcsHouse		= HE.totalPcsHouse,
			totalFullHouse		= HE.totalFullHouse,
			fechaDespacho		= PC.fechaDespacho,
			idGuiaHouse			= HE.id,
			idGuiaHouseDetalle	= HD.id,
			idPo				= null,
			idPoDetalle			= HD.idPoDetalle,
			carrier				= TS.nombre,
			--shipTo = CL.nombreClienteFinal,
			CASE CL.nombreClienteFinal
			WHEN '' THEN
				CL.nombreClienteFinal
			ELSE
				CL.nombre
			END
			
	FROM	#ClientesSeleccionados		CS
		inner join GuiasHouse			HE WITH(NOLOCK)	ON	HE.idCliente = CS.id 
		inner join GuiasHouseDetalles	HD WITH(NOLOCK)	ON	HD.idGuiaHouse = HE.id
		inner join ProgramacionCarrier	PC WITH(NOLOCK)	ON	PC.idGuiaHouseDetalle = HD.id
		inner join Exportadores			EX WITH(NOLOCK)	ON	EX.id = HE.idExportador
		inner join TiposDePieza			TP WITH(NOLOCK)	ON	TP.id = HD.idTipoDePieza
		inner join Ciudades				CD WITH(NOLOCK)	ON	CD.id = HE.idCiudadPuertoOrigen
		inner join Transportes			TS WITH(NOLOCK)  ON  PC.idCarrier = TS.id
		inner join Clientes				CL WITH(NOLOCK)  ON  HD.idClienteFinal = CL.id
	WHERE
			PC.fechaDespacho	>=	@fechaDesde
		and	PC.fechaDespacho	<=	@fechaHasta and HD.estadoPieza in ('DISPATCHED WH','RECEIVED DR','RECEIVED WH','PENDING')


	-- Excluye las ordenes locales que ya fueron canceladas
    DELETE PRE FROM @Preliminar PRE 
		inner join	PoDetalles			PD WITH(NOLOCK) 	ON	PD.id = PRE.idPoDetalle
		inner join	PoEncabezado		PE WITH(NOLOCK)	ON	PE.id = PD.idPo
		inner join	OrdenesLocales		OL WITH(NOLOCK)	ON	OL.id = PE.idOrdenLocal
	    inner join	Catalogos			CA WITH(NOLOCK)	ON	CA.id = OL.idCatalogoStatus
    WHERE  CA.codigoRelacion ='CANCELADO'

	
	-- SET el la variable local  para distinguir que es orden local
		UPDATE	@Preliminar
	SET		
			idPo		= PE.id,
			awb			= 'LOCAL'
	FROM	@Preliminar					PRE
		inner join	PoDetalles			PD WITH(NOLOCK)	ON	PD.id = PRE.idPoDetalle
		inner join	PoEncabezado		PE WITH(NOLOCK)	ON	PE.id = PD.idPo
		inner join	OrdenesLocales		OL WITH(NOLOCK)	ON	OL.id = PE.idOrdenLocal

	-- Se actualiza la ciudad para las POs en base a la ciudad de la empresa
	UPDATE	@Preliminar
	SET		origin		= CD.nombre
	FROM	@Preliminar					PRE
		inner join PoDetalles			PD WITH(NOLOCK)	ON	PD.id = PRE.idPoDetalle
		inner join PoEncabezado			PE WITH(NOLOCK)	ON	PE.id = PD.idPo
		inner join Empresas				EM WITH(NOLOCK)	ON	EM.id = PE.idEmpresa
		inner join Ciudades				CD WITH(NOLOCK)	ON	CD.id = EM.idCiudad


	UPDATE	@Preliminar
	SET		poNumber	= null
	WHERE	poNumber	= ''

	-- Resultado final
	SELECT
			id				= CONVERT(VARCHAR(64), NEWID()),
			idConsignatario  ='',
			consignatario   ='',
			shipper,
			boxes			= SUM(boxes),
			[type],
			fb				= ROUND(SUM(equivalencia), 2),
			largo,
			ancho,
			alto,
			cubic			= ROUND(SUM(alto * largo * ancho / 1728), 2),
			[status],
			awb,
			origin,
			poNumber,
			carrier,
			shipTo,
			fechaDespacho
	FROM	@Preliminar
	GROUP BY
			shipper,
			[type],
			largo,
			alto,
			ancho,
			[status],
			awb,
			origin,
			poNumber,
			carrier,
			shipTo,
			fechaDespacho
	ORDER BY awb
END

/*
DECLARE @clientes	VARCHAR(max) = 'CLI012287,CLI011713,CLI0116411,CLI0116413,CLI0515044,CLI0515186,CLI0116414,CLI0420135,CLI012405,CLI0415590,CLI0116957,CLI0416179,CLI0111914,CLI0112086';
DECLARE @fechaDesde	DATETIME = '2022-08-16T00:00:00';
DECLARE @fechaHasta	DATETIME = '2022-08-16T00:00:00';
execute [dbo].[pro_reportes_analiticadespachoconsolidado] @clientes, @fechaDesde, @fechaHasta;
*/