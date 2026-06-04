ALTER   PROCEDURE [dbo].[Ac_pro_GetRelatedClients360]
(
	@idUsuario VARCHAR(16),
	@subCustomer VARCHAR(128) --NOMBRE

)
AS
BEGIN
BEGIN TRY
	DECLARE @tipoCliente VARCHAR(64),
			@RangoFecha DATE, 
			@fechaDestinoComodin DATE, 
			@nombreGrupo VARCHAR(256),
			@IdCliente VARCHAR(16),
			@Final VARCHAR (16) = NULL,
			@Consignee VARCHAR (16) = NULL,
			@Consolidador VARCHAR (16) = NULL

	SELECT 
		@RangoFecha = DATEADD(MM, -3, GETDATE()),	
		@fechaDestinoComodin = DATEADD(MM, -1, GETDATE())
		
	

	CREATE TABLE #ClientesRelacionados(
		[idClienteB] [VARCHAR](16)
	)
	CREATE TABLE #allClients(
		[idClienteConsolidador] [VARCHAR](16),
		[idClienteFinal] [VARCHAR](16)
	)

	
	SELECT 
		@IdCliente = CL.id,
		@tipoCliente = cat.identificador 
	FROM 
		Usuarios us
		INNER JOIN Clientes CL ON CL.id = US.idEntidad
		INNER JOIN dbo.DetalleEntidades DetI ON DetI.idEntidad = CL.id
		INNER JOIN dbo.Catalogos cat ON cat.id = DetI.idCatalogo
	WHERE 
		US.id = @IdUsuario

	IF @tipoCliente = 'CLIENTE'
		BEGIN 
			INSERT INTO #ClientesRelacionados (idClienteB) 
			VALUES(@IdCliente)

		END
	ELSE
		BEGIN 
			
			INSERT INTO #ClientesRelacionados (idClienteB) 
			SELECT 
				idCliente 
			FROM 
				dbo.GrupoClientes 
			WHERE 
				idGrupoCliente = @IdCliente
		END

--ORIGEN
	INSERT INTO #allClients
	SELECT  DISTINCT
		ISNULL(gmaster.idCliente,g.idCliente)   AS idClienteConsolidador,
		ISNULL(GDIST.idCliente, G.idCliente)AS idClienteFinal		
	FROM 
		Guias g  WITH (NOLOCK)
		INNER JOIN #ClientesRelacionados CL ON CL.idClienteB = G.idCliente
		LEFT JOIN Guias gdist  WITH (NOLOCK) ON gdist.idGuiaConsolidada = G.id
		LEFT JOIN Guias gmaster  WITH (NOLOCK) ON gmaster.ID = g.idGuiaConsolidada 
	WHERE 
		G.fechaEmbarque >= @RangoFecha

	/* validacion  tipo de clientes*/
	SELECT TOP 1 
		@Consolidador = 'CONSOLIDADOR'
	FROM 
		GuiasHouse GH
		INNER JOIN #ClientesRelacionados CLI ON CLI.idClienteB = GH.idCliente
	WHERE 
		GH.house IS NULL 
		AND fechaDestino >= @fechaDestinoComodin
		AND GH.[manual] = 1

	SELECT TOP 1 
		@Consignee ='CONSIGNEE'
	FROM 
		GuiasHouse GH
		INNER JOIN #ClientesRelacionados CLI ON CLI.idClienteB = GH.idCliente
	WHERE 
		GH.house IS NOT NULL 
		AND fechaDestino >= @fechaDestinoComodin
		AND GH.[manual] = 1

	SELECT TOP 1 
		@Final = 'FINAL'
	FROM 
		GuiasHouseDetalles GHD
		INNER JOIN #ClientesRelacionados CLI ON CLI.idClienteB = GHD.idClienteFinal
	WHERE 
		GHD.fechaCreacion >= @fechaDestinoComodin


	IF @Final IS NOT NULL 
	BEGIN
		INSERT INTO  #allClients 
		SELECT DISTINCT
			GHM.idCliente,
			ghd.idClienteFinal AS IdClienteFinal
		FROM
			GuiasHouseDetalles AS GHD WITH (NOLOCK) 
			INNER JOIN #ClientesRelacionados CL ON CL.idClienteB = GHD.idClienteFinal
			INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.id =  GHD.idGuiaHouse
															AND GH.[manual] = 1
			LEFT JOIN dbo.GuiasHouse GHM WITH (NOLOCK) ON GHM.idGuia = GH.idGuia
															AND GHM.[manual] = 1
		WHERE 
			GHD.fechaCreacion >= @fechaDestinoComodin
				
	END
			
		/* CLIENTES CONSIGNEE */
	IF @Consignee IS NOT NULL
	BEGIN
			
		INSERT INTO  #allClients
		SELECT DISTINCT
			GHM.idCliente,
			ghd.idClienteFinal AS IdClienteFinal
		FROM
			dbo.GuiasHouse GH WITH (NOLOCK)
			INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idClienteB = GH.idCliente
			INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
			LEFT JOIN dbo.GuiasHouse GHM WITH (NOLOCK) ON GHM.idGuia = GH.idGuia
		WHERE 
			GH.house IS NOT NULL 
			AND GH.fechaDestino >= @fechaDestinoComodin
			AND GH.[manual] = 1
	END

	/* CLIENTES CONSOLIDADORES */
	IF @Consolidador IS NOT NULL
	BEGIN
		INSERT INTO #allClients
		SELECT DISTINCT
			GH1.idCliente,
			GHD.idClienteFinal AS IdClienteFinal
		FROM
			dbo.GuiasHouse GH1 WITH (NOLOCK)
			INNER JOIN #ClientesRelacionados CLI WITH (NOLOCK) ON CLI.idClienteB = GH1.idCliente
			INNER JOIN dbo.GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = gh1.idGuia
			INNER JOIN GuiasHouseDetalles AS GHD WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
		WHERE 
			GH1.house IS NULL 
			AND GH1.fechaDestino >= @fechaDestinoComodin
			AND GH1.[manual] = 1
	END


	IF EXISTS(
		SELECT TOP 1  1 
		FROM 
			#allClients AC 
			INNER JOIN #ClientesRelacionados CLI ON CLI.idClienteB = AC.idClienteConsolidador 
		)
	BEGIN
		INSERT INTO #ClientesRelacionados
		SELECT DISTINCT
			AC.idClienteFinal
		FROM 
			#allClients AC
			--INNER JOIN Clientes  CL ON CL.id = AC.idClienteFinal
		
	END
	

		SELECT  DISTINCT
			AC.idClienteB AS id,
			AC.idClienteB AS  [value],
			ISNULL(CL.nombreClienteFinal, CL.nombre) AS [label]
		FROM 
			#ClientesRelacionados AC
			INNER JOIN Clientes  CL ON CL.id = AC.idClienteB
		WHERE 
			(@subCustomer IS NULL OR CL.nombre LIKE '%' + @subCustomer + '%')
	
	DROP TABLE #ClientesRelacionados
	DROP TABLE #allClients
END TRY
BEGIN CATCH			
	EXEC [dbo].[pro_LogError] 
END CATCH;
END
