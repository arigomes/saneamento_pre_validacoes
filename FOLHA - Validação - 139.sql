-- VALIDAÇÃO 139
-- Calculo base outras empresas

select a.i_entidades,
       a.i_funcionarios,
       a.i_periodos,
       a.dt_aquis_ini,
       a.dt_aquis_fin,
       canceladoA = if exists (select 1
                                 from bethadba.periodos_ferias pf
                                where a.i_entidades = pf.i_entidades
                                  and a.i_funcionarios = pf.i_funcionarios
                                  and a.i_periodos = pf.i_periodos
                                  and pf.tipo in (5,7)) then 'true' else 'false' endif,
       canceladoB = if exists (select 1
                                 from bethadba.periodos_ferias pf
                                where b.i_entidades = pf.i_entidades
                                  and b.i_funcionarios = pf.i_funcionarios
                                  and b.i_periodos = pf.i_periodos
                                  and pf.tipo in (5,7)) then 'true' else 'false' endif,
       diferencaPeriodo = b.i_periodos - a.i_periodos
  from bethadba.periodos a 
  join bethadba.periodos b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios 
 where (a.dt_aquis_ini BETWEEN b.dt_aquis_ini and b.dt_aquis_fin or a.dt_aquis_fin BETWEEN b.dt_aquis_ini and b.dt_aquis_fin) 
   and a.i_periodos <> b.i_periodos
   and diferencaPeriodo = 1
   and (canceladoA = 'false' and canceladoB = 'false');


-- CORREÇÃO
-- Ajusta os períodos de férias para que não haja sobreposição entre os períodos aquisitivos dos funcionários, exceto quando um dos períodos estiver cancelado.
update bethadba.periodos a
  join bethadba.periodos b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios
   and a.i_periodos = b.i_periodos - 1
   set a.dt_aquis_fin = dateadd(day, -1, b.dt_aquis_ini)
 where (a.dt_aquis_ini BETWEEN b.dt_aquis_ini and b.dt_aquis_fin or a.dt_aquis_fin BETWEEN b.dt_aquis_ini and b.dt_aquis_fin);