-- VALIDAÇÃO 132
-- Obrigatório informar a entidade educacional (S/N)

select i_entidades,
	     indicativo_entidade_educativa
  from bethadba.hist_entidades_compl as hec
 where indicativo_entidade_educativa is null;


-- CORREÇÃO

update bethadba.hist_entidades_compl
   set indicativo_entidade_educativa = 'N'
 where indicativo_entidade_educativa is null;