
# Contenido
[[_TOC_]]

## Objetivo

Proporcionar un conjunto de reglas para el desarrollo dentro de las bases de datos en SQL Server, en cuanto a la nomenclatura, organización de archivos, estandarización del código y despliegue de cambios a nivel de base de datos.

## Alcance

El presente documento es de aplicación para el Departamento de Desarrollo y Proveedores Externos de soluciones de software.

## Estándares Generales

1. El nombre de los objetos y los scripts debe definirse en inglés y en [Pascal Case](https://techterms.com/definition/pascalcase)
1. La nomenclatura debe ser descriptiva haciendo referencia a la funcionalidad y en lo posible no usar abreviaturas.
1. En el nombre de los objetos no se debe utilizar caracteres especiales a excepción del guion bajo en aquellos donde es permitido.
1. Para CREATE o ALTER siempre especificar el esquema [dbo] para la interpretación de la réplica.
1. Toda tabla debe tener una llave primaria definida y los campos de control CreatedDate, CreatedBy, ModifiedDate, ModifiedBy.
1. La mayoría de campos en una tabla deben estipularse como Not Nullable.
1. Evitar en lo posible el uso de tipos de datos Unicode: nchar, nvarchar, ntext, char, varchar(MAX).
1. Evitar en lo posible el uso del tipo de datos BIT, en su lugar utilizar un INT y agregar un Catalogo o un Diccionario de datos para dicho campo.
1. Para la lectura de las tablas transaccionales, se debe utilizar el comando WITH (NOLOCK), siempre y cuando no se requiera leer los datos que están siendo modificados en ese instante, entre las tablas a considerar se detallan las siguientes:
CodigosDeBarra
Coordinaciones
CoordinacionesDetalles
DocumentosEmbarque
FacturaDetalle
FacturaEncabezado
Guias
GuiasHouse
GuiasHouseDetalles
GuiasHouseDetallesHistorico
Pallets
PalletsDetalles
PiezasInventariadas
PoDetalles
ProgramacionCarrier
ProgramacionManifiesto
UbicacionPiezas

1. Debe existir un archivo por cada objeto o script de manipulación de datos que satisfaga una necesidad funcional sobre un objeto específico.
1. El nombre del archivo debe seguir la siguiente convención: 
```<Orden de ejecución con doble dígito>-<Nombre descriptivo del script>.sql```   (No se debe agregar más texto en el nombre del archivo, únicamente la secuencia y el nombre descriptivo.)

    > _Por ejemplo:_ 
```01-InsertCycleCounts.sql``` será el primero en ejecutarse.
```02-v_ListAspNetUsers.sql``` será el segundo en ejecutarse.
```03-AC_pro_GetClientData.sql``` será el tercero en ejecutarse.
 
    > Nombre correcto: ```02-v_ListAspNetUsers.sql```  
    > Nombre incorrecto: ```2-v_ListAspNetUsers-last.sql```  
    > Nombre incorrecto: ```v_ListAspNetUsers execute last.sql```


1. Dentro de los scripts de manipulación de datos ( [DML](https://en.wikipedia.org/wiki/Data_manipulation_language)) no deben existir comandos DDL
1. Dentro de los scripts de definición de datos ( [DDL](https://en.wikipedia.org/wiki/Data_definition_language)) no deben existir comandos DML, tampoco  TRUNCATE TABLE para borrar de datos.
1. El script debe ser [idempotente](https://es.wikipedia.org/wiki/Idempotencia), es decir, si se ejecuta un mismo script en múltiples ocasiones, el resultado debe ser siempre el deseado a nivel funcional, tanto para DDLs como para DMLs.

   > _Por ejemplo:_  
   > Si se genera un script que crea una nueva opción del menú y dicho script se ejecuta 3 veces, la nueva opción del menú debe aparecer una sola vez, no 3 veces.  
   > 
   > _Código T-SQL:_
   > 
   > ```sql
   > -- Create new option at Analytics Menu
   > DECLARE
   > 	@IdMenuAnalytics VARCHAR(32),
   > 	@IdMenuDashboard VARCHAR(32)
   > 
   > SELECT	@IdMenuAnalytics = Id
   > FROM	Menu 
   > WHERE	[Name] = 'Analytics' 
   > 
   > SELECT @IdMenuDashboard = Id 
   > FROM Menu 
   > WHERE [Name] = 'Dashboards' 
   > AND IdPrincipal = @idMenuAnalytics
   > 
   > -- Insert only if the new menu doesnt exist 
   > IF @IdMenuDashboard IS NULL
   > BEGIN
   > 	EXEC AC_pro_General_GenerateId @Table = 'Menu', @Id = @IdMenuDashboard OUTPUT
   >   
   > 	INSERT INTO Menu(
   > 	Id, 
   > 	IdPrincipal, 
   > 	IdUser, 
   > 	[Name], 
   > 	[Url], 
   >	[Action], 
   > 	[Order], 
   > 	IsMenu, 
   > 	ModifiedDate, 
   > 	[Status], 
   >	IsNewTab, 
   > 	Instruction, 
   > 	EnglishName)
   >	VALUES(
   > 	@IdMenuDashboard, 
   > 	@IdMenuAnalytics, 
   > 	'USU0159', 
   > 	'Dashboards', 
   > 	'/Analitica/Home',
   >	'MENU', 
   > 	0, 
   > 	1, 
   > 	GETDATE(), 
   > 	'ACTIVO', 
   >	0, 
   > 	'MENU', 
   > 	'Dashboards')
   > END
   > ```


## Consideraciones Generales
1. Cada desarrollador puede generar uno o más archivos de scripts según sea necesario.
1. Asegurar la integridad de datos para la ejecución de cada script.
1. Durante el tiempo de desarrollo, si más de un desarrollador debe hacer operaciones sobre un mismo objeto de programación, se debe mantener un solo archivo.
1. La creación de índices debe ser analizada y probada en conjunto con el **DBA**.
1. Los scripts deben ordenarse, primero los DDLs y luego los DMLs. A excepción de manipulación a ParametrosGenerales y Contadores, los cuales deben colocarse siempre al inicio.
1. Utilizar el diccionario de datos para colocar comentarios a cualquier objeto (tabla, columna, sp, etc.), con el fin de proporcionar información más específica.
1. Si se tiene una cantidad mayor o igual a 5 scripts debe empaquetarse en una carpeta comprimida y nombrarla con el número de HU.
1. En los scripts que se requiera se debe estipular la característica NOT FOR REPLICATION, principalmente en FK, CK y triggers.
1. Preparar el script del RollBack para cada caso.


## Estándares Específicos
### Tablas
1. El script debe ser  [idempotente](https://es.wikipedia.org/wiki/Idempotencia). validando si la tabla o columna existe.
1. El nombre de tabla debe especificarse en plural.
1. Los atributos de la tabla deben estar en [Pascal Case](https://techterms.com/definition/pascalcase)

    > _Por ejemplo:_  ```CycleCounts```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >CREATE TABLE dbo.CycleCounts(
    >	Id UNIQUEIDENTIFIER NOT NULL,
    >	CycleCountNumber INT NOT NULL CONSTRAINT DF_CycleCounts_CycleCountNumber DEFAULT 0,
    >	RequestedBy VARCHAR(128) NOT NULL,
    >	IdCycleCountReason INT NOT NULL,
    >	IdCompany VARCHAR(16) NOT NULL,
    >	IdWarehouse VARCHAR(16) NOT NULL,
    >	IdCycleCountType INT NOT NULL,
    >	IdChannel INT NOT NULL,
    >	Observation VARCHAR(256) NULL,
    >	IdStatus INT NOT NULL,
    >	Quantity INT NOT NULL CONSTRAINT DF_CycleCounts_quantity DEFAULT 0,
    >	CycleCountDate DATETIME NOT NULL,
    >	ClosedBy VARCHAR(16) NULL,
    >	CloseDate DATETIME NULL,
    >	CreatedDate DATETIME NOT NULL,
    >	CreatedBy VARCHAR(16) NOT NULL,
    >	ModifiedDate DATETIME NOT NULL,
    >	ModifiedBy VARCHAR(16) NOT NULL,
    >CONSTRAINT PK_CycleCount PRIMARY KEY NONCLUSTERED (Id)) 
    > ```

### Tablas Temporales
1. Por convención de nombres la tabla temporal debe utilizar el siguiente estándar: ```TMP_<NombreTablaTemporal>```
1. El prefijo ```TMP_``` se coloca en mayúsculas 

    > _Por ejemplo:_ ```#TMP_GuiasTotals```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >CREATE TABLE #TMP_GuiasTotals (
    >	IdGuia VARCHAR(16),
    >	TotalFleet DECIMAL(10,3),
    >	TotalAWB DECIMAL(10,3),
    >	TotalAgent DECIMAL(12,3),
    >	TotalCarrier DECIMAL(12,3)
    >)
    > ```

### Índices
1. Por convención de nombres el índice debe utilizar el siguiente estándar: ```idx_<NombreTabla>_<NombreColumnas>```
1. El prefijo ```idx_``` se coloca en minúsculas 

    > _Por ejemplo:_ ```idx_CycleCountDetails_barcode```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >CREATE NONCLUSTERED INDEX idx_CycleCountDetails_barcode ON CycleCountDetails (
    >	[barcode]
    >)
    > ```

### Vistas
1. Por convención de nombres la vista debe utilizar el siguiente estándar: ```v_<NombreDescriptivo>```  
1. El prefijo ```v_``` se coloca en minúsculas

    > _Por ejemplo:_ ```v_Guias_Distribucion```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >    /*
    >    VERSION	MODIFIEDBY      MODIFIEDDATE	HU		MODIFICATION
    >    1		Juan Ordonez    2026-07-20	N/A		Initial code - Retrieve list of items based on type
    >    */
    >    CREATE VIEW v_Guias_Distribucion AS (
    >    SELECT 
    >    G.id
    >    ,G.idGuiaConsolidada
    >    ,CL.nombre AS cliente
    >    ,CL.direccion
    >    ,CL.telefono
    >    ,CL.fax
    >    ,CI.nombre AS ciudad
    >    ,P.nombre AS pais
    >    FROM Guias G
    >    LEFT JOIN Clientes CL ON G.idCliente = CL.id 
    >    LEFT JOIN Ciudades CI ON CL.idCiudad = CI.id 
    >    LEFT JOIN Paises P ON CL.idPais = P.id
    >    WHERE G.tipoGuia = 'Distribucion'
    >)
    > ```

### Procedimientos Almacenados
1. Por convención de nombres para procedimientos almacenados se debe utilizar el siguiente estándar:
```AC_pro_<NombreDescriptivo>```

1. El prefijo ```AC_pro_``` se coloca en mayúsculas y minúsculas según corresponde
1. Se debe agregar BEGIN TRY/CATCH, el catch debe contener EXEC [dbo].[pro_LogError] 

    > _Por ejemplo:_ ```AC_pro_RetrievePCData```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >/*
    >VERSION		MODIFIEDBY      MODIFIEDDATE	HU		MODIFICATION
    >1		Juan Ordonez    2026-07-20	N/A		Initial code - Retrieve list of items based on date
    >*/
    >CREATE OR ALTER PROCEDURE AC_pro_RetrievePCData
    >   @DateSince DATETIME
    >AS
    >BEGIN
    >    BEGIN TRY
    >        SELECT
    >        id
    >        ,idCarrier
    >        ,fechaDespacho
    >        ,esProgramacionCliente
    >        FROM ProgramacionCarrier WITH (NOLOCK)
    >        WHERE fechaDespacho >= @DateSince
    >    END TRY
    >    BEGIN CATCH
    >        EXEC [dbo].[pro_LogError]
    >    END CATCH
    >END
    >/*
    >EXEC AC_pro_RetrievePCData @DateSince = '20260723'
    >*/
    > ```

### Funciones
1. Por convención de nombres para funciones se debe utilizar  el siguiente estándar: ```f_<NombreDescriptivo>```  
1. El prefijo ```f_``` se coloca en minúsculas

    > _Por ejemplo:_ ```f_GetNextAlphaSequence```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >/*    
    >VERSION		MODIFIEDBY		MODIFIEDDATE	HU		MODIFICATION
    >1		Joel Cedeno		2026-03-02	CC 57480	Initial Code - Alphanumeric sequence generator (A–Z) for atomic counters 
    >*/
    >CREATE OR ALTER FUNCTION f_GetNextAlphaSequence(
    >    @CurrentValue VARCHAR(8)
    >)
    >RETURNS VARCHAR(8)
    >AS
    >BEGIN
    >    DECLARE @Len INT = LEN(@CurrentValue)
    >            ,@PosToInc INT =  LEN(@CurrentValue) - PATINDEX('%[^Z]%', REVERSE(@CurrentValue)) + 1
    >
    >    IF @CurrentValue IS NULL OR @CurrentValue LIKE '%[^A-Z]%' RETURN 'A'
    >
    >    IF @CurrentValue NOT LIKE '%[^Z]%' 
    >        RETURN REPLICATE('A', @Len + 1)
    >
    >    RETURN 
    >        LEFT(@CurrentValue, @PosToInc - 1) + CHAR(ASCII(SUBSTRING(@CurrentValue, @PosToInc, 1)) + 1) + REPLICATE('A', @Len - @PosToInc)                
    >END
    >
    >/*
    >SELECT dbo.f_GetNextAlphaSequence('A')
    >*/
    > ```

### Desencadenadores (Triggers)
1. Por convención de nombres para triggers se debe utilizar el siguiente estándar: 
```trg_<NombreDescriptivo>```  
1. El prefijo ```trg_``` se coloca en minúsculas

    > _Por ejemplo:_ ```trg_InsertClientesContablesFromClientes```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >/*
    >VERSION		MODIFIEDBY		MODIFIEDDATE	HU		MODIFICATION
    >1		Juan Ordonez		2026-07-23	16715		Initial Code - Trigger to insert data in ClientesContables after an insert in Clientes
    >*/
    >CREATE OR ALTER TRIGGER trg_InsertClientesContablesFromClientes
    >    ON Clientes
    >    AFTER INSERT
    >    NOT FOR REPLICATION
    >AS
    >BEGIN
    >    INSERT INTO ClientesContables (id, nombreCliente, idEmpresa, [status], fechaCambio)
    >    SELECT NEWID(),nombre, idEmpresa, [status], GETDATE()
    >    FROM inserted 
    >END
    > ```
 
### Tipos definidos por el usuario (User-defined types)
1. Por convención de nombres para tipos definidos por el usuario se debe utilizar el siguiente estándar:  ```ut_<NombreDescriptivo>```  
1. El prefijo ```ut_``` se coloca en minúsculas

    > _Por ejemplo:_ ```ut_GuiasSummary```
    >
    > _Código T-SQL:_
    >
    > ```sql
    >CREATE TYPE ut_GuiasSummary AS TABLE(
    >	Id INT IDENTITY(1,1) NOT NULL
    >	,IdEmpresa VARCHAR(16) NOT NULL
    >	,IdCliente VARCHAR(16) NOT NULL
    >	,idGuiaConsolidada VARCHAR(16) NULL
    >	,idPuertoOrigen VARCHAR(16) NOT NULL
    >	,idPuertoDestino VARCHAR(16) NOT NULL
    >	,fechaEmbarque DATETIME NOT NULL
    >	,tipoGuia VARCHAR(16) NOT NULL
    >)
    > ```

## Estándar Restricciones (Constraints)

### Llave Primaria
1. Por convención de nombres para llaves primarias se debe utilizar el siguiente estándar:  ```PK_<NombreTabla>```
1. El prefijo ```PK_``` se coloca en mayúsculas

    > _Por ejemplo:_ 
    > Tabla:```CycleCountDetails```
    > Llave Primaria:```PK_CycleCountDetails```
    > 
    > _Código T-SQL:_
    >
    > ```sql
    >ALTER TABLE dbo.CycleCountDetails 
    >ADD CONSTRAINT PK_CycleCountDetails 
    >PRIMARY KEY NONCLUSTERED (id)
    > ```

### Llave Foránea
1. Por convención de nombres para llaves foráneas se debe utilizar el siguiente estándar:  ```FK_<NombreTablaHija>_<NombreTablaPadre>```  
1. El prefijo ```FK_``` se coloca en mayúsculas

    > _Por ejemplo:_ 
    > Tablas:```CycleCountDetails / CycleCounts```
    > Llave Foránea:```FK_CycleCountDetails_CycleCounts```
    > 
    > _Código T-SQL:_
    >
    > ```sql
    >ALTER TABLE dbo.CycleCountDetails 
    >ADD CONSTRAINT FK_CycleCountDetails_CycleCounts
    >FOREIGN KEY(idCycleCount)
    >REFERENCES CycleCounts (id)
    >NOT FOR REPLICATION
    > ```

### Llave Única
1. Por convención de nombres para llaves únicas se debe utilizar el siguiente estándar:  ```UK_<NombreTabla>_<NombreColumna>```  
1. El prefijo ```UK_``` se coloca en mayúsculas

    > _Por ejemplo:_ 
    > Tabla:```CycleCounts```
    > Campo:```CycleCountNumber```
    > Llave Única:```UK_CycleCounts_CycleCountNumber```
    > 
    > _Código T-SQL:_
    >
    > ```sql
    >ALTER TABLE CycleCounts
    >ADD CONSTRAINT UK_CycleCounts_CycleCountNumber 
    >UNIQUE (CycleCountNumber)
    > ```

### Por Defecto (Default)
1. Por convención de nombres para constraints por defecto se debe utilizar el siguiente estándar:  ```DF_<NombreTabla>_<NombreColumna>```
1. El prefijo ```DF_``` se coloca en mayúsculas

    > _Por ejemplo:_ 
    > Tabla:```CycleCounts```
    > Campo:```IsInventory```
    > Restricción por default:```DF_CycleCounts_IsInventory```
    > 
    > _Código T-SQL:_
    >
    > ```sql
    >ALTER TABLE CycleCountDetails 
    >ADD CONSTRAINT DF_CycleCountDetails_isInventory 
    >DEFAULT (0) FOR isInventory
    > ```

### De Comprobación
1. Por convención de nombres para check constraints se debe utilizar el siguiente estándar:  ```CK_<NombreTabla>_<NombreColumna>```
1. El prefijo ```CK_``` se coloca en mayúsculas

    > _Por ejemplo:_ 
    > Tabla:```CycleCounts```
    > Campo:```IsDiscrepancy```
    > Restricción por comprobación:```CK_CycleCountDetails_IsDiscrepancy```
    > 
    > _Código T-SQL:_
    >
    > ```sql
    >ALTER TABLE CycleCounts
    >ADD CONSTRAINT CK_CycleCountDetails_IsDiscrepancy 
    >CHECK NOT FOR REPLICATION (IsDiscrepancy BETWEEN 1 AND 3)
    > ```

## Estándar Encabezado y Comentarios

El siguiente encabezado debe ser utilizado al inicio dentro de cada archivo:

   > _Código T-SQL:_
   >
   > ```sql
   > /*    
   >VERSION		MODIFIEDBY			MODIFIEDDATE	HU			MODIFICATION
   >1		Veronica Vicente		2020-09-21	CC 85741		Add parameter @idCoordination 
   >2		Veronica Vicente		2020-09-23	SC 17672		Add update on table ClientTemporalInventory
   > */
   > ```

## Estándares de Programación BDD

Para la programación dentro de las bases de datos (vistas, procedimientos almacenados, funciones, desencadenadores) tomar en cuenta las siguientes indicaciones:

1. Registrar en el encabezado los cambios realizados en cada objeto de programación, con versión, responsable, fecha, HU y descripción de la modificación. 
1. Todo programa debe empezar por CREATE OR ALTER.
1. Los parámetros y variables deben tener el mismo tipo de datos y longitud del campo con el que se está comparando o poblando. En caso de ser nuevos, su longitud debe especificarse en octetos.
1. No utilizar SET para la asignación de un valor a una variable, en su lugar usar SELECT.
1. No usar cursores, excepto que sean la única solución (en su lugar realizar consultas anidadas).
1. Utilizar variables tipo tabla "@TBL_COUNTRIES" o Common Table Expression (CTE) "WITH CTE_PORTS", en lugar de tablas temporales "#TMP_GUIAS" (únicamente en casos con cantidades menores a 2.000 registros y que no realicen JOINs con las tablas de mayor tamaño dentro de la BDD), para el resto de casos siempre será mejor usar tablas temporales.
1. Bajo ninguna circunstancia se debe realizar SELECT * dentro de programación en la base de datos.
1. Indentar el código (formatear con sangrías) para mantener un orden y facilitar la lectura y comprensión.
1. Las palabras reservadas del lenguaje SQL deben escribirse en mayúsculas.
1. Cuando una columna o variable tenga como nombre una palabra reservada se debe especificar entre corchetes, ejemplo: [Status], [EXP].
1. Los alias de las tablas deben asignarse en siglas referentes a la tabla, con máximo 4 caracteres alfanuméricos en mayúsculas, ejemplo: Catalogs C, CycleCounts CC, CycleCountDetails CCD, etc.
1. Por defecto no utilizar alias para columnas y mostrar el nombre del atributo tal como se encuentra definido en la estructura de la tabla. A excepción de campos calculados,  que tengan alguna validación, seteo personalizado o para evitar columnas con nombres repetidos; cuando esto sea necesario debe escribirse en [Pascal Case](https://techterms.com/definition/pascalcase). Así por ejemplo:
    > Incorrecto: ```SELECT CCD.StatusPiece AS StatusPiece```  
    > Incorrecto: ```SELECT COUNT(GHD.id) AS totalPieces```  
    > Incorrecto: ```SELECT ISNULL(G.Id, GC.Id) AS IDAWB```  
    > Incorrecto: ```SELECT 1 AS FilterORDER```  

    > Correcto: ```SELECT CCD.StatusPiece ```  
    > Correcto: ```SELECT COUNT(GHD.Id) AS TotalPieces```  
    > Correcto: ```SELECT ISNULL(G.Id, GC.Id) AS IdAwb```  
    > Correcto: ```SELECT 1 AS FilterOrder``` 
1. Para validar la Nullabilidad de valores no se debe usar IIF o COALESCE, en su lugar utilizar ISNULL.
1. Evitar el uso de querys dinámicos dentro de la programación.
1. Colocar comentarios dentro del código para una mejor documentación y descripción del mismo, cuando amerite.
1. Cuando se realicen UPDATES o INSERTS se deben actualizar los campos ModifiedDate y ModifiedBy.
1. No realizar ORDER BY en la medida de lo posible.
1. Evitar aplicar lógica del negocio dentro de los sps, ya que se complica el mantenimiento (uso de sps embebidos).
1. Los valores referenciales por tipo de consulta son:
⚬ Consultas granulares: 20,000 lecturas (por Guía, por Pieza, por Po, por HeaderLeabel, etc.)
⚬ Consultas masivas: 800,000 lecturas (en un rango de fechas, por clientes, etc)
1. Al final del código ubicar un ejemplo de la ejecución del mismo (incluyendo parámetros en caso de existir), siempre y cuando el programa no realice modificaciones de datos. Deben considerarse casos que tengan mayor cantidad de registros, así por ejemplo: Clientes con mayor cantidad de guías, Guías padre con mayor cantidad de guías hijas, rangos de fechas dentro de la temporada, etc.
1. En caso de necesitar forzar el uso de un índice se debe utilizar el siguiente formato WITH (NOLOCK, INDEX = idx_GuiasHouseDetalles_codigoBarra_idGuiaHouse).



> ```sql
>/*
>VERSION		MODIFIEDBY			MODIFIEDDATE	HU			MODIFICATION
>1		Patricia Chicaiza		2022-06-21	AC 99557		Initial Code- Get data from a specific client
>2		Patricia Chicaiza		2022-06-21	CC 85741		Add email attribute
>*/
>CREATE OR ALTER PROCEDURE [dbo].[pro_RetriveClientInformation] 
>	@IdClient VARCHAR(16)
>AS
>BEGIN  
>	BEGIN TRY
>		SELECT 
>		Id,
>		[Name],
>		Adress,
>		Phone,
>		Email
>		FROM [Clients] C
>		WHERE C.Id = @IdClient
>	END TRY
>	BEGIN CATCH
>		EXEC [dbo].[pro_LogError]
>	END CATCH	 
>END
>/*
>EXEC [dbo].[pro_RetriveClientInformation] @IdClient = 'CLI012336'
>*/
> ```


## Despliegue

1. Cuando la HU cambie a estado Resolved Doing, establecer el tag **BDD**, tag **[Nombre ambiente pruebas]** (PreProducción / Blackbox / Sandbox).
![image.png](/.attachments/image-d7a7e02e-dbca-463e-b3c4-3dcf7c594286.png)

1. Adjuntar los scripts en la sección de **Attachments**. 
1. DBA descarga los scripts el viernes a las 12:00 cada 15 días (los tags solo se consideran hasta esa hora).
1. Se descargan las HUs en estado: Certificated, Resolved o Active.
1. Se consideran todos los proyectos excepto los siguientes:
   >AC BI
AC Testing
Base de Conocimientos

6. Llenar la [Guía de Puesta en producción](https://logiztikalliance.sharepoint.com/Shared%20Documents/Forms/AllItems.aspx?id=%2FShared%20Documents%2FGuia%20puesta%20en%20producci%C3%B3n&viewid=b34d158f%2D56ac%2D42df%2Db713%2D2a3715020720) y en el nombre del archivo colocar el número de la HU:


   - **Sección Base de Datos**
![image.png](/.attachments/image-435d386a-0589-4212-805d-2680655e5475.png)

   - **Sección Guía de Ejecución de Scripts**
![image.png](/.attachments/image-6e49d23e-fa4a-4911-ad2e-8362f7efb9b9.png)


  >### Tipo de Cambio
>
>```
>DATOS - Inserción
>DATOS - Modificación
>DATOS - Eliminación
>DATOS - Respaldo
>TABLA - Creación
>TABLA - Modificación
>TABLA - Eliminación
>SP - Creación
>SP - Modificación
>SP - Eliminación
>ÍNDICE - Creación
>ÍNDICE - Modificación
>ÍNDICE - Eliminación
>VISTA - Creación
>VISTA - Modificación
>VISTA - Eliminación
>FUNCIÓN - Creación
>FUNCIÓN - Modificación
>FUNCIÓN - Eliminación
>DICCIONARIO - Creación
>DICCIONARIO - Modificación
>DICCIONARIO - Eliminación
>TRIGGER - Creación
>TRIGGER - Modificación
>TRIGGER - Eliminación
>```

7. Enviar correo de Despliegue al ambiente requerido (Producción / PreProducción / Blackbox / Sandbox ):

- Destinatarios: Team Leader, Scrum, Devops
- Asunto: ```<Código HU> - <Nombre HU>```
- Cuerpo del mensaje
![image.png](/.attachments/image-e2805cc1-dea0-4b73-814a-6fe5532957ea.png)



# Revisiones
| Versión | Fecha | Autor | Descripción |
|:---:|:----:|:---:|---|
| 1 | 3-Jul-2020 |José Arévalo|Versión inicial|
| 2 | 21-Jul-2022 |Patricia Chicaiza, Jairo González, Luis Campos, Paúl Castillo, Maricela Becerra|Actualización considerando procesos que se aplican|
| 3 | 15-Feb-2023 |Patricia Chicaiza, Jairo González, Luis Campos|Actualización general|
| 4 | 11-Mar-2024 |Patricia Chicaiza, Paul Castillo, Jairo González, Luis Campos, Maricela Becerra|Actualización general|
| 5 | 21-Feb-2025 |Patricia Chicaiza|Actualización general para definiciones alliance 2.0|
| 6 | 24-Jul-2026 |Patricia Chicaiza, Juan Ordoñez|Actualización general para definiciones alliance v2.1|
