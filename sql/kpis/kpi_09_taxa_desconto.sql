-- KPI 09 — Taxa de desconto concedido (%) = valor de desconto ÷ valor bruto, por ano e tipo de promoção.
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_09_taxa_desconto;
CREATE MATERIALIZED VIEW kpi.kpi_09_taxa_desconto AS
SELECT d.ano, pr.tipo AS tipo_promocao,
       SUM(f.valor_bruto)                                                     AS valor_bruto,
       SUM(f.valor_desconto)                                                  AS valor_desconto,
       ROUND(100.0 * SUM(f.valor_desconto) / NULLIF(SUM(f.valor_bruto), 0), 2) AS taxa_desconto_pct,
       COUNT(*)                                                               AS itens_vendidos
FROM dw.fato_vendas f
JOIN dw.dim_data d      ON d.sk_data      = f.sk_data_pedido
JOIN dw.dim_promocao pr ON pr.sk_promocao = f.sk_promocao
GROUP BY d.ano, pr.tipo
ORDER BY d.ano, valor_desconto DESC;
