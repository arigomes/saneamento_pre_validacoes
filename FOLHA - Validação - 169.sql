/*
 -- VALIDAÇÃO 169
 * Data da primeira CNH maior que a da emissão da CNH
 */

select pfc.i_pessoas,
         pfc.dt_primeira_cnh,
         pfc.dt_emissao_cnh
          from bethadba.pessoas_fis_compl pfc 
          where pfc.dt_primeira_cnh > pfc.dt_emissao_cnh 
          and pfc.dt_primeira_cnh is not null and pfc.dt_emissao_cnh is not null

/*
 -- CORREÇÃO
 */

update bethadba.pessoas_fis_compl pfc 
set dt_primeira_cnh = dt_emissao_cnh
where pfc.dt_primeira_cnh > pfc.dt_emissao_cnh 
          and pfc.dt_primeira_cnh is not null and pfc.dt_emissao_cnh is not null
          
