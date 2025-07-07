-- VALIDAÇÃO 52
-- Verifica os grupos funcionais repetidos

select list(i_entidades) as entidades,
       list(i_grupos) as grupos,
       nome,
       count(nome) as quantidade
  from bethadba.grupos
 group by nome 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os nomes dos grupos funcionais repetidos, adicionando o identificador da entidade ao final do nome

update bethadba.grupos as a
   set a.nome = a.nome || '-' || a.i_entidades 
  from bethadba.grupos as b
 where a.i_grupos = b.i_grupos
   and a.nome = b.nome 
   and a.i_entidades <> b.i_entidades 
   and a.i_entidades > b.i_entidades;