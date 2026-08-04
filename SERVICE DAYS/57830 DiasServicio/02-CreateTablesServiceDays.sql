/*
VERSION     MODIFIEDBY              MODIFIEDDATE    HU          MODIFICATION
1           Marlon Pizarro          2026-02-19      57830       LAG-CT-001​ Creacion de tabla ServiceDays y ServiceDaysCarriers
2           Marlon Pizarro          2026-03-25      57830       Table ServiceDaysCarriers was removed  
*/

IF OBJECT_ID('dbo.ServiceDays', 'U') IS NOT NULL
BEGIN
    PRINT 'Table ServiceDays already exists';
END
ELSE
BEGIN
    CREATE TABLE dbo.ServiceDays (
        Id VARCHAR(16) NOT NULL,
        ModeId UNIQUEIDENTIFIER NOT NULL,                          
        ConsigneeId VARCHAR(16) NOT NULL,
        BillToId VARCHAR(16) NULL,                      
        OriginId VARCHAR(16) NOT NULL,                
        DestinationId VARCHAR(16) NOT NULL,           
        CommodityId VARCHAR(16) NULL,
        AccountNumber VARCHAR(32) NULL,                      
        RepeatFrequency INT NOT NULL,                    
        RepeatEvery INT NOT NULL,                                 
        Monday BIT NOT NULL,
        Tuesday BIT NOT NULL,
        Wednesday BIT NOT NULL,
        Thursday BIT NOT NULL,
        Friday BIT NOT NULL,
        Saturday BIT NOT NULL,
        Sunday BIT NOT NULL,
        StartFrequencyDate DATE NOT NULL,      
        [Status] INT NOT NULL,                        
        CreatedDate DATETIME NOT NULL,
        CreatedBy VARCHAR(16) NOT NULL,
        ModifiedDate DATETIME NOT NULL,
        ModifiedBy VARCHAR(16) NOT NULL
		CONSTRAINT [PK_ServiceDays] PRIMARY KEY NONCLUSTERED ([Id]) 
    )

    EXEC sys.sp_addextendedproperty  
        @name = N'MS_Description',  
        @value = N'1 = Weekly, 2 = Monthly',  
        @level0type = N'SCHEMA', @level0name = N'dbo',  
        @level1type = N'TABLE',  @level1name = N'ServiceDays',  
        @level2type = N'COLUMN', @level2name = N'RepeatFrequency';
    
    EXEC sys.sp_addextendedproperty  
        @name = N'MS_Description',  
        @value = N'0 = Inactive, 1 = Active',  
        @level0type = N'SCHEMA', @level0name = N'dbo',  
        @level1type = N'TABLE',  @level1name = N'ServiceDays',  
        @level2type = N'COLUMN', @level2name = N'Status';

    EXEC sys.sp_addextendedproperty  
        @name = N'MS_Description',  
        @value = N'Number of periods to repeat. Allowed values: 1 to 100.',  
        @level0type = N'SCHEMA', @level0name = N'dbo',  
        @level1type = N'TABLE',  @level1name = N'ServiceDays',  
        @level2type = N'COLUMN', @level2name = N'RepeatEvery';

END;


-- CREATE TABLE for ServiceDaysDetails
IF OBJECT_ID('dbo.ServiceDaysDetails', 'U') IS NOT NULL
BEGIN
    PRINT 'Table ServiceDaysDetails already exists';
END
ELSE
BEGIN
    CREATE TABLE dbo.ServiceDaysDetails (
        Id VARCHAR(16) NOT NULL,
        ServiceDayId VARCHAR(16) NOT NULL,
        CarrierId VARCHAR(16) NULL,
        [Type] INT NOT NULL,
        [Status] INT NOT NULL,
        AdditionalDate DATE NULL,
        Monday BIT NOT NULL,
        Tuesday BIT NOT NULL,
        Wednesday BIT NOT NULL,
        Thursday BIT NOT NULL,
        Friday BIT NOT NULL,
        Saturday BIT NOT NULL,
        Sunday BIT NOT NULL,
        CreatedDate DATETIME NOT NULL,
        CreatedBy VARCHAR(16) NOT NULL,
        ModifiedDate DATETIME NOT NULL,
        ModifiedBy VARCHAR(16) NOT NULL
        CONSTRAINT [PK_ServiceDaysDetails] PRIMARY KEY NONCLUSTERED ([Id])
    );

    EXEC sys.sp_addextendedproperty  
        @name = N'MS_Description',  
        @value = N'0= noPreferredCarrier,1 = PreferredCarrier, 2 = Additional Day',  
        @level0type = N'SCHEMA', @level0name = N'dbo',  
        @level1type = N'TABLE',  @level1name = N'ServiceDaysDetails',  
        @level2type = N'COLUMN', @level2name = N'Type';

    EXEC sys.sp_addextendedproperty  
        @name = N'MS_Description',  
        @value = N'0 = Inactive, 1 = Active',  
        @level0type = N'SCHEMA', @level0name = N'dbo',  
        @level1type = N'TABLE',  @level1name = N'ServiceDaysDetails',  
        @level2type = N'COLUMN', @level2name = N'Status';
END;

-- CREATE TABLE for ServiceDaysHistory
IF OBJECT_ID('dbo.ServiceDaysHistory', 'U') IS NOT NULL
BEGIN
    PRINT 'Table ServiceDaysHistory already exists';
END
ELSE
BEGIN
    CREATE TABLE dbo.ServiceDaysHistory (
        Id VARCHAR(16) NOT NULL,
        ServiceDayId VARCHAR(16) NOT NULL,
        RepeatFrequency INT NOT NULL,
        RepeatEvery INT NOT NULL,
        Monday BIT NOT NULL,
        Tuesday BIT NOT NULL,
        Wednesday BIT NOT NULL,
        Thursday BIT NOT NULL,
        Friday BIT NOT NULL,
        Saturday BIT NOT NULL,
        Sunday BIT NOT NULL,
        StartFrequencyDate DATE NOT NULL,
        EndFrequencyDate DATE NOT NULL,
        CreatedDate DATETIME NOT NULL,
        CreatedBy VARCHAR(16) NOT NULL
        CONSTRAINT [PK_ServiceDaysHistory] PRIMARY KEY NONCLUSTERED ([Id])
    );
END;
