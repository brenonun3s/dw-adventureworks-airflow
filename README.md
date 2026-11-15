# DW AdventureWorks — ETL com Apache Airflow e PostgreSQL

Data Warehouse em **esquema estrela** construído a partir da base transacional **AdventureWorks**, com pipeline de ETL orquestrado no **Apache Airflow 3** e armazenamento em **PostgreSQL 16**.

Trabalho prático das disciplinas *Projeto de Análise e Fluxo de Dados – OLAP e ETL* e *Projeto de Desenvolvimento de Dashboard Analítico* (Unisales, 2026). Evolução do repositório [work_etl_university](https://github.com/brenonun3s/work_etl_university).

![Modelo estrela](docs/img/modelo_estrela.png)

## O que mudou em relação à versão anterior

| Antes (`work_etl_university`) | Agora |
|---|---|
| Script Python único, sem orquestração | 2 DAGs no Airflow 3 (ETL + KPIs), com retries, paralelismo e agendamento por Asset |
| `__main__` não carregava as dimensões nem o calendário (a carga quebrava por FK) | Carga em ordem: estrutura → staging → dimensões → fatos → checagens de qualidade |
| Chaves substitutas recalculadas em Python por posição | Chaves geradas pelo banco e resolvidas por *lookup* da chave natural, com membro "desconhecido" (0) |
| Custo pelo `StandardCost` atual | Custo histórico vigente na data do pedido (`ProductCostHistory`) |
| 6 dimensões, 1 fato | 7 dimensões (+ promoção), 2 fatos (+ metas de vendedores) |
| Sem ambiente reproduzível (README citava `docker compose`, mas o arquivo não existia) | `docker compose up` sobe Postgres com AdventureWorks + Airflow prontos |
| Sem validação | 6 checagens automáticas, incluindo reconciliação da receita com a origem |

## Arquitetura

```
AdventureWorks (OLTP)          dw_adventureworks (PostgreSQL)
┌──────────────────┐   E    ┌───────────┐   T + L   ┌──────────────┐        ┌───────────┐
│ sales, person,   │ ─────► │ stg.*     │ ────────► │ dw.dim_*     │ ─────► │ kpi.*     │ ─► Power BI
│ production, hr   │ pandas │ (cópia    │   SQL     │ dw.fato_*    │  SQL   │ (views    │
└──────────────────┘  COPY  │  bruta)   │           │ (estrela)    │        │  materia- │
                            └───────────┘           └──────────────┘        │  lizadas) │
                                                                            └───────────┘
        └──────────── DAG dw_adventureworks_etl ───────────┘   └─ DAG dw_adventureworks_kpis ─┘
```

* **Extração** (Python/pandas): 18 tabelas da origem são copiadas para o schema `stg` com `COPY`, uma task por tabela (*dynamic task mapping*).
* **Transformação e carga** (SQL dentro do DW): tradução de domínios para português, desnormalização da hierarquia de produto, tratamento de nulos, troca de chaves naturais por substitutas, custo histórico e cálculo das medidas derivadas.
* **Qualidade**: a carga só é considerada concluída se as 6 checagens passarem; só então o Asset é publicado e a DAG de KPIs é disparada.

## Estrutura do repositório

```
dags/
  dw_adventureworks_etl.py     DAG 1 — extração, dimensões, fatos e qualidade
  dw_adventureworks_kpis.py    DAG 2 — recalcula os 10 KPIs (disparada por Asset)
  etl_aw/                      extract.py · transform.py · quality.py
sql/
  01_ddl_dw.sql                estrutura do DW (schemas stg, dw, kpi)
  transform/*.sql              uma transformação por dimensão/fato
  kpis/kpi_01 … kpi_10.sql     os 10 indicadores (views materializadas)
  kpis/99_painel_resumo.sql    tabela com um valor de referência por KPI
  02_consultas_indicadores.sql consultas prontas para conferir os KPIs
docker/                        imagens do Postgres (com AdventureWorks) e do Airflow
docs/                          dicionário de dados, KPIs, diagrama e prints das DAGs
powerbi/                       medidas DAX e guia do dashboard
scripts/run_etl_local.py       roda o mesmo pipeline sem Airflow (depuração)
```

## Como executar

Pré-requisito: [Docker Desktop](https://www.docker.com/products/docker-desktop/) (ou Docker Engine + Compose v2).

```bash
git clone https://github.com/brenonun3s/<este-repositorio>.git
cd <este-repositorio>
docker compose up -d --build
```

1. Na **primeira** subida o Postgres baixa e carrega o AdventureWorks (2 a 5 minutos). Acompanhe com `docker compose logs -f postgres` até aparecer `AdventureWorks carregado`.
2. Abra o Airflow em **http://localhost:8080** (sem login — ambiente acadêmico).
3. A DAG `dw_adventureworks_etl` já nasce ativa e executa uma vez; ao terminar, dispara a `dw_adventureworks_kpis`. Para rodar de novo, clique em **Trigger**.
4. Conecte-se ao DW (Power BI, DBeaver, pgAdmin): host `localhost`, porta `5432`, banco `dw_adventureworks`, usuário/senha `postgres`/`postgres`.

> Porta 5432 ocupada por outro Postgres? Rode `PG_PORT=5433 docker compose up -d --build` e use a porta 5433.

Para recomeçar do zero: `docker compose down -v`.

### Executar sem Docker (opcional)

Com um PostgreSQL local já contendo o AdventureWorks:

```bash
pip install -r requirements-local.txt
export AW_ORIGEM_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/Adventureworks
export DW_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/dw_adventureworks
python scripts/run_etl_local.py
```

## Indicadores

| # | KPI | Valor (base completa) |
|---|---|---|
| 1 | Receita líquida total | US$ 109,85 mi |
| 2 | Crescimento YoY 2025 (jan–abr, base comparável) | +74,07% |
| 3 | Ticket médio por pedido | US$ 3.491,07 |
| 4 | Margem bruta | 11,43% |
| 5 | Participação do canal Internet | 26,73% |
| 6 | Participação do maior território (EUA Sudoeste) | 22,02% |
| 7 | Participação da categoria Bicicletas | 86,17% |
| 8 | Taxa de recompra de clientes | 39,07% |
| 9 | Taxa de desconto concedido | 0,48% |
| 10 | Atingimento de meta dos vendedores | 84,09% |

Definições, fórmulas e leitura de cada indicador em [docs/kpis.md](docs/kpis.md). Dicionário de dados em [docs/dicionario_dados.md](docs/dicionario_dados.md).

## DAGs no Airflow

![Grafo da DAG de ETL](docs/img/dag_etl_grafo.png)
![Grafo da DAG de KPIs](docs/img/dag_kpis_grafo.png)

## Créditos

* Base AdventureWorks: Microsoft ([sql-server-samples](https://github.com/microsoft/sql-server-samples)).
* Conversão para PostgreSQL: [lorint/AdventureWorks-for-Postgres](https://github.com/lorint/AdventureWorks-for-Postgres) (MIT) — arquivos em `docker/postgres/`.

## Autor

Breno Nunes dos Santos — Sistemas de Informação, Unisales (2026).
