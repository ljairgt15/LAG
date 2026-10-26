/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_Convenios001Traer
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_Convenios001Traer]
	@IdAerolineas char(11),
	@CodigoEmpresas char(3),
	@CodigoFacturador char(13),
	@Destino char(3),
	@PaisOrigen char(3),
	@FechaInicial datetime,
	@IdConsignatario char(13)
AS
BEGIN
	BEGIN TRY
		SELECT
		CON.idaerolineas,
		CON.codigofacturador,
		CON.fechainicial,
		CON.fechafinal,
		ISNULL(CON.notas, '') AS Notas,
		ISNULL(CON.tipo, '') AS Tipo,
		ISNULL(CON.adicional, '') AS Adicional
		FROM convenioscodigo001 CON
		WHERE CON.idaerolineas = @IdAerolineas
		AND	CON.codigoempresas = @CodigoEmpresas
		AND	(CON.codigofacturador = @CodigoFacturador OR CON.codigofacturador = @IdConsignatario)
		AND	CON.destino = @Destino
		AND	CON.paisorigen = @PaisOrigen
		AND	CON.fechainicial <= @FechaInicial
		AND	CON.vigente = 1
		ORDER BY CON.fechainicial DESC
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
/*
EXEC [dbo].[AC_pro_Convenios001Traer]
	@IdAerolineas = '20259876543',
	@CodigoEmpresas = '001',
	@CodigoFacturador = '0987654321000',
	@Destino = 'UIO',
	@PaisOrigen = 'ECU',
	@FechaInicial = '20260101',
	@IdConsignatario = '0987654321000'
*/