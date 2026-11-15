-- Carga completa (full refresh): esvazia o DW antes de recarregar.
-- RESTART IDENTITY reinicia as chaves substitutas; CASCADE alcança as fatos.
TRUNCATE TABLE dw.fato_vendas, dw.fato_meta_vendedor,
               dw.dim_cliente, dw.dim_produto, dw.dim_territorio, dw.dim_vendedor,
               dw.dim_canal, dw.dim_promocao, dw.dim_data
RESTART IDENTITY CASCADE;
