-- VALIDAÇÃO 16
-- Descrição maior que o numero permitido de caracteres - Descrição maior que o numero permitido de caracteres(500)

select i_fatores,
       nome
  from bethadba.fatores as f
 where length(f.descricao) > 500;


-- CORREÇÃO

