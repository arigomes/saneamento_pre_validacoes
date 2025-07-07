-- VALIDAÇÃO 16
-- Verifica os atos com número nulos

select i_atos
  from bethadba.atos 
 where num_ato is null
    or num_ato = '';


-- CORREÇÃO

update bethadba.atos 
   set num_ato = i_atos 
 where num_ato is null
    or num_ato = '';