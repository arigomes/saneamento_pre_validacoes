-- VALIDAÇÃO 104
-- Eventos sem histórico

select e.i_eventos
  from bethadba.eventos as e
 where e.i_eventos not in (select he.i_eventos
 					  		 from bethadba.hist_eventos as he
 							where he.i_eventos = e.i_eventos);


-- CORREÇÃO
-- Insere os eventos que não possuem histórico na tabela de histórico de eventos

insert into bethadba.hist_eventos
            (i_eventos,
             nome,
             taxa,
             sai_rais,
             compoe_hmes,
             classif_evento,
             desativado,
             codigo_tce,
             inverte_compoe_liq,
             dt_criacao,
             grupo_provisao,
             i_eventos_provisao,
             i_eventos_ajuste_neg,
             i_eventos_distorcao_pos,
             i_eventos_abono,
             i_eventos_fervenc,
             i_eventos_pensmor13,
             deduc_fundo_financ,
             i_atos,
             envia_fly_transparencia,
             montar_base_fgts_integral_afast,
             i_competencias,
             tipo_pd,
             unidade,
             compoe_liq,
             digitou_form,
             cods_conversao,
             seq_impressao,
             descricao,
             caracteristica,
             deduc_prevmun,
             classif_provisao,
             i_eventos_ajuste_pos,
             i_eventos_estorno,
             i_eventos_distorcao_neg,
             i_eventos_ferprop,
             i_eventos_fercoletiva,
             i_agrupadores,
             natureza)
	 select i_eventos,
	 	    nome,taxa,
 		    sai_rais,
 		    compoe_hmes,
		    classif_evento,
		    desativado,
		    codigo_tce,
		    inverte_compoe_liq,
		    dt_criacao,
		    grupo_provisao,
		    i_eventos_provisao,
		    i_eventos_ajuste_neg,
		    i_eventos_distorcao_pos,
		    i_eventos_abono,
		    i_eventos_fervenc,
		    i_eventos_pensmor13,
		    deduc_fundo_financ,
		    i_atos,
		    envia_fly_transparencia,
		    montar_base_fgts_integral_afast,
		    '1900-01-01',
		    tipo_pd,
		    unidade,
		    compoe_liq,
		    digitou_form,
		    cods_conversao,
		    seq_impressao,
		    descricao,
		    caracteristica,
		    deduc_prevmun,
		    classif_provisao,
		    i_eventos_ajuste_pos,
		    i_eventos_estorno,
		    i_eventos_distorcao_neg,
		    i_eventos_ferprop,
		    i_eventos_fercoletiva,
		    i_agrupadores,
	   		natureza
  	   from bethadba.eventos as e
	  where e.i_eventos not in (select he.i_eventos
 	  	 				  		  from bethadba.hist_eventos as he
	 							 where he.i_eventos = e.i_eventos);