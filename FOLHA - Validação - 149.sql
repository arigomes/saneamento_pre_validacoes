-- VALIDAÇÃO 149
-- Pensionistas não registrados

select f.i_entidades,
       f.i_funcionarios,
       f.tipo_pens
  from bethadba.funcionarios as f 
 where f.tipo_pens in (1,2)
   and f.tipo_func = 'B'
   and not exists (select 1
                     from bethadba.beneficiarios as b
                    where f.i_entidades = b.i_entidades
                      and f.i_funcionarios = b.i_funcionarios)
 order by 1,2 asc;


-- CORREÇÃO

