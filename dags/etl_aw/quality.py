from __future__ import annotations

import logging

from sqlalchemy import text
from sqlalchemy.engine import Engine

log = logging.getLogger(__name__)

CHECAGENS: dict[str, str] = {
    "linhas_fato_igual_origem": """
        SELECT (SELECT COUNT(*) FROM dw.fato_vendas) = (SELECT COUNT(*) FROM stg.sales_order_detail)
    """,
    "receita_reconcilia_com_origem": """
        SELECT ABS((SELECT SUM(valor_liquido) FROM dw.fato_vendas)
                 - (SELECT SUM(subtotal)      FROM stg.sales_order_header)) < 1
    """,
    "sem_cliente_ou_produto_desconhecido": """
        SELECT COUNT(*) = 0 FROM dw.fato_vendas WHERE sk_cliente = 0 OR sk_produto = 0
    """,
    "datas_resolvidas": """
        SELECT COUNT(*) = 0 FROM dw.fato_vendas WHERE sk_data_pedido = 0
    """,
    "medidas_consistentes": """
        SELECT COUNT(*) = 0 FROM dw.fato_vendas
        WHERE ABS(valor_bruto - valor_desconto - valor_liquido) > 0.01
    """,
    "metas_com_vendedor": """
        SELECT COUNT(*) > 0 AND COUNT(*) FILTER (WHERE sk_vendedor = 0) = 0
        FROM dw.fato_meta_vendedor
    """,
}


def validar_carga(dw: Engine) -> dict[str, bool]:
    resultados: dict[str, bool] = {}
    with dw.connect() as conn:
        for nome, sql in CHECAGENS.items():
            resultados[nome] = bool(conn.execute(text(sql)).scalar_one())
            log.info("checagem %-40s %s", nome, "OK" if resultados[nome] else "FALHOU")
    falhas = [n for n, ok in resultados.items() if not ok]
    if falhas:
        raise ValueError(f"Falha nas checagens de qualidade: {falhas}")
    return resultados
