-- VALIDAÇÃO 17
-- Necessario possuir uma area de atuação

select i_entidades,
       i_concursos,
       i_candidatos
  from bethadba.candidatos as c
 where i_areas_atuacao is null;


-- CORREÇÃO
-- Insere área de atuação nos cargos dos concursos quando não existe área de atuação vinculada ao cargo no concurso
insert into bethadba.areas_conhec(i_entidades,i_concursos,i_cargos,num_vagas,i_areas_atuacao,num_vagas_gerais,reserva_vagas_gerais,local_distr_vagas_gerais,num_vagas_deffis,reserva_vagas_deffis,local_distr_vagas_deffis,num_vagas_afrodescendentes,reserva_vagas_afro,local_distr_vagas_afro,num_vagas_indio,reserva_vagas_indio,local_distr_vagas_indio,num_vagas_comp_afrod_indio,reserva_vagas_comp_afrod_indio,local_distr_vagas_comp_afrod_indio)
select cc.i_entidades,
	     cc.i_concursos,
	     cc.i_cargos,
	     cc.num_vagas,
	     2,
	     cc.num_vagas,
	     null,
	     null,
	     null,
	     null,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null
  from bethadba.cargos_concursos as cc
 where not exists(select 1
                    from bethadba.areas_conhec as ac
                   where ac.i_entidades = cc.i_entidades
                     and ac.i_concursos = cc.i_concursos
                     and ac.i_cargos = cc.i_cargos);

-- Atualiza os candidatos que não possuem área de atuação para a área de atuação padrão (1)
update bethadba.candidatos
   set i_areas_atuacao = (select i_areas_atuacao
                            from bethadba.areas_conhec as ac
                           where ac.i_entidades = candidatos.i_entidades
                             and ac.i_concursos = candidatos.i_concursos
                             and ac.i_cargos = candidatos.i_cargos)
 where i_areas_atuacao is null;