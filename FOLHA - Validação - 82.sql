-- VALIDAÇÃO 82
-- Verifica  Cnpj Inválido

select i_pessoas as pessoa
  from bethadba.pessoas_juridicas
 where cnpj is not null
   and bethadba.dbf_valida_cgc_cpf(cnpj, null, 'J') = 0;


-- CORREÇÃO

update bethadba.pessoas_juridicas
   set cnpj = '47606434000101'
 where cnpj is not null
   and bethadba.dbf_valida_cgc_cpf(cnpj, null, 'J') = 0;