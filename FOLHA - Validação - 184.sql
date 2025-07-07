-- VALIDAÇÃO 184
-- Descrição da natureza de texto jurídica duplicada

select a.i_natureza_texto_juridico,
       a.descricao
  from bethadba.natureza_texto_juridico as a
 where exists(select first 1
                from bethadba.natureza_texto_juridico as b
               where b.descricao = a.descricao
                 and b.i_natureza_texto_juridico <> a.i_natureza_texto_juridico);


-- CORREÇÃO

