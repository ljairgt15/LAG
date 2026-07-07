/*    
------------------------------------------------------------------------
-- Consultar informacion para generar manifiestos
--
--  VERSION		AUTOR				FECHA			HU			CAMBIO
--  1			Luis Campos			05-04-2023		AC 25548  	Codigo Inicial
--  2			Willan Mejia  		25-07-2023		28666  		Agregar campo estado pieza, total piezas, piezas picked, piezas manifest
-------------------------------------------------------------------------
*/
ALTER   PROCEDURE [dbo].[pro_GetManifestInfo]
(
	@listaPiezas VARCHAR(MAX)
)
AS
BEGIN
	BEGIN TRY
		CREATE TABLE #ListaPiezasTemp
		(
			idGuiaHouseDetalle UNIQUEIDENTIFIER,
			idCliente VARCHAR(16),
			manifestType VARCHAR(32)
		)
		
		INSERT INTO #ListaPiezasTemp
        (
            idGuiaHouseDetalle,
			idCliente,
			manifestType
        )
		
        SELECT 
			idGuiaHouseDetalle,
			idCliente,
			manifestType
        FROM
            OPENJSON(@listaPiezas)
            WITH
            (
                idGuiaHouseDetalle UNIQUEIDENTIFIER '$.IdGuiaHouseDetalle',
				idCliente VARCHAR(16) '$.IdCliente',
				manifestType VARCHAR(32) '$.ManifestType'
            );
			
		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Id
		, pc.id AS IdProgramacionCarrier
		, pm.id AS IdProgramacionManifiesto
		, md.id AS IdManifiestoDespacho
		, md.nroManifiesto AS NroManifiesto
		, ghd.po AS Po
		, gh.nroGuia AS NroGuia
		, svc.id AS IdSolicitudVentas
		, ptmp.idCliente AS IdCliente
		, ptmp.manifestType AS TipoManifiesto
		, 1 AS Piece
		, CASE
			WHEN PC.idUsuarioLogPicking IS NOT NULL
			THEN 1
			WHEN GHD.estadoPieza = 'DISPATCHED WH'
			THEN 1
		  ELSE 0 END AS PiecePicked
		, CASE
			WHEN pm.id IS NOT NULL 
				AND pm.nota = 'Escaner Picking'
			THEN 1
			ELSE 0
		  END AS PieceManifest
		FROM #ListaPiezasTemp AS ptmp
		INNER JOIN GuiasHouseDetalles AS ghd WITH (NOLOCK) ON ghd.id = ptmp.idGuiaHouseDetalle  
		INNER JOIN GuiasHouse AS gh WITH (NOLOCK) ON ghd.idGuiaHouse = gh.id
		INNER JOIN ProgramacionCarrier AS pc WITH (NOLOCK) ON ghd.id = pc.idGuiaHouseDetalle
		LEFT JOIN ProgramacionManifiesto AS pm WITH (NOLOCK) ON pc.id = pm.idProgramacionCarrier
		LEFT JOIN ManifiestosDespacho AS md WITH (NOLOCK) ON pm.idManifiestoDespacho = md.id
		OUTER APPLY 
		(	
			SELECT TOP 1 solicitud.id, solicitud.nroOrden
            FROM dbo.SolicitudDeVentaDetalles solicitudDetalle WITH (NOLOCK)
            LEFT JOIN dbo.SolicitudDeVenta solicitud WITH (NOLOCK) ON solicitud.id = solicitudDetalle.idSolicitud
            WHERE solicitudDetalle.idGuiaHouseDetalle = ghd.id
            ORDER BY solicitud.fechaSolicitud DESC
		) AS svc	
		
	END TRY
    BEGIN CATCH			
		EXEC [dbo].[pro_LogError] 
    END CATCH;
END

/*

EXEC pro_GetManifestInfo 
'[{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"24bebf90-fc4b-46d3-b568-06e0317ec22d"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"3e040b89-cc1b-41f0-a03d-1d5cc42a78ab"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"d70afd51-dfb0-431d-af2f-2aa1cce44b39"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"29c3ea66-7353-47b9-aa21-42242256336a"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"f80d945c-88fd-432f-a671-4618a13f4099"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"c2e60b5a-c340-4e14-9322-4fa4d1b0ddf4"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"ec84dcf1-c95a-40ab-b9ba-5828fbcb4fc6"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"19fddedf-8cdd-444c-984e-5b676288e7c9"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"b37a9ce2-783b-48fa-8053-c0c2f24a0dec"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"c7b7e99f-2900-4277-ab18-edc9cc8d6683"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"868e489f-c1ca-4dbb-ad3e-f74c2ecdf5ef"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"932501e6-4d78-4480-a0ad-f9ab43e8ac10"},{"ManifestType":"MANIFIESTOPYF","IdGuiaHouseDetalle":"dfb86154-ff81-48e0-aef0-fa428a5a80e2"}]'

*/