/*
VERSION		MODIFIEDBY				MODIFIEDDATE	HU			MODIFICATION
1		Rogger Lindao			2026-08-24	AC 64492	Lista todos los convenios sin parametros de entrada
2		jgonzalez				2026-08-31	N/A			Estandarizacion: prefijo AC_pro_, TRY/CATCH, alias, reservadas en mayusculas, ejemplo de ejecucion
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_Convenios001Traer_Todo]
AS
BEGIN
		SELECT
		CC01.id,
		CC01.idaerolineas,
		CC01.paisorigen,
		CC01.codigoempresas,
		CC01.destino,
		CC01.fechainicial,
		CC01.fechafinal,
		CC01.codigofacturador,
		CC01.cedulalog,
		CC01.versionfila,
		CC01.vigente,
		CC01.notas,
		CC01.tipo,
		CC01.adicional
		FROM	convenioscodigo001 CC01
		WHERE	CC01.vigente = 1
END
