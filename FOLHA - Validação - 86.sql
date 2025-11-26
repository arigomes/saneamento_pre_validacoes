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
   set email = case
                when lower(replace(replace(replace(trim(replace(replace(email, 'ç', 'c'), 'ã', 'a')),' ', ''),',', ''))) like '%.com' then
                  replace(replace(replace(trim(replace(replace(email, 'ç', 'c'), 'ã', 'a')), ' ', ''), ',', '')
                else
                  replace(replace(replace(trim(replace(replace(email, 'ç', 'c'), 'ã', 'a')), ' ', ''), ',', '') ) || '.com'
                end
 where email is not null
   and bethadba.dbf_valida_email(trim(email)) = 1;