-- VALIDAÇÃO 1
-- Busca as descrições repetidas no horário ponto

select list(i_entidades) as entidades, 
       list(i_horarios_ponto) as horario, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.horarios_ponto
 group by descricao 
having quantidade > 1;


-- CORREÇÃO

