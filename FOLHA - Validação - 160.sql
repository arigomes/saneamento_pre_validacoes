-- VALIDAÇÃO 160
-- Averbação sem tipo de conta

select distinct hf.i_entidades,
       hf.i_funcionarios
  from bethadba.hist_funcionarios as hf 
  join bethadba.vinculos as v
    on hf.i_vinculos = v.i_vinculos
 where v.gera_licpremio = 'S'
   and exists (select 1
                 from bethadba.funcionarios as f
                where f.i_entidades = hf.i_entidades
                  and f.i_funcionarios = hf.i_funcionarios
                  and f.tipo_func = 'F'
   and f.conta_licpremio = 'N');


-- CORREÇÃO
-- Atualiza conta_licpremio para 'S' para funcionários com tipo_func = 'F' e conta_licpremio = 'N' e possui vinculo com adicionais

update bethadba.funcionarios f
   set conta_licpremio = 'S'
  from bethadba.hist_funcionarios hf
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where v.gera_licpremio = 'S'
   and f.tipo_func = 'F'
   and f.i_entidades = hf.i_entidades
   and f.i_funcionarios = hf.i_funcionarios
   and f.conta_licpremio = 'N';