-- VALIDAÇÃO 116
-- Verifica os funcionarios sem historico de cargo

select i_funcionarios
  from bethadba.funcionarios  
 where i_funcionarios not in (select i_funcionarios
                                from bethadba.hist_cargos);


-- CORREÇÃO

