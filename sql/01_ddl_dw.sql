-- =====================================================================
-- DW AdventureWorks — Estrutura (DDL)
-- Schemas:
--   stg  -> área de staging (cópia bruta das tabelas de origem)
--   dw   -> modelo dimensional (esquema estrela)
--   kpi  -> visões materializadas dos indicadores
-- Script idempotente: pode ser executado a cada carga.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS kpi;

-- ===================== DIMENSÕES =====================

CREATE TABLE IF NOT EXISTS dw.dim_data (
    sk_data          INTEGER      PRIMARY KEY,          -- formato AAAAMMDD
    data             DATE         NOT NULL UNIQUE,
    dia              SMALLINT     NOT NULL,
    mes              SMALLINT     NOT NULL,
    nome_mes         VARCHAR(15)  NOT NULL,
    mes_abrev        CHAR(3)      NOT NULL,
    ano_mes          CHAR(7)      NOT NULL,             -- 'AAAA-MM'
    trimestre        SMALLINT     NOT NULL,
    semestre         SMALLINT     NOT NULL,
    ano              SMALLINT     NOT NULL,
    dia_semana       SMALLINT     NOT NULL,             -- 1=segunda ... 7=domingo (ISO)
    nome_dia_semana  VARCHAR(15)  NOT NULL,
    fim_de_semana    BOOLEAN      NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_cliente (
    sk_cliente       SERIAL       PRIMARY KEY,
    id_cliente       INTEGER      NOT NULL UNIQUE,       -- sales.customer.customerid
    nome             VARCHAR(200) NOT NULL,
    tipo_cliente     VARCHAR(20)  NOT NULL,             -- Pessoa Física | Loja (revenda)
    cidade           VARCHAR(100) NOT NULL,
    estado           VARCHAR(100) NOT NULL,
    pais             VARCHAR(60)  NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_produto (
    sk_produto       SERIAL       PRIMARY KEY,
    id_produto       INTEGER      NOT NULL UNIQUE,       -- production.product.productid
    codigo_produto   VARCHAR(25)  NOT NULL,
    nome             VARCHAR(100) NOT NULL,
    categoria        VARCHAR(50)  NOT NULL,
    subcategoria     VARCHAR(50)  NOT NULL,
    linha_produto    VARCHAR(20)  NOT NULL,
    cor              VARCHAR(20)  NOT NULL,
    custo_padrao     NUMERIC(12,4) NOT NULL,
    preco_lista      NUMERIC(12,4) NOT NULL,
    fabricado_internamente BOOLEAN NOT NULL,
    em_linha         BOOLEAN      NOT NULL               -- ainda está à venda?
);

CREATE TABLE IF NOT EXISTS dw.dim_territorio (
    sk_territorio    SERIAL       PRIMARY KEY,
    id_territorio    INTEGER      NOT NULL UNIQUE,       -- sales.salesterritory.territoryid
    nome             VARCHAR(50)  NOT NULL,
    pais             VARCHAR(60)  NOT NULL,
    grupo_regiao     VARCHAR(50)  NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_vendedor (
    sk_vendedor      SERIAL       PRIMARY KEY,
    id_vendedor      INTEGER      NOT NULL UNIQUE,       -- sales.salesperson.businessentityid
    nome             VARCHAR(150) NOT NULL,
    cargo            VARCHAR(60)  NOT NULL,
    territorio       VARCHAR(50)  NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_canal (
    sk_canal         SMALLINT     PRIMARY KEY,
    canal            VARCHAR(30)  NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dw.dim_promocao (
    sk_promocao      SERIAL       PRIMARY KEY,
    id_promocao      INTEGER      NOT NULL UNIQUE,       -- sales.specialoffer.specialofferid
    descricao        VARCHAR(255) NOT NULL,
    tipo             VARCHAR(50)  NOT NULL,
    categoria        VARCHAR(50)  NOT NULL,
    percentual_desconto NUMERIC(6,4) NOT NULL
);

-- ===================== FATOS =====================

-- Grão: uma linha por item de pedido de venda (sales.salesorderdetail)
CREATE TABLE IF NOT EXISTS dw.fato_vendas (
    sk_venda             BIGSERIAL     PRIMARY KEY,
    sk_data_pedido       INTEGER       NOT NULL REFERENCES dw.dim_data(sk_data),
    sk_data_envio        INTEGER       NOT NULL REFERENCES dw.dim_data(sk_data),
    sk_cliente           INTEGER       NOT NULL REFERENCES dw.dim_cliente(sk_cliente),
    sk_produto           INTEGER       NOT NULL REFERENCES dw.dim_produto(sk_produto),
    sk_territorio        INTEGER       NOT NULL REFERENCES dw.dim_territorio(sk_territorio),
    sk_vendedor          INTEGER       NOT NULL REFERENCES dw.dim_vendedor(sk_vendedor),
    sk_canal             SMALLINT      NOT NULL REFERENCES dw.dim_canal(sk_canal),
    sk_promocao          INTEGER       NOT NULL REFERENCES dw.dim_promocao(sk_promocao),
    numero_pedido        INTEGER       NOT NULL,          -- dimensão degenerada
    id_item_pedido       INTEGER       NOT NULL UNIQUE,   -- dimensão degenerada
    quantidade           INTEGER       NOT NULL,
    preco_unitario       NUMERIC(14,4) NOT NULL,
    percentual_desconto  NUMERIC(6,4)  NOT NULL,
    valor_bruto          NUMERIC(16,4) NOT NULL,          -- quantidade * preço unitário
    valor_desconto       NUMERIC(16,4) NOT NULL,          -- valor_bruto - valor_liquido
    valor_liquido        NUMERIC(16,4) NOT NULL,          -- receita da linha
    custo_total          NUMERIC(16,4) NOT NULL,          -- quantidade * custo histórico
    lucro_bruto          NUMERIC(16,4) NOT NULL,          -- valor_liquido - custo_total
    dias_para_envio      SMALLINT      NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_fv_data_pedido ON dw.fato_vendas (sk_data_pedido);
CREATE INDEX IF NOT EXISTS ix_fv_cliente     ON dw.fato_vendas (sk_cliente);
CREATE INDEX IF NOT EXISTS ix_fv_produto     ON dw.fato_vendas (sk_produto);
CREATE INDEX IF NOT EXISTS ix_fv_territorio  ON dw.fato_vendas (sk_territorio);
CREATE INDEX IF NOT EXISTS ix_fv_vendedor    ON dw.fato_vendas (sk_vendedor);
CREATE INDEX IF NOT EXISTS ix_fv_pedido      ON dw.fato_vendas (numero_pedido);

-- Grão: uma linha por vendedor por trimestre (sales.salespersonquotahistory)
CREATE TABLE IF NOT EXISTS dw.fato_meta_vendedor (
    sk_meta              SERIAL        PRIMARY KEY,
    sk_vendedor          INTEGER       NOT NULL REFERENCES dw.dim_vendedor(sk_vendedor),
    sk_data_inicio       INTEGER       NOT NULL REFERENCES dw.dim_data(sk_data),
    sk_data_fim          INTEGER       NOT NULL REFERENCES dw.dim_data(sk_data),
    valor_meta           NUMERIC(16,4) NOT NULL,
    UNIQUE (sk_vendedor, sk_data_inicio)
);
