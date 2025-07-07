-- VALIDAÇÃO 2
-- Busca as descrições repetidas na turma

select list(i_entidades) as entidades, 
       list(i_turmas) as turma, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.turmas
 group by descricao 
having quantidade > 1;


-- CORREÇÃO

