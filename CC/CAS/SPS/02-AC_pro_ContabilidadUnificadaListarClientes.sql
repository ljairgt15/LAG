/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_ContabilidadUnificadaListarClientes
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_ContabilidadUnificadaListarClientes]
	@banderas varchar(25),
	@codigocliente varchar(13),
	@codigoempresa varchar(3)	
AS
BEGIN
BEGIN TRY
	IF(@banderas='CLIENTERELACION')
	BEGIN
		/*
		SELECT c.codigo, c.valortransfe, c.ruc, c.nombres, c.pais, cl.nomcli, cl.codcli, cl.codcta, cl.rucced, cl.dircli, cl.telcli,cl.ciucli
		FROM clientes c INNER JOIN contabilidadunificada.kdbs_unificada.dbo.clientes cl 
		ON c.codigocontable=cl.codcli 
		AND c.codigo = @codigocliente
		*/		
		RETURN
	END

	IF(@banderas='ARTICULORELACION')
	BEGIN		
		--codcta codigo de cuenta contable para compras
		--codven codigo de cuenta contable para ventas
		/*
		SELECT a.codtip, a.nomtip, a.codcta, a.ctaven
		FROM contabilidadunificada.kdbs_unificada.dbo.me_tipo_servicios a 		
		WHERE a.codtip = @codigocliente
		*/
		RETURN
	END

	IF(@banderas='TIPOASIENTORELACION')
	BEGIN
		/*
		SELECT idtipoasiento, codigo FROM contabilidadunificada.contab.dbo.asientotipo
		WHERE codigo = @codigocliente
		*/
		RETURN
	END

	IF (@banderas = 'MAXCODIGO')
	BEGIN

	/*
	SELECT --'CP-G' + 
			max(cast(substring(x.codcli,5,15) as int) + 1)  AS maximo
			FROM  contabilidadunificada.kdbs_unificada.dbo.clientes x
		WHERE ltrim(rtrim(substring(x.codcli,4,1))) = 'G'
	*/

		RETURN
	END

	IF (@banderas = 'BUSCACLIENTE')
	BEGIN
		SELECT NOMBRES 
			FROM ggcargo.dbo.clientes c
		WHERE c.codigocontable = @codigocliente
		RETURN
	END

	IF (@banderas = 'CLIENTESCUADRECASS')
	BEGIN
		/*SELECT ltrim(rtrim(substring(g.codigo,1,13))) as codigo,
		'GYG' + ' - ' + ltrim(rtrim(k.nomcli)) as nombres, 'GYG' as empresa
		--, rtrim(k.dircli) as direccion, '' as tipo, 
		--isnull(consig,'') as consig, isnull(k.codcli,'') as codigocontable
		--,Fax = ltrim(rtrim(isnull(g.faxes,'' ))) 
		FROM contabilidadunificada.kdbs_unificada.dbo.clientes k inner join 
		ggcargo.dbo.clientes g on  ltrim(rtrim(substring(k.codcli,1,13))) = ltrim(rtrim(g.codigocontable))
		UNION */
		SELECT ltrim(rtrim(id)) as codigo, ltrim(rtrim(empresa)) + '-' + nombre as nombres, empresa 
		FROM clientesrelacioncass
		order by nombres
	END

	IF (@banderas = 'CONSIGNATARIOSCUADRECASS')
	BEGIN
		/*SELECT  id,  'GYG' + ' - ' + LTRIM(RTRIM(nombre1)) + ' '  + LTRIM(RTRIM(isnull(nombre2,''))) as nombre1, 
		'GYG' as empresa
		FROM      consignatarios
		WHERE     activo=1 --and (codigoempresa = @codEmpresa or rtrim(codigoempresa)='' or codigoempresa='GYE')		
		UNION */
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
    @Banderas = 'BUSCACLIENTE',
    @CodigoCliente = 'CLI0000000001',
    @CodigoEmpresa = '001'
*/