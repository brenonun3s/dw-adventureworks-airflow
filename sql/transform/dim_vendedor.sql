-- Dimensão Vendedor. O membro 0 representa vendas sem vendedor (canal Internet).
INSERT INTO dw.dim_vendedor VALUES (0, -1, 'Sem vendedor (venda online)', 'Não se aplica', 'Não se aplica');

INSERT INTO dw.dim_vendedor (id_vendedor, nome, cargo, territorio)
SELECT sp.businessentityid,
       TRIM(p.firstname || ' ' || p.lastname)     AS nome,
       COALESCE(e.jobtitle, 'Não informado')      AS cargo,
       COALESCE(t.name, 'Sem território fixo')    AS territorio
FROM stg.sales_person sp
JOIN stg.person p             ON p.businessentityid = sp.businessentityid
LEFT JOIN stg.employee e      ON e.businessentityid = sp.businessentityid
LEFT JOIN stg.sales_territory t ON t.territoryid = sp.territoryid::int;
