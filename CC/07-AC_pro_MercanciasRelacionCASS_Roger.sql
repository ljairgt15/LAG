/*    
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_MercanciasRelacionCASS
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
