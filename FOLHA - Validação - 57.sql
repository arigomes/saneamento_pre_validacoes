-- VALIDAÇÃO 57
-- Busca os funcionários com data de nomeação maior que a data de posse

select i_funcionarios 
  from bethadba.hist_cargos
 where dt_nomeacao > dt_posse;


-- CORREÇÃO
-- Atualiza a data de nomeação para ser igual à data de posse

update bethadba.hist_cargos
   set dt_nomeacao = dt_posse
 where dt_nomeacao > dt_posse;