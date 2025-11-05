-- VALIDAÇÃO 20
-- Renomeia os vinculos empregaticios repetidos

select list(i_vinculos) as vinculos, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.vinculos 
 group by descricao 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os vinculos empregaticios repetidos para evitar duplicidade, adicionando o i_vinculos ao nome do vinculo

update bethadba.vinculos v
   set descricao = v.i_vinculos || ' - ' || v.descricao
 where exists (select 1
                 from bethadba.vinculos v2
                where v2.descricao = v.descricao
                  and v2.i_vinculos <> v.i_vinculos)
   and v.i_vinculos <> (select min(v3.i_vinculos)
                          from bethadba.vinculos v3
                         where v3.descricao = v.descricao)
   and v.descricao not like v.i_vinculos || ' - %';