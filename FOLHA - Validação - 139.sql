-- VALIDAÇÃO 139
-- Periodo aquisitivo de ferias concomitantes

select a.i_entidades,
       a.i_funcionarios,
       a.i_periodos,
       a.dt_aquis_ini,
       a.dt_aquis_fin,
       b.i_entidades,
       b.i_funcionarios,
       b.i_periodos,
       b.dt_aquis_ini,
       b.dt_aquis_fin,
       canceladoA = if exists (select 1
                                 from bethadba.periodos_ferias pf 
                                where a.i_entidades=pf.i_entidades and
                                      a.i_funcionarios=pf.i_funcionarios and
                                      a.i_periodos=pf.i_periodos and
                                      pf.tipo in (5,7)) then 'true' else 'false' endif,
       canceladoB = if exists (select 1
                                 from bethadba.periodos_ferias pf 
                                where b.i_entidades=pf.i_entidades and
                                      b.i_funcionarios=pf.i_funcionarios and
                                      b.i_periodos=pf.i_periodos and
                                      pf.tipo in (5,7)) then 'true' else 'false' endif                             
  from bethadba.periodos a 
  join bethadba.periodos b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios 
 where (a.dt_aquis_ini between b.dt_aquis_ini and b.dt_aquis_fin or a.dt_aquis_fin between b.dt_aquis_ini and b.dt_aquis_fin) 
   and a.i_periodos <> b.i_periodos
   and (canceladoA = 'false' and canceladoB = 'false');


-- CORREÇÃO
                
update periodos
   set dt_aquis_fin =  //Informar aqui a data do período aquisitivo a ser corrigido
 where i_funcionarios =  //Informar aqui a matrícula do funcionário a ser corrigido
   and i_periodos =  //Informar aqui o id do período a ser corrigido;