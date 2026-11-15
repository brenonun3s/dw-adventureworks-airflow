-- KPI 01 — Receita líquida (mensal), com volume de pedidos e clientes ativos.
-- Receita líquida = Σ (quantidade × preço unitário × (1 − desconto))
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_01_receita_liquida;
CREATE MATERIALIZED VIEW kpi.kpi_01_receita_liquida AS
SELECT d.ano, d.mes, d.ano_mes,
       SUM(f.valor_liquido)              AS receita_liquida,
       COUNT(DISTINCT f.numero_pedido)   AS qtd_pedidos,
       COUNT(DISTINCT f.sk_cliente)      AS clientes_ativos
FROM dw.fato_vendas f
JOIN dw.dim_data d ON d.sk_data = f.sk_data_pedido
GROUP BY d.ano, d.mes, d.ano_mes
ORDER BY d.ano, d.mes;
