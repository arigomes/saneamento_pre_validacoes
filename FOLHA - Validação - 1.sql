-- VALIDAÇÃO 01
-- Descricao de Logradouros Duplicadas

select list(i_ruas) as ruas, 
       trim(nome) as nome,
       i_cidades, 
       count(nome) as quantidade
  from bethadba.ruas 
 group by nome, i_cidades
having quantidade > 1;


-- CORREÇÃO
-- Atualiza o nome das ruas duplicadas para incluir o ID da cidade

update bethadba.ruas
   set nome = nome || ' - ' || i_cidades
 where i_ruas in (select i_ruas
                    from bethadba.ruas 
                   group by nome, i_cidades
                  having count(nome) > 1);