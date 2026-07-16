-------------------------------------------------------------------------
--  pro_Scanner_ConsultarInformacionPicking    
--
--  procedimiento para abasstraer informacion de picking para el scanner segundo nivel
--
--  VERSION		AUTOR			FECHA		HU			CAMBIO
--  1			Edwin Casa  	10-03-2023	SC		  	Codigo Inicial
-------------------------------------------------------------------------
ALTER   PROCEDURE [dbo].[pro_AgregarMarcaPickingScanner]
(
	@isPallet bit,
	@codigoDeBarra VARCHAR(32),
	@idUsuarioLogPicking VARCHAR(16)
)
AS
BEGIN
BEGIN TRY

	DECLARE @resultado VARCHAR(16) = '', 
			@Bad VARCHAR(16) ='Bad', 
			@Ok VARCHAR(16) = 'Ok'
		
	CREATE TABLE #ProgramacionCarrierTemp(
		[id] [UNIQUEIDENTIFIER]
	)	
	BEGIN TRAN
		IF @isPallet = 1
		BEGIN
		
			INSERT INTO #ProgramacionCarrierTemp
			SELECT 
				pc.id
			FROM
				Pallets PL  
				INNER JOIN PalletsDetalles PLD ON PLD.idPallet = PL.id
				INNER JOIN ProgramacionCarrier PC ON PC.idGuiaHouseDetalle = PLD.idGuiasHouseDetalle
			WHERE PL.pallet = @codigoDeBarra
		
			UPDATE PC
			SET
				PC.[idUsuarioLogPicking] = @idUsuarioLogPicking,
				PC.fechaCambioPicking = GETDATE(),
				PC.idUsuarioLog = @idUsuarioLogPicking,
				PC.fechaCambio =  GETDATE()
			FROM 
				#ProgramacionCarrierTemp PCTemp
				INNER JOIN ProgramacionCarrier PC ON PC.id = PCTemp.id
		
			SELECT  @resultado = @Ok
		
		END
		ELSE
		BEGIN 

			UPDATE PC
			SET 
				PC.[idUsuarioLogPicking] = @idUsuarioLogPicking,
				PC.fechaCambioPicking = GETDATE(),
				PC.idUsuarioLog = @idUsuarioLogPicking,
				PC.fechaCambio =  GETDATE()
			FROM 
				dbo.GuiasHouseDetalles GHD 
				INNER JOIN dbo.ProgramacionCarrier PC ON PC.idGuiaHouseDetalle = GHD.id
			WHERE GHD.codigoBarra = @codigoDeBarra
				
			SELECT @resultado =@Ok
		
		
		END

		SELECT 
			1  AS id,
			@resultado AS response
	COMMIT TRAN
END TRY
BEGIN CATCH		
	ROLLBACK TRAN
	EXEC [dbo].[pro_LogError] 
END CATCH;	

END
