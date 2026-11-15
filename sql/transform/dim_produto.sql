-- Dimensão Produto: desnormaliza categoria/subcategoria (snowflake -> estrela),
-- traduz domínios codificados e trata nulos.
INSERT INTO dw.dim_produto VALUES
    (0, -1, 'N/I', 'Não informado', 'Não informado', 'Não informado', 'Não informado', 'Não informado', 0, 0, FALSE, FALSE);

INSERT INTO dw.dim_produto (id_produto, codigo_produto, nome, categoria, subcategoria,
                            linha_produto, cor, custo_padrao, preco_lista,
                            fabricado_internamente, em_linha)
SELECT p.productid,
       p.productnumber,
       p.name,
       CASE pc.name
            WHEN 'Bikes'       THEN 'Bicicletas'
            WHEN 'Components'  THEN 'Componentes'
            WHEN 'Clothing'    THEN 'Vestuário'
            WHEN 'Accessories' THEN 'Acessórios'
            ELSE 'Sem categoria' END                          AS categoria,
       COALESCE(ps.name, 'Sem subcategoria')                  AS subcategoria,
       CASE TRIM(p.productline)
            WHEN 'R' THEN 'Estrada'
            WHEN 'M' THEN 'Montanha'
            WHEN 'T' THEN 'Touring'
            WHEN 'S' THEN 'Padrão'
            ELSE 'Não se aplica' END                          AS linha_produto,
       COALESCE(p.color, 'Sem cor')                           AS cor,
       p.standardcost,
       p.listprice,
       p.makeflag,
       p.sellenddate IS NULL                                  AS em_linha
FROM stg.product p
LEFT JOIN stg.product_subcategory ps ON ps.productsubcategoryid = p.productsubcategoryid::int
LEFT JOIN stg.product_category pc    ON pc.productcategoryid = ps.productcategoryid;
