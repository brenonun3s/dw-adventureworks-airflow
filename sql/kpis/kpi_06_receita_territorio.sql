-- KPI 06 — Receita e participação (%) por território de vendas, com ranking.
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_06_receita_territorio;
CREATE MATERIALIZED VIEW kpi.kpi_06_receita_territorio AS
SELECT t.grupo_regiao, t.pais, t.nome AS territorio,
       SUM(f.valor_liquido)                                                  AS receita_liquida,
       ROUND(100.0 * SUM(f.valor_liquido) / SUM(SUM(f.valor_liquido)) OVER (), 2) AS participacao_pct,
       RANK() OVER (ORDER BY SUM(f.valor_liquido) DESC)                      AS ranking
FROM dw.fato_vendas f
JOIN dw.dim_territorio t ON t.sk_territorio = f.sk_territorio
GROUP BY t.grupo_regiao, t.pais, t.nome
ORDER BY ranking;
