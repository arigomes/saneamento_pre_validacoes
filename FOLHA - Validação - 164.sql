-- VALIDAÇÃO 164
-- Autônomos com categorias diferentes de contribuinte individual

select f.i_entidades,
       f.i_funcionarios,
       f.tipo_func, 
       hf.i_vinculos, 
       v.categoria_esocial  
  from bethadba.funcionarios f 
  join bethadba.hist_funcionarios hf
    on f.i_entidades = hf.i_entidades
   and f.i_funcionarios = hf.i_funcionarios
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos 
 where f.tipo_func = 'A'
   and v.categoria_esocial not in ('701')
   and f.conselheiro_tutelar = 'N';

-- CORREÇÃO

update funcionarios
   set conselheiro_tutelar = 'S'
 where i_funcionarios in (747,748,749,1000);