/*
 -- VALIDAÇÃO 168
 * Data de CNH maior que a data de nascimento
 */

select pf.i_pessoas,
                pf.dt_nascimento,
                pfc.dt_primeira_cnh 
          from bethadba.pessoas_fis_compl pfc 
          join bethadba.pessoas_fisicas pf on pfc.i_pessoas = pf.i_pessoas 
          where dt_primeira_cnh < pf.dt_nascimento and dt_primeira_cnh is not null


/*
 -- CORREÇÃO
 */

update bethadba.pessoas_fis_compl pfc
join bethadba.pessoas_fisicas pf on pfc.i_pessoas = pf.i_pessoas
set pfc.dt_primeira_cnh = DATEADD(year, 18, pf.dt_nascimento)
where pfc.dt_primeira_cnh < pf.dt_nascimento and pfc.dt_primeira_cnh is not null;
