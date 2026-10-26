/*
VERSION     MODIFIEDBY          MODIFIEDDATE    HU          MODIFICATION
1           Jair Gomez          2026-10-16      64492       Insert Commodities
*/

use ggcargo_desa
DECLARE @TBL_MERCANCIAS TABLE (
    IdMercanciaAlianza VARCHAR(16),
    Nombre VARCHAR(30)
);

INSERT INTO @TBL_MERCANCIAS (IdMercanciaAlianza, Nombre)
VALUES
    ('MER0145', 'PRODUCTOS FARMACEUTICOS'),
    ('MER0148', 'ACEITES'),
    ('MER0150', 'CAFE'),
    ('MER0154', 'CACAO'),
    ('MER0155', 'TE'),
    ('MER0156', 'MADERA AROMATICA'),
    ('MER0158', 'VEGETALES'),
    ('MER0159', 'MADERA'),
    ('MER0172', 'FLOR TROPICAL SECA'),
    ('MER0174', 'FRUIT  FROZEN'),
    ('MER0181', 'LANGOSTA FRESCA'),
    ('MER0184', 'CACAO ORNAMENTAL')
	;


DECLARE @UltimoId INT;

SELECT @UltimoId = ISNULL(
    MAX(TRY_CAST(SUBSTRING(id, 2, LEN(id)) AS INT)),
    0
)
FROM mercancias
WHERE id LIKE 'U[0-9]%';

INSERT INTO mercancias (
    id,
    nombre,
    idMercanciaAlianza
)
SELECT
    'U' + CAST(
        ROW_NUMBER() OVER (ORDER BY TM.IdMercanciaAlianza) + @UltimoId
        AS VARCHAR(10)
    ),
    TM.Nombre,
    TM.IdMercanciaAlianza
FROM @TBL_MERCANCIAS TM
WHERE NOT EXISTS (
    SELECT 1
    FROM mercancias M
    WHERE M.idMercanciaAlianza = TM.IdMercanciaAlianza
);



