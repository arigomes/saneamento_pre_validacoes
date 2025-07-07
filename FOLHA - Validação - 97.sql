-- VALIDAÇÃO 97
-- Numero da certidão maior que 32 caracteres

select i_pessoas,
       modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(pessoas_fis_compl.num_reg)) = 1 then
					'NOVO'
                else
                    'ANTIGO'
                endif,
       numeroNascimento = if modelo = 'ANTIGO' then 
							pessoas_fis_compl.num_reg 
                          else
                            bethadba.dbf_retira_alfa_de_inteiros(pessoas_fis_compl.num_reg)
                          endif
  from bethadba.pessoas_fis_compl
 where numeroNascimento is not null 
   and modelo = 'NOVO'
   and (length(numeroNascimento) > 32 or length(numeroNascimento) < 32);


-- CORREÇÃO

update bethadba.pessoas_fis_compl
   set num_reg = replicate('0', 32 - length(bethadba.dbf_retira_caracteres_especiais(num_reg))) + bethadba.dbf_retira_caracteres_especiais(num_reg)
 where length(bethadba.dbf_retira_caracteres_especiais(num_reg)) < 32
   and num_reg is not null;