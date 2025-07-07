-- VALIDAÇÃO 14
-- Verifica os nomes dos tipos bases repetidos

select list(i_tipos_bases) tiposs, 
       nome, 
       count(nome) as quantidade
  from bethadba.tipos_bases 
 group by nome 
having quantidade > 1;


-- CORREÇÃO
  
