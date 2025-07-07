-- VALIDAÇÃO 25
-- Verifica históricos salariais com salário zerado ou nulo

select i_entidades, 
       i_funcionarios, 
       dt_alteracoes 
  from bethadba.hist_salariais
 where salario in (0, null);


-- CORREÇÃO

update bethadba.hist_salariais
   set salario = 0.01
 where salario = 0 or salario is null;