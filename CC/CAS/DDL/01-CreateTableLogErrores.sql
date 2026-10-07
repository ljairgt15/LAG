/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Roger Lindao        2026-08-31          64492           Create tables
*/

IF OBJECT_ID('dbo.LogErrores', 'U') IS NOT NULL
BEGIN
    PRINT 'Table LogErrores already exists'
END
ELSE
BEGIN
	CREATE TABLE [dbo].[LogErrores](
		[FechaError] [datetime] NULL,
		[NumeroError] [int] NULL,
		[NumeroErrorSevero] [int] NULL,
		[EstadoError] [int] NULL,
		[ProcedimientoError] [varchar](64) NULL,
		[LineaError] [int] NULL,
		[MensajeError] [nvarchar](1024) NULL
	) ON [PRIMARY]
	GO

    PRINT 'Table created: LogErrores'
END
