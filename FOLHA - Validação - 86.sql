-- VALIDAÇÂO 86
-- Pessoas fisicas com email incorreto

select i_pessoas as pessoa, 
       email
  from bethadba.pessoas
 where email is not null
   and bethadba.dbf_valida_email(trim(email)) = 1;


-- CORREÇÃO
-- Corrige o email para NULL se for inválido

update bethadba.pessoas
   set email = 'ficticio_' || cast(i_pessoas as varchar) || '@dominiofalso.com'
 where email is not null
   and bethadba.dbf_valida_email(trim(email)) = 1;