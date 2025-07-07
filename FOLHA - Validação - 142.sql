-- VALIDAÇÃO 142
-- Ordem campo adicional

select nome,
       ordem,
       count(ordem) as quantidade
  from (select 'cargos' as nome, ordem
          from bethadba.cargos_caract_cfg
       union all
        select 'eventos' as nome, ordem
          from bethadba.eventos_caract_cfg
       union all
        select 'tipos_cargos' as nome, ordem
          from bethadba.tipos_cargos_caract_cfg
       union all
        select 'tipos_afast' as nome, ordem
          from bethadba.tipos_afast_caract_cfg
       union all
        select 'atos' as nome, ordem
          from bethadba.atos_caract_cfg
       union all
        select 'areas_atuacao' as nome, ordem
          from bethadba.areas_atuacao_caract_cfg
       union all
        select 'empresas' as nome, ordem
          from bethadba.empresas_ant_caract_cfg
       union all
        select 'niveis' as nome, ordem
          from bethadba.niveis_caract_cfg
       union all
        select 'organogramas' as nome, ordem
          from bethadba.organogramas_caract_cfg
       union all
        select 'funcionario' as nome, ordem
          from bethadba.funcionarios_caract_cfg
       union all
        select 'hist_cargos' as nome, ordem
          from bethadba.hist_cargos_caract_cfg
       union all
        select 'pessoas' as nome, ordem
          from bethadba.pessoas_caract_cfg) as tab
 group by nome, ordem
having quantidade > 1;


-- CORREÇÃO

