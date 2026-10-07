/*    
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Based on pro_RentabilidadConvenios
2           Roger Lindao        2026-09-10          64492           Add flag TODOSACTIVOS
3           Jair Gómez          2026-09-21          64492           Remove the filter for validity or expiration status and fix flags
*/
CREATE OR ALTER   PROCEDURE [dbo].[AC_pro_RentabilidadConvenios]
	@IdAerolinea char(4),
	@IdConsignatario char(13),
	@IdPagador char(13),
	@IdMercancia char(11),
	@Origen char(3),
	@Destino char(3),
	@CodigoEmpresa char(3),
	@Prepaid char(7),
	@FechaEmbarque datetime,
	@TipoConvenio varchar(13),
	@Bandera char(30)
AS
BEGIN
	BEGIN TRY
		-- 1. Búsqueda Específica
		IF (@Bandera = '')
		BEGIN
			SELECT
			RC.id, 
			RC.activo, 
			LTRIM(RTRIM(RC.idAerolinea)) AS IdAerolinea, 
			LTRIM(RTRIM(RC.idConsignatario)) AS IdConsignatario,
			LTRIM(RTRIM(RC.idPagador)) AS IdPagador, 
			LTRIM(RTRIM(RC.idMercancia)) AS IdMercancia, 
			LTRIM(RTRIM(RC.origen)) AS Origen,
			LTRIM(RTRIM(RC.destino)) AS Destino, 
			LTRIM(RTRIM(RC.codigoempresa)) AS CodigoEmpresa, 
			RC.prepaid, 
			RC.fechadesde,
			ISNULL(RC.fechahasta, '12/31/2099') AS FechaHasta, 
			RC.formula, 
			RC.comision, 
			RC.descuento, 
			RC.overcomision,
			RC.manejo, 
			RC.diferenciatarifas, 
			ISNULL(RC.campo1, '') AS Campo1, 
			RC.campo2, 
			RC.campo3, 
			RC.campo4, 
			RC.campo5, 
			RC.cedularesponsable
			FROM RentabilidadConvenios RC
			WHERE RC.tipoconvenio = @TipoConvenio
			AND (RC.idAerolinea = @IdAerolinea OR RC.idAerolinea = '000')
			AND (RC.idConsignatario = @IdConsignatario OR RC.idConsignatario = 'TODOS')
			AND (RC.idPagador = @IdPagador OR RC.idPagador = 'TODOS')
			AND (RC.idMercancia = @IdMercancia OR RC.idMercancia = 'TODOS')
			AND (RC.origen = @Origen OR RC.origen = 'TODOS')
			AND (RC.destino = @Destino OR RC.destino = 'TODOS')
			AND (RC.codigoempresa = @CodigoEmpresa OR RC.codigoempresa = 'TODOS')
			AND (RC.prepaid = @Prepaid OR RC.prepaid = 'TODOS')
			AND (RC.fechadesde <= @FechaEmbarque AND ISNULL(RC.fechahasta, '12/31/2099') >= @FechaEmbarque)
			AND (RC.activo = 1)
			ORDER BY RC.fechadesde DESC
			RETURN
		END

		IF (@Bandera = 'TODOS')
		BEGIN
			SELECT
			RC.id, 
			RC.activo, 
			LTRIM(RTRIM(RC.tipoconvenio)) AS TipoConvenio, 
			LTRIM(RTRIM(RC.idAerolinea)) AS IdAerolinea,
			LTRIM(RTRIM(RC.idConsignatario)) AS IdConsignatario, 
			LTRIM(RTRIM(RC.idPagador)) AS IdPagador, 
			LTRIM(RTRIM(RC.idMercancia)) AS IdMercancia,
			LTRIM(RTRIM(RC.origen)) AS Origen, 
			LTRIM(RTRIM(RC.destino)) AS Destino, 
			LTRIM(RTRIM(RC.codigoempresa)) AS CodigoEmpresa,
			RC.prepaid, 
			RC.fechadesde, 
			ISNULL(RC.fechahasta, '12/31/2099') AS FechaHasta, 
			RC.formula, 
			LTRIM(RTRIM(RC.diferenciatarifas)) AS Tarifa,
			RC.cedularesponsable, 
			LTRIM(RTRIM(EMP.nombres)) + ' ' + LTRIM(RTRIM(EMP.apellidos)) AS NombreEmpleado, 
			RC.fechamodificacion,
			RC.campo1, 
			RC.campo2, 
			RC.campo3
			FROM RentabilidadConvenios RC
			LEFT JOIN empleados EMP ON RC.cedularesponsable = EMP.cedula
			ORDER BY RC.fechadesde DESC
			RETURN
		END

		IF (@Bandera = 'ACTIVOS')
		BEGIN
			SELECT
			RC.id, 
			RC.activo, 
			LTRIM(RTRIM(RC.tipoconvenio)) AS TipoConvenio, 
			LTRIM(RTRIM(RC.idAerolinea)) AS IdAerolinea,
			LTRIM(RTRIM(RC.idConsignatario)) AS IdConsignatario, 
			LTRIM(RTRIM(RC.idPagador)) AS IdPagador, 
			LTRIM(RTRIM(RC.idMercancia)) AS IdMercancia,
			LTRIM(RTRIM(RC.origen)) AS Origen, 
			LTRIM(RTRIM(RC.destino)) AS Destino, 
			LTRIM(RTRIM(RC.codigoempresa)) AS CodigoEmpresa,
			RC.prepaid, 
			RC.fechadesde, 
			ISNULL(RC.fechahasta, '12/31/2099') AS FechaHasta, 
			RC.formula, 
			LTRIM(RTRIM(RC.diferenciatarifas)) AS Tarifa,
			RC.cedularesponsable, 
			LTRIM(RTRIM(EMP.nombres)) + ' ' + LTRIM(RTRIM(EMP.apellidos)) AS NombreEmpleado, 
			RC.fechamodificacion,
			RC.campo1, 
			RC.campo2, 
			RC.campo3
			FROM RentabilidadConvenios RC
			LEFT JOIN empleados EMP ON RC.cedularesponsable = EMP.cedula
			WHERE RC.activo = 1
			ORDER BY RC.fechadesde DESC
			RETURN
		END

		IF (@Bandera = 'INACTIVOS')
		BEGIN
			SELECT
			RC.id, 
			RC.activo, 
			LTRIM(RTRIM(RC.tipoconvenio)) AS TipoConvenio, 
			LTRIM(RTRIM(RC.idAerolinea)) AS IdAerolinea,
			LTRIM(RTRIM(RC.idConsignatario)) AS IdConsignatario, 
			LTRIM(RTRIM(RC.idPagador)) AS IdPagador, 
			LTRIM(RTRIM(RC.idMercancia)) AS IdMercancia,
			LTRIM(RTRIM(RC.origen)) AS Origen, 
			LTRIM(RTRIM(RC.destino)) AS Destino, 
			LTRIM(RTRIM(RC.codigoempresa)) AS CodigoEmpresa,
			RC.prepaid, 
			RC.fechadesde, 
			ISNULL(RC.fechahasta, '12/31/2099') AS FechaHasta, 
			RC.formula, 
			LTRIM(RTRIM(RC.diferenciatarifas)) AS Tarifa,
			RC.cedularesponsable, 
			LTRIM(RTRIM(EMP.nombres)) + ' ' + LTRIM(RTRIM(EMP.apellidos)) AS NombreEmpleado, 
			RC.fechamodificacion,
			RC.campo1, 
			RC.campo2, 
			RC.campo3
			FROM RentabilidadConvenios RC
			LEFT JOIN empleados EMP ON RC.cedularesponsable = EMP.cedula
			WHERE RC.activo = 0 
			ORDER BY RC.fechadesde DESC
			RETURN
		END

		-- 3. Liquidación CAS
		IF (@Bandera = 'TODOSACTIVOS')
		BEGIN
			SELECT
			RC.id, 
			RC.activo, 
			LTRIM(RTRIM(RC.tipoconvenio)) AS TipoConvenio, 
			LTRIM(RTRIM(RC.idAerolinea)) AS IdAerolinea,
			LTRIM(RTRIM(RC.idConsignatario)) AS IdConsignatario, 
			LTRIM(RTRIM(RC.idPagador)) AS IdPagador, LTRIM(RTRIM(RC.idMercancia)) AS IdMercancia,
			LTRIM(RTRIM(RC.origen)) AS Origen, 
			LTRIM(RTRIM(RC.destino)) AS Destino, 
			LTRIM(RTRIM(RC.codigoempresa)) AS CodigoEmpresa,
			RC.prepaid, 
			RC.fechadesde, 
			ISNULL(RC.fechahasta, '12/31/2099') AS FechaHasta, 
			RC.formula, 
			RC.comision, 
			RC.descuento,
			RC.overcomision, 
			RC.manejo, 
			RC.diferenciatarifas, 
			ISNULL(RC.campo1, '') AS Campo1, 
			RC.campo2, 
			RC.campo3,
			RC.campo4, 
			RC.campo5, 
			RC.cedularesponsable
			FROM RentabilidadConvenios RC
			WHERE RC.activo = 1
			ORDER BY RC.fechadesde DESC
			RETURN
		END
	END TRY
	BEGIN CATCH
		EXEC [dbo].[pro_LogError]
	END CATCH
END
/*
EXEC [dbo].[AC_pro_RentabilidadConvenios]
	@IdAerolinea = '000', @IdConsignatario = 'TODOS', @IdPagador = 'TODOS', @IdMercancia = 'TODOS',
	@Origen = 'TODOS', @Destino = 'TODOS', @CodigoEmpresa = 'TODOS', @Prepaid = 'TODOS',
	@FechaEmbarque = '20260831', @TipoConvenio = 'COMISION', @Bandera = ''

EXEC [dbo].[AC_pro_RentabilidadConvenios]
	@IdAerolinea = '000', @IdConsignatario = 'TODOS', @IdPagador = 'TODOS', @IdMercancia = 'TODOS',
	@Origen = 'TODOS', @Destino = 'TODOS', @CodigoEmpresa = 'TODOS', @Prepaid = 'TODOS',
	@FechaEmbarque = '20260831', @TipoConvenio = 'COMISION', @Bandera = 'TODOS'

EXEC [dbo].[AC_pro_RentabilidadConvenios]
	@IdAerolinea = '000', @IdConsignatario = 'TODOS', @IdPagador = 'TODOS', @IdMercancia = 'TODOS',
	@Origen = 'TODOS', @Destino = 'TODOS', @CodigoEmpresa = 'TODOS', @Prepaid = 'TODOS',
	@FechaEmbarque = '20260831', @TipoConvenio = 'COMISION', @Bandera = 'TODOSACTIVOS'
*/