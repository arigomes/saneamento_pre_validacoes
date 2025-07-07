-- VALIDAÇÃO 192
-- Numero de certidão civil duplicada

select i_pessoas,
       modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(A.num_reg)) = 1 then
       				    'NOVO'
                else
                  'ANTIGO'
                endif,
       numeroNascimento = if modelo = 'ANTIGO' then 
							              A.num_reg 
                          else
                            bethadba.dbf_retira_alfa_de_inteiros(A.num_reg)
                          endif
  from bethadba.pessoas_fis_compl A
 where numeroNascimento is not null
   and exists(select first modeloB = if isnumeric(bethadba.dbf_retira_caracteres_especiais(B.num_reg)) = 1 then
                                        'NOVO'
                        			       else
				                                'ANTIGO'
                			               endif,
		                 numeroNascimentoB = if modeloB = 'ANTIGO' then 
										                  			B.num_reg 
			                                   else
             				                        bethadba.dbf_retira_alfa_de_inteiros(B.num_reg)
                             				     endif
	              from bethadba.pessoas_fis_compl B
	             where A.i_pessoas <> B.i_pessoas
                 and numeroNascimentoB = numeroNascimento);


-- CORREÇÃO

update pessoas_fis_compl
   set num_reg = null
 where i_pessoas in (33,34,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,69,63,64,65,66,67,68);