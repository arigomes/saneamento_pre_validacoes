-- VALIDAÇÃO 158
-- Dados divergentes em endereços de pessoas

select pe.i_pessoas,
	     pe.i_cidades,
	     r.i_cidades
  from bethadba.pessoas_enderecos as pe
  join bethadba.ruas as r
    on pe.i_ruas = r.i_ruas
 where pe.i_cidades <> r.i_cidades;


-- CORREÇÃO

update bethadba.pessoas_enderecos as pe
   set pe.i_cidades = r.i_cidades 
  from bethadba.ruas as r
 where r.i_ruas = pe.i_ruas
   and r.i_cidades <> pe.i_cidades;