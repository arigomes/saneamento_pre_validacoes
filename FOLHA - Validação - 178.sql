-- VALIDAÇÃO 178
-- Funcionario com vinculo com a categoria_esocial 771 ou 701

select hf.i_entidades,
       hf.i_funcionarios,
       hf.i_vinculos,
       v.categoria_esocial
  from bethadba.hist_funcionarios as hf 
  join bethadba.funcionarios as f
    on hf.i_entidades = f.i_entidades
   and hf.i_funcionarios = f.i_funcionarios 
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where f.tipo_func = 'F'
   and v.categoria_esocial in ('701','771');


-- Correção

update hist_funcionarios as hf
   set hf.i_vinculos = 5
  from funcionarios as f,
       vinculos as v
 where hf.i_entidades = f.i_entidades
   and hf.i_funcionarios = f.i_funcionarios
   and hf.i_vinculos = v.i_vinculos
   and f.tipo_func = 'F'
   and v.categoria_esocial in ('701','771')
   and f.i_funcionarios in (354);