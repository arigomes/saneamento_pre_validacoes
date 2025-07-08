-- VALIDAÇÃO 92
-- Funcionarios sem local de trabalho principal

select principal = if isnull(locais_mov.principal,'N') = 'S' then 'true' else 'false' endif,
       i_funcionarios func,
       count(principal) as total
  from bethadba.locais_mov
 where i_funcionarios = i_funcionarios 
   and i_entidades = i_entidades
   and principal = 'false'
   and i_funcionarios not in (select lm.i_funcionarios      
                                from bethadba.locais_mov lm
                               where lm.i_funcionarios = locais_mov.i_funcionarios 
                                 and lm.i_entidades = locais_mov.i_entidades
                                 and lm.principal = 'S')
 group by principal, i_funcionarios
having total > 1
 order by locais_mov.i_funcionarios;


-- CORREÇÃO
-- Atualiza o local de trabalho principal para os funcionarios que não possuem um definido
-- Atribui o local de trabalho com maior i_locais_trab como principal

update bethadba.locais_mov
   set principal = 'S'
 where i_funcionarios = i_funcionarios 
   and i_entidades = i_entidades
   and principal = 'N'
   and i_locais_trab = (select max(i_locais_trab)
                          from bethadba.locais_mov lm
                         where lm.i_funcionarios = locais_mov.i_funcionarios 
                           and lm.i_entidades = locais_mov.i_entidades
                           and lm.principal = 'N')
   and i_funcionarios not in (select lm.i_funcionarios      
                                from bethadba.locais_mov lm
                               where lm.i_funcionarios = locais_mov.i_funcionarios 
                                 and lm.i_entidades = locais_mov.i_entidades
                                 and lm.principal = 'S');