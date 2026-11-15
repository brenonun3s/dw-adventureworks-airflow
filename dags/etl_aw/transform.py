from __future__ import annotations

import logging
import os
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.engine import Engine

log = logging.getLogger(__name__)

SQL_DIR = Path(os.getenv("DW_SQL_DIR", Path(__file__).resolve().parents[2] / "sql"))

DIMENSOES = ["dim_data", "dim_cliente", "dim_produto", "dim_territorio",
             "dim_vendedor", "dim_canal", "dim_promocao"]
FATOS = ["fato_vendas", "fato_meta_vendedor"]


def ler_sql(caminho_relativo: str) -> str:
    return (SQL_DIR / caminho_relativo).read_text(encoding="utf-8")


def executar_script(caminho_relativo: str, dw: Engine) -> None:
    """Executa um arquivo .sql inteiro numa única transação."""
    sql = ler_sql(caminho_relativo)
    raw = dw.raw_connection()
    try:
        with raw.cursor() as cur:
            cur.execute(sql)
        raw.commit()
    except Exception:
        raw.rollback()
        raise
    finally:
        raw.close()
    log.info("script executado: %s", caminho_relativo)


def carregar_tabela(tabela: str, dw: Engine) -> int:
    """Carrega uma dimensão/fato a partir do staging e devolve a contagem final."""
    executar_script(f"transform/{tabela}.sql", dw)
    with dw.connect() as conn:
        total = conn.execute(text(f"SELECT COUNT(*) FROM dw.{tabela}")).scalar_one()
        conn.execute(text(f"ANALYZE dw.{tabela}"))
        conn.commit()
    log.info("dw.%s: %s linhas carregadas", tabela, total)
    return int(total)
