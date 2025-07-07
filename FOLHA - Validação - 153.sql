-- VALIDAÇÃO 153
-- Lotação fisica principal

select i_entidades,
       i_funcionarios,
       count(*) as total 
  from bethadba.locais_mov lm 
 where principal = 'S'
 group by i_entidades, i_funcionarios  
having total > 1
 order by 1,2 asc;


-- CORREÇÃO

update bethadba.locais_mov lm
   set lm.principal = 'N'
 where lm.principal = 'S'
   and exists (select 1
                 from bethadba.locais_mov lm2
                where lm2.i_entidades = lm.i_entidades
                  and lm2.i_funcionarios = lm.i_funcionarios
                  and lm2.principal = 'S'
                group by lm2.i_entidades, lm2.i_funcionarios
               having count(*) > 1);