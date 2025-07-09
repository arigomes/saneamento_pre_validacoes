-- VALIDAÇÃO 106
-- Pessoas com certidão de nasicmento maior que 32 caracteres

select i_pessoas,
       num_reg
  from bethadba.pessoas_fis_compl
 where length(num_reg)  > 32;


-- CORREÇÃO
-- Atualiza o campo num_reg para null onde o tamanho é maior que 32 caracteres

update bethadba.pessoas_fis_compl
   set num_reg = null
 where length(num_reg) > 32;