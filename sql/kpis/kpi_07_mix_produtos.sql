-- KPI 07 — Mix de produtos: participação de cada categoria/subcategoria na receita
-- e posição no ranking (curva ABC: A = até 80% da receita acumulada).
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_07_mix_produtos;
CREATE MATERIALIZED VIEW kpi.kpi_07_mix_produtos AS
WITH por_sub AS (
    SELECT p.categoria, p.subcategoria,
           SUM(f.valor_liquido) AS receita_liquida,
           SUM(f.lucro_bruto)   AS lucro_bruto
    FROM dw.fato_vendas f
    JOIN dw.dim_produto p ON p.sk_produto = f.sk_produto
    GROUP BY p.categoria, p.subcategoria
)
SELECT categoria, subcategoria, receita_liquida, lucro_bruto,
       ROUND(100.0 * receita_liquida / SUM(receita_liquida) OVER (), 2) AS participacao_pct,
       ROUND(100.0 * SUM(receita_liquida) OVER (ORDER BY receita_liquida DESC)
                   / SUM(receita_liquida) OVER (), 2)                   AS participacao_acumulada_pct,
       CASE WHEN SUM(receita_liquida) OVER (ORDER BY receita_liquida DESC)
                 - receita_liquida < 0.80 * SUM(receita_liquida) OVER () THEN 'A'
            WHEN SUM(receita_liquida) OVER (ORDER BY receita_liquida DESC)
                 - receita_liquida < 0.95 * SUM(receita_liquida) OVER () THEN 'B'
            ELSE 'C' END                                                AS classe_abc
FROM por_sub
ORDER BY receita_liquida DESC;
