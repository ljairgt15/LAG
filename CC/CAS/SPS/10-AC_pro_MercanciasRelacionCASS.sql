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
	BEGIN TRY
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
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
GO
/*
EXEC [dbo].[AC_pro_MercanciasRelacionCASS] @Banderas = 'CODIGORELACION', @Mercancia = 'MER0001234', @CodigoEmpresas = '001'
EXEC [dbo].[AC_pro_MercanciasRelacionCASS] @Banderas = 'TODOS', @Mercancia = 'GEN0001234', @CodigoEmpresas = '001'
EXEC [dbo].[AC_pro_MercanciasRelacionCASS] @Banderas = 'TODOS', @Mercancia = 'MER0001234', @CodigoEmpresas = '001'
EXEC [dbo].[AC_pro_MercanciasRelacionCASS] @Banderas = 'CATALOGO_COMPLETO', @Mercancia = '', @CodigoEmpresas = '001'
*/