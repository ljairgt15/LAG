/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_ContabilidadUnificadaListarClientes
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_ContabilidadUnificadaListarClientes]
	@Bandera varchar(25),
	@CodigoCliente varchar(13),
	@codigoempresa varchar(3)	
AS
BEGIN
BEGIN TRY

	IF (@Bandera = 'CLIENTESCUADRECASS')
	BEGIN
		SELECT ltrim(rtrim(id)) as codigo, ltrim(rtrim(empresa)) + '-' + nombre as nombres, empresa 
		FROM clientesrelacioncass
		order by nombres
	END

	IF (@Bandera = 'CONSIGNATARIOSCUADRECASS')
	BEGIN
		SELECT id, ltrim(rtrim(empresa)) + ' - ' + nombre as nombre1, empresa 
		FROM consignatariosrelacioncass
		order by nombre1
	END
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
GO
/*
EXEC [dbo].[AC_pro_ContabilidadUnificadaListarClientes]
    @Bandera = 'BUSCACLIENTE',
    @CodigoCliente = 'CLI0000000001',
    @CodigoEmpresa = '001'
*/