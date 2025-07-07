/*
 -- VALIDAÇÃO 120
 * Concursos sem data de homologação informada
 */

select
concursos.i_entidades, 
concursos.i_concursos,
candidatos.i_candidatos,
concursos.dt_homolog
from bethadba.candidatos left join bethadba.concursos
on candidatos.i_concursos = concursos.i_concursos
                              where  candidatos.dt_nomeacao is null
                              and candidatos.dt_posse is null
                              and candidatos.dt_doc_nao_posse is null
                              and candidatos.dt_prorrog_posse is null
                              and concursos.dt_homolog is null

/*
 -- CORREÇÃO
 */

update bethadba.candidatos 
left join bethadba.concursos on candidatos.i_concursos = concursos.i_concursos
set dt_homolog = dateadd(dd,30,dt_ini_insc)
where i_candidatos in (select
candidatos.i_candidatos
from bethadba.candidatos left join bethadba.concursos
on candidatos.i_concursos = concursos.i_concursos
                              where  candidatos.dt_nomeacao is null
                              and candidatos.dt_posse is null
                              and candidatos.dt_doc_nao_posse is null
                              and candidatos.dt_prorrog_posse is null
                              and concursos.dt_homolog is null)    
and dt_homolog is null;
  