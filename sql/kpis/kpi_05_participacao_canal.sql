-- KPI 05 — Participação de cada canal (Internet × Revenda) na receita do ano (%).
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_05_participacao_canal;
CREATE MATERIALIZED VIEW kpi.kpi_05_participacao_canal AS
SELECT d.ano, c.canal,
       SUM(f.valor_liquido) AS receita_liquida,
       ROUND(100.0 * SUM(f.valor_liquido) / SUM(SUM(f.valor_liquido)) OVER (PARTITION BY d.ano), 2)
                            AS participacao_pct
FROM dw.fato_vendas f
JOIN dw.dim_data d  ON d.sk_data  = f.sk_data_pedido
JOIN dw.dim_canal c ON c.sk_canal = f.sk_canal
GROUP BY d.ano, c.canal
ORDER BY d.ano, c.canal;
