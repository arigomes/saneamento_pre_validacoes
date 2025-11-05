-- VALIDAÇÃO 113
-- Verifica os afastamentos concomitantes com ferias do funcionario

select a.i_funcionarios,
       a.dt_inicial,
       b.dt_afastamento,
       b.dt_ultimo_dia
  from bethadba.faltas a 
  join bethadba.afastamentos b
    on a.i_funcionarios = b.i_funcionarios 
 where a.dt_inicial between b.dt_afastamento and b.dt_ultimo_dia and a.i_entidades = b.i_entidades;


-- CORREÇÃO
-- Atualiza a data do afastamento para o dia seguinte ao término da falta para os funcionários que possuem afastamentos concomitantes com faltas

update bethadba.afastamentos as b
   set b.dt_afastamento = DATEADD(dd, 1, a.dt_inicial)
  from bethadba.faltas as a
 where a.dt_inicial between b.dt_afastamento and b.dt_ultimo_dia
   and a.i_funcionarios = b.i_funcionarios
   and a.i_entidades = b.i_entidades
   and not exists (select 1
                     from bethadba.afastamentos as a2
      		        where a2.i_funcionarios = b.i_funcionarios
                      and a2.dt_afastamento = DATEADD(dd, 1, a.dt_inicial));