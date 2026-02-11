/*
VERSION     MODIFIEDBY      MODIFIEDDATE    HU      MODIFICATION
1           Jair Gomez     2026-02-05      57731   Update COSTUMER to CONSIGNEE in subject and body
*/

IF EXISTS (
    SELECT 1
    FROM [dbo].[OpcionesRetraso] T WITH (NOLOCK)
    WHERE T.Id = 'ORT0140'
      AND (
            T.Asunto LIKE '%[[COSTUMER]]%'
         OR T.Asunto LIKE '%Customer%'
         OR T.Descripcion LIKE '%[[COSTUMER]]%'
         OR T.Descripcion LIKE '%Customer%'
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
    WHERE T.Id = 'ORT0140';

    PRINT 'OpcionesRetraso updated successfully: [COSTUMER]/Customer replaced with CONSIGNEE for ORT0140.'
END
ELSE
BEGIN
    PRINT 'No update required: [COSTUMER]/Customer not found for ORT0140.'
END
