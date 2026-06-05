/*
VERSION		MODIFIEDBY			MODIFIEDDATE	  HU			 MODIFICATION
1			Jair Gomez	 	 	2026-05-15		  65319			 Fill RolesActors Table
*/

    DECLARE @CatEmployee   UNIQUEIDENTIFIER,
            @CatClient     UNIQUEIDENTIFIER,
            @CatExporter   UNIQUEIDENTIFIER,
            @CatBroker     UNIQUEIDENTIFIER,
            @IdEmpresa     VARCHAR(20) = 'EMP014'

    SELECT @CatEmployee   = Id FROM [dbo].[Catalogos] WHERE [codigo] = 'UserRoles' AND [identificador] = 'EMPLEADO_TYPE'
    SELECT @CatClient     = Id FROM [dbo].[Catalogos] WHERE [codigo] = 'UserRoles' AND [identificador] = 'CLIENTE_TYPE'
    SELECT @CatExporter   = Id FROM [dbo].[Catalogos] WHERE [codigo] = 'UserRoles' AND [identificador] = 'EXPORTADOR_TYPE'
    SELECT @CatBroker     = Id FROM [dbo].[Catalogos] WHERE [codigo] = 'UserRoles' AND [identificador] = 'BROKER_TYPE'

    IF @CatEmployee IS NULL OR @CatClient IS NULL OR @CatExporter IS NULL
        OR @CatBroker IS NULL
    BEGIN
        PRINT ('ERROR: UserRoles catalogs not found. Run the Catalogs script first.');
        RETURN;
    END

    -- Definimos @Id como INT basado en la respuesta del SP y creamos la tabla temporal para capturar el resultado
    DECLARE @Id INT
    DECLARE @TempId TABLE (id INT, unificado INT)

    -- =============================================
    -- EMPLEADO (79 roles)
    -- =============================================
    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '2ebf6a9f-bbe1-461c-bd3a-f892348a5ee6' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'2ebf6a9f-bbe1-461c-bd3a-f892348a5ee6',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- BI

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '340691A3-0989-4868-B9F5-82C3BEA9C1C7' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'340691A3-0989-4868-B9F5-82C3BEA9C1C7',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- BI AMS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '12D028CE-94D8-406C-A3B9-79058F88C0E2' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'12D028CE-94D8-406C-A3B9-79058F88C0E2',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- BODEGUERO MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'd9ea17b1-f8da-48e4-b46c-6d8362ebc1dd' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'d9ea17b1-f8da-48e4-b46c-6d8362ebc1dd',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- BOGOTA CODIFICACION

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'EA08E7CB-01EE-4E20-8D42-E7544063270A' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'EA08E7CB-01EE-4E20-8D42-E7544063270A',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CHOFER

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '03A295F7-CA96-4AE8-AB76-C9768F7B15C4' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'03A295F7-CA96-4AE8-AB76-C9768F7B15C4',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLAIMS MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '9E296BCF-BED2-44D4-9CA0-D2B4504EE3D0' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'9E296BCF-BED2-44D4-9CA0-D2B4504EE3D0',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COBRANZAS CO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '3E228D17-DCA2-401B-BDF5-AE9CDD04229A' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'3E228D17-DCA2-401B-BDF5-AE9CDD04229A',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COBRANZAS EC

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '7566D5F0-3B32-4A2E-BF0B-610BCF8D7221' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'7566D5F0-3B32-4A2E-BF0B-610BCF8D7221',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COBRANZAS MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'f1a9e25a-b81a-4c04-809d-c6a97788fab6' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'f1a9e25a-b81a-4c04-809d-c6a97788fab6',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CODIFICACION

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '00DCB10A-C268-4E9C-97D3-959C279B812E' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'00DCB10A-C268-4E9C-97D3-959C279B812E',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIAL COL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '47D23A64-4415-4E4D-9C3B-E6FBE3D38146' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'47D23A64-4415-4E4D-9C3B-E6FBE3D38146',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIAL IMPO-EXPO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'BAAA787B-314E-4119-BCC9-5E8C318452B9' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'BAAA787B-314E-4119-BCC9-5E8C318452B9',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CONTABILIDAD CO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '98C12ADC-ACF1-4263-A383-6E0C4E2678A3' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'98C12ADC-ACF1-4263-A383-6E0C4E2678A3',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CONTABILIDAD EC

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '481FD5A0-3890-4FA9-AF70-8B849CDDB07C' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'481FD5A0-3890-4FA9-AF70-8B849CDDB07C',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CONTABILIDAD MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'b9fbaf9a-10b3-47ac-a0c8-63813b72c4ed' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'b9fbaf9a-10b3-47ac-a0c8-63813b72c4ed',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CONTROLLER MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'da8b25a0-fc09-4ee9-ac21-2faf63b4cdc3' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'da8b25a0-fc09-4ee9-ac21-2faf63b4cdc3',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- DESPACHO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '0f614a96-6d6a-4156-adce-823c838b2f40' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'0f614a96-6d6a-4156-adce-823c838b2f40',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- EJECUTIVO VENTAS COL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '481c3d7f-fc19-47ec-9610-c9ffcd1f706f' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'481c3d7f-fc19-47ec-9610-c9ffcd1f706f',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- FINANCE PLANNING

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '16C83F33-E153-4029-B0F8-15C6E1ED5F55' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'16C83F33-E153-4029-B0F8-15C6E1ED5F55',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- GERENCIA COL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'c39b37a1-8413-4640-8340-fb99b89e3217' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'c39b37a1-8413-4640-8340-fb99b89e3217',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- GERENCIA COMERCIAL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'E9EA0F08-5A95-4B6D-89B8-286EDF883013' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'E9EA0F08-5A95-4B6D-89B8-286EDF883013',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- GERENCIA ECU

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '19B79F62-6589-4889-8A0B-2F3D337C5253' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'19B79F62-6589-4889-8A0B-2F3D337C5253',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- GERENCIA FIN EC

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'DC38D934-83A2-438F-8EC3-6F64A8CCB707' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'DC38D934-83A2-438F-8EC3-6F64A8CCB707',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- GERENCIA MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '0C0605F1-3803-4D7D-9D9C-36C0AAA6BAC6' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'0C0605F1-3803-4D7D-9D9C-36C0AAA6BAC6',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- GERENTE OPS AMS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'C0492171-2CCF-4872-A721-7B148D5D3190' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'C0492171-2CCF-4872-A721-7B148D5D3190',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- HR MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '092F15A2-AC77-4582-97D1-0D98B3DBE917' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'092F15A2-AC77-4582-97D1-0D98B3DBE917',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- IMPORTACIONES

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '728b930f-f90a-45af-bff7-ecb90dff97c9' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'728b930f-f90a-45af-bff7-ecb90dff97c9',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- JEFATURA OPERACIONAL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'CA848BF5-5527-4CC7-A083-197E3BFC16C1' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'CA848BF5-5527-4CC7-A083-197E3BFC16C1',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- JEFE SERVICIO AL CLIENTE

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '62E18BD0-852C-4E8B-8B60-F8593540FF99' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'62E18BD0-852C-4E8B-8B60-F8593540FF99',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- MARITIMO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'F1FE7B21-B001-4D0E-9DAF-C086D6871665' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'F1FE7B21-B001-4D0E-9DAF-C086D6871665',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- MARKETING

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'F1FE7B21-B001-4D0E-9DAF-C086D6871555' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'F1FE7B21-B001-4D0E-9DAF-C086D6871555',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- MARKETING BI

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '34F65310-1A00-4C6B-BB66-86FC41DF637D' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'34F65310-1A00-4C6B-BB66-86FC41DF637D',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- MARKETING BI AMS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '6ba9ea38-f836-4272-afbc-d8e7f65e5197' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'6ba9ea38-f836-4272-afbc-d8e7f65e5197',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- MEDELLIN CODIFICACION

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '605774BF-BFBB-4228-BBA9-732799C263B3' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'605774BF-BFBB-4228-BBA9-732799C263B3',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES AMS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '5108A1E8-B057-4FBF-83D8-9EFB3E80E898' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'5108A1E8-B057-4FBF-83D8-9EFB3E80E898',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES COL BOG

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'F9ED34FF-F838-48D6-854F-C61F1BC54156' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'F9ED34FF-F838-48D6-854F-C61F1BC54156',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES COL MED

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'f91b885a-b456-4cfb-b757-14c0838eb858' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'f91b885a-b456-4cfb-b757-14c0838eb858',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES DOCS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'E5748746-4787-4B53-87B3-68DE78E28EF6' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'E5748746-4787-4B53-87B3-68DE78E28EF6',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES GUA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '0139467E-9652-4F77-85B9-879A920CD312' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'0139467E-9652-4F77-85B9-879A920CD312',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '1c0ac610-8be0-40f5-8bda-5db3d762220f' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'1c0ac610-8be0-40f5-8bda-5db3d762220f',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES MONITOREO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'db10dbfb-19db-4c17-acc6-a8da539d0c60' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'db10dbfb-19db-4c17-acc6-a8da539d0c60',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- OPERACIONES SJO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '349CFDF3-73A2-4F18-AD2D-A8BA6B141499' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'349CFDF3-73A2-4F18-AD2D-A8BA6B141499',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- PERFIL DE CONSULTA COL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '31409E37-8C77-473A-9DAB-AC851DE5F9F1' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'31409E37-8C77-473A-9DAB-AC851DE5F9F1',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- RECEIVING MANAGEMENT

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '3C2ECB86-B56B-4178-9811-B1CD4EE8155A' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'3C2ECB86-B56B-4178-9811-B1CD4EE8155A',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- RECEPCION OFICINA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '4e08fce8-d18e-441e-8c4f-01804ac35770' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'4e08fce8-d18e-441e-8c4f-01804ac35770',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- RECEPCION Y BODEGA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'b106ca7b-3954-4d13-8baf-81e69984381d' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'b106ca7b-3954-4d13-8baf-81e69984381d',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- RECLAMOS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'c72a2877-1af4-4c6e-afe2-c0358a30dc0b' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'c72a2877-1af4-4c6e-afe2-c0358a30dc0b',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- RECURSOS HUMANOS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '7e34883b-790c-470a-aac1-2b55cfacaf56' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'7e34883b-790c-470a-aac1-2b55cfacaf56',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- RESERVAS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '8b3ad83d-c65a-43ee-91d7-5468beb4bc9a' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'8b3ad83d-c65a-43ee-91d7-5468beb4bc9a',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- RESERVAS COL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '328BB726-4AE7-447A-BB36-2A4DE346266D' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'328BB726-4AE7-447A-BB36-2A4DE346266D',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SCANNER MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '906cf861-9970-4c4f-8b87-e4fc6c9cff14' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'906cf861-9970-4c4f-8b87-e4fc6c9cff14',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SEGURIDAD

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '36DE05FF-EEB8-4AC9-BF63-0E791BCCF1F3' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'36DE05FF-EEB8-4AC9-BF63-0E791BCCF1F3',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SEGURIDAD CO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '52B48C54-9C41-4247-9307-E4F3F9A1BB66' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'52B48C54-9C41-4247-9307-E4F3F9A1BB66',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SEGURIDAD SISTEMAS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '64561b5f-17d2-4ebd-870d-d7226f31077f' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'64561b5f-17d2-4ebd-870d-d7226f31077f',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SERVICIO AL CLIENTE

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'C6CFDB5C-8AD1-4320-9FD0-1F5538A45484' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'C6CFDB5C-8AD1-4320-9FD0-1F5538A45484',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SERVICIO AL CLIENTE COMERCIAL COL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '6A823E6C-8ADB-4E6E-BC32-C8ECE54FB438' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'6A823E6C-8ADB-4E6E-BC32-C8ECE54FB438',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SERVICIO AL CLIENTE MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'e903addd-f301-43f8-86be-ac0067cae868' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'e903addd-f301-43f8-86be-ac0067cae868',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SISTEMAS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '6d69b428-eaab-4ab9-8a61-3b4df288e296' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'6d69b428-eaab-4ab9-8a61-3b4df288e296',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SISTEMAS FINANZAS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'D0611047-B8D3-4BBA-A596-0D08E040CC8E' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'D0611047-B8D3-4BBA-A596-0D08E040CC8E',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SOCIOS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '200DF558-D2BF-4C45-9D55-931F397E5C7F' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'200DF558-D2BF-4C45-9D55-931F397E5C7F',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR AMS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '200DF558-D2BF-4C45-9D55-931F387E5C6F' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'200DF558-D2BF-4C45-9D55-931F387E5C6F',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR BI AMS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'DC0748AA-7074-4A4B-9FD7-3A93D3A2A83D' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'DC0748AA-7074-4A4B-9FD7-3A93D3A2A83D',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR DE OPERACIONES COL BOG

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '5DAF00BE-7C1E-418B-ACAE-023346F1CDDB' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'5DAF00BE-7C1E-418B-ACAE-023346F1CDDB',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR IT AMS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'A9AA9150-F852-4CE9-89B1-6041BFBF68CF' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'A9AA9150-F852-4CE9-89B1-6041BFBF68CF',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '1b660738-9b0f-4be0-974a-27948e4d93e3' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'1b660738-9b0f-4be0-974a-27948e4d93e3',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR OPERATIVO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '7BF3B7AC-FF68-4816-B2AA-855628C3F536' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'7BF3B7AC-FF68-4816-B2AA-855628C3F536',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR OPS MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '03EC2FA0-80DC-40B6-9CB8-BCC839AC49D8' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'03EC2FA0-80DC-40B6-9CB8-BCC839AC49D8',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR PROCESOS MIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '24C42340-1653-4A7B-925D-0E6A74559406' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'24C42340-1653-4A7B-925D-0E6A74559406',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR SERVICIO AL CLIENTE

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'D404F355-7A96-431E-9C69-A5CBAFEFE759' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'D404F355-7A96-431E-9C69-A5CBAFEFE759',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR SERVICIO AL CLIENTE COL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '576CFEA4-71A8-46CA-B6E6-CFED38E54BB7' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'576CFEA4-71A8-46CA-B6E6-CFED38E54BB7',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR SERVICIO AL CLIENTE UIO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '5E687C15-AEDC-43C2-9FEB-0C754E7EA70A' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'5E687C15-AEDC-43C2-9FEB-0C754E7EA70A',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- SUPERVISOR VENTAS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '83380485-21d4-4424-bcb8-d13c979cbff3' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'83380485-21d4-4424-bcb8-d13c979cbff3',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- TEST5

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '3ab2403d-40bb-44c0-b6c4-68a880597ebf' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'3ab2403d-40bb-44c0-b6c4-68a880597ebf',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- TRAFICO AEREO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'c114267e-456f-4aa1-a0e2-a23156aa087b' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'c114267e-456f-4aa1-a0e2-a23156aa087b',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- TRANSMISIONES A LA ADUANA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'de31a307-163e-4cbb-b7fe-933334cb2341' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'de31a307-163e-4cbb-b7fe-933334cb2341',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- TRANSPORTISTA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'E0045FBC-2854-4B4E-BD7A-2B9D5114D9EA' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'E0045FBC-2854-4B4E-BD7A-2B9D5114D9EA',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- TV Miami

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '49ba35d9-71c0-416a-a9cb-068685299d61' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'49ba35d9-71c0-416a-a9cb-068685299d61',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- VENTAS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '857D7864-9846-463A-A31B-F8E91F89A706' AND [CatalogosId] = @CatEmployee)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'857D7864-9846-463A-A31B-F8E91F89A706',@CatEmployee,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- VENTAS AMS

    -- =============================================
    -- CLIENTE (10 roles)
    -- =============================================
    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '146e80da-cffa-4d03-a4bc-a39ccf178a7e' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'146e80da-cffa-4d03-a4bc-a39ccf178a7e',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '3361AEA8-536D-467B-8D9A-F7485FA62452' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'3361AEA8-536D-467B-8D9A-F7485FA62452',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES 360

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '22EA7F22-5E76-4F99-813B-88F5E1A0C497' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'22EA7F22-5E76-4F99-813B-88F5E1A0C497',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES 360 DESPACHO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'DD13A4F4-77A3-4802-B93C-47D9AE9EB463' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'DD13A4F4-77A3-4802-B93C-47D9AE9EB463',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES 360 INVENTARIO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'E9778E85-FA4A-4A81-8699-4BB15FFDB875' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'E9778E85-FA4A-4A81-8699-4BB15FFDB875',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES DESPACHO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'B7D09D61-5B5C-43BB-B499-4C2D0FF07883' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'B7D09D61-5B5C-43BB-B499-4C2D0FF07883',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES DESPACHO SIN OL

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '3BF88A61-729E-4C04-93BD-3B0BFDA4AA9D' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'3BF88A61-729E-4C04-93BD-3B0BFDA4AA9D',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES EXPORTADOR

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'ED18026E-4AD3-4577-9787-BFF822C9B2A1' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'ED18026E-4AD3-4577-9787-BFF822C9B2A1',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES INVENTARIO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '09F299B5-FF76-4E98-B805-B066E6AD9D37' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'09F299B5-FF76-4E98-B805-B066E6AD9D37',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES PLAN B

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '1640BFBA-A151-48ED-ABC7-6A0FEA39A216' AND [CatalogosId] = @CatClient)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'1640BFBA-A151-48ED-ABC7-6A0FEA39A216',@CatClient,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- CLIENTES PO

    -- =============================================
    -- EXPORTADOR (12 roles)
    -- =============================================
    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '5F1DA7E5-F719-4837-915A-99C6B6303021' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'5F1DA7E5-F719-4837-915A-99C6B6303021', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIALIZADORA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '03A2D783-21D4-4020-A719-165C1B299760' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'03A2D783-21D4-4020-A719-165C1B299760', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIALIZADORA AMSTERDAN

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '7F5E1F24-E31A-4DDD-944B-6B7502484FF1' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'7F5E1F24-E31A-4DDD-944B-6B7502484FF1', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIALIZADORA BOGOTA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '166E7C6B-3A90-414E-8FD7-73C84B0ACAD3' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'166E7C6B-3A90-414E-8FD7-73C84B0ACAD3', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIALIZADORA GUATEMALA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '942F12F8-ECBA-440A-925C-42F1C0878B07' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'942F12F8-ECBA-440A-925C-42F1C0878B07', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIALIZADORA MEDELLIN

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '51F22256-B133-466B-9535-46EDF5E215B3' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'51F22256-B133-466B-9535-46EDF5E215B3', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIALIZADORA MIAMI

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '530E12CD-8E40-4CB4-99A9-4A4D94950ACC' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'530E12CD-8E40-4CB4-99A9-4A4D94950ACC', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- COMERCIALIZADORA PO

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '1e4125bf-7866-4fa0-837d-43a1df2a0fd7' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'1e4125bf-7866-4fa0-837d-43a1df2a0fd7', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- EXPORTADOR

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'E955AF16-586F-4A52-9DA6-61209809F9D9' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'E955AF16-586F-4A52-9DA6-61209809F9D9', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- EXPORTADOR COLOMBIA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'B0FBA674-93FA-4849-9480-51F9BD5FBA91' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'B0FBA674-93FA-4849-9480-51F9BD5FBA91', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- EXPORTADOR COSTA RICA

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'C92790AE-1FB9-4EB7-953C-A53064635E81' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'C92790AE-1FB9-4EB7-953C-A53064635E81', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- EXPORTADOR ESTADOS UNIDOS

    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = 'DBF21744-1A75-41E9-B445-4DE816192101' AND [CatalogosId] = @CatExporter)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'DBF21744-1A75-41E9-B445-4DE816192101', @CatExporter,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- EXPORTADOR GUATEMALA

    -- =============================================
    -- BROKER (1 rol)
    -- =============================================
    IF NOT EXISTS (SELECT 1 FROM [dbo].[RolesActors] WHERE [AspNetRoleId] = '876F1564-DFC3-43DB-8BFD-3E5F1395E52A' AND [CatalogosId] = @CatBroker)
    BEGIN DELETE FROM @TempId; INSERT INTO @TempId (id, unificado) EXEC dbo.AC_pro_General_GenerateBulkInt @table = 'RolesActors', @idEmpresa = @IdEmpresa; SELECT TOP 1 @Id = unificado FROM @TempId;
    INSERT INTO [dbo].[RolesActors] ([Id],[AspNetRoleId],[CatalogosId],[Status],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
    VALUES (@Id,'876F1564-DFC3-43DB-8BFD-3E5F1395E52A',@CatBroker,1,'qVYus9gi',GETDATE(),'qVYus9gi',GETDATE()); END; -- BROKER