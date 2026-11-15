-- KPI 08 — Taxa de recompra (%) = clientes com 2+ pedidos ÷ clientes que compraram, por tipo de cliente.
DROP MATERIALIZED VIEW IF EXISTS kpi.kpi_08_taxa_recompra;
CREATE MATERIALIZED VIEW kpi.kpi_08_taxa_recompra AS
WITH pedidos_cliente AS (
    SELECT f.sk_cliente, COUNT(DISTINCT f.numero_pedido) AS qtd_pedidos
    FROM dw.fato_vendas f
    GROUP BY f.sk_cliente
)
SELECT c.tipo_cliente,
       COUNT(*)                                              AS clientes_compradores,
       COUNT(*) FILTER (WHERE pc.qtd_pedidos > 1)            AS clientes_recorrentes,
       ROUND(100.0 * COUNT(*) FILTER (WHERE pc.qtd_pedidos > 1) / COUNT(*), 2) AS taxa_recompra_pct,
       ROUND(AVG(pc.qtd_pedidos), 2)                         AS pedidos_por_cliente
FROM pedidos_cliente pc
JOIN dw.dim_cliente c ON c.sk_cliente = pc.sk_cliente
GROUP BY ROLLUP (c.tipo_cliente)
ORDER BY c.tipo_cliente NULLS LAST;
