-- VALIDAÇÃO 66
-- Verifica horas mês zerado

select hist_salariais.i_entidades entidade, 
       hist_salariais.i_funcionarios func, 
       hist_salariais.dt_alteracoes dt_alt
  from bethadba.hist_salariais 
  join bethadba.funcionarios f
 where cast(hist_salariais.horas_mes as integer) < 1
   and tipo_func != 'A'
 order by hist_salariais.i_entidades,
          hist_salariais.i_funcionarios, 
          hist_salariais.dt_alteracoes;


-- CORREÇÃO
-- Atualiza horas mês para 220 quando zerado e não for tipo A
-- Considera que o mês tem 220 horas
 
update bethadba.hist_salariais  
   set horas_mes = 220
  from bethadba.funcionarios
 where cast(hist_salariais.horas_mes as integer) < 1
   and hist_salariais.i_entidades = funcionarios.i_entidades
   and hist_salariais.i_funcionarios = funcionarios.i_funcionarios
   and tipo_func != 'A';