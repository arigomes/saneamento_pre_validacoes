-- VALIDAÇÃO 146
-- Cpf inválido

select i_pessoas ,
       dt_alteracoes ,
       isnumeric(cpf) as validacao 
  from bethadba.hist_pessoas_fis hpf 
 where cpf is not null
   and cpf <> ''
   and validacao = 0;


-- CORREÇÃO

