-- Fato Vendas (grão: item de pedido).
-- Transformações: troca das chaves naturais pelas chaves substitutas das dimensões
-- (com membro "desconhecido" = 0), custo pelo histórico vigente na data do pedido,
-- e cálculo das medidas derivadas (valor bruto, desconto, lucro, prazo de envio).
INSERT INTO dw.fato_vendas (
    sk_data_pedido, sk_data_envio, sk_cliente, sk_produto, sk_territorio, sk_vendedor,
    sk_canal, sk_promocao, numero_pedido, id_item_pedido, quantidade, preco_unitario,
    percentual_desconto, valor_bruto, valor_desconto, valor_liquido, custo_total,
    lucro_bruto, dias_para_envio)
WITH itens AS (
    SELECT h.salesorderid, d.salesorderdetailid, h.orderdate::date AS data_pedido,
           h.shipdate::date AS data_envio, h.customerid, h.territoryid::int AS territoryid,
           h.salespersonid::int AS salespersonid, h.onlineorderflag,
           d.productid, d.specialofferid, d.orderqty,
           -- staging guarda valores como double precision: converte para NUMERIC (precisão decimal)
           d.unitprice::numeric AS unitprice, d.unitpricediscount::numeric AS unitpricediscount,
           -- custo vigente na data do pedido; se não houver histórico, usa o custo padrão atual
           COALESCE(pch.standardcost, p.standardcost)::numeric AS custo_unitario
    FROM stg.sales_order_detail d
    JOIN stg.sales_order_header h ON h.salesorderid = d.salesorderid
    JOIN stg.product p            ON p.productid = d.productid
    LEFT JOIN stg.product_cost_history pch
           ON pch.productid = d.productid
          AND h.orderdate >= pch.startdate
          AND (pch.enddate IS NULL OR h.orderdate <= pch.enddate)
)
SELECT TO_CHAR(i.data_pedido, 'YYYYMMDD')::int,
       COALESCE(TO_CHAR(i.data_envio, 'YYYYMMDD')::int, 0),
       COALESCE(dc.sk_cliente, 0),
       COALESCE(dp.sk_produto, 0),
       COALESCE(dt.sk_territorio, 0),
       COALESCE(dv.sk_vendedor, 0),
       CASE WHEN i.onlineorderflag THEN 1 ELSE 2 END,
       COALESCE(dpr.sk_promocao, 0),
       i.salesorderid,
       i.salesorderdetailid,
       i.orderqty,
       i.unitprice,
       i.unitpricediscount,
       ROUND(i.orderqty * i.unitprice, 4)                                     AS valor_bruto,
       ROUND(i.orderqty * i.unitprice * i.unitpricediscount, 4)               AS valor_desconto,
       ROUND(i.orderqty * i.unitprice * (1 - i.unitpricediscount), 4)         AS valor_liquido,
       ROUND(i.orderqty * i.custo_unitario, 4)                                AS custo_total,
       ROUND(i.orderqty * (i.unitprice * (1 - i.unitpricediscount) - i.custo_unitario), 4) AS lucro_bruto,
       COALESCE(i.data_envio - i.data_pedido, 0)                              AS dias_para_envio
FROM itens i
LEFT JOIN dw.dim_cliente dc    ON dc.id_cliente    = i.customerid
LEFT JOIN dw.dim_produto dp    ON dp.id_produto    = i.productid
LEFT JOIN dw.dim_territorio dt ON dt.id_territorio = i.territoryid
LEFT JOIN dw.dim_vendedor dv   ON dv.id_vendedor   = i.salespersonid
LEFT JOIN dw.dim_promocao dpr  ON dpr.id_promocao  = i.specialofferid;
