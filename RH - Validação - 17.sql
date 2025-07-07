-- VALIDAÇÃO 17
-- Necessario possuir uma area de atuação

select i_entidades,
       i_concursos,
       i_candidatos
  from bethadba.candidatos as c
 where i_areas_atuacao is null;


-- CORREÇÃO

