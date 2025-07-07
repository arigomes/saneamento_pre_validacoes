-- VALIDAÇÃO 68
-- Quando a forma de pagamento for Crédito em conta é necessário informar a conta bancária

select i_funcionarios,
       i_entidades,
       mensagem_erro = 'Funcionarios com recebimento credito em conta sem dados da conta bancaria'
  from bethadba.hist_funcionarios as hf 
 where forma_pagto = 'R'
   and i_pessoas_contas is null;


-- CORREÇÃO

