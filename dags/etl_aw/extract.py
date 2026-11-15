from __future__ import annotations

import io
import logging

import pandas as pd
from sqlalchemy.engine import Engine

log = logging.getLogger(__name__)

TABELAS_ORIGEM: dict[str, str] = {
    "customer": """
        SELECT customerid, personid, storeid, territoryid
        FROM sales.customer""",
    "person": """
        SELECT businessentityid, firstname, middlename, lastname, persontype
        FROM person.person""",
    "store": """
        SELECT businessentityid, name
        FROM sales.store""",
    "business_entity_address": """
        SELECT businessentityid, addressid, addresstypeid
        FROM person.businessentityaddress""",
    "address": """
        SELECT addressid, city, stateprovinceid
        FROM person.address""",
    "state_province": """
        SELECT stateprovinceid, name, countryregioncode
        FROM person.stateprovince""",
    "country_region": """
        SELECT countryregioncode, name
        FROM person.countryregion""",
    "product": """
        SELECT productid, productnumber, name, color, productline, makeflag,
               standardcost, listprice, productsubcategoryid, sellenddate
        FROM production.product""",
    "product_subcategory": """
        SELECT productsubcategoryid, productcategoryid, name
        FROM production.productsubcategory""",
    "product_category": """
        SELECT productcategoryid, name
        FROM production.productcategory""",
    "product_cost_history": """
        SELECT productid, startdate, enddate, standardcost
        FROM production.productcosthistory""",
    "sales_territory": """
        SELECT territoryid, name, countryregioncode, "group" AS grupo
        FROM sales.salesterritory""",
    "sales_person": """
        SELECT businessentityid, territoryid, salesquota
        FROM sales.salesperson""",
    "employee": """
        SELECT businessentityid, jobtitle
        FROM humanresources.employee""",
    "special_offer": """
        SELECT specialofferid, description, discountpct, type, category
        FROM sales.specialoffer""",
    "sales_order_header": """
        SELECT salesorderid, orderdate, duedate, shipdate, status, onlineorderflag,
               customerid, salespersonid, territoryid, subtotal, taxamt, freight
        FROM sales.salesorderheader""",
    "sales_order_detail": """
        SELECT salesorderdetailid, salesorderid, productid, specialofferid,
               orderqty, unitprice, unitpricediscount
        FROM sales.salesorderdetail""",
    "sales_person_quota_history": """
        SELECT businessentityid, quotadate, salesquota
        FROM sales.salespersonquotahistory""",
}


def _copy_dataframe(df: pd.DataFrame, tabela: str, engine: Engine, schema: str = "stg") -> None:
    """Recria a tabela de staging e carrega os dados com COPY (bem mais rápido que INSERT)."""
    df.head(0).to_sql(tabela, engine, schema=schema, if_exists="replace", index=False)
    buffer = io.StringIO()
    df.to_csv(buffer, index=False, header=False, na_rep="\\N")
    buffer.seek(0)
    raw = engine.raw_connection()
    try:
        with raw.cursor() as cur:
            cur.copy_expert(
                f'COPY {schema}."{tabela}" FROM STDIN WITH (FORMAT csv, NULL \'\\N\')', buffer
            )
        raw.commit()
    finally:
        raw.close()


def extrair_tabela(tabela: str, origem: Engine, dw: Engine) -> int:
    """Extrai uma tabela da origem para stg.<tabela>. Retorna a quantidade de linhas."""
    consulta = TABELAS_ORIGEM[tabela]
    df = pd.read_sql(consulta, origem)
    _copy_dataframe(df, tabela, dw)
    log.info("stg.%s: %s linhas extraídas", tabela, len(df))
    return len(df)
