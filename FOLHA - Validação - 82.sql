-- VALIDAÇÃO 82
-- Verifica Cnpj Inválido

select i_pessoas as pessoa
  from bethadba.pessoas_juridicas
 where cnpj is not null
   and bethadba.dbf_valida_cgc_cpf(cnpj, null, 'J') = 0;


-- CORREÇÃO
-- Atualiza o CNPJ inválido para um CNPJ válido fictício

update bethadba.pessoas_juridicas
   set cnpj = null
 where cnpj is not null
   and bethadba.dbf_valida_cgc_cpf(cnpj, null, 'J') = 0;