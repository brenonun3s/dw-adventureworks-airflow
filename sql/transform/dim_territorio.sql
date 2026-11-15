-- Dimensão Território de vendas, com país e grupo regional em português.
INSERT INTO dw.dim_territorio VALUES (0, -1, 'Não informado', 'Não informado', 'Não informado');

INSERT INTO dw.dim_territorio (id_territorio, nome, pais, grupo_regiao)
SELECT t.territoryid,
       CASE t.name
            WHEN 'Northwest' THEN 'EUA Noroeste'
            WHEN 'Northeast' THEN 'EUA Nordeste'
            WHEN 'Central'   THEN 'EUA Central'
            WHEN 'Southwest' THEN 'EUA Sudoeste'
            WHEN 'Southeast' THEN 'EUA Sudeste'
            WHEN 'Canada'    THEN 'Canadá'
            WHEN 'France'    THEN 'França'
            WHEN 'Germany'   THEN 'Alemanha'
            WHEN 'Australia' THEN 'Austrália'
            WHEN 'United Kingdom' THEN 'Reino Unido'
            ELSE t.name END                                   AS nome,
       CASE t.countryregioncode
            WHEN 'US' THEN 'Estados Unidos' WHEN 'CA' THEN 'Canadá'
            WHEN 'FR' THEN 'França'         WHEN 'DE' THEN 'Alemanha'
            WHEN 'AU' THEN 'Austrália'      WHEN 'GB' THEN 'Reino Unido'
            ELSE t.countryregioncode END                      AS pais,
       CASE t.grupo
            WHEN 'North America' THEN 'América do Norte'
            WHEN 'Europe'        THEN 'Europa'
            WHEN 'Pacific'       THEN 'Pacífico'
            ELSE t.grupo END                                  AS grupo_regiao
FROM stg.sales_territory t;
