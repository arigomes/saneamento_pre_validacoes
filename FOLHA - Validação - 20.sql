-- VALIDAÇÃO 20
-- Renomeia os vinculos empregaticios repetidos

select list(i_vinculos) as vinculos, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.vinculos 
 group by descricao 
having quantidade > 1;


-- CORREÇÃO

update bethadba.vinculos
   set vinculos.descricao = vinculos.i_vinculos || vinculos.descricao
 where i_vinculos in (2, 12);