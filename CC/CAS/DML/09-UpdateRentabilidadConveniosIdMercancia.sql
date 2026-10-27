/*
VERSION     MODIFIEDBY          MODIFIEDDATE        HU              MODIFICATION
1           Jair Gómez          2026-10-26          64492           Update RentabilidadConvenios IdMercancia 
*/

UPDATE RC
SET RC.idMercancia = CAT.id
FROM rentabilidadconvenios RC
INNER JOIN mercancias CAT
    ON (
        (RC.idMercancia LIKE 'MER%' AND RC.idMercancia = CAT.idMercanciaAlianza)
        
        OR
        (
            RC.idMercancia NOT LIKE 'MER%' 
            AND RC.idMercancia NOT LIKE 'U%' 
            AND RC.idMercancia <> 'TODOS'
            AND LTRIM(RTRIM(RC.idMercancia)) = LTRIM(RTRIM(CAT.nombre))
        )

        OR 
        (LTRIM(RTRIM(RC.idMercancia)) = 'PESCADO FRESCO' AND CAT.id = 'U3')

        OR
        (LTRIM(RTRIM(RC.idMercancia)) = 'CHOCOLATE' AND CAT.id = 'U14')
    )
WHERE 
    RC.idMercancia NOT LIKE 'U%' 
    AND RC.idMercancia <> 'TODOS';

