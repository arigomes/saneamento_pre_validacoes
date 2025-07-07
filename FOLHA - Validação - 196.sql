-- VALIDAÇÃO 196
-- Categoria esocial com tipos divergentes

select i_vinculos,
	   categoria_esocial,
       descricao,
       tipo_vinculo
  from bethadba.vinculos as v
 where categoria_esocial is not null
   and exists(select first 1
                from bethadba.vinculos as v2
               where v2.categoria_esocial = v.categoria_esocial
                 and v2.tipo_vinculo <> v.tipo_vinculo)
 order by 2 asc;


-- CORREÇÃO

update vinculos as v
   set v.tipo_vinculo = 1
 where i_vinculos = 3;