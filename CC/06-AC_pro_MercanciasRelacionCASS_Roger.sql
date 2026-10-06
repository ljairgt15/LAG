/*
VERSION		MODIFIEDBY				MODIFIEDDATE	HU			MODIFICATION
1		Rogger Lindao			2026-08-24	AC 64492	Lista todas las ciudades y paises
2		jgonzalez				2026-08-31	N/A			Estandarizacion: prefijo AC_pro_, TRY/CATCH, alias, reservadas en mayusculas, ejemplo de ejecucion
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_MercanciasRelacionCASS]
	@Banderas varchar(20),
	@Mercancia varchar(20),
	@CodigoEmpresas varchar(3)
AS
BEGIN
		IF (@Banderas = 'CODIGORELACION')
		BEGIN
			SELECT
			MRC.idMercancia,
			ISNULL(MRC.Mercancia, '') AS Mercancia,
			MRC.CodigoEmpresa
			FROM	mercanciasrelacioncass MRC
			WHERE	MRC.mercancia = @Mercancia
		END

		IF ((SUBSTRING(@Mercancia, 1, 3) <> 'MER') AND (@Banderas = 'TODOS'))
		BEGIN
			SELECT
			MRC.idMercancia,
			ISNULL(MRC.Mercancia, '') AS Mercancia,
			MRC.CodigoEmpresa
			FROM	mercanciasrelacioncass MRC
		END

		IF ((SUBSTRING(@Mercancia, 1, 3) = 'MER') AND (@Banderas = 'TODOS'))
		BEGIN
			SELECT
			MERC.id AS IdMercancia,
			ISNULL(MERC.idMercanciaAlianza, '') AS Mercancia,
			'ALO' AS CodigoEmpresa
			FROM	mercancias MERC
			WHERE	MERC.idMercanciaAlianza = @Mercancia
		END

		IF (@Banderas = 'CATALOGO_COMPLETO')
		BEGIN
			SELECT
			MERC.id AS IdMercancia,
			ISNULL(MERC.idMercanciaAlianza, '') AS Mercancia,
			'ALO' AS CodigoEmpresa
			FROM	mercancias MERC
		END
END
