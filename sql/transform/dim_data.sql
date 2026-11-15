-- Dimensão Data: calendário contínuo do primeiro pedido até a última data de envio/meta,
-- com atributos em português. Inclui o membro "desconhecido" (sk_data = 0).
INSERT INTO dw.dim_data VALUES
    (0, DATE '1900-01-01', 0, 0, 'Não informado', 'N/I', '0000-00', 0, 0, 0, 0, 'Não informado', FALSE);

WITH limites AS (
    SELECT LEAST(MIN(h.orderdate), (SELECT MIN(quotadate) FROM stg.sales_person_quota_history))::date AS inicio,
           (GREATEST(MAX(h.shipdate), MAX(h.duedate),
                     (SELECT MAX(quotadate) FROM stg.sales_person_quota_history))
            + INTERVAL '3 months')::date AS fim
    FROM stg.sales_order_header h
)
INSERT INTO dw.dim_data
SELECT TO_CHAR(d, 'YYYYMMDD')::int                       AS sk_data,
       d::date                                            AS data,
       EXTRACT(DAY FROM d)                                AS dia,
       EXTRACT(MONTH FROM d)                              AS mes,
       (ARRAY['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho',
              'Agosto','Setembro','Outubro','Novembro','Dezembro'])[EXTRACT(MONTH FROM d)] AS nome_mes,
       (ARRAY['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[EXTRACT(MONTH FROM d)] AS mes_abrev,
       TO_CHAR(d, 'YYYY-MM')                              AS ano_mes,
       EXTRACT(QUARTER FROM d)                            AS trimestre,
       CASE WHEN EXTRACT(MONTH FROM d) <= 6 THEN 1 ELSE 2 END AS semestre,
       EXTRACT(YEAR FROM d)                               AS ano,
       EXTRACT(ISODOW FROM d)                             AS dia_semana,
       (ARRAY['Segunda-feira','Terça-feira','Quarta-feira','Quinta-feira',
              'Sexta-feira','Sábado','Domingo'])[EXTRACT(ISODOW FROM d)] AS nome_dia_semana,
       EXTRACT(ISODOW FROM d) IN (6, 7)                   AS fim_de_semana
FROM limites, generate_series(limites.inicio, limites.fim, INTERVAL '1 day') AS d;
