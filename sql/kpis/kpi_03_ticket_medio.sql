-- KPI 03 — Ticket médio por pedido = receita líquida ÷ nº de pedidos distintos (por ano e canal).
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_03_ticket_medio;
CREATE MATERIALIZED VIEW kpi.kpi_03_ticket_medio AS
SELECT d.ano, c.canal,
       COUNT(DISTINCT f.numero_pedido)                                   AS qtd_pedidos,
       ROUND(SUM(f.valor_liquido) / COUNT(DISTINCT f.numero_pedido), 2)  AS ticket_medio,
       ROUND(SUM(f.quantidade)::numeric / COUNT(DISTINCT f.numero_pedido), 2) AS itens_por_pedido
FROM dw.fato_vendas f
JOIN dw.dim_data d  ON d.sk_data  = f.sk_data_pedido
JOIN dw.dim_canal c ON c.sk_canal = f.sk_canal
GROUP BY d.ano, c.canal
ORDER BY d.ano, c.canal;
