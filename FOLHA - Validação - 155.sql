-- VALIDAÇÃO 155
-- Dependente sem motivo de inicio

select i_pessoas, 
       i_dependentes 
  from bethadba.dependentes d
 where mot_ini_depende is null;


-- CORREÇÃO
-- Atribui o motivo '1 - Nascimento' ao dependente que não possui motivo de início

update bethadba.dependentes
   set mot_ini_depende = case
                            when grau = 1 then 1
                            when grau = 2 then 7
                         end
 where grau in (1, 2)
   and mot_ini_depende is null;