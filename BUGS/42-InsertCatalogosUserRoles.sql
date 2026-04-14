/*
VERSION		MODIFIEDBY				MODIFIEDDATE	HU					MODIFICATION
1			Mateo Velasco			2025-06-25		AC 51314			Initial Code - Creation of Consignees Rol
2			Jorge Ortiz			    2025-07-24		LAG-CT-013 53071	Initial Code - Add new Catalog
3           Ian Carlos Ortega       2025-12-15      LAG-CT-019 55188    Add new role called 'CLIENTE' to UserRoles catalog
*/
IF NOT EXISTS (
      SELECT 1
      FROM [dbo].[Catalogos]
      WHERE [codigo] = 'UserRoles' 
      AND [identificador] IN (
            'AGENCIA_CARGA',
            'BROKER',
            'EMPLEADO',
            'EXPORTADOR',
            'BILLTO',
            'CONSIGNEE',
            'CLIENTE'
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
        ,'AGENCIA_CARGA'
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
        ,'BROKER'
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
        ,'EMPLEADO'
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
        ,'EXPORTADOR'
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
        ,'BILLTO'
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
        ,'Tipo de roles de usuario para listar'
        ,'ACTIVO'
        ,NULL
        ,GETDATE()
        ,'CONSIGNEE'
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
        ,'CLIENTE'
        ,NULL
        ,NULL
        ,8
        ,0
        ,NULL
        ,NULL,
        @IdNew
        );
END;