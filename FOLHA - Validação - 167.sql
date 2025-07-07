-- VALIDAÇÃO 167
-- Ceritidão de obito nulas

select i_pessoas,
       dt_obito,
       ehfalecido 
  from bethadba.pessoas_fis_obito as pfo
 where ehfalecido = 'S'
   and certidao is null;

-- CORREÇÃO

