from __future__ import annotations

from datetime import datetime, timedelta

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.sdk import Asset, dag, task, task_group

from etl_aw import extract, quality, transform

CONN_ORIGEM = "aw_origem"
CONN_DW = "dw_postgres"

DW_ATUALIZADO = Asset("postgres://dw_postgres/dw_adventureworks/dw/fato_vendas")


def _engine(conn_id: str):
    return PostgresHook(postgres_conn_id=conn_id).get_sqlalchemy_engine()


@dag(
    dag_id="dw_adventureworks_etl",
    description="ETL AdventureWorks (OLTP) -> Data Warehouse em estrela no PostgreSQL",
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    template_searchpath=[str(transform.SQL_DIR)],
    default_args={"owner": "breno", "retries": 2, "retry_delay": timedelta(minutes=2)},
    tags=["adventureworks", "etl", "dw"],
    doc_md=__doc__,
)
def dw_adventureworks_etl():

    criar_estrutura = SQLExecuteQueryOperator(
        task_id="criar_estrutura_dw",
        conn_id=CONN_DW,
        sql="01_ddl_dw.sql",
        split_statements=True,
    )

    limpar_dw = SQLExecuteQueryOperator(
        task_id="limpar_dw",
        conn_id=CONN_DW,
        sql="transform/00_limpar_dw.sql",
    )

    @task(max_active_tis_per_dag=6)
    def extrair_tabela(tabela: str) -> int:
        return extract.extrair_tabela(tabela, _engine(CONN_ORIGEM), _engine(CONN_DW))

    extracao = extrair_tabela.expand(tabela=list(extract.TABELAS_ORIGEM))

    @task_group(group_id="dimensoes")
    def carregar_dimensoes():
        for nome in transform.DIMENSOES:
            @task(task_id=f"carregar_{nome}")
            def carregar(tabela: str = nome) -> int:
                return transform.carregar_tabela(tabela, _engine(CONN_DW))
            carregar()

    @task_group(group_id="fatos")
    def carregar_fatos():
        for nome in transform.FATOS:
            @task(task_id=f"carregar_{nome}")
            def carregar(tabela: str = nome) -> int:
                return transform.carregar_tabela(tabela, _engine(CONN_DW))
            carregar()

    @task(outlets=[DW_ATUALIZADO])
    def validar_qualidade() -> dict:
        return quality.validar_carga(_engine(CONN_DW))

    criar_estrutura >> limpar_dw >> extracao >> carregar_dimensoes() >> carregar_fatos() >> validar_qualidade()


dw_adventureworks_etl()
