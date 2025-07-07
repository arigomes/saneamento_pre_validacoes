-- VALIDAÇÃO 157
-- Dados faltantes em endereços de pessoas

select i_pessoas
  from bethadba.pessoas_enderecos as pe 
 where pe.i_ruas is null
    or pe.i_bairros is null
    or pe.i_cidades is null;


-- CORREÇÃO

update bethadba.pessoas_enderecos
   set i_ruas = (select max(i_ruas) from bethadba.entidades),
       i_bairros = (select max(i_bairros) from bethadba.entidades),
       i_cidades = (select max(i_cidades) from bethadba.entidades)
 where i_ruas is null
    or i_bairros is null
    or i_cidades is null;