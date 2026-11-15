-- KPI 04 — Margem bruta (%) = (receita líquida − custo) ÷ receita líquida, por ano e categoria.
-- O custo usa o histórico de custo vigente na data do pedido (ProductCostHistory).
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_04_margem_bruta;
CREATE MATERIALIZED VIEW kpi.kpi_04_margem_bruta AS
SELECT d.ano, p.categoria,
       SUM(f.valor_liquido)                                                       AS receita_liquida,
       SUM(f.custo_total)                                                         AS custo_total,
       SUM(f.lucro_bruto)                                                         AS lucro_bruto,
       ROUND(100.0 * SUM(f.lucro_bruto) / NULLIF(SUM(f.valor_liquido), 0), 2)     AS margem_bruta_pct
FROM dw.fato_vendas f
JOIN dw.dim_data d    ON d.sk_data    = f.sk_data_pedido
JOIN dw.dim_produto p ON p.sk_produto = f.sk_produto
GROUP BY d.ano, p.categoria
ORDER BY d.ano, p.categoria;
