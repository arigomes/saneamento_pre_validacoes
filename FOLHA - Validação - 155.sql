-- VALIDAÇÃO 155
-- Dependente sem motivo de inicio

select i_pessoas,
       i_dependentes,
       grau
  from bethadba.dependentes d
 where mot_ini_depende is null;


-- CORREÇÃO
-- Atribui o motivo '1 - Nascimento' ao dependente que não possui motivo de início

update bethadba.dependentes
   set mot_ini_depende = case
                            when grau = 1 then 1
                            when grau = 2 then 7
                            when grau = 10 then 9
                            when grau = 9 then 8
                            when grau = 3 then 9
                         end
 where mot_ini_depende is null;