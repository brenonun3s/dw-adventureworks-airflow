-- Dimensão Cliente: unifica pessoas físicas e lojas (revendas) e anexa a localização.
INSERT INTO dw.dim_cliente (sk_cliente, id_cliente, nome, tipo_cliente, cidade, estado, pais)
VALUES (0, -1, 'Não informado', 'Não informado', 'Não informado', 'Não informado', 'Não informado');

WITH endereco_principal AS (
    -- uma entidade pode ter vários endereços: prioriza Principal/Residencial/Cobrança
    SELECT DISTINCT ON (bea.businessentityid)
           bea.businessentityid, a.city, sp.name AS estado, sp.countryregioncode
    FROM stg.business_entity_address bea
    JOIN stg.address a         ON a.addressid = bea.addressid
    JOIN stg.state_province sp ON sp.stateprovinceid = a.stateprovinceid
    ORDER BY bea.businessentityid,
             CASE bea.addresstypeid WHEN 3 THEN 1 WHEN 2 THEN 2 WHEN 4 THEN 3 WHEN 1 THEN 4 ELSE 5 END
)
INSERT INTO dw.dim_cliente (id_cliente, nome, tipo_cliente, cidade, estado, pais)
SELECT c.customerid::int,
       COALESCE(st.name,
                TRIM(p.firstname || ' ' || COALESCE(p.middlename || ' ', '') || p.lastname),
                'Cliente ' || c.customerid::int)                         AS nome,
       CASE WHEN c.storeid IS NOT NULL THEN 'Loja (revenda)' ELSE 'Pessoa Física' END AS tipo_cliente,
       COALESCE(e.city, 'Não informado')                                 AS cidade,
       COALESCE(e.estado, 'Não informado')                               AS estado,
       COALESCE(CASE cr.name
                    WHEN 'United States'  THEN 'Estados Unidos'
                    WHEN 'Canada'         THEN 'Canadá'
                    WHEN 'France'         THEN 'França'
                    WHEN 'Germany'        THEN 'Alemanha'
                    WHEN 'Australia'      THEN 'Austrália'
                    WHEN 'United Kingdom' THEN 'Reino Unido'
                    ELSE cr.name END, 'Não informado')                   AS pais
FROM stg.customer c
LEFT JOIN stg.person p          ON p.businessentityid = c.personid::int
LEFT JOIN stg.store st          ON st.businessentityid = c.storeid::int
LEFT JOIN endereco_principal e  ON e.businessentityid = COALESCE(c.storeid, c.personid)::int
LEFT JOIN stg.country_region cr ON cr.countryregioncode = e.countryregioncode;
