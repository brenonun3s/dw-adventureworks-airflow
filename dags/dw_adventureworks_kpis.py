from __future__ import annotations

from datetime import datetime

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.sdk import Asset, dag

from etl_aw.transform import SQL_DIR

DW_ATUALIZADO = Asset("postgres://dw_postgres/dw_adventureworks/dw/fato_vendas")
KPIS = sorted(p.name for p in (SQL_DIR / "kpis").glob("kpi_*.sql"))


@dag(
    dag_id="dw_adventureworks_kpis",
    description="Atualiza as visões materializadas dos 10 KPIs após cada carga do DW",
    schedule=[DW_ATUALIZADO],
    start_date=datetime(2026, 1, 1),
    catchup=False,
    template_searchpath=[str(SQL_DIR / "kpis")],
    default_args={"owner": "breno", "retries": 1},
    tags=["adventureworks", "kpi", "dw"],
    doc_md=__doc__,
)
def dw_adventureworks_kpis():
    calcular = [
        SQLExecuteQueryOperator(
            task_id=arquivo.removesuffix(".sql"),
            conn_id="dw_postgres",
            sql=arquivo,
            split_statements=True,
        )
        for arquivo in KPIS
    ]
    painel = SQLExecuteQueryOperator(
        task_id="montar_painel_resumo",
        conn_id="dw_postgres",
        sql="99_painel_resumo.sql",
        split_statements=True,
    )
    calcular >> painel


dw_adventureworks_kpis()
