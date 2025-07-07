-- VALIDAÇÃO 166
-- CPF inválido

select i_pessoas,
       cpf,
       digitoAtual,
       digitoCalculado
  from (select i_pessoas, 
               cpf,
               MOD(MOD(cast(substring(cpf,1,1) + substring(cpf,2,1) * 2 + substring(cpf,3,1) * 3 + 
                substring(cpf,4,1) * 4 + substring(cpf,5,1) * 5 + substring(cpf,6,1) * 6 +
                substring(cpf,7,1) * 7 + substring(cpf,8,1) * 8 + substring(cpf,9,1) * 9 as int), 11), 10) as resto1,
               MOD(MOD(cast(substring(cpf,2,1) + substring(cpf,3,1) * 2 + substring(cpf,4,1) * 3 + 
                substring(cpf,5,1) * 4 + substring(cpf,6,1) * 5 + substring(cpf,7,1) * 6 + 
                substring(cpf,8,1) * 7 + substring(cpf,9,1) * 8 + resto1 * 9 as int),11),10) as resto2,
               string(resto1) || string(resto2) as digitoCalculado,
               right(cpf,2) as digitoAtual
          from bethadba.hist_pessoas_fis as hpf
         where cpf is not null and cpf <> ''
           and right(cpf,2) <> digitoCalculado
           and length(cpf) = 11) as tab;

-- CORREÇÃO

update hist_pessoas_fis 
   set cpf = 
 where i_pessoas = 49;

update pessoas_fisicas
   set cpf = 
 where i_pessoas = 49;