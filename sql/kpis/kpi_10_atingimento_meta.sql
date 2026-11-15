-- KPI 10 — Atingimento de meta (%) = receita realizada pelo vendedor no período ÷ meta do período.
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_10_atingimento_meta;
CREATE MATERIALIZED VIEW kpi.kpi_10_atingimento_meta AS
SELECT m.sk_vendedor, m.sk_data_inicio,          -- chaves para relacionar no Power BI
       v.nome AS vendedor, v.territorio,
       di.data AS inicio_periodo, dfim.data AS fim_periodo,
       di.ano, di.trimestre,
       m.valor_meta,
       COALESCE(r.realizado, 0)                                          AS realizado,
       ROUND(100.0 * COALESCE(r.realizado, 0) / NULLIF(m.valor_meta, 0), 2) AS atingimento_pct
FROM dw.fato_meta_vendedor m
JOIN dw.dim_vendedor v ON v.sk_vendedor = m.sk_vendedor
JOIN dw.dim_data di    ON di.sk_data    = m.sk_data_inicio
JOIN dw.dim_data dfim  ON dfim.sk_data  = m.sk_data_fim
LEFT JOIN LATERAL (
    SELECT SUM(f.valor_liquido) AS realizado
    FROM dw.fato_vendas f
    WHERE f.sk_vendedor = m.sk_vendedor
      AND f.sk_data_pedido BETWEEN m.sk_data_inicio AND m.sk_data_fim
) r ON TRUE
ORDER BY v.nome, di.data;
