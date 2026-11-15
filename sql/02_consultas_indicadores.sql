-- Visão geral: um valor por indicador
SELECT ordem, indicador, valor, unidade FROM kpi.painel_resumo ORDER BY ordem;

-- KPI 01 — Receita líquida mensal
SELECT ano_mes, receita_liquida, qtd_pedidos, clientes_ativos FROM kpi.kpi_01_receita_liquida;

-- KPI 02 — Crescimento YoY em base comparável
SELECT * FROM kpi.kpi_02_crescimento_receita;

-- KPI 03 — Ticket médio por ano e canal
SELECT * FROM kpi.kpi_03_ticket_medio;

-- KPI 04 — Margem bruta por ano e categoria
SELECT ano, categoria, margem_bruta_pct FROM kpi.kpi_04_margem_bruta;

-- KPI 05 — Participação dos canais
SELECT * FROM kpi.kpi_05_participacao_canal;

-- KPI 06 — Receita por território
SELECT * FROM kpi.kpi_06_receita_territorio;

-- KPI 07 — Mix de produtos (curva ABC por subcategoria)
SELECT * FROM kpi.kpi_07_mix_produtos;

-- KPI 08 — Taxa de recompra (linha com tipo_cliente NULL = total)
SELECT * FROM kpi.kpi_08_taxa_recompra;

-- KPI 09 — Taxa de desconto por ano e tipo de promoção
SELECT * FROM kpi.kpi_09_taxa_desconto WHERE valor_desconto > 0;

-- KPI 10 — Atingimento de meta por vendedor (consolidado)
SELECT vendedor,
       SUM(valor_meta) AS meta, SUM(realizado) AS realizado,
       ROUND(100.0 * SUM(realizado) / SUM(valor_meta), 2) AS atingimento_pct
FROM kpi.kpi_10_atingimento_meta
GROUP BY vendedor
ORDER BY atingimento_pct DESC;

-- Consulta OLAP ad hoc direto na estrela (ex.: receita por grupo regional × canal × ano)
SELECT d.ano, t.grupo_regiao, c.canal, SUM(f.valor_liquido) AS receita
FROM dw.fato_vendas f
JOIN dw.dim_data d       ON d.sk_data = f.sk_data_pedido
JOIN dw.dim_territorio t ON t.sk_territorio = f.sk_territorio
JOIN dw.dim_canal c      ON c.sk_canal = f.sk_canal
GROUP BY ROLLUP (d.ano, t.grupo_regiao, c.canal)
ORDER BY 1, 2, 3;
