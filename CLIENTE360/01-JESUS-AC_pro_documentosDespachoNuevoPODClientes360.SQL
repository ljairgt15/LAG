ALTER   PROCEDURE [dbo].[AC_pro_documentosDespachoNuevoPODClientes360]
(
    @fechaDespachoDesde DATETIME,
    @fechaDespachoHasta DATETIME,
    @nroManifiesto VARCHAR(32) = NULL,
    @nroGuia  VARCHAR(32)= NULL,
    @PO  VARCHAR(64)= NULL,
    @idCarrier  VARCHAR(16)= NULL,
    @codigoDeBarra  VARCHAR(32)= NULL,
    @entityId  VARCHAR(16) = NULL,
    @shipTo VARCHAR(128) = NULL
)
AS
BEGIN
BEGIN TRY

    DECLARE @fechaDestinoComodin DATETIME = DATEADD(DAY,-15,@fechaDespachoDesde);

    DECLARE @ClientesRelacionados TABLE (idClienteB VARCHAR(16));
    DECLARE @TMP_Entities TABLE
    (
        EntityId VARCHAR(16),
        IdCliente VARCHAR(16),
        TipoCliente VARCHAR(32)
    );

    INSERT INTO @TMP_Entities
    EXEC AC_pro_GetClientsEntities @EntityId = @entityId;

    INSERT INTO @ClientesRelacionados
        SELECT EntityId FROM @TMP_Entities;

    DECLARE @ShipTosTemp TABLE (Id VARCHAR(16));

    IF NULLIF(@shipTo,'') IS NOT NULL
    BEGIN
        INSERT INTO @ShipTosTemp
        SELECT Id
        FROM f_SearchEntities(@shipTo,'Consignee');
    END

    DECLARE @temporalPods TABLE
    (
        IdGuiasHouseDetalles UNIQUEIDENTIFIER,
        idProgramacionCarrier UNIQUEIDENTIFIER,
        IdGuia VARCHAR(64),
        FechaDespacho DATETIME,
        IdClienteFinal VARCHAR(16),
        IdCarrier VARCHAR(16),
        po VARCHAR(64),
        nroGuia VARCHAR(32),
        codigoBarra VARCHAR(32),
        idBodega VARCHAR(16),
        idEmpresa VARCHAR(16)
    );

    DECLARE @DocumentosPod TABLE
		(
			IdGuiaHouse UNIQUEIDENTIFIER,
			Id VARCHAR(64) ,
			NombreDocumento VARCHAR(128) ,
			MailEnviado BIT,
			Procesado VARCHAR(16),
			FechaDespacho DATETIME,
			IdManifiesto VARCHAR(64),
			NroManifiesto VARCHAR(32),
			IdClienteFinal VARCHAR(16),
			NombreClienteFinal VARCHAR(128),
			NombreCliente VARCHAR(128),
			IdCarrier VARCHAR(16),
			NombreCarrier VARCHAR(128),
			IdBodega VARCHAR(16),
			CodigoDocumento VARCHAR(32),
			Estado VARCHAR(16),
			idEmpresa VARCHAR(16)
		)

    INSERT INTO @temporalPods
    SELECT 
        DISTINCT
        GHD.id,
        T.id,
        GH.idGuia,
        T.fechaDespacho,
        GHD.ShipToId,
        T.idCarrier,
        GHD.po,
        GH.nroGuia,
        GHD.codigoBarra,
        GH.idBodega,
        GH.idEmpresa
    FROM ProgramacionCarrier T
        INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GHD.id = T.idGuiaHouseDetalle
        INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.id = GHD.idGuiaHouse
        INNER JOIN v_ClientsEntities CEV ON GHD.ShipToId = CEV.ConsigneeId
        INNER JOIN @ClientesRelacionados CR ON CEV.id = CR.idClienteB
    WHERE
        T.fechaDespacho BETWEEN @fechaDespachoDesde AND @fechaDespachoHasta
        AND GHD.fechaCreacion BETWEEN @fechaDestinoComodin AND @fechaDespachoHasta
        AND (@idCarrier IS NULL OR T.idCarrier = @idCarrier)
        AND (@PO IS NULL OR GHD.po LIKE '%' + @PO + '%')
        AND (@codigoDeBarra IS NULL OR GHD.codigoBarra LIKE '%' + @codigoDeBarra + '%')
        AND (@nroGuia IS NULL OR GH.nroGuia LIKE '%' + @nroGuia + '%')
    
    INSERT INTO @temporalPods
    SELECT DISTINCT
        GHD.id,
        T.id,
        GH.idGuia,
        T.fechaDespacho,
        GHD.ShipToId,
        T.idCarrier,
        GHD.po,
        GH.nroGuia,
        GHD.codigoBarra,
        GH.idBodega,
        GH.idEmpresa
    FROM GuiasHouse GH
        INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
        INNER JOIN v_ClientsEntities CEV ON GH.ConsigneeId = CEV.ConsigneeId
        INNER JOIN @ClientesRelacionados CR ON CEV.id = CR.idClienteB
        INNER JOIN ProgramacionCarrier T WITH (NOLOCK) ON T.idGuiaHouseDetalle = GHD.id
    WHERE GH.house IS NOT NULL
        AND T.fechaDespacho BETWEEN @fechaDespachoDesde AND @fechaDespachoHasta
        AND GH.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaDespachoHasta
        AND (@idCarrier IS NULL OR T.idCarrier = @idCarrier)
        AND (@PO IS NULL OR GHD.po LIKE '%' + @PO + '%')
        AND (@codigoDeBarra IS NULL OR GHD.codigoBarra LIKE '%' + @codigoDeBarra + '%')
        AND (@nroGuia IS NULL OR GH.nroGuia LIKE '%' + @nroGuia + '%');

    INSERT INTO @temporalPods
    SELECT DISTINCT
        GHD.id,
        T.id,
        GH.idGuia,
        T.fechaDespacho,
        GHD.ShipToId,
        T.idCarrier,
        GHD.po,
        GH.nroGuia,
        GHD.codigoBarra,
        GH.idBodega,
        GH.idEmpresa
    FROM GuiasHouse GH1
        INNER JOIN GuiasHouse GH WITH (NOLOCK) ON GH.idGuia = GH1.idGuia
        INNER JOIN GuiasHouseDetalles GHD WITH (NOLOCK) ON GHD.idGuiaHouse = GH.id
        INNER JOIN v_ClientsEntities CEV ON GH1.ConsigneeId = CEV.ConsigneeId
        INNER JOIN @ClientesRelacionados CR ON CEV.id = CR.idClienteB
        INNER JOIN ProgramacionCarrier T WITH (NOLOCK) ON T.idGuiaHouseDetalle = GHD.id
    WHERE GH1.house IS NULL
        AND T.fechaDespacho BETWEEN @fechaDespachoDesde AND @fechaDespachoHasta
        AND GH1.fechaDestino BETWEEN @fechaDestinoComodin AND @fechaDespachoHasta
        AND (@idCarrier IS NULL OR T.idCarrier = @idCarrier)
        AND (@PO IS NULL OR GHD.po LIKE '%' + @PO + '%')
        AND (@codigoDeBarra IS NULL OR GHD.codigoBarra LIKE '%' + @codigoDeBarra + '%')
        AND (@nroGuia IS NULL OR GH1.nroGuia LIKE '%' + @nroGuia + '%');
    
    INSERT INTO @DocumentosPod
		SELECT DISTINCT 
			temp.IdGuiasHouseDetalles,
			documentoDespacho.id AS IdDocumentosDespacho,
			documentoDespacho.nombreArchivo AS NombreDocumento,
			ISNULL(documentoDespacho.mailEnviado,0) AS  MailEnviado,
			CASE
				WHEN  documentoDespacho.mailEnviado IS NULL
				THEN 'NO' 
				ELSE 'SI' 
			END AS Procesado,
			temp.FechaDespacho,
			manifiesto.id AS IdManifiesto,
			manifiesto.nroManifiesto,
			IdClienteFinal,
			ce.nombre AS [NombreClienteFinal],
			ce.nombre AS [NombreCliente],
			IdCarrier,
			[transporte].[nombre] AS [NombreCarrier],
			ISNULL(ubicacionesBodega.idBodega, temp.idBodega) AS idBodega,
			documento.codigo AS CodigoDocumento,
			ce.idEstado,
			temp.idEmpresa
		FROM @temporalPods temp
			INNER JOIN v_ClientsEntities CE ON temp.IdClienteFinal = CE.id
			INNER JOIN Transportes AS transporte  WITH (NOLOCK) ON temp.idCarrier = transporte.id
			LEFT JOIN ProgramacionManifiesto AS programacionManifiesto  WITH (NOLOCK) ON temp.idProgramacionCarrier = programacionManifiesto.idProgramacionCarrier
			LEFT JOIN ManifiestosDespacho AS manifiesto  WITH (NOLOCK) ON programacionManifiesto.idManifiestoDespacho = manifiesto.id
			LEFT JOIN DocumentosDespacho AS documentoDespacho  WITH (NOLOCK) ON manifiesto.id = documentoDespacho.idManifiesto
			LEFT JOIN Documentos AS documento  WITH (NOLOCK) ON documentoDespacho.idDocumento = documento.id
			LEFT JOIN UbicacionPiezas AS ubicacionPiezas ON temp.IdGuiasHouseDetalles = ubicacionPiezas.idGuiaHouseDetalle
			LEFT JOIN Ubicaciones AS ubicaciones ON ubicacionPiezas.idUbicacion = ubicaciones.id
			LEFT JOIN UbicacionesBodega AS ubicacionesBodega ON ubicaciones.idUbicacionBodega = ubicacionesBodega.id
		WHERE (@nroManifiesto IS NULL OR manifiesto.nroManifiesto LIKE @nroManifiesto + '%')
        
    SELECT 
			NEWID() AS Id,
			ISNULL(CAST(result.Id AS VARCHAR(64)),'') AS IdReal,
			ISNULL(NombreDocumento,'') AS NombreDocumento,
			ISNULL(Estado, '-') AS estado,
			MailEnviado,
			Procesado ,
			ISNULL(CAST(IdManifiesto  AS VARCHAR(64)) ,'') AS IdManifiesto,
			ISNULL(NroManifiesto,'') AS NroManifiesto,
			IdClienteFinal ,
			NombreClienteFinal ,
			NombreCliente ,
			IdCarrier ,
			NombreCarrier ,
			FechaDespacho,
			ISNULL(IdBodega,'') AS  IdBodega,
			ISNULL(CodigoDocumento ,'') AS CodigoDocumento,
			COUNT(1) AS numeroPiezas,
			idEmpresa
		FROM @DocumentosPod result
		WHERE result.Id IS NULL Or result.CodigoDocumento = 'MANIFEST'
		GROUP BY  
			result.Id,
			result.IdClienteFinal, 
			result.IdCarrier,
			result.FechaDespacho,
			result.NombreDocumento,
			result.MailEnviado,
			result.Procesado,
			result.IdBodega,
			result.IdManifiesto,
			result.NroManifiesto,
			result.Estado,
			result.CodigoDocumento,
			result.NombreCliente,
			result.NombreClienteFinal,
			NombreCarrier,
			result.idEmpresa
		ORDER BY NombreClienteFinal

END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
        THROW;
END CATCH

END