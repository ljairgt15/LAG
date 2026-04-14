/*
VERSION		MODIFIEDBY				MODIFIEDDATE	HU					MODIFICATION
1			Mateo Velasco			2025-06-25		AC 51314			Initial Code - Creation of Consignees Rol
2			Jorge Ortiz			    2025-07-24		LAG-CT-013 53071	Initial Code - Add new Catalog
3           Ian Carlos Ortega       2025-12-15      LAG-CT-019 55188    Add new role called 'CLIENTE' to UserRoles catalog
4           Jair Gomez              2026-04-14      LAG-CT-022 55188    Add suffix _TYPE to UserRoles catalog 
*/
IF NOT EXISTS (
      SELECT 1
      FROM [dbo].[Catalogos]
      WHERE [codigo] = 'UserRoles' 
      AND [identificador] IN (
            'AGENCIA_CARGA_TYPE',
            'BROKER_TYPE',
            'EMPLEADO_TYPE',
            'EXPORTADOR_TYPE',
            'BILLTO_TYPE',
            'CONSIGNEE_TYPE',
            'CLIENTE_TYPE'
      )
)
BEGIN
    DECLARE @IdNew INT;
    SELECT @IdNew = MAX([IdNew]) + 1
    FROM [dbo].[Catalogos];

    INSERT INTO [dbo].[Catalogos]
        (
        [idEmpresa]
        ,[nombre]
        ,[nombreIngles]
        ,[codigo]
        ,[tipo]
        ,[descripcion]
        ,[status]
        ,[nota]
        ,[fechaCambio]
        ,[identificador]
        ,[clase]
        ,[codigoRelacion]
        ,[orden]
        ,[oculto]
        ,[idCatalgoPadre]
        ,[idRegistroVinculado]
        ,[IdNew]
        )
    VALUES
        (
        NULL
        ,'AGENCIA DE CARGA'
        ,'CARGO AGENCY'
        ,'UserRoles'
        ,'ENUMERACION'
        ,'User role type for listing'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'AGENCIA_CARGA_TYPE'
        ,NULL
        ,NULL
        ,1
        ,0
        ,NULL
        ,NULL
        ,@IdNew
        );

    SELECT @IdNew = MAX([IdNew]) + 1
    FROM [dbo].[Catalogos];
    INSERT INTO [dbo].[Catalogos]
    (
        [idEmpresa]
        ,[nombre]
        ,[nombreIngles]
        ,[codigo]
        ,[tipo]
        ,[descripcion]
        ,[status]
        ,[nota]
        ,[fechaCambio]
        ,[identificador]
        ,[clase]
        ,[codigoRelacion]
        ,[orden]
        ,[oculto]
        ,[idCatalgoPadre]
        ,[idRegistroVinculado]
        ,[IdNew]
        )
    VALUES
    (
        NULL
        ,'BROKER'
        ,'BROKER'
        ,'UserRoles'
        ,'ENUMERACION'
        ,'User role type for listing'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'BROKER_TYPE'
        ,NULL
        ,NULL
        ,2
        ,0
        ,NULL
        ,NULL
        ,@IdNew
    );

    SELECT @IdNew = MAX([IdNew]) + 1
    FROM [dbo].[Catalogos];
    INSERT INTO [dbo].[Catalogos]
    (
        [idEmpresa]
        ,[nombre]
        ,[nombreIngles]
        ,[codigo]
        ,[tipo]
        ,[descripcion]
        ,[status]
        ,[nota]
        ,[fechaCambio]
        ,[identificador]
        ,[clase]
        ,[codigoRelacion]
        ,[orden]
        ,[oculto]
        ,[idCatalgoPadre]
        ,[idRegistroVinculado]
        ,[IdNew]
    )
    VALUES
    (
        NULL
        ,'EMPLEADO'
        ,'EMPLOYEE'
        ,'UserRoles'
        ,'ENUMERACION'
        ,'User role type for listing'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'EMPLEADO_TYPE'
        ,NULL
        ,NULL
        ,4
        ,0
        ,NULL
        ,NULL
        ,@IdNew
    );

    SELECT @IdNew = MAX([IdNew]) + 1
    FROM [dbo].[Catalogos];
    INSERT INTO [dbo].[Catalogos]
        (
        [idEmpresa]
        ,[nombre]
        ,[nombreIngles]
        ,[codigo]
        ,[tipo]
        ,[descripcion]
        ,[status]
        ,[nota]
        ,[fechaCambio]
        ,[identificador]
        ,[clase]
        ,[codigoRelacion]
        ,[orden]
        ,[oculto]
        ,[idCatalgoPadre]
        ,[idRegistroVinculado]
        ,[IdNew]
        )
    VALUES
        (
        NULL
        ,'EXPORTADOR'
        ,'EXPORTER'
        ,'UserRoles'
        ,'ENUMERACION'
        ,'User role type for listing'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'EXPORTADOR_TYPE'
        ,NULL
        ,NULL
        ,5
        ,0
        ,NULL
        ,NULL
        ,@IdNew
        );

    SELECT @IdNew = MAX([IdNew]) + 1
    FROM [dbo].[Catalogos];
    INSERT INTO [dbo].[Catalogos]
        (
        [idEmpresa]
        ,[nombre]
        ,[nombreIngles]
        ,[codigo]
        ,[tipo]
        ,[descripcion]
        ,[status]
        ,[nota]
        ,[fechaCambio]
        ,[identificador]
        ,[clase]
        ,[codigoRelacion]
        ,[orden]
        ,[oculto]
        ,[idCatalgoPadre]
        ,[idRegistroVinculado]
        ,[IdNew]
        )
    VALUES
        (
        NULL
        ,'BILL TO'
        ,'BILL TO'
        ,'UserRoles'
        ,'ENUMERACION'
        ,'User role type for listing'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'BILLTO_TYPE'
        ,NULL
        ,NULL
        ,7
        ,0
        ,NULL
        ,NULL
        ,@IdNew
        );

    SELECT @IdNew = MAX([IdNew]) + 1
    FROM [dbo].[Catalogos];

    INSERT INTO [dbo].[Catalogos]
        (
        [idEmpresa]
        ,[nombre]
        ,[nombreIngles]
        ,[codigo]
        ,[tipo]
        ,[descripcion]
        ,[status]
        ,[nota]
        ,[fechaCambio]
        ,[identificador]
        ,[clase]
        ,[codigoRelacion]
        ,[orden]
        ,[oculto]
        ,[idCatalgoPadre]
        ,[idRegistroVinculado]
        ,[IdNew]
        )
    VALUES
        (
        NULL
        ,'CONSIGNATARIOS'
        ,'CONSIGNEES'
        ,'UserRoles'
        ,'ENUMERACION'
        ,'User role type for listing'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'CONSIGNEE_TYPE'
        ,NULL
        ,NULL
        ,3
        ,0
        ,NULL
        ,NULL,
        @IdNew
        );

    SELECT @IdNew = MAX([IdNew]) + 1
    FROM [dbo].[Catalogos];

    INSERT INTO [dbo].[Catalogos]
        (
        [idEmpresa]
        ,[nombre]
        ,[nombreIngles]
        ,[codigo]
        ,[tipo]
        ,[descripcion]
        ,[status]
        ,[nota]
        ,[fechaCambio]
        ,[identificador]
        ,[clase]
        ,[codigoRelacion]
        ,[orden]
        ,[oculto]
        ,[idCatalgoPadre]
        ,[idRegistroVinculado]
        ,[IdNew]
        )
    VALUES
        (
        NULL
        ,'CLIENTE'
        ,'CLIENT'
        ,'UserRoles'
        ,'ENUMERACION'
        ,'User role type for listing'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'CLIENTE_TYPE'
        ,NULL
        ,NULL
        ,8
        ,0
        ,NULL
        ,NULL,
        @IdNew
        );
END;