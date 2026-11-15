-- Dimensão Promoção (ofertas especiais aplicadas aos itens do pedido).
INSERT INTO dw.dim_promocao VALUES (0, -1, 'Não informado', 'Não informado', 'Não informado', 0);

INSERT INTO dw.dim_promocao (id_promocao, descricao, tipo, categoria, percentual_desconto)
SELECT so.specialofferid,
       so.description,
       CASE so.type
            WHEN 'No Discount'         THEN 'Sem desconto'
            WHEN 'Volume Discount'     THEN 'Desconto por volume'
            WHEN 'Discontinued Product' THEN 'Produto descontinuado'
            WHEN 'Seasonal Discount'   THEN 'Desconto sazonal'
            WHEN 'Excess Inventory'    THEN 'Excesso de estoque'
            WHEN 'New Product'         THEN 'Produto novo'
            ELSE so.type END,
       CASE so.category
            WHEN 'No Discount' THEN 'Sem desconto'
            WHEN 'Reseller'    THEN 'Revenda'
            WHEN 'Customer'    THEN 'Cliente'
            ELSE so.category END,
       so.discountpct
FROM stg.special_offer so;
