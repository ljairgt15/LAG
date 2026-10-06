/*
VERSION		MODIFIEDBY				MODIFIEDDATE	HU			MODIFICATION
1		Paul Castillo			2008-02-26	N/A			Traer que Pagadores tienen el Convenio 001
2		FT						2010-07-05	N/A			Aumento de campos Notas y Tipo
3		Rogger Lindao			2026-08-24	AC 64492	Lista todas las ciudades y paises
4		jgonzalez				2026-08-31	N/A			Estandarizacion: prefijo AC_pro_, TRY/CATCH, parametros en Pascal Case, alias, reservadas en mayusculas, ejemplo de ejecucion
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
		SELECT
		CC01.idaerolineas,
		CC01.codigofacturador,
		CC01.fechainicial,
		CC01.fechafinal,
		ISNULL(CC01.notas, '') AS Notas,
		ISNULL(CC01.tipo, '') AS Tipo,
		ISNULL(CC01.adicional, '') AS Adicional
		FROM	convenioscodigo001 CC01
		WHERE	CC01.idaerolineas = @IdAerolineas
		AND		CC01.codigoempresas = @CodigoEmpresas
		AND		(CC01.codigofacturador = @CodigoFacturador OR CC01.codigofacturador = @IdConsignatario)
		AND		CC01.destino = @Destino
		AND		CC01.paisorigen = @PaisOrigen
		AND		CC01.fechainicial <= @FechaInicial
		AND		CC01.vigente = 1
		ORDER BY CC01.fechainicial DESC
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
