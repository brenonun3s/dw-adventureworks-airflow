-- Fato Meta de Vendedor (grão: vendedor x período de meta, normalmente trimestral).
-- A data final de cada meta é o dia anterior ao início da meta seguinte do mesmo vendedor.
INSERT INTO dw.fato_meta_vendedor (sk_vendedor, sk_data_inicio, sk_data_fim, valor_meta)
WITH metas AS (
    SELECT q.businessentityid,
           q.quotadate::date AS inicio,
           COALESCE(LEAD(q.quotadate::date) OVER (PARTITION BY q.businessentityid ORDER BY q.quotadate) - 1,
                    (q.quotadate::date + INTERVAL '3 months' - INTERVAL '1 day')::date) AS fim,
           q.salesquota
    FROM stg.sales_person_quota_history q
)
SELECT COALESCE(dv.sk_vendedor, 0),
       TO_CHAR(m.inicio, 'YYYYMMDD')::int,
       TO_CHAR(m.fim, 'YYYYMMDD')::int,
       m.salesquota
FROM metas m
LEFT JOIN dw.dim_vendedor dv ON dv.id_vendedor = m.businessentityid;
