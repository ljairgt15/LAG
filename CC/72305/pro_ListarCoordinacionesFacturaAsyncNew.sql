/*    
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1			Juan Domínguez		2020-07-07		    ----  			Codigo Inicial
2			Jonathan Merino		2020-07-07		    SC 10268  	    Cambio para ver si hay piezas retornadas en la factura
3			Jonathan Merino	    2020-07-13          SC 10268  	    Cambio para buscar fitos y certificados de guia master
*/  
CREATE OR ALTER PROCEDURE [dbo].[pro_ListarCoordinacionesFacturaAsync]
(
    @FechaEmbarqueGuia DATE,
    @StatusDistinto VARCHAR(32),
    @IdCoordinacion VARCHAR(16) = NULL,
    @IdEmpresa VARCHAR(16)
)
AS
BEGIN
    SELECT coordinacion.id,
           coordinacion.abierto,
           bodega.nombre AS bodega,
           cliente.nombre AS cliente,
           IIF((guia.tipoGuia = 'DISTRIBUCION'), guiaConsolidada.nroGuia, guia.nroGuia) AS numeroGuia,
           ISNULL(DatosFacturaEncabezado.cajasfactura, 0.00) AS cajasfactura,
           ISNULL(DatosFacturaEncabezado.piezasfactura, 0.00) AS piezasfactura,
           puertoDestinoDoc.nombre AS destinoGuia,
           coordinacion.totalCajasRecepcion - ISNULL(DatosFacturaEncabezado.cajasfactura, 0.00) AS diferenciacajas,
           coordinacion.totalPiezasRecepcion - ISNULL(DatosFacturaEncabezado.piezasfactura, 0.00) AS diferenciapiezas,
           exportador.nombre AS exportador,
           guia.abierta AS GuiaAbierta,
           IIF(
               EXISTS
               (
                   SELECT 1
                   FROM dbo.CertificadosOrigenEncabezado certOrigenEncabezado
                   WHERE certOrigenEncabezado.idGuia =  IIF((guia.tipoGuia = 'DISTRIBUCION' AND guia.idGuiaConsolidada IS NOT NULL), guia.idGuiaConsolidada, guia.id)
                         AND certOrigenEncabezado.status IS NOT NULL
                         AND certOrigenEncabezado.status <> 'ANULADO'
               ),
               CONVERT(BIT, 1),
               CONVERT(BIT, 0)) AS HasCertificadosOrigen,
           IIF(
               EXISTS
               (
                   SELECT 1
                   FROM dbo.FitosEncabezado fitosEncabezado
                   WHERE fitosEncabezado.idGuia = IIF((guia.tipoGuia = 'DISTRIBUCION' AND guia.idGuiaConsolidada IS NOT NULL), guia.idGuiaConsolidada, guia.id)
                         AND fitosEncabezado.status IS NOT NULL
                         AND fitosEncabezado.status <> 'ANULADO'
               ),
               CONVERT(BIT, 1),
               CONVERT(BIT, 0)) AS HasFitos,
           coordinacion.house,
           DatosFacturaEncabezado.nameusuarioReg,
           IIF(
               coordinacion.abierto = 1
               AND NOT EXISTS
                       (
                           SELECT 1
                           FROM dbo.DetalleIngresos detIngreso
                           WHERE detIngreso.idCoordinacion = coordinacion.id
                       ),
               'CIRCLE_GREEN',
               IIF(
                   coordinacion.abierto = 1
                   AND EXISTS
                       (
                           SELECT 1
                           FROM dbo.DetalleIngresos detIngreso
                           WHERE detIngreso.idCoordinacion = coordinacion.id
                       ),
                   'CIRCLE_YELLOW',
                   IIF(coordinacion.abierto = 0, 'CIRCLE_RED', ''))) AS status,
           coordinacion.totalCajasRecepcion,
           coordinacion.totalPiezasRecepcion,
           ISNULL(CONVERT(DECIMAL(18, 2), DatosFacturaEncabezado.tallos), 0.00) AS tallos,
           ISNULL(DatosFacturaEncabezado.precio, 0.00) AS precio,
           STUFF(
           (
               SELECT ', ' + detMercancia.nombre
               FROM dbo.FacturaEncabezado factEncabezado
                   INNER JOIN dbo.FacturaDetalle factDetalle
                       ON factDetalle.idFacturaEncabezado = factEncabezado.id
                   INNER JOIN dbo.ExportadorProductos expProducto
                       ON expProducto.id = factDetalle.idExportadorProductos
                   INNER JOIN dbo.DetalleMercancias detMercancia
                       ON detMercancia.id = expProducto.idDetalleMercancia
               WHERE factEncabezado.idCoordinacion = coordinacion.id
			   GROUP BY detMercancia.nombre
               FOR XML PATH('')
           ),
           1,
           1,
           ''
                ) AS variedad,
		 ISNULL(IIF(fec.piezasRetornadas IS NULL AND SUBSTRING(coordinacion.house, 1, 2) = 'XX', CONVERT(BIT, 1), fec.piezasRetornadas), CONVERT(BIT, 0)) AS piezasRetornadas,
		 IIF(facturaSubdetalle.id IS NOT NULL, CONVERT(BIT, 1), CONVERT(BIT, 0)) AS tieneSubDetalle,
		 ISNULL(ValidadorBouquet.FacturasConDiferencia, '') AS FacturasConDiferencia

    FROM dbo.Coordinaciones coordinacion WITH (NOLOCK)
        INNER JOIN dbo.Guias guia WITH (NOLOCK)
            ON guia.id = coordinacion.idGuia
        INNER JOIN dbo.Clientes cliente
            ON cliente.id = guia.idCliente
        INNER JOIN dbo.Bodegas bodega
            ON bodega.id = guia.idBodega
        INNER JOIN dbo.Puertos puertoDestinoDoc
            ON puertoDestinoDoc.id = guia.idPuertoDestinoDocumentos
        INNER JOIN dbo.Exportadores exportador
            ON exportador.id = coordinacion.idExportador
        LEFT JOIN dbo.Guias guiaConsolidada WITH (NOLOCK)
            ON guiaConsolidada.id = guia.idGuiaConsolidada
        OUTER APPLY
		(
        SELECT SUM(factDetalle.cajasFacturaDetalle) AS cajasfactura,
               SUM(factDetalle.piezasFacturaDetalle) AS piezasfactura,
               SUM(factDetalle.tallos) AS tallos,
               SUM(factDetalle.valorTotal) AS precio,
               factEncabezado.idCoordinacion,         
               MIN(usuarioRegistro.nombre) AS nameusuarioReg
        FROM dbo.FacturaEncabezado factEncabezado
            INNER JOIN dbo.FacturaDetalle factDetalle
                ON factDetalle.idFacturaEncabezado = factEncabezado.id
            INNER JOIN dbo.Usuarios usuarioRegistro
                ON usuarioRegistro.id = factEncabezado.idUsuarioRegistro
        WHERE factEncabezado.idCoordinacion = coordinacion.id
        GROUP BY factEncabezado.idCoordinacion
		) AS DatosFacturaEncabezado
		OUTER APPLY
		(
			SELECT TOP 1 IIF(piezasRetornadas IS NULL, CONVERT(BIT, 0), piezasRetornadas) AS piezasRetornadas
			FROM FacturaEncabezado factEncabezado
			WHERE factEncabezado.idCoordinacion = coordinacion.id
		)fec
		OUTER APPLY
		(
			SELECT TOP 1 SubFacturaSubdetalle.id
			FROM FacturaEncabezado factEncabezado
			INNER JOIN FacturaDetalle factDetalle ON factEncabezado.id = factDetalle.idFacturaEncabezado
			INNER JOIN FacturaDetalleBouquets SubFacturaSubdetalle ON factDetalle.id = SubFacturaSubdetalle.idFacturaDetalle
			WHERE factEncabezado.idCoordinacion = coordinacion.id										
		) facturaSubdetalle
		OUTER APPLY
		(
			SELECT STUFF(
			(
				SELECT DISTINCT ', ' + ISNULL(fd.nroFactura, '')
				FROM dbo.FacturaEncabezado fe WITH (NOLOCK)
				INNER JOIN dbo.FacturaDetalle fd WITH (NOLOCK) ON fd.idFacturaEncabezado = fe.id
				INNER JOIN dbo.ExportadorProductos expProd WITH (NOLOCK) ON expProd.id = fd.idExportadorProductos
				INNER JOIN dbo.DetalleMercancias detMerc WITH (NOLOCK) ON detMerc.id = expProd.idDetalleMercancia
				WHERE fe.idCoordinacion = coordinacion.id
				  AND detMerc.nombre IN ('BOUQUET', 'BOXMIX')
				  AND (
					  ISNULL(fd.tallos, 0) <> (SELECT ISNULL(SUM(fdb.tallos), 0) FROM dbo.FacturaDetalleBouquets fdb WITH (NOLOCK) WHERE fdb.idFacturaDetalle = fd.id)
					  OR
					  ISNULL(fd.valorTotal, 0) <> (SELECT ISNULL(SUM(fdb.valorTotal), 0) FROM dbo.FacturaDetalleBouquets fdb WITH (NOLOCK) WHERE fdb.idFacturaDetalle = fd.id)
				  )
				FOR XML PATH('')
			), 1, 2, '') AS FacturasConDiferencia
		) AS ValidadorBouquet
    WHERE CONVERT(VARCHAR(8), guia.fechaEmbarque, 112) = CONVERT(VARCHAR(8), @FechaEmbarqueGuia, 112)
          AND guia.status <> @StatusDistinto
          AND guia.idEmpresa = @IdEmpresa
          AND coordinacion.id = ISNULL(@IdCoordinacion, coordinacion.id);
END;
