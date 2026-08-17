/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez      	2026-08-17		  58719			 Based on pro_OrdenesLocales_ValidacionDatos
*/
CREATE OR ALTER PROCEDURE [dbo].[AC_pro_ValidateAndClassifyLocalOrders] (
    @ListaOrdenLocal VARCHAR(MAX)
)
AS
BEGIN
    BEGIN TRY
        DECLARE @DatosEntradaOrdenLocal TABLE (
            Id INT,
            UnitId VARCHAR(16),
            ShipDate DATETIME,
            Shipper VARCHAR(16),
            BillToConsigneeId VARCHAR(32),
            Accion VARCHAR(12)
        )

        DECLARE @TableTemp TABLE (
            Id INT IDENTITY(1,1),
            CodigoBarraEntrada VARCHAR(16),
            CodigoBarraBase VARCHAR(16),
            ShipperEntrada VARCHAR(16),
            ShipperBase VARCHAR(16),
            BillToConsigneeEntrada VARCHAR(32),
            BillToConsigneeBase VARCHAR(32),
            ShipDateEntrada DATETIME,
            ShipDateBase DATETIME,
            IdOrdenLocal UNIQUEIDENTIFIER,
            IdGHDetalle UNIQUEIDENTIFIER,
            IdGuiaHouse UNIQUEIDENTIFIER,
            IdPoDetalle UNIQUEIDENTIFIER,
            IdPoEncabezado UNIQUEIDENTIFIER,
            EstadoPieza VARCHAR(16),
            Accion VARCHAR(12)
        )

        INSERT INTO @DatosEntradaOrdenLocal (
            UnitId,
            Shipper,
            ShipDate,
            BillToConsigneeId
        )
        SELECT 
            UnitId,
            Shipper,
            ShipDate,
            BillToConsigneeId
        FROM OPENJSON(@ListaOrdenLocal)
        WITH (
            UnitId VARCHAR(16) '$.UnitID',
            Shipper VARCHAR(16) '$.Shipper',
            ShipDate DATETIME '$.Shipdate',
            BillToConsigneeId VARCHAR(32) '$.BillToConsigneeId'
        )

        INSERT INTO @TableTemp (
            CodigoBarraEntrada,
            CodigoBarraBase,
            ShipperEntrada,
            ShipperBase,
            BillToConsigneeEntrada,
            BillToConsigneeBase,
            ShipDateEntrada,
            ShipDateBase,
            IdOrdenLocal,
            IdGHDetalle,
            IdGuiaHouse,
            IdPoDetalle,
            IdPoEncabezado,
            EstadoPieza,
            Accion
        )
        SELECT 
            TMP.UnitId,
            PD.CodigoBarra,
            TMP.Shipper,
            OL.IdExportador,
            TMP.BillToConsigneeId,
            OL.BillToConsigneeId,
            TMP.ShipDate,
            OL.FechaEntrega,
            OL.Id,
            GHD.Id,
            GHD.IdGuiaHouse,
            PD.Id,
            POE.Id,
            GHD.EstadoPieza,
            TMP.Accion
        FROM @DatosEntradaOrdenLocal TMP
        LEFT JOIN PoDetalles PD ON TMP.UnitId = PD.CodigoBarra
        LEFT JOIN PoEncabezado POE ON PD.IdPo = POE.Id
        LEFT JOIN OrdenesLocales OL ON POE.IdOrdenLocal = OL.Id
        LEFT JOIN GuiasHouseDetalles GHD ON TMP.UnitId = GHD.CodigoBarra

        UPDATE TMP
        SET TMP.Accion =  
            CASE 
                WHEN CodigoBarraBase IS NULL 
                AND BillToConsigneeBase IS NULL 
                AND ShipperBase IS NULL 
                AND ShipDateBase IS NULL THEN 'i'
                ELSE 
                    CASE 
                        WHEN BillToConsigneeBase = BillToConsigneeEntrada 
                        AND ShipperBase = ShipperEntrada 
                        AND ShipDateEntrada = ShipDateBase 
                        AND EstadoPieza = 'PENDING' THEN 'u'
                        ELSE 
                            CASE 
                                WHEN BillToConsigneeBase = BillToConsigneeEntrada 
                                AND ShipperBase = ShipperEntrada 
                                AND ShipDateEntrada = ShipDateBase 
                                AND EstadoPieza <> 'PENDING' THEN 'es'
                                ELSE 'e'
                            END
                    END
            END
        FROM @TableTemp TMP

        SELECT 
            Id,
            CodigoBarraEntrada,
            CodigoBarraBase,
            ShipperEntrada,
            ShipperBase,
            BillToConsigneeEntrada,
            BillToConsigneeBase,
            ShipDateEntrada,
            ShipDateBase,
            IdOrdenLocal,
            IdGHDetalle,
            IdGuiaHouse,
            IdPoDetalle,
            IdPoEncabezado,
            EstadoPieza,
            Accion
        FROM @TableTemp
    END TRY
    BEGIN CATCH
            EXEC [dbo].[pro_LogError]
    END CATCH
END