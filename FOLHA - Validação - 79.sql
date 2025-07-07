-- VALIDAÇÃO 79
-- Funcionarios em férias no dia da rescisão

select rescisoes.i_entidades entidade, 
       rescisoes.i_funcionarios func, 
       rescisoes.dt_rescisao dt_resc, 
       ferias.dt_gozo_ini dt_ini_gozo, 
       ferias.dt_gozo_fin dt_fin_gozo
  from bethadba.rescisoes
  join bethadba.ferias
    on (ferias.i_entidades = rescisoes.i_entidades
   and ferias.i_funcionarios = rescisoes.i_funcionarios)
 where rescisoes.dt_canc_resc is null
   and rescisoes.dt_rescisao >= ferias.dt_gozo_ini
   and rescisoes.dt_rescisao <= ferias.dt_gozo_fin;


-- CORREÇÃO
-- Atualiza a data de rescisão para o dia seguinte ao término do gozo de férias

update bethadba.rescisoes, bethadba.ferias
   set bethadba.rescisoes.dt_rescisao = dateadd(day, 1, dt_gozo_fin)
 where bethadba.ferias.i_entidades = rescisoes.i_entidades
   and bethadba.ferias.i_funcionarios = rescisoes.i_funcionarios
   and bethadba.ferias.dt_gozo_fin >= rescisoes.dt_rescisao
   and rescisoes.dt_canc_resc is null;