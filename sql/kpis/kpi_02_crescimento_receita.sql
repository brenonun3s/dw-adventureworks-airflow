-- KPI 02 — Crescimento da receita ano contra ano (YoY), em base comparável.
-- Duas regras evitam conclusões falsas:
--   1) cada ano é comparado apenas com os MESMOS meses do ano anterior (a base começa em mai/2022);
--   2) a série é cortada no último mês completo. Os pedidos de Revenda acontecem só no fim de cada
--      mês (dias 27–31); depois do último mês com Revenda a carga está incompleta (mai–jun/2025).
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_02_crescimento_receita;
CREATE MATERIALIZED VIEW kpi.kpi_02_crescimento_receita AS
WITH corte AS (
    SELECT MAX(d.data) AS ultimo_mes_completo
    FROM dw.fato_vendas f
    JOIN dw.dim_data d ON d.sk_data = f.sk_data_pedido
    WHERE f.sk_canal = 2                                   -- Revenda
),
mensal AS (
    SELECT d.ano, d.mes, SUM(f.valor_liquido) AS receita
    FROM dw.fato_vendas f
    JOIN dw.dim_data d ON d.sk_data = f.sk_data_pedido
    CROSS JOIN corte
    WHERE date_trunc('month', d.data) <= date_trunc('month', corte.ultimo_mes_completo)
    GROUP BY d.ano, d.mes
)
SELECT atual.ano,
       COUNT(*)                                  AS meses_comparados,
       MIN(atual.mes) || '–' || MAX(atual.mes)   AS faixa_meses,
       SUM(atual.receita)                        AS receita_periodo,
       SUM(anterior.receita)                     AS receita_mesmo_periodo_ano_anterior,
       ROUND(100.0 * (SUM(atual.receita) - SUM(anterior.receita)) / NULLIF(SUM(anterior.receita), 0), 2)
                                                 AS crescimento_pct
FROM mensal atual
JOIN mensal anterior ON anterior.ano = atual.ano - 1 AND anterior.mes = atual.mes
GROUP BY atual.ano
ORDER BY atual.ano;
