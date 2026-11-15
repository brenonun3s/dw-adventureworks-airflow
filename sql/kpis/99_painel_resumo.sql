-- Painel-resumo: um valor de referência por indicador (visão geral de toda a base).
DROP TABLE IF EXISTS kpi.painel_resumo;
CREATE TABLE kpi.painel_resumo AS
SELECT 1 AS ordem, 'Receita líquida total' AS indicador,
       ROUND(SUM(valor_liquido), 2) AS valor, 'US$' AS unidade
FROM dw.fato_vendas
UNION ALL
SELECT 2, 'Crescimento YoY ' || ano || ' (base comparável)', crescimento_pct, '%'
FROM kpi.kpi_02_crescimento_receita WHERE ano = (SELECT MAX(ano) FROM kpi.kpi_02_crescimento_receita)
UNION ALL
SELECT 3, 'Ticket médio por pedido',
       ROUND(SUM(valor_liquido) / COUNT(DISTINCT numero_pedido), 2), 'US$'
FROM dw.fato_vendas
UNION ALL
SELECT 4, 'Margem bruta', ROUND(100.0 * SUM(lucro_bruto) / SUM(valor_liquido), 2), '%'
FROM dw.fato_vendas
UNION ALL
SELECT 5, 'Participação do canal Internet',
       ROUND(100.0 * SUM(valor_liquido) FILTER (WHERE sk_canal = 1) / SUM(valor_liquido), 2), '%'
FROM dw.fato_vendas
UNION ALL
SELECT 6, 'Participação do maior território (' || territorio || ')', participacao_pct, '%'
FROM kpi.kpi_06_receita_territorio WHERE ranking = 1
UNION ALL
SELECT 7, 'Participação da categoria Bicicletas',
       ROUND(100.0 * SUM(receita_liquida) FILTER (WHERE categoria = 'Bicicletas') / SUM(receita_liquida), 2), '%'
FROM kpi.kpi_07_mix_produtos
UNION ALL
SELECT 8, 'Taxa de recompra de clientes', taxa_recompra_pct, '%'
FROM kpi.kpi_08_taxa_recompra WHERE tipo_cliente IS NULL
UNION ALL
SELECT 9, 'Taxa de desconto concedido',
       ROUND(100.0 * SUM(valor_desconto) / SUM(valor_bruto), 2), '%'
FROM dw.fato_vendas
UNION ALL
SELECT 10, 'Atingimento médio de meta dos vendedores',
       ROUND(100.0 * SUM(realizado) / SUM(valor_meta), 2), '%'
FROM kpi.kpi_10_atingimento_meta
ORDER BY 1;
