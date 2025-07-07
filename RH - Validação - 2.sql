-- VALIDAÇÃO 2
-- Cadastro de distância - O total de KM não pode estar nulo

select i_distancias,
	     total_km
  from bethadba.distancias
 where total_km is null;


-- CORREÇÃO

update bethadba.distancias
   set total_km = 999
 where total_km is null;