-- VALIDAÇÃO 1
-- Cadastro de locais de avaliação - O local de avaliação consta com bloco vazio

select i_locais_aval
  from bethadba.locais_aval
 where bloco is null;


-- CORREÇÃO

