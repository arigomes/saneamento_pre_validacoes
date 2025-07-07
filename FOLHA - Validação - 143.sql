-- VALIDAÇÃO 143
-- Ordem duplicada de campos adicionais

select nome,
	     ordem,
	     list(codigo),
	     count(ordem) as quantidade
  from (select 'cargos' as nome, ordem, i_caracteristicas as codigo
          from bethadba.cargos_caract_cfg 
        union all    
        select 'eventos' as nome, ordem, i_caracteristicas as codigo
          from bethadba.eventos_caract_cfg
        union all    
        select 'tipos_cargos' as nome, ordem, i_caracteristicas as codigo
          from bethadba.tipos_cargos_caract_cfg
        union all    
        select 'tipos_afast' as nome, ordem, i_caracteristicas as codigo
          from bethadba.tipos_afast_caract_cfg
        union all    
        select 'atos' as nome, ordem, i_caracteristicas as codigo
          from bethadba.atos_caract_cfg
        union all    
        select 'areas_atuacao' as nome, ordem, i_caracteristicas as codigo
          from bethadba.areas_atuacao_caract_cfg
        union all    
        select 'empresas' as nome, ordem, i_caracteristicas as codigo
          from bethadba.empresas_ant_caract_cfg    
        union all    
        select 'niveis' as nome, ordem, i_caracteristicas as codigo
          from bethadba.niveis_caract_cfg        
        union all    
        select 'organogramas' as nome, ordem, i_caracteristicas as codigo
          from bethadba.organogramas_caract_cfg
        union all    
        select 'funcionario' as nome, ordem, i_caracteristicas as codigo
          from bethadba.funcionarios_caract_cfg fcc
        union all    
        select 'hist_cargos' as nome, ordem, i_caracteristicas as codigo
          from bethadba.hist_cargos_caract_cfg    
        union all    
        select 'pessoas' as nome, ordem, i_caracteristicas as codigo
          from bethadba.pessoas_caract_cfg) as tab
 group by nome, ordem
having quantidade > 1;


-- CORREÇÃO

update bethadba.cargos_caract_cfg 
   set ordem = 6
 where i_caracteristicas = 23901;