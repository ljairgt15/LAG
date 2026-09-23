/*    
VERSION     MODIFIEDBY          MODIFIEDDATE    HU          MODIFICATION
1           Jair Gómez          2026-09-23      64492       Based on pro_RentabilidadConveniosGuardar
2           Jair Gómez          2026-09-23      64492       Add soft delete functionality
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_ManageRentabilidadConvenios]
    @Id CHAR(13),
    @Activo BIT,
    @IdAerolinea VARCHAR(5),
    @IdConsignatario VARCHAR(30),
    @IdPagador VARCHAR(30),
    @IdMercancia VARCHAR(30),
    @Origen VARCHAR(30),
    @Destino VARCHAR(30),
    @CodigoEmpresa VARCHAR(30),
    @Prepaid VARCHAR(7),
    @FechaDesde DATETIME,
    @FechaHasta DATETIME,
    @TipoConvenio VARCHAR(50),
    @Formula VARCHAR(8000),
    @Comision VARCHAR(500),
    @Descuento VARCHAR(500),
    @Overcomision VARCHAR(500),
    @Manejo VARCHAR(500),
    @DiferenciaTarifas VARCHAR(500),
    @Campo1 VARCHAR(500),
    @Campo2 VARCHAR(500),
    @Campo3 VARCHAR(500),
    @Campo4 VARCHAR(500),
    @Campo5 VARCHAR(500),
    @CedulaResponsable VARCHAR(13),
    @FechaModificacion DATETIME,
    @Bandera VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        IF (@Bandera = 'INSERTAR')
        BEGIN
            INSERT INTO RentabilidadConvenios (
                id, idAerolinea, activo, idConsignatario,
                idPagador, idMercancia, origen,
                destino, codigoempresa, prepaid,
                fechadesde, fechahasta, tipoConvenio,
                Formula, comision, descuento,
                overcomision, manejo, diferenciatarifas,
                campo1, campo2, campo3, 
                campo4, campo5, cedularesponsable, fechamodificacion
            )
            VALUES (
                @Id, @IdAerolinea, @Activo, @IdConsignatario,
                @IdPagador, @IdMercancia, @Origen,
                @Destino, @CodigoEmpresa, @Prepaid,
                @FechaDesde, @FechaHasta, @TipoConvenio,
                @Formula, @Comision, @Descuento,
                @Overcomision, @Manejo, @DiferenciaTarifas,
                @Campo1, @Campo2, @Campo3, 
                @Campo4, @Campo5, @CedulaResponsable, @FechaModificacion
            );
            RETURN;
        END

        IF (@Bandera = 'ACTUALIZAR')
        BEGIN
            UPDATE RentabilidadConvenios 
            SET 
                idAerolinea = @IdAerolinea, 
                activo = @Activo, 
                idConsignatario = @IdConsignatario,
                idPagador = @IdPagador, 
                idMercancia = @IdMercancia, 
                origen = @Origen,
                destino = @Destino, 
                codigoempresa = @CodigoEmpresa, 
                prepaid = @Prepaid,
                fechadesde = @FechaDesde, 
                fechahasta = @FechaHasta, 
                tipoConvenio = @TipoConvenio,
                Formula = @Formula, 
                comision = @Comision, 
                descuento = @Descuento,
                overcomision = @Overcomision, 
                manejo = @Manejo, 
                diferenciatarifas = @DiferenciaTarifas,
                campo1 = @Campo1, 
                campo2 = @Campo2, 
                campo3 = @Campo3, 
                campo4 = @Campo4, 
                campo5 = @Campo5,
                cedularesponsable = @CedulaResponsable,
                fechamodificacion = @FechaModificacion
            WHERE 
                id = @Id;
            RETURN;
        END

        IF (@Bandera = 'ELIMINAR')
        BEGIN
            UPDATE RentabilidadConvenios 
            SET 
                activo = 0,
                fechamodificacion = @FechaModificacion,
                cedularesponsable = @CedulaResponsable
            WHERE 
                id = @Id;
            RETURN;
        END
    END TRY
    BEGIN CATCH
        EXEC [dbo].[pro_LogError];
    END CATCH
END
GO

/*
EJEMPLO DE EJECUCIÓN (Modifica datos en base a la @Bandera):
EXEC [dbo].[AC_pro_ManageRentabilidadConvenios] 
    @Id = 'CONV000000001', 
    @Activo = 1, 
    @IdAerolinea = 'AL001', 
    @IdConsignatario = 'CONS001', 
    @IdPagador = 'PAG001', 
    @IdMercancia = 'MER001', 
    @Origen = 'UIO', 
    @Destino = 'MIA', 
    @CodigoEmpresa = 'EMP01', 
    @Prepaid = 'PREPAID', 
    @FechaDesde = '2026-09-01 00:00:00', 
    @FechaHasta = '2026-12-31 23:59:59', 
    @TipoConvenio = 'ESTANDAR', 
    @Formula = 'A+B', 
    @Comision = '10', 
    @Descuento = '5', 
    @Overcomision = '2', 
    @Manejo = '1', 
    @DiferenciaTarifas = '0', 
    @Campo1 = '', @Campo2 = '', @Campo3 = '', @Campo4 = '', @Campo5 = '', 
    @CedulaResponsable = '1700000000', 
    @FechaModificacion = '2026-09-23 10:45:00', 
    @Bandera = 'INSERTAR'
*/