-- VALIDAÇÃO 1
-- Cadastro de locais de avaliação - O local de avaliação consta com bloco vazio

select i_locais_aval
  from bethadba.locais_aval
 where bloco is null;


-- CORREÇÃO
-- Atualiza os locais de avaliação que não possuem bloco para o bloco padrão (1)
update bethadba.locais_aval
   set bloco = 1
 where bloco is null;