-- VALIDAÇÃO 00
-- Afastamentos Concomitantes para o mesmo funcionário e mesma entidade

WITH raw AS (
    select i_entidades,
           i_funcionarios,
           tipo = 'AFASTAMENTO',
           dataInicioConcomitante = dt_afastamento,
           dataFimConcomitante = dt_ultimo_dia
      from bethadba.afastamentos

    union all

    select i_entidades,
           i_funcionarios,
           tipo = 'FALTAS',
           dataInicioConcomitante = dt_inicial,
           dataFimConcomitante = Date(dt_inicial + qtd_faltas)
      from bethadba.faltas

    union all

    select i_entidades,
           i_funcionarios,
           tipo = 'FERIAS',
           dataInicioConcomitante = dt_gozo_ini,
           dataFimConcomitante = dt_gozo_fin
      from bethadba.ferias

    union all

    select i_entidades,
           i_funcionarios,
           tipo = 'RESCISAO',
           dataInicioConcomitante = dt_rescisao,
           dataFimConcomitante = null
      from bethadba.rescisoes
),
tabTemp AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY i_entidades, i_funcionarios
            ORDER BY dataInicioConcomitante, tipo
        ) AS id,
        *
    FROM raw
)
SELECT t.i_entidades,
       t.i_funcionarios,
       t.tipo,
       t.dataInicioConcomitante,
       t.dataFimConcomitante,
       CASE WHEN EXISTS (SELECT 1
                           FROM tabTemp o
                          WHERE o.id <> t.id
                            AND o.i_entidades = t.i_entidades
                            AND o.i_funcionarios = t.i_funcionarios
                            -- tratar datas nulas como intervalo aberto usando um sentinela no futuro
                            AND COALESCE(o.dataFimConcomitante, CAST('9999-12-31' AS date)) >= t.dataInicioConcomitante
                            AND COALESCE(t.dataFimConcomitante, CAST('9999-12-31' AS date)) >= o.dataInicioConcomitante) THEN 'S' ELSE 'N' END AS ExisteConcomitante
  FROM tabTemp as t
 WHERE ExisteConcomitante = 'S'
 ORDER BY t.i_entidades, t.i_funcionarios, t.dataInicioConcomitante;

-- CORREÇÃO 00
-- Ajuste de Afastamentos Concomitantes para o mesmo funcionário e mesma entidade

