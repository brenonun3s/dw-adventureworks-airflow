import logging
import os
import sys
from pathlib import Path

from sqlalchemy import create_engine

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dags"))
from etl_aw import extract, quality, transform  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

origem = create_engine(os.environ["AW_ORIGEM_URL"])
dw = create_engine(os.environ["DW_URL"])

transform.executar_script("01_ddl_dw.sql", dw)
transform.executar_script("transform/00_limpar_dw.sql", dw)
for tabela in extract.TABELAS_ORIGEM:
    extract.extrair_tabela(tabela, origem, dw)
for tabela in transform.DIMENSOES + transform.FATOS:
    transform.carregar_tabela(tabela, dw)
print(quality.validar_carga(dw))
for arquivo in sorted((transform.SQL_DIR / "kpis").glob("kpi_*.sql")) + [transform.SQL_DIR / "kpis" / "99_painel_resumo.sql"]:
    transform.executar_script(f"kpis/{arquivo.name}", dw)
print("Pipeline concluído.")
