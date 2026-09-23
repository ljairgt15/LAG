CREATE OR ALTER PROCEDURE [dbo].[pro_RentabilidadConveniosGuardar]
	@id char(13)
   ,@activo bit
   ,@idAerolinea varchar(5)
   ,@idConsignatario varchar(30)
   ,@idPagador varchar(30)
   ,@idMercancia varchar(30)
   ,@origen varchar(30)
   ,@destino varchar(30)
   ,@codigoempresa varchar(30)
   ,@prepaid varchar(7)
   ,@fechadesde datetime
   ,@fechahasta datetime
   ,@tipoConvenio varchar(50)
   ,@Formula varchar(8000)
   ,@comision varchar(500)
   ,@descuento varchar(500)
   ,@overcomision varchar(500)
   ,@manejo varchar(500)
   ,@diferenciatarifas varchar(500)
   ,@campo1 varchar(500)
   ,@campo2 varchar(500)
   ,@campo3 varchar(500)
   ,@campo4 varchar(500)
   ,@campo5 varchar(500)
   ,@cedularesponsable varchar(13)
   ,@fechamodificacion datetime
   ,@bandera varchar(20)
AS
BEGIN

	IF (@bandera='INSERTAR')
	BEGIN
		INSERT INTO rentabilidadconvenios 
				(id, idAerolinea, activo, idConsignatario,
                idPagador, idMercancia, origen,
                destino, codigoempresa, prepaid,
                fechadesde, fechahasta, tipoConvenio,
				Formula, comision, descuento,
				overcomision, manejo, diferenciatarifas,
				campo1, campo2, campo3, 
				campo4, campo5, cedularesponsable, fechamodificacion)
		VALUES (@id, @idAerolinea, @activo, @idConsignatario,
                @idPagador, @idMercancia, @origen,
                @destino , @codigoempresa , @prepaid,
                @fechadesde , @fechahasta , @tipoConvenio ,
				@Formula , @comision , @descuento ,
				@overcomision , @manejo , @diferenciatarifas ,
				@campo1 , @campo2 , @campo3 , 
				@campo4 , @campo5, @cedularesponsable, @fechamodificacion)
		RETURN
	END

	IF (@bandera='ACTUALIZAR')
	BEGIN
			UPDATE rentabilidadconvenios 
			SET idAerolinea = @idAerolinea, activo = @activo, idConsignatario = @idConsignatario,
					idPagador = @idPagador , idMercancia = @idMercancia, origen = @origen,
					destino = @destino, codigoempresa = @codigoempresa, prepaid = @prepaid,
					fechadesde = @fechadesde, fechahasta = @fechahasta, tipoConvenio = @tipoConvenio,
					Formula = @Formula, comision = @comision, descuento = @descuento,
					overcomision = @overcomision, manejo = @manejo, diferenciatarifas = @diferenciatarifas,
					campo1 = @campo1, campo2 = @campo2, campo3 = @campo3, 
					campo4 = @campo4, campo5 = @campo5,
					cedularesponsable = @cedularesponsable,
					fechamodificacion = @fechamodificacion
			WHERE id = @id
		RETURN
	END
	IF (@bandera='ELIMINAR')
	BEGIN
		-- Eliminación lógica (Soft Delete)
		UPDATE rentabilidadconvenios 
		SET activo = 0,
		    fechamodificacion = @fechamodificacion,
		    cedularesponsable = @cedularesponsable
		WHERE id = @id
		RETURN
	END

END