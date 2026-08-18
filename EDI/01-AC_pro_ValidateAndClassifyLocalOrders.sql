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
/*
exec [dbo].[AC_pro_ValidateAndClassifyLocalOrders]
@listaOrdenLocal=N'[{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696564","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696566","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696584","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696586","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696595","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696599","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696637","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696641","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696645","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696647","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696658","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696690","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696692","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696699","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696702","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696729","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696754","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696756","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696760","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696814","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523696824","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972375","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972377","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972379","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972380","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972383","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972384","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972387","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972388","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972389","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972396","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972400","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972401","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972402","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972403","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972408","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972409","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972416","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972417","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972420","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972421","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972422","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972438","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972439","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972440","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972441","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972442","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972443","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972444","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972445","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972446","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972447","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972449","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972450","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972451","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972452","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972453","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972454","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972455","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972456","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972457","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972458","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972459","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972460","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972461","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972462","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972463","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972464","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972466","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972467","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972468","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972469","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972470","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972471","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972472","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972473","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972474","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972475","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972476","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972477","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972478","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972479","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972480","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972481","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972482","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972483","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972484","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972485","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972486","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523972487","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523973998","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523973999","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974000","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974001","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974002","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974003","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974004","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974005","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974006","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974007","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974008","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974009","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR523974010","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263003","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263004","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263008","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263010","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263028","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263029","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263030","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263031","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263032","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263033","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263064","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263066","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263088","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263095","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263098","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263099","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263100","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263101","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263104","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263105","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263106","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263107","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524263108","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524376865","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524376868","BillToConsigneeId":"REL012258"},{"Shipdate":"2026-08-13T00:00:00","Shipper":"EXP051737","UnitID":"PR524376869","BillToConsigneeId":"REL012258"}]'
*/