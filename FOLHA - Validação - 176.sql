-- VALIDAÇÃO 176
-- Conselheiro com vinculo com a categoria_esocial diferente de 771

select hf.i_entidades,
       hf.i_funcionarios,
       hf.i_vinculos 
  from bethadba.hist_funcionarios as hf
  join bethadba.funcionarios as f
    on hf.i_entidades = f.i_entidades
   and hf.i_funcionarios = f.i_funcionarios
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where f.tipo_func = 'A' 
   and f.conselheiro_tutelar = 'S'
   and v.categoria_esocial <> '771';


-- CORREÇÃO

update hist_funcionarios
   set i_vinculos = 18
 where i_funcionarios in (2642,2642,1794,1796,1793,1795,1797,2377,2376,2456);