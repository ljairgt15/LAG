/*
VERSION		MODIFIEDBY			MODIFIEDDATE	HU		MODIFICATION
1		Jair Gomez			2026-02-04	NEW WORK 57731	Update COSTUMER to CONSIGNEE in subject and body
*/
IF EXISTS (
    SELECT 1
    FROM [dbo].[OpcionesRetraso] T WITH (NOLOCK)
    WHERE T.Id = 'ORT0140'
        AND (
            T.Asunto LIKE '%COSTUMER%'
            OR T.Descripcion LIKE '%c¿Customer%'
        )
)
BEGIN
    UPDATE T
    SET 
        Asunto = REPLACE(
                    REPLACE(T.Asunto, '[COSTUMER]', '[CONSIGNEE]'),
                    'Customer', 'Consignee'
                    ),
        Descripcion = REPLACE(
                    REPLACE(T.Descripcion, '[COSTUMER]', '[CONSIGNEE]'),
                    'Customer', 'Consignee'
                    ),
        FechaCambio = GETDATE()
    FROM [dbo].[OpcionesRetraso] T
    WHERE T.Id ='ORT0140'
END