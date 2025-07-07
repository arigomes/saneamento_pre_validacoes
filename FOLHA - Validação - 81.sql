-- VALIDAÇÃO 81
-- Inscrição municipal da pessoa Juridica maior que 9 digitos

select i_pessoas as pessoa 
  from bethadba.pessoas
 where tipo_pessoa = 'J' 
   and length(inscricao_municipal) > 9;


-- CORREÇÃO
-- Atualiza a inscrição municipal para '0' onde o tipo de pessoa é 'J' e a inscrição municipal tem mais de 9 dígitos

update bethadba.pessoas
   set inscricao_municipal = '0'
 where tipo_pessoa = 'J'
   and length(inscricao_municipal) > 9;